/// Payment Repository (Refactored)
/// 
/// Single Responsibility: Handles payment data access
/// Dependency Inversion: Depends on API abstraction

import '../api/payment_api.dart';
import '../models/transaction_model.dart';
import '../utils/api_cache.dart';
import '../utils/performance_utils.dart';
import 'package:dio/dio.dart';

class PaymentRepository {
  final PaymentApi _api;
  final ApiCache _cache;
  final RequestDeduplicator _deduplicator;

  PaymentRepository({
    PaymentApi? api,
    ApiCache? cache,
    RequestDeduplicator? deduplicator,
  })  : _api = api ?? PaymentApi(),
        _cache = cache ?? ApiCache(),
        _deduplicator = deduplicator ?? RequestDeduplicator();

  /// Send payment request
  Future<TransactionModel> sendPayment({
    required String aadhar,
    required double amount,
    required String customerName,
    String? mobile,
    double? interest,
    List<MultipartFile>? documents,
  }) async {
    PerformanceMonitor.start('send_payment');
    final transaction = await _api.sendPayment(
      aadhar: aadhar,
      amount: amount,
      customerName: customerName,
      mobile: mobile,
      interest: interest,
      documents: documents,
    );
    PerformanceMonitor.end('send_payment');

    // Invalidate cache
    await _invalidateHistoryCache();

    return transaction;
  }

  /// Close payment
  Future<TransactionModel> closePayment(String transactionId) async {
    PerformanceMonitor.start('close_payment');
    final transaction = await _api.closePayment(transactionId);
    PerformanceMonitor.end('close_payment');

    // Invalidate cache
    await _invalidateHistoryCache();

    return transaction;
  }

  /// Send customer close OTP
  Future<void> sendCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
  }) async {
    await _api.sendCustomerCloseOtp(
      transactionId: transactionId,
      ownerAadhar: ownerAadhar,
    );
  }

  /// Verify customer close OTP
  Future<TransactionModel> verifyCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
    required String otp,
  }) async {
    final transaction = await _api.verifyCustomerCloseOtp(
      transactionId: transactionId,
      ownerAadhar: ownerAadhar,
      otp: otp,
    );

    // Invalidate cache
    await _invalidateHistoryCache();

    return transaction;
  }

  /// Get payment history by Aadhaar with caching
  Future<List<TransactionModel>> getHistoryByAadhar(
    String aadhar, {
    int page = 1,
    int limit = 50,
    bool useCache = true,
  }) async {
    final cacheKey = 'payment_history_${aadhar}_${page}_$limit';

    // Check cache first (only for first page)
    if (useCache && page == 1) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> transactions = cachedData['transactions'] ?? [];
          final result = transactions
              .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
              .toList();
          // Load fresh data in background
          _getHistoryInBackground(aadhar, page: page, limit: limit);
          return result;
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('get_history_$aadhar');
      final transactions = await _api.getHistoryByAadhar(
        aadhar,
        page: page,
        limit: limit,
      );
      PerformanceMonitor.end('get_history_$aadhar');

      // Cache the response (only first page)
      if (page == 1) {
        await _cache.put(cacheKey, {
          'transactions': transactions.map((t) => t.toJson()).toList(),
        });
      }

      return transactions;
    });
  }

  /// Background refresh
  Future<void> _getHistoryInBackground(String aadhar, {int page = 1, int limit = 50}) async {
    try {
      final freshTransactions = await _api.getHistoryByAadhar(
        aadhar,
        page: page,
        limit: limit,
      );
      await _cache.put('payment_history_${aadhar}_${page}_$limit', {
        'transactions': freshTransactions.map((t) => t.toJson()).toList(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Get all transactions
  Future<List<TransactionModel>> getAll({
    int page = 1,
    int limit = 50,
    bool useCache = true,
  }) async {
    final cacheKey = 'payment_all_${page}_$limit';

    // Check cache first (only for first page)
    if (useCache && page == 1) {
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
      PerformanceMonitor.start('get_all_payments');
      final transactions = await _api.getAllTransactions(
        page: page,
        limit: limit,
      );
      PerformanceMonitor.end('get_all_payments');

      // Cache the response (only first page)
      if (page == 1) {
        await _cache.put(cacheKey, {
          'transactions': transactions.map((t) => t.toJson()).toList(),
        });
      }

      return transactions;
    });
  }

  /// Invalidate history cache
  Future<void> _invalidateHistoryCache() async {
    // Clear payment-related cache entries
    // Clear common cache keys (we can't pattern match, so clear known keys)
    final commonKeys = [
      'payment_all_1_50', // Most common fetchAll call
      'payment_all_1_100',
    ];
    for (final key in commonKeys) {
      await _cache.remove(key);
    }
    // Also clear memory cache for payment_all pattern
    // The memory cache will expire naturally, but we try to clear what we can
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await _cache.clear();
  }
}

