import 'package:dio/dio.dart';
import '../utils/app_constants.dart';
import '../utils/env.dart';
import '../utils/http_client.dart';
import '../utils/logger.dart';

class AadharApi {
  final Dio _dio = HttpClient.instance;

  Future<Map<String, dynamic>> generateOtp(String aadhar) async {
    // Call backend API (backend handles QuickeKYC sandbox in dev, production in prod)
    try {
      Logger.log('📤 Calling backend to generate OTP via QuickeKYC');
      final response = await _dio.post(
        AppConstants.generateOtpEndpoint,
        data: {
          'aadhar': aadhar,
        },
      );
      Logger.log('✅ OTP generation response received');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyAadharOtp(String aadhar, String otp) async {
    // Call backend API (backend handles QuickeKYC sandbox in dev, production in prod)
    try {
      Logger.log('📤 Calling backend to verify OTP via QuickeKYC');
      final response = await _dio.post(
        AppConstants.verifyAadharOtpEndpoint,
        data: {
          'aadhar': aadhar,
          'otp': otp,
        },
      );
      Logger.log('✅ OTP verification response received');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final message = error.response?.data['message'] ?? 
                       error.response?.data['error'] ?? 
                       'An error occurred';
        return Exception(message);
      } else {
        Logger.log('Network error: ${error.message}');
        return Exception('Network error');
      }
    }
    return Exception('Unexpected error: $error');
  }
}

