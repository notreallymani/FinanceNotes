/// Document Service
/// 
/// Single Responsibility: Handles document download operations
/// Dependency Inversion: Depends on abstractions

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../api/payment_api.dart';

class DocumentService {
  final PaymentApi _paymentApi = PaymentApi();

  /// Download document from URL (gets signed URL first if needed)
  Future<File?> downloadDocument({
    required String url,
    required String filename,
  }) async {
    try {
      // Validate URL
      if (url.isEmpty) {
        throw Exception('Document URL is empty');
      }

      // Get signed URL from backend for GCS files
      String downloadUrl = url;
      try {
        // Check if this is a GCS URL
        final uri = Uri.parse(url);
        if (uri.hostname == 'storage.googleapis.com') {
          // Get signed URL from backend
          downloadUrl = await _paymentApi.getDocumentDownloadUrl(url);
        }
      } catch (e) {
        // If getting signed URL fails, try using original URL
        // (might be a public URL or already signed)
      }

      // Validate URL format
      Uri? uri;
      try {
        uri = Uri.parse(downloadUrl);
        if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
          throw Exception('Invalid URL format');
        }
      } catch (e) {
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
                throw Exception('Storage permission denied. Please grant storage permission in app settings.');
              }
            }
          }
        }
      }

      // Get download directory - use app-specific directory for better compatibility
      // This works without special permissions on all Android versions
      final directory = await getApplicationDocumentsDirectory();

      // Create downloads subdirectory
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Sanitize filename and ensure unique name
      final sanitizedFilename = _sanitizeFilename(filename);
      var filePath = '${downloadsDir.path}/$sanitizedFilename';
      
      // Ensure unique filename if file already exists
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

      // Download file with timeout
      final response = await http.get(uri!).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Download timeout: File took too long to download');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('permission')) {
        throw Exception('Permission denied. Please grant storage permission in app settings.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Download timeout. Please check your internet connection and try again.');
      } else if (e.toString().contains('HTTP')) {
        throw Exception('Failed to download file. The file may not be available.');
      } else {
        throw Exception('Download failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
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

