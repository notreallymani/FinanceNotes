/// Auth Use Case
/// 
/// Single Responsibility: Handles authentication business logic
/// Dependency Inversion: Depends on repository abstractions
/// 
/// This separates business logic from UI and data access

import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthUseCase {
  final AuthRepository _repository;

  AuthUseCase(this._repository);

  /// Login with email and password
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // Business logic validation
    if (email.isEmpty || password.isEmpty) {
      return AuthResult.failure('Email and password are required');
    }

    try {
      final result = await _repository.loginWithEmail(
        email: email,
        password: password,
      );
      return AuthResult.success(result.user, result.token);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    // Business logic validation
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      return AuthResult.failure('All required fields must be filled');
    }

    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters');
    }

    try {
      final result = await _repository.registerWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      return AuthResult.success(result.user, result.token);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle(String idToken) async {
    if (idToken.isEmpty) {
      return AuthResult.failure('Google token is required');
    }

    try {
      final result = await _repository.signInWithGoogle(idToken);
      return AuthResult.success(result.user, result.token);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Send password reset
  Future<bool> sendPasswordReset(String email) async {
    if (email.isEmpty) {
      return false;
    }

    try {
      await _repository.sendPasswordReset(email);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Auth Result
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? token;
  final String? error;

  AuthResult._({
    required this.success,
    this.user,
    this.token,
    this.error,
  });

  factory AuthResult.success(UserModel user, String token) {
    return AuthResult._(
      success: true,
      user: user,
      token: token,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(
      success: false,
      error: error,
    );
  }
}

