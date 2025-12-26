/// Profile Provider (Refactored with SOLID Principles)
/// 
/// Single Responsibility: State management only
/// Dependency Inversion: Depends on use case abstraction

import 'package:flutter/foundation.dart';
import '../use_cases/profile_use_case.dart';
import '../repositories/profile_repository.dart';
import '../models/user_model.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileUseCase _useCase;

  ProfileProvider({ProfileUseCase? useCase})
      : _useCase = useCase ?? ProfileUseCase(ProfileRepository());

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch user profile
  Future<bool> fetchProfile({bool useCache = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.getProfile(useCache: useCache);

    _isLoading = false;
    if (result.success && result.user != null) {
      _user = result.user;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? aadhar,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.updateProfile(
      name: name,
      phone: phone,
      email: email,
      aadhar: aadhar,
    );

    _isLoading = false;
    if (result.success && result.user != null) {
      _user = result.user;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

