/// Payment Use Case
/// 
/// Single Responsibility: Handles payment business logic
/// Dependency Inversion: Depends on repository abstractions

import '../repositories/payment_repository.refactored.dart';
import '../models/transaction_model.dart';
import 'package:dio/dio.dart';

class PaymentUseCase {
  final PaymentRepository _repository;

  PaymentUseCase(this._repository);

  /// Send payment request
  Future<PaymentResult> sendPayment({
    required String aadhar,
    required double amount,
    String? mobile,
    double? interest,
    List<MultipartFile>? documents,
  }) async {
    // Business logic validation
    if (aadhar.isEmpty || aadhar.length != 12) {
      return PaymentResult.failure('Aadhaar must be 12 digits');
    }

    if (amount <= 0) {
      return PaymentResult.failure('Amount must be greater than 0');
    }

    if (mobile != null && mobile.isNotEmpty && mobile.length != 10) {
      return PaymentResult.failure('Mobile number must be 10 digits');
    }

    if (interest != null && interest < 0) {
      return PaymentResult.failure('Interest cannot be negative');
    }

    try {
      final transaction = await _repository.sendPayment(
        aadhar: aadhar,
        amount: amount,
        mobile: mobile,
        interest: interest,
        documents: documents,
      );
      return PaymentResult.success(transaction);
    } catch (e) {
      return PaymentResult.failure(e.toString());
    }
  }

  /// Close payment
  Future<PaymentResult> closePayment(String transactionId) async {
    if (transactionId.isEmpty) {
      return PaymentResult.failure('Transaction ID is required');
    }

    try {
      final transaction = await _repository.closePayment(transactionId);
      return PaymentResult.success(transaction);
    } catch (e) {
      return PaymentResult.failure(e.toString());
    }
  }

  /// Send customer close OTP
  Future<bool> sendCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
  }) async {
    if (transactionId.isEmpty || ownerAadhar.isEmpty) {
      return false;
    }

    try {
      await _repository.sendCustomerCloseOtp(
        transactionId: transactionId,
        ownerAadhar: ownerAadhar,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify customer close OTP
  Future<PaymentResult> verifyCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
    required String otp,
  }) async {
    if (transactionId.isEmpty || ownerAadhar.isEmpty) {
      return PaymentResult.failure('Transaction ID and owner Aadhaar are required');
    }

    if (otp.length != 6) {
      return PaymentResult.failure('OTP must be 6 digits');
    }

    try {
      final transaction = await _repository.verifyCustomerCloseOtp(
        transactionId: transactionId,
        ownerAadhar: ownerAadhar,
        otp: otp,
      );
      return PaymentResult.success(transaction);
    } catch (e) {
      return PaymentResult.failure(e.toString());
    }
  }

  /// Get payment history
  Future<PaymentListResult> getHistory(
    String aadhar, {
    int page = 1,
    int limit = 50,
    bool useCache = true,
  }) async {
    if (aadhar.isEmpty) {
      return PaymentListResult.failure('Aadhaar is required');
    }

    try {
      final transactions = await _repository.getHistoryByAadhar(
        aadhar,
        page: page,
        limit: limit,
        useCache: useCache,
      );
      return PaymentListResult.success(transactions);
    } catch (e) {
      return PaymentListResult.failure(e.toString());
    }
  }

  /// Get all transactions
  Future<PaymentListResult> getAllTransactions({
    int page = 1,
    int limit = 50,
    bool useCache = true,
  }) async {
    try {
      final transactions = await _repository.getAll(
        page: page,
        limit: limit,
        useCache: useCache,
      );
      return PaymentListResult.success(transactions);
    } catch (e) {
      return PaymentListResult.failure(e.toString());
    }
  }
}

/// Payment Result
class PaymentResult {
  final bool success;
  final TransactionModel? transaction;
  final String? error;

  PaymentResult._({
    required this.success,
    this.transaction,
    this.error,
  });

  factory PaymentResult.success(TransactionModel transaction) {
    return PaymentResult._(
      success: true,
      transaction: transaction,
    );
  }

  factory PaymentResult.failure(String error) {
    return PaymentResult._(
      success: false,
      error: error,
    );
  }
}

/// Payment List Result
class PaymentListResult {
  final bool success;
  final List<TransactionModel>? transactions;
  final String? error;

  PaymentListResult._({
    required this.success,
    this.transactions,
    this.error,
  });

  factory PaymentListResult.success(List<TransactionModel> transactions) {
    return PaymentListResult._(
      success: true,
      transactions: transactions,
    );
  }

  factory PaymentListResult.failure(String error) {
    return PaymentListResult._(
      success: false,
      error: error,
    );
  }
}

