import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'performance_utils.dart';

/// API response cache with secure storage
class ApiCache {
  static final ApiCache _instance = ApiCache._internal();
  factory ApiCache() => _instance;
  ApiCache._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final MemoryCache<String> _memoryCache = MemoryCache<String>(
    ttl: const Duration(minutes: 5),
  );

  /// Cache API response
  Future<void> put(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      _memoryCache.put(key, jsonString);
      await _storage.write(key: 'cache_$key', value: jsonString);
    } catch (e) {
      // Silently fail - caching is optional
    }
  }

  /// Get cached API response
  Future<Map<String, dynamic>?> get(String key) async {
    try {
      // Check memory cache first (faster)
      final memoryData = _memoryCache.get(key);
      if (memoryData != null) {
        return jsonDecode(memoryData) as Map<String, dynamic>;
      }

      // Check persistent storage
      final storedData = await _storage.read(key: 'cache_$key');
      if (storedData != null) {
        final data = jsonDecode(storedData) as Map<String, dynamic>;
        // Put back in memory cache
        _memoryCache.put(key, storedData);
        return data;
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }

  /// Clear cache
  Future<void> clear() async {
    _memoryCache.clear();
    // Note: We can't easily clear all secure storage keys
    // This is a limitation, but acceptable for this use case
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _storage.delete(key: 'cache_$key');
  }
}

