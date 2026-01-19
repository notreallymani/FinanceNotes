/// Update API
/// 
/// Single Responsibility: Handles API calls for app version checking
/// Dependency Inversion: Implements BaseApi interface

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'base_api.dart';
import '../utils/http_client.dart';
import '../utils/app_constants.dart';

class UpdateApi implements BaseApi {
  @override
  String get baseUrl => '';

  /// Check for app version updates
  /// Returns version info from server or null if error
  Future<Map<String, dynamic>?> checkVersion() async {
    try {
      final dio = HttpClient.instance;
      final response = await dio.get(
        AppConstants.appVersionEndpoint,
      );

      // Dio returns response.data directly if successful
      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }

      return null;
    } on DioException catch (e) {
      debugPrint('[UpdateApi] Error checking version: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[UpdateApi] Error checking version: $e');
      return null;
    }
  }

  // BaseApi interface methods (not used for update API)
  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) {
    throw UnimplementedError('Use checkVersion() instead');
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) {
    throw UnimplementedError('Not implemented');
  }

  @override
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) {
    throw UnimplementedError('Not implemented');
  }

  @override
  Future<Map<String, dynamic>> delete(String path) {
    throw UnimplementedError('Not implemented');
  }
}
