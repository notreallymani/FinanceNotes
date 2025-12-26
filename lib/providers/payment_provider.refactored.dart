/// Payment Provider (Refactored with SOLID Principles)
/// 
/// Single Responsibility: State management only
/// Dependency Inversion: Depends on use case abstraction

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../use_cases/payment_use_case.dart';
import '../repositories/payment_repository.refactored.dart' as payment_repo;
import '../models/transaction_model.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentUseCase _useCase;

  PaymentProvider({PaymentUseCase? useCase})
      : _useCase = useCase ??
            PaymentUseCase(payment_repo.PaymentRepository());

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

  /// Send payment request
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

    // Convert PlatformFile to MultipartFile
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
      documents = uploads.whereType<MultipartFile>().toList();
      if (documents.isEmpty) documents = null;
    }

    final result = await _useCase.sendPayment(
      aadhar: aadhar,
      amount: amount,
      mobile: mobile,
      interest: interest,
      documents: documents,
    );

    _isLoading = false;
    if (result.success && result.transaction != null) {
      _currentTransaction = result.transaction;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Send customer close OTP
  Future<bool> sendCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
  }) async {
    _isOtpSending = true;
    _error = null;
    notifyListeners();

    final success = await _useCase.sendCustomerCloseOtp(
      transactionId: transactionId,
      ownerAadhar: ownerAadhar,
    );

    _isOtpSending = false;
    if (!success) {
      _error = 'Failed to send OTP';
    }
    notifyListeners();
    return success;
  }

  /// Verify customer close OTP
  Future<bool> verifyCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.verifyCustomerCloseOtp(
      transactionId: transactionId,
      ownerAadhar: ownerAadhar,
      otp: otp,
    );

    _isLoading = false;
    if (result.success && result.transaction != null) {
      _currentTransaction = result.transaction;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Close payment
  Future<bool> closePayment(String transactionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.closePayment(transactionId);

    _isLoading = false;
    if (result.success && result.transaction != null) {
      _currentTransaction = result.transaction;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Fetch all transactions
  Future<bool> fetchAll({
    int page = 1,
    int limit = 50,
    bool useCache = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.getAllTransactions(
      page: page,
      limit: limit,
      useCache: useCache,
    );

    _isLoading = false;
    if (result.success && result.transactions != null) {
      _history = result.transactions!;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Fetch payment history by Aadhaar
  Future<bool> fetchHistory(
    String aadhar, {
    int page = 1,
    int limit = 50,
    bool useCache = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.getHistory(
      aadhar,
      page: page,
      limit: limit,
      useCache: useCache,
    );

    _isLoading = false;
    if (result.success && result.transactions != null) {
      _history = result.transactions!;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
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

