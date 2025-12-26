/// Profile Repository
/// 
/// Single Responsibility: Handles profile data access
/// Dependency Inversion: Depends on API abstraction

import '../api/profile_api.dart';
import '../models/user_model.dart';
import '../utils/api_cache.dart';
import '../utils/performance_utils.dart';

class ProfileRepository {
  final ProfileApi _api;
  final ApiCache _cache;
  final RequestDeduplicator _deduplicator;

  ProfileRepository({
    ProfileApi? api,
    ApiCache? cache,
    RequestDeduplicator? deduplicator,
  })  : _api = api ?? ProfileApi(),
        _cache = cache ?? ApiCache(),
        _deduplicator = deduplicator ?? RequestDeduplicator();

  /// Get user profile with caching
  Future<UserModel> getProfile({bool useCache = true}) async {
    const cacheKey = 'user_profile';

    // Check cache first
    if (useCache) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final user = UserModel.fromJson(cachedData);
          // Load fresh data in background
          _getProfileInBackground();
          return user;
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('get_profile');
      final user = await _api.getProfile();
      PerformanceMonitor.end('get_profile');

      // Cache the response
      await _cache.put(cacheKey, user.toJson());

      return user;
    });
  }

  /// Background refresh
  Future<void> _getProfileInBackground() async {
    try {
      final freshUser = await _api.getProfile();
      await _cache.put('user_profile', freshUser.toJson());
    } catch (e) {
      // Silently fail - user already has cached data
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? aadhar,
  }) async {
    PerformanceMonitor.start('update_profile');
    final user = await _api.updateProfile(
      name: name,
      phone: phone,
      email: email,
      aadhar: aadhar,
    );
    PerformanceMonitor.end('update_profile');

    // Update cache
    await _cache.put('user_profile', user.toJson());

    return user;
  }

  /// Clear profile cache
  Future<void> clearCache() async {
    await _cache.remove('user_profile');
  }
}

