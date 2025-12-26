/// Auth Repository
/// 
/// Single Responsibility: Handles authentication data access
/// Dependency Inversion: Depends on API abstraction

/// Auth Repository
/// 
/// Single Responsibility: Handles authentication data access
/// Dependency Inversion: Depends on API abstraction

import '../api/auth_api.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final AuthApi _api;
  final FlutterSecureStorage _storage;

  AuthRepository({
    AuthApi? api,
    FlutterSecureStorage? storage,
  })  : _api = api ?? AuthApi(),
        _storage = storage ?? const FlutterSecureStorage();

  /// Login with email and password
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _api.emailLogin(
      email: email,
      password: password,
    );

    // Save token
    await _storage.write(
      key: AppConstants.tokenKey,
      value: response['token'] as String,
    );

    return AuthResult(
      user: UserModel.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final response = await _api.emailRegister(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    // Save token
    await _storage.write(
      key: AppConstants.tokenKey,
      value: response['token'] as String,
    );

    return AuthResult(
      user: UserModel.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle(String idToken) async {
    final response = await _api.googleAuth(idToken);

    // Save token
    await _storage.write(
      key: AppConstants.tokenKey,
      value: response['token'] as String,
    );

    return AuthResult(
      user: UserModel.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  /// Send password reset
  Future<void> sendPasswordReset(String email) async {
    await _api.forgotPassword(email);
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  /// Clear token
  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }
}

/// Auth Result Model
class AuthResult {
  final UserModel user;
  final String token;

  AuthResult({
    required this.user,
    required this.token,
  });
}

