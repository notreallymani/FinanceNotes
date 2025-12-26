/// Profile Use Case
/// 
/// Single Responsibility: Handles profile business logic
/// Dependency Inversion: Depends on repository abstractions

import '../repositories/profile_repository.dart';
import '../models/user_model.dart';

class ProfileUseCase {
  final ProfileRepository _repository;

  ProfileUseCase(this._repository);

  /// Get user profile
  Future<ProfileResult> getProfile({bool useCache = true}) async {
    try {
      final user = await _repository.getProfile(useCache: useCache);
      return ProfileResult.success(user);
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }

  /// Update user profile
  Future<ProfileResult> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? aadhar,
  }) async {
    // Business logic validation
    if (name != null && name.trim().length < 2) {
      return ProfileResult.failure('Name must be at least 2 characters');
    }

    if (phone != null && phone.isNotEmpty) {
      if (phone.length != 10) {
        return ProfileResult.failure('Phone must be 10 digits');
      }
    }

    try {
      final user = await _repository.updateProfile(
        name: name,
        phone: phone,
        email: email,
        aadhar: aadhar,
      );
      return ProfileResult.success(user);
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }
}

/// Profile Result
class ProfileResult {
  final bool success;
  final UserModel? user;
  final String? error;

  ProfileResult._({
    required this.success,
    this.user,
    this.error,
  });

  factory ProfileResult.success(UserModel user) {
    return ProfileResult._(
      success: true,
      user: user,
    );
  }

  factory ProfileResult.failure(String error) {
    return ProfileResult._(
      success: false,
      error: error,
    );
  }
}

