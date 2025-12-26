/// Base Repository Pattern
/// 
/// Follows SOLID Principles:
/// - Single Responsibility: Handles only data access
/// - Open/Closed: Extendable without modification
/// - Liskov Substitution: All repositories can be substituted
/// - Dependency Inversion: Depends on API abstractions

import '../api/base_api.dart';
import '../utils/api_cache.dart';
import '../utils/performance_utils.dart';

abstract class BaseRepository<T> {
  final BaseApi api;
  final ApiCache cache;
  final RequestDeduplicator deduplicator;

  BaseRepository({
    required this.api,
    ApiCache? cache,
    RequestDeduplicator? deduplicator,
  })  : cache = cache ?? ApiCache(),
        deduplicator = deduplicator ?? RequestDeduplicator();

  /// Convert JSON to model
  T fromJson(Map<String, dynamic> json);

  /// Convert model to JSON
  Map<String, dynamic> toJson(T model);

  /// Fetch with caching
  Future<T?> fetchWithCache(
    String cacheKey,
    Future<T> Function() fetchFunction, {
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cachedData = await cache.get(cacheKey);
      if (cachedData != null) {
        try {
          return fromJson(cachedData);
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    // Fetch with deduplication
    return await deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start(cacheKey);
      final result = await fetchFunction();
      PerformanceMonitor.end(cacheKey);

      // Cache the result
      await cache.put(cacheKey, toJson(result));

      return result;
    });
  }

  /// Fetch list with caching
  Future<List<T>> fetchListWithCache(
    String cacheKey,
    Future<List<T>> Function() fetchFunction, {
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cachedData = await cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> items = cachedData['items'] ?? [];
          return items.map((json) => fromJson(json as Map<String, dynamic>)).toList();
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    // Fetch with deduplication
    return await deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start(cacheKey);
      final result = await fetchFunction();
      PerformanceMonitor.end(cacheKey);

      // Cache the result
      await cache.put(cacheKey, {
        'items': result.map((item) => toJson(item)).toList(),
      });

      return result;
    });
  }

  /// Clear cache
  Future<void> clearCache(String cacheKey) async {
    await cache.remove(cacheKey);
  }
}

