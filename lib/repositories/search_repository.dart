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
  /// Only returns transactions where the searched Aadhaar is the customer (receiverAadhar)
  Future<List<TransactionModel>> searchByAadhar(
    String aadhar, {
    bool useCache = true,
  }) async {
    final cacheKey = 'search_aadhar_$aadhar';

    // Always clear cache for search to get fresh results (search should always be current)
    // This ensures we don't show stale data if the backend query logic changed
    await _cache.remove(cacheKey);

    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('search_aadhar_$aadhar');
      final transactions = await _api.getHistoryByAadhar(aadhar);
      PerformanceMonitor.end('search_aadhar_$aadhar');

      // Don't cache search results - always fetch fresh data
      // This ensures search always shows current results matching customer Aadhaar only

      return transactions;
    });
  }

  /// Clear search cache
  Future<void> clearCache() async {
    // Clear all search-related cache
    // In production, you might want to be more selective
  }
}

