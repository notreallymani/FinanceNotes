import 'package:dio/dio.dart';
import '../utils/app_constants.dart';
import '../utils/http_client.dart';
import '../utils/logger.dart';

class AuthApi {
  final Dio _dio = HttpClient.instance;

  Future<Map<String, dynamic>> verifyOtp(String aadhar, String otp) async {
    try {
      final response = await _dio.post(
        AppConstants.verifyOtpEndpoint,
        data: {
          'aadhar': aadhar,
          'otp': otp,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> emailRegister({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.emailRegisterEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> emailLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.emailLoginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        AppConstants.forgotPasswordEndpoint,
        data: {
          'email': email,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Authenticate with Google ID token
  /// 
  /// Sends the Google ID token to the backend for verification.
  /// The backend will verify the token and return a JWT if successful.
  Future<Map<String, dynamic>> googleAuth(String idToken) async {
    try {
      Logger.log('[AuthAPI] Sending Google ID token to backend...');
      Logger.log('[AuthAPI] Endpoint: ${AppConstants.googleAuthEndpoint}');
      Logger.log('[AuthAPI] Token length: ${idToken.length}');
      
      final response = await _dio.post(
        AppConstants.googleAuthEndpoint,
        data: {
          'idToken': idToken,
        },
      );
      
      Logger.log('[AuthAPI] Response status: ${response.statusCode}');
      Logger.log('[AuthAPI] Authentication successful');
      
      return response.data;
    } catch (e) {
      Logger.log('[AuthAPI] Error during Google authentication: $e');
      
      if (e is DioException) {
        Logger.log('[AuthAPI] DioException details:');
        Logger.log('[AuthAPI] - Status code: ${e.response?.statusCode}');
        Logger.log('[AuthAPI] - Response data: ${e.response?.data}');
        Logger.log('[AuthAPI] - Error message: ${e.message}');
      }
      
      throw _handleError(e);
    }
  }

  /// Handle and format errors from API calls
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        // Server returned an error response
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        // Extract error message from response
        String message = data['message'] ?? 
                        data['error'] ?? 
                        data['hint'] ?? 
                        'An error occurred';
        
        // Add helpful context for common errors
        if (statusCode == 401) {
          if (message.contains('Google token')) {
            message = 'Invalid Google token. This usually means:\n'
                     '• Token expired (try signing in again)\n'
                     '• Client ID mismatch between app and server\n'
                     '• Token format is invalid\n'
                     'Check server logs for detailed error.';
          }
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else if (statusCode == 400) {
          // Keep the original message for 400 errors
        }
        
        Logger.log('[AuthAPI] Error response: $statusCode - $message');
        return Exception(message);
      } else {
        // Network or connection error
        Logger.log('[AuthAPI] Network error: ${error.message}');
        String networkMsg = 'Network error';
        if (error.type == DioExceptionType.connectionTimeout) {
          networkMsg = 'Connection timeout. Please check your internet connection.';
        } else if (error.type == DioExceptionType.receiveTimeout) {
          networkMsg = 'Request timeout. Please try again.';
        } else if (error.type == DioExceptionType.connectionError) {
          networkMsg = 'Cannot connect to server. Please check if the server is running.';
        }
        return Exception(networkMsg);
      }
    }
    return Exception('Unexpected error: $error');
  }
}
