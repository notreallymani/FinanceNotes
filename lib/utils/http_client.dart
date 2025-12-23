import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_constants.dart';
import 'env.dart';
import 'logger.dart';

class HttpClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),  // Fast fail for connection issues
      receiveTimeout: const Duration(seconds: 15),   // Reasonable timeout for API responses
      sendTimeout: const Duration(seconds: 10),     // Fast fail for send issues
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static bool _initialized = false;

  static Dio get instance {
    if (!_initialized) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await _storage.read(key: AppConstants.tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            Logger.log('REQ ${options.method} ${options.path}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            Logger.log('RES ${response.statusCode} ${response.requestOptions.path}');
            return handler.next(response);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 500) {
              final options = error.requestOptions;
              try {
                final retry = await _dio.request(
                  options.path,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                  data: options.data,
                  queryParameters: options.queryParameters,
                );
                return handler.resolve(retry);
              } catch (_) {}
            }
            Logger.log('ERR ${error.response?.statusCode} ${error.requestOptions.path}');
            return handler.next(error);
          },
        ),
      );
      _initialized = true;
    }
    return _dio;
  }
}
