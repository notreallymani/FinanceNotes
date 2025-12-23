import 'package:dio/dio.dart';
import '../utils/app_constants.dart';
import '../models/user_model.dart';
import '../utils/http_client.dart';
import '../utils/logger.dart';

class ProfileApi {
  final Dio _dio = HttpClient.instance;

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(
        AppConstants.profileEndpoint,
      );
      return UserModel.fromJson(response.data['user'] ?? response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? aadhar,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (email != null) data['email'] = email;
      if (aadhar != null) data['aadhar'] = aadhar;

      final response = await _dio.put(
        AppConstants.profileEndpoint,
        data: data,
      );
      return UserModel.fromJson(response.data['user'] ?? response.data);
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

