/// Generic Result Type
/// 
/// Follows functional programming principles for error handling
/// Eliminates exceptions for expected failures
/// 
/// High-level design: Abstract result pattern
/// Low-level design: Sealed class with success/failure variants

sealed class Result<T> {
  const Result();
  
  /// Check if result is success
  bool get isSuccess => this is Success<T>;
  
  /// Check if result is failure
  bool get isFailure => this is Failure<T>;
  
  /// Get value if success, null otherwise
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Failure<T>() => null,
  };
  
  /// Get error if failure, null otherwise
  String? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final error) => error,
  };
  
  /// Map success value to another type
  Result<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Success<T>(:final value) => Success(mapper(value)),
      Failure<T>(:final error) => Failure(error),
    };
  }
  
  /// Flat map (bind) - chain operations
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return switch (this) {
      Success<T>(:final value) => mapper(value),
      Failure<T>(:final error) => Failure(error),
    };
  }
  
  /// Fold - handle both success and failure
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(String error) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>(:final error) => onFailure(error),
    };
  }
}

/// Success variant
final class Success<T> extends Result<T> {
  final T value;
  
  const Success(this.value);
  
  @override
  String toString() => 'Success($value)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
}

/// Failure variant
final class Failure<T> extends Result<T> {
  final String error;
  
  const Failure(this.error);
  
  @override
  String toString() => 'Failure($error)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && error == other.error;
  
  @override
  int get hashCode => error.hashCode;
}

/// Extension methods for Result
extension ResultExtensions<T> on Result<T> {
  /// Execute callback on success
  Result<T> onSuccess(void Function(T value) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).value);
    }
    return this;
  }
  
  /// Execute callback on failure
  Result<T> onFailure(void Function(String error) callback) {
    if (this is Failure<T>) {
      callback((this as Failure<T>).error);
    }
    return this;
  }
}

