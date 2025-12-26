/// Search Repository
/// 
/// Single Responsibility: Handles search data access
/// Dependency Inversion: Depends on API abstraction

import '../api/payment_api.dart';
import '../models/transaction_model.dart';
import '../utils/api_cache.dart';
import '../utils/performance_utils.dart';

class SearchRepository {
  final PaymentApi _api;
  final ApiCache _cache;
  final RequestDeduplicator _deduplicator;

  SearchRepository({
    PaymentApi? api,
    ApiCache? cache,
    RequestDeduplicator? deduplicator,
  })  : _api = api ?? PaymentApi(),
        _cache = cache ?? ApiCache(),
        _deduplicator = deduplicator ?? RequestDeduplicator();

  /// Search transactions by Aadhaar
  Future<List<TransactionModel>> searchByAadhar(
    String aadhar, {
    bool useCache = true,
  }) async {
    final cacheKey = 'search_aadhar_$aadhar';

    // Check cache first
    if (useCache) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> transactions = cachedData['transactions'] ?? [];
          return transactions
              .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('search_aadhar_$aadhar');
      final transactions = await _api.getHistoryByAadhar(aadhar);
      PerformanceMonitor.end('search_aadhar_$aadhar');

      // Cache the response
      await _cache.put(cacheKey, {
        'transactions': transactions.map((t) => t.toJson()).toList(),
      });

      return transactions;
    });
  }

  /// Clear search cache
  Future<void> clearCache() async {
    // Clear all search-related cache
    // In production, you might want to be more selective
  }
}

