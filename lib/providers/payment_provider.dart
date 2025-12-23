import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../repositories/payment_repository.dart';
import '../models/transaction_model.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentRepository _repo = PaymentRepository();

  List<TransactionModel> _history = [];
  TransactionModel? _currentTransaction;
  bool _isLoading = false;
  String? _error;
  bool _isOtpSending = false;

  List<TransactionModel> get history => _history;
  TransactionModel? get currentTransaction => _currentTransaction;
  bool get isLoading => _isLoading;
  bool get isOtpSending => _isOtpSending;
  String? get error => _error;

  Future<bool> sendPayment({
    required String aadhar,
    required double amount,
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
        mobile: mobile,
        interest: interest,
        documents: documents,
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

  Future<bool> fetchAll({int page = 1, int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _repo.getAll(page: page, limit: limit);
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
}

