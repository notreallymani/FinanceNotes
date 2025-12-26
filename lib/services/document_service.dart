/// Document Service
/// 
/// Single Responsibility: Handles document download operations
/// Dependency Inversion: Depends on abstractions

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class DocumentService {
  /// Download document from URL
  Future<File?> downloadDocument({
    required String url,
    required String filename,
  }) async {
    try {
      // Request storage permission (Android 13+ uses different permissions)
      if (Platform.isAndroid) {
        if (await Permission.storage.isDenied) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            // Try alternative permission for Android 13+
            final manageStorage = await Permission.manageExternalStorage.request();
            if (!manageStorage.isGranted) {
              throw Exception('Storage permission denied');
            }
          }
        }
      }

      // Get download directory
      final directory = await getApplicationDocumentsDirectory();
      // Sanitize filename
      final sanitizedFilename = filename.replaceAll(RegExp(r'[^\w\s.-]'), '_');
      final filePath = '${directory.path}/$sanitizedFilename';

      // Download file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// Get file size in human readable format
  String formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

