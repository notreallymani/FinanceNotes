/// Base API Interface
/// 
/// Interface Segregation Principle: Defines minimal interface
/// Dependency Inversion: Depends on abstraction

abstract class BaseApi {
  /// Base URL for API
  String get baseUrl;

  /// Make GET request
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters});

  /// Make POST request
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data});

  /// Make PUT request
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data});

  /// Make DELETE request
  Future<Map<String, dynamic>> delete(String path);
}

