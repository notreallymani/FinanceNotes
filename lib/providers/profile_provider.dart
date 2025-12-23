import 'package:flutter/foundation.dart';
import '../api/profile_api.dart';
import '../models/user_model.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileApi _profileApi = ProfileApi();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _profileApi.getProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? aadhar,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _profileApi.updateProfile(
        name: name,
        phone: phone,
        email: email,
        aadhar: aadhar,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

