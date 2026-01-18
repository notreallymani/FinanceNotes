/// Error Types
/// 
/// High-level design: Error hierarchy
/// Low-level design: Specific error classes for different failure scenarios

/// Base error class
abstract class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });
  
  @override
  String toString() => message;
}

/// Network errors
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
  });
  
  factory NetworkError.fromException(dynamic error) {
    return NetworkError(
      message: 'Network error: ${error.toString()}',
      originalError: error,
    );
  }
}

/// Validation errors
class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
  });
}

/// Authentication errors
class AuthenticationError extends AppError {
  const AuthenticationError({
    required super.message,
    super.code,
  });
}

/// Server errors
class ServerError extends AppError {
  final int? statusCode;
  
  const ServerError({
    required super.message,
    super.code,
    this.statusCode,
    super.originalError,
  });
  
  factory ServerError.fromResponse(int statusCode, String message) {
    return ServerError(
      message: message,
      statusCode: statusCode,
      code: 'HTTP_$statusCode',
    );
  }
}

/// Cache errors
class CacheError extends AppError {
  const CacheError({
    required super.message,
    super.code,
  });
}

/// Unknown errors
class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.originalError,
  });
  
  factory UnknownError.fromException(dynamic error) {
    return UnknownError(
      message: 'An unexpected error occurred: ${error.toString()}',
      originalError: error,
    );
  }
}

