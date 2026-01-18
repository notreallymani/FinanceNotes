import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/auth_api.dart';
import '../api/profile_api.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import '../config/google_auth_config.dart';
import '../services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  final ProfileApi _profileApi = ProfileApi();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  /// Google Sign-In instance configured with Web Client ID
  /// 
  /// IMPORTANT: We use the Web Client ID (not Android Client ID) because:
  /// - The Node.js backend needs to verify the ID token
  /// - Only Web Client ID tokens can be verified by google-auth-library
  /// - Android Client ID tokens can only be verified by Google's Android SDK
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: GoogleAuthConfig.scopes,
    serverClientId: GoogleAuthConfig.webClientId,
  );

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAuthenticated => _user != null;

  // Initialize and check persistent login
  Future<void> initialize() async {
    try {
      final token = await loadToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[Auth] Token loading timed out');
          return null;
        },
      );
      if (token != null && token.isNotEmpty) {
        // Token exists, try to load user data
        try {
          await loadUserData().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('[Auth] User data loading timed out');
            },
          );
        } catch (e) {
          debugPrint('[Auth] Error loading user data: $e');
          // Continue even if user data loading fails
        }
        // Optionally verify token with backend
        // For now, if token exists, we consider user logged in
      }
    } catch (e) {
      debugPrint('[Auth] Initialization error: $e');
      // Continue even if initialization fails
    }
  }

  Future<bool> verifyOtp(String aadhar, String otp) async {
    if (_isLoading) return false; // Prevent multiple calls
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Always use real API call - backend handles environment-specific logic
      // No dummy OTP bypass - backend will use QuickeKYC in production
      final response = await _authApi.verifyOtp(aadhar, otp);

      if (response['token'] != null) {
        await saveToken(response['token']);
        if (response['user'] != null) {
          final user = UserModel.fromJson(response['user']);
          await saveUserData(user);
          _user = user;
          // Register FCM token after successful login
          _registerFcmToken();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'OTP verification failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error during verification: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authApi.emailRegister(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      final token = response['token'] as String?;
      final user = response['user'] as Map<String, dynamic>?;
      if (token == null || user == null) {
        _error = 'Invalid response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await saveToken(token);
      final userModel = UserModel.fromJson(user);
      await saveUserData(userModel);
      
      // Register FCM token after successful registration/login
      _registerFcmToken();
      
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

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authApi.emailLogin(
        email: email,
        password: password,
      );

      final token = response['token'] as String?;
      final user = response['user'] as Map<String, dynamic>?;
      if (token == null || user == null) {
        _error = 'Invalid response from server';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await saveToken(token);
      final userModel = UserModel.fromJson(user);
      await saveUserData(userModel);
      
      // Register FCM token after successful login
      _registerFcmToken();
      
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

  /// Register FCM token after successful login
  void _registerFcmToken() {
    try {
      final fcmService = FcmService();
      if (fcmService.isInitialized && fcmService.currentToken != null) {
        fcmService.registerToken(fcmService.currentToken!).catchError((e) {
          // Don't fail login if FCM registration fails
          debugPrint('[Auth] FCM token registration failed: $e');
        });
      }
    } catch (e) {
      // Don't fail login if FCM registration fails
      debugPrint('[Auth] FCM token registration error: $e');
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authApi.forgotPassword(email);
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

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> loadToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  // Save user data for persistent login
  Future<void> saveUserData(UserModel user) async {
    _user = user;
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: AppConstants.userKey, value: userJson);
    notifyListeners();
  }

  // Load user data from storage
  Future<void> loadUserData() async {
    try {
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _user = UserModel.fromJson(userMap);
        notifyListeners();
      }
    } catch (e) {
      // If error loading user data, clear it
      await _storage.delete(key: AppConstants.userKey);
    }
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }
    // Disconnect Google session if any
    try {
      await GoogleSignIn().signOut();
      await GoogleSignIn().disconnect();
    } catch (_) {}
    
    // Delete FCM token on logout
    try {
      await FcmService().deleteToken();
    } catch (e) {
      // Continue with logout even if FCM token deletion fails
      debugPrint('[Auth] FCM token deletion failed: $e');
    }
    
    // Clear all stored data
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<UserModel?> fetchProfile() async {
    try {
      _isLoading = true;
      notifyListeners();
      final profile = await _profileApi.getProfile();
      await saveUserData(profile);
      _isLoading = false;
      notifyListeners();
      return profile;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<UserModel?> updateProfile(
      {String? name, String? phone, String? email, String? aadhar}) async {
    try {
      _isLoading = true;
      notifyListeners();
      final updated = await _profileApi.updateProfile(
          name: name, phone: phone, email: email, aadhar: aadhar);
      await saveUserData(updated);
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Sign in with Google OAuth
  /// 
  /// Flow:
  /// 1. Clear any cached Google sessions to ensure fresh token
  /// 2. User selects Google account
  /// 3. Google returns ID token (using Web Client ID via serverClientId)
  /// 4. Send ID token to backend for verification
  /// 5. Backend verifies token and returns JWT
  /// 6. Save JWT and user data locally
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      debugPrint('[Google Auth] Step 0: Clearing any cached Google sessions...');
      debugPrint('[Google Auth] Using Web Client ID: ${GoogleAuthConfig.webClientId}');

      // Step 0: Sign out and disconnect to clear any cached tokens
      // This ensures we get a fresh token with the correct client ID
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
        debugPrint('[Google Auth] Cleared cached Google sessions');
      } catch (e) {
        // Ignore errors if user wasn't signed in
        debugPrint('[Google Auth] No previous session to clear (this is OK)');
      }

      // Step 1: Show Google Sign-In dialog
      debugPrint('[Google Auth] Step 1: Starting Google Sign-In...');
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('[Google Auth] User cancelled sign-in');
        _error = null; // Not an error, user just cancelled
        return;
      }

      debugPrint('[Google Auth] Step 2: User selected: ${googleUser.email}');
      
      // Step 2: Get authentication tokens
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      
      if (idToken == null) {
        debugPrint('[Google Auth] ERROR: idToken is null');
        debugPrint('[Google Auth] This usually means serverClientId is incorrect or token expired');
        _error = 'Failed to get authentication token. Please try again.';
        return;
      }

      // Log token info (first 20 chars only for security)
      debugPrint('[Google Auth] Step 3: Obtained ID token (length: ${idToken.length})');
      debugPrint('[Google Auth] Token preview: ${idToken.substring(0, idToken.length > 20 ? 20 : idToken.length)}...');
      
      // Decode token to verify audience (for debugging and early detection)
      try {
        final parts = idToken.split('.');
        if (parts.length == 3) {
          // Decode the payload (second part) - JWT tokens use base64url encoding
          final payload = parts[1];
          // Add padding if needed (base64url doesn't include padding)
          String normalizedPayload = payload;
          final remainder = payload.length % 4;
          if (remainder != 0) {
            normalizedPayload += '=' * (4 - remainder);
          }
          // base64Url.decode handles URL-safe base64 (with - and _ instead of + and /)
          final decodedBytes = base64Url.decode(normalizedPayload);
          final decodedJson = jsonDecode(utf8.decode(decodedBytes)) as Map<String, dynamic>;
          final audience = decodedJson['aud'] as String?;
          
          debugPrint('[Google Auth] Token audience (aud): $audience');
          debugPrint('[Google Auth] Expected audience: ${GoogleAuthConfig.webClientId}');
          
          if (audience != null && audience != GoogleAuthConfig.webClientId) {
            debugPrint('[Google Auth] ERROR: Token audience mismatch detected!');
            debugPrint('[Google Auth] Token was issued for: $audience');
            debugPrint('[Google Auth] But server expects: ${GoogleAuthConfig.webClientId}');
            debugPrint('[Google Auth] This will cause authentication to fail.');
            debugPrint('[Google Auth] Clearing session to force fresh token...');
            
            // Clear the session to force a fresh token on next attempt
            await _googleSignIn.signOut();
            await _googleSignIn.disconnect();
            
            _error = 'Token audience mismatch detected.\n'
                    'The token was issued for a different client ID.\n'
                    'Please try signing in again - a fresh token will be requested.';
            return;
          } else if (audience == GoogleAuthConfig.webClientId) {
            debugPrint('[Google Auth] ✓ Token audience matches expected client ID');
          }
        }
      } catch (e) {
        // Non-critical - if we can't decode, just continue and let server verify
        debugPrint('[Google Auth] Could not decode token for pre-verification (non-critical): $e');
        debugPrint('[Google Auth] Server will verify the token instead');
      }

      // Step 3: Send token to backend for verification
      debugPrint('[Google Auth] Step 4: Sending token to backend...');
      final result = await _authApi.googleAuth(idToken);
      
      // Step 4: Extract response
      final token = result['token'] as String?;
      final user = result['user'] as Map<String, dynamic>?;
      
      if (token == null || user == null) {
        debugPrint('[Google Auth] ERROR: Invalid response from server');
        debugPrint('[Google Auth] Response: $result');
        _error = 'Invalid response from server. Please try again.';
        return;
      }

      // Step 5: Save authentication data
      debugPrint('[Google Auth] Step 5: Saving authentication data...');
      await saveToken(token);
      final userModel = UserModel.fromJson(user);
      await saveUserData(userModel);
      
      // Register FCM token after successful login
      _registerFcmToken();
      
      _error = null;
      debugPrint('[Google Auth] SUCCESS: User authenticated - ${userModel.email} (ID: ${userModel.id})');
      
    } on PlatformException catch (e) {
      // Handle platform-specific errors
      debugPrint('[Google Auth] PlatformException: ${e.code} - ${e.message}');
      debugPrint('[Google Auth] PlatformException details: ${e.toString()}');
      debugPrint('[Google Auth] Stack trace: ${e.stacktrace}');
      
      switch (e.code) {
        case 'sign_in_canceled':
          _error = null; // User cancelled, not an error
          break;
        case 'network_error':
          _error = 'Network error. Please check your internet connection.';
          break;
        case 'sign_in_failed':
          // Extract error code from message if available
          String errorDetails = e.message ?? 'Unknown error';
          if (errorDetails.contains('ApiException: 10')) {
            _error = 'Sign-in failed (Error Code 10).\n\n'
                    'This usually means:\n'
                    '1. OAuth Consent Screen is not configured\n'
                    '2. Your email is not in the test users list\n'
                    '3. Google Sign-In API is not enabled\n\n'
                    'Fix: Go to Google Cloud Console → APIs & Services → OAuth consent screen\n'
                    'Configure it and add your email to test users, then wait 10-15 minutes.';
          } else {
            _error = 'Sign-in failed: $errorDetails\n\n'
                    'Please check:\n'
                    '1. OAuth Consent Screen is configured\n'
                    '2. Your email is in test users list\n'
                    '3. Google Sign-In API is enabled';
          }
          break;
        default:
          _error = 'Google sign-in error: ${e.message ?? e.code}\n\n'
                  'Error Code: ${e.code}\n'
                  'Message: ${e.message ?? "No message"}';
      }
    } catch (e) {
      debugPrint('[Google Auth] Unexpected error: $e');
      debugPrint('[Google Auth] Error type: ${e.runtimeType}');
      
      // Extract meaningful error message
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceAll('Exception: ', '');
      }
      if (errorMsg.contains('Invalid Google token')) {
        errorMsg = 'Authentication failed. The token could not be verified. '
                   'Please check:\n'
                   '1. Server is running and accessible\n'
                   '2. Google Client ID matches on both app and server\n'
                   '3. Check server logs for detailed error';
      }
      
      _error = errorMsg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any cached Google Sign-In sessions
  /// Use this if you're experiencing token audience mismatch errors
  Future<void> clearGoogleSignInCache() async {
    try {
      debugPrint('[Google Auth] Clearing Google Sign-In cache...');
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      debugPrint('[Google Auth] Google Sign-In cache cleared');
    } catch (e) {
      debugPrint('[Google Auth] Error clearing cache (may not be signed in): $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
