/// Document Service
/// 
/// Single Responsibility: Handles document download operations
/// Dependency Inversion: Depends on abstractions

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../api/payment_api.dart';
import 'notification_service.dart';

class DocumentService {
  final PaymentApi _paymentApi = PaymentApi();
  final NotificationService _notificationService = NotificationService();

  /// Download document from URL (gets signed URL first if needed)
  /// Shows notifications for download progress and completion
  Future<File?> downloadDocument({
    required String url,
    required String filename,
  }) async {
    // Generate unique notification ID based on filename hash
    final notificationId = filename.hashCode.abs() % 2147483647;
    
    try {
      // Initialize notification service
      await _notificationService.initialize();

      // Validate URL
      if (url.isEmpty) {
        throw Exception('Document URL is empty');
      }

      // Sanitize filename
      final sanitizedFilename = _sanitizeFilename(filename);

      // Show download started notification
      await _notificationService.showDownloadStarted(sanitizedFilename, notificationId);

      // Get signed URL from backend for GCS files
      String downloadUrl = url;
      
      // Check if this is a GCS URL
      try {
        final uri = Uri.parse(url);
        if (uri.host == 'storage.googleapis.com') {
          // Get signed URL from backend - required for private buckets
          downloadUrl = await _paymentApi.getDocumentDownloadUrl(url);
        }
      } catch (e) {
        // If URL parsing fails, throw error
        if (e.toString().contains('FormatException') || e.toString().contains('Invalid')) {
          await _notificationService.showDownloadFailed(sanitizedFilename, 'Invalid URL format', notificationId);
          throw Exception('Invalid document URL format');
        }
        // If getting signed URL fails, throw the error to be handled by outer catch
        rethrow;
      }

      // Validate URL format
      Uri? uri;
      try {
        uri = Uri.parse(downloadUrl);
        if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
          throw Exception('Invalid URL format');
        }
      } catch (e) {
        await _notificationService.showDownloadFailed(sanitizedFilename, 'Invalid URL format', notificationId);
        throw Exception('Invalid document URL: $downloadUrl');
      }

      // Request storage permission (Android 13+ uses different permissions)
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use photos permission for images
        // For other files, try storage permissions
        final androidInfo = await Permission.photos.status;
        if (androidInfo.isDenied) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            // Try storage permission as fallback
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              // For Android 13+, try manageExternalStorage (requires special handling)
              if (await _isAndroid13OrHigher()) {
                // Use app-specific directory which doesn't require special permissions
                // This will work without manageExternalStorage
              } else {
                await _notificationService.showDownloadFailed(sanitizedFilename, 'Storage permission denied', notificationId);
                throw Exception('Storage permission denied. Please grant storage permission in app settings.');
              }
            }
          }
        }
      }

      // Get download directory - prefer app-specific directory for compatibility
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Ensure unique filename if file already exists
      var filePath = '${downloadsDir.path}/$sanitizedFilename';
      var counter = 1;
      while (await File(filePath).exists()) {
        final lastDotIndex = sanitizedFilename.lastIndexOf('.');
        if (lastDotIndex > 0) {
          final nameWithoutExt = sanitizedFilename.substring(0, lastDotIndex);
          final ext = sanitizedFilename.substring(lastDotIndex);
          filePath = '${downloadsDir.path}/${nameWithoutExt}_$counter$ext';
        } else {
          filePath = '${downloadsDir.path}/${sanitizedFilename}_$counter';
        }
        counter++;
        if (counter > 1000) break; // Prevent infinite loop
      }

      // Download file with progress tracking
      final client = http.Client();
      try {
        final request = http.Request('GET', uri);
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            client.close();
            throw Exception('Download timeout: File took too long to download');
          },
        );

        if (streamedResponse.statusCode != 200) {
          await _notificationService.showDownloadFailed(sanitizedFilename, 'HTTP ${streamedResponse.statusCode}', notificationId);
          throw Exception('Failed to download file: HTTP ${streamedResponse.statusCode}');
        }

        final contentLength = streamedResponse.contentLength ?? 0;
        final file = File(filePath);
        final sink = file.openWrite();

        int downloaded = 0;

        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          downloaded += chunk.length;

          // Update progress notification (every 10%)
          if (contentLength > 0) {
            final progress = ((downloaded / contentLength) * 100).round();
            if (progress % 10 == 0 || downloaded == contentLength) {
              await _notificationService.showDownloadProgress(sanitizedFilename, notificationId, progress);
            }
          }
        }

        await sink.close();

        if (await file.length() == 0) {
          await _notificationService.showDownloadFailed(sanitizedFilename, 'Downloaded file is empty', notificationId);
          throw Exception('Downloaded file is empty');
        }

        // Show download completed notification
        await _notificationService.showDownloadCompleted(sanitizedFilename, filePath, notificationId);

        return file;
      } finally {
        client.close();
      }
    } catch (e) {
      // Generate notification ID for error notification
      final notificationId = filename.hashCode.abs() % 2147483647;
      final sanitizedFilename = _sanitizeFilename(filename);
      
      // Provide more specific error messages
      final errorString = e.toString();
      String userFriendlyError;
      
      if (errorString.contains('permission')) {
        userFriendlyError = 'Permission denied. Please grant storage permission in app settings.';
      } else if (errorString.contains('timeout')) {
        userFriendlyError = 'Download timeout. Please check your internet connection and try again.';
      } else if (errorString.contains('Network error') || errorString.contains('Failed to get download URL')) {
        userFriendlyError = 'Failed to connect to server. Please check your internet connection and try again.';
      } else if (errorString.contains('HTTP') || errorString.contains('status')) {
        userFriendlyError = 'Failed to download file. The file may not be available.';
      } else if (errorString.contains('Access denied') || errorString.contains('403')) {
        userFriendlyError = 'Access denied to this document. Please contact support.';
      } else if (errorString.contains('File not found') || errorString.contains('404')) {
        userFriendlyError = 'File not found. The document may have been removed.';
      } else {
        // Clean up error message
        final cleanError = errorString.replaceAll('Exception: ', '').trim();
        userFriendlyError = cleanError.isEmpty ? 'Download failed. Please try again.' : cleanError;
      }
      
      // Show download failed notification
      await _notificationService.showDownloadFailed(sanitizedFilename, userFriendlyError, notificationId);
      
      throw Exception(userFriendlyError);
    }
  }

  /// Check if Android version is 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    // Android 13 is API level 33
    // We'll assume newer versions for permission handling
    return true; // Simplified - in production, check actual SDK version
  }

  /// Sanitize filename to remove invalid characters
  String _sanitizeFilename(String filename) {
    // Remove or replace invalid characters
    var sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Ensure filename is not too long
    if (sanitized.length > 200) {
      final ext = sanitized.substring(sanitized.lastIndexOf('.'));
      sanitized = '${sanitized.substring(0, 200 - ext.length)}$ext';
    }
    // Ensure filename is not empty
    if (sanitized.isEmpty) {
      sanitized = 'document_${DateTime.now().millisecondsSinceEpoch}';
    }
    return sanitized;
  }

  /// Get file size in human readable format
  String formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

