import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../repositories/payment_repository.dart';
import '../models/transaction_model.dart';
import '../utils/api_cache.dart';
import '../utils/performance_utils.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentRepository _repo = PaymentRepository();
  final ApiCache _cache = ApiCache();
  final RequestDeduplicator _deduplicator = RequestDeduplicator();

  List<TransactionModel> _history = [];
  List<TransactionModel> _receivedHistory = [];
  TransactionModel? _currentTransaction;
  bool _isLoading = false;
  String? _error;
  bool _isOtpSending = false;

  List<TransactionModel> get history => _history;
  List<TransactionModel> get receivedHistory => _receivedHistory;
  TransactionModel? get currentTransaction => _currentTransaction;
  bool get isLoading => _isLoading;
  bool get isOtpSending => _isOtpSending;
  String? get error => _error;

  Future<bool> sendPayment({
    required String aadhar,
    required double amount,
    required String customerName,
    String? mobile,
    double? interest,
    List<PlatformFile>? proofFiles,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<MultipartFile>? documents;
      if (proofFiles != null && proofFiles.isNotEmpty) {
        final uploads = await Future.wait(
          proofFiles.map((file) async {
            try {
              if (file.bytes != null) {
                return MultipartFile.fromBytes(
                  file.bytes!,
                  filename: file.name,
                );
              } else if (file.path != null) {
                return await MultipartFile.fromFile(
                  file.path!,
                  filename: file.name,
                );
              }
            } catch (_) {
              // Skip problematic file
            }
            return null;
          }),
        );
        final filtered = uploads.whereType<MultipartFile>().toList();
        if (filtered.isNotEmpty) {
          documents = filtered;
        }
      }

      _currentTransaction = await _repo.sendPayment(
        aadhar: aadhar,
        amount: amount,
        customerName: customerName,
        mobile: mobile,
        interest: interest,
        documents: documents,
      );
      
      // Clear cache and refresh the list to show the new payment
      await _cache.remove('payment_all_1_50');
      await _cache.remove('payment_all_1_100');
      // Refresh the list without cache in background (don't wait)
      fetchAll(page: 1, limit: 50, useCache: false).catchError((_) {
        // Silently fail - user can manually refresh
        return false;
      });
      
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

  Future<bool> sendCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
  }) async {
    _isOtpSending = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.sendCustomerCloseOtp(transactionId: transactionId, ownerAadhar: ownerAadhar);
      _isOtpSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isOtpSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentTransaction = await _repo.verifyCustomerCloseOtp(
        transactionId: transactionId,
        ownerAadhar: ownerAadhar,
        otp: otp,
      );
      // Clear cache and refresh lists
      await _cache.remove('payment_all_1_50');
      await _cache.remove('payment_received_1_50');
      // Refresh in background
      fetchAll(useCache: false).catchError((_) {
        // Silently fail - background refresh
      });
      fetchReceived(useCache: false).catchError((_) {
        // Silently fail - background refresh
      });
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

  Future<bool> closePayment(String transactionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentTransaction = await _repo.closePayment(transactionId);
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

  Future<bool> fetchAll({int page = 1, int limit = 50, bool useCache = true}) async {
    final cacheKey = 'payment_all_${page}_$limit';
    
    // Check cache first
    if (useCache && page == 1) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> transactionsJson = cachedData['transactions'] ?? [];
          _history = transactionsJson.map((json) => TransactionModel.fromJson(json)).toList();
          notifyListeners();
          // Load fresh data in background
          _fetchAllInBackground(page: page, limit: limit);
          return true;
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    return await _deduplicator.deduplicate(cacheKey, () async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        PerformanceMonitor.start('fetch_all_payments');
        _history = await _repo.getAll(page: page, limit: limit);
        PerformanceMonitor.end('fetch_all_payments');

        // Cache the response
        if (page == 1) {
          await _cache.put(cacheKey, {
            'transactions': _history.map((t) => t.toJson()).toList(),
          });
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    });
  }

  Future<void> _fetchAllInBackground({int page = 1, int limit = 50}) async {
    try {
      final freshHistory = await _repo.getAll(page: page, limit: limit);
      _history = freshHistory;
      await _cache.put('payment_all_${page}_$limit', {
        'transactions': _history.map((t) => t.toJson()).toList(),
      });
      notifyListeners();
    } catch (e) {
      // Silently fail - user already has cached data
    }
  }

  Future<bool> fetchHistory(String aadhar, {int page = 1, int limit = 50}) async {
    // Optimize: Don't show loading for background fetches (like on app start)
    final isBackgroundFetch = _history.isNotEmpty;
    
    if (!isBackgroundFetch) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _history = await _repo.getHistoryByAadhar(
        aadhar,
        page: page,
        limit: limit,
      );
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      if (!isBackgroundFetch) {
        notifyListeners();
      }
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentTransaction() {
    _currentTransaction = null;
    notifyListeners();
  }

  Future<bool> fetchReceived({int page = 1, int limit = 50, bool useCache = true}) async {
    final cacheKey = 'payment_received_${page}_$limit';
    
    // Check cache first
    if (useCache && page == 1) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> transactionsJson = cachedData['transactions'] ?? [];
          _receivedHistory = transactionsJson.map((json) => TransactionModel.fromJson(json)).toList();
          notifyListeners();
          // Load fresh data in background
          _fetchReceivedInBackground(page: page, limit: limit);
          return true;
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    return await _deduplicator.deduplicate(cacheKey, () async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        PerformanceMonitor.start('fetch_received_payments');
        _receivedHistory = await _repo.getReceivedTransactions(page: page, limit: limit);
        PerformanceMonitor.end('fetch_received_payments');

        // Cache the response
        if (page == 1) {
          await _cache.put(cacheKey, {
            'transactions': _receivedHistory.map((t) => t.toJson()).toList(),
          });
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    });
  }

  Future<void> _fetchReceivedInBackground({int page = 1, int limit = 50}) async {
    try {
      final freshHistory = await _repo.getReceivedTransactions(page: page, limit: limit);
      _receivedHistory = freshHistory;
      await _cache.put('payment_received_${page}_$limit', {
        'transactions': _receivedHistory.map((t) => t.toJson()).toList(),
      });
      notifyListeners();
    } catch (e) {
      // Silently fail - user already has cached data
    }
  }
}

