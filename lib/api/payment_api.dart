import 'package:dio/dio.dart';
import '../utils/app_constants.dart';
import '../models/transaction_model.dart';
import '../utils/http_client.dart';
import '../utils/logger.dart';

class PaymentApi {
  final Dio _dio = HttpClient.instance;

  Future<TransactionModel> sendPayment({
    required String aadhar,
    required double amount,
    required String customerName,
    String? mobile,
    double? interest,
    List<MultipartFile>? documents,
  }) async {
    // Call backend API (same for dev and prod - backend handles environment)
    try {
      Logger.log('📤 Calling backend to send payment');
      final formData = FormData.fromMap({
        'aadhar': aadhar,
        'amount': amount,
        'customerName': customerName,
        if (mobile != null) 'mobile': mobile,
        if (interest != null) 'interest': interest,
      });

      if (documents != null && documents.isNotEmpty) {
        formData.files.addAll(
          documents.map(
            (file) => MapEntry('documents', file),
          ),
        );
      }

      final response = await _dio.post(
        AppConstants.sendPaymentEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return TransactionModel.fromJson(response.data['transaction'] ?? response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<TransactionModel> closePayment(String transactionId) async {
    try {
      final response = await _dio.post(
        AppConstants.closePaymentEndpoint,
        data: {
          'transactionId': transactionId,
        },
      );
      return TransactionModel.fromJson(response.data['transaction'] ?? response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> sendCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
  }) async {
    try {
      await _dio.post(
        AppConstants.customerCloseSendOtpEndpoint,
        data: {
          'transactionId': transactionId,
          'ownerAadhar': ownerAadhar,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<TransactionModel> verifyCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.customerCloseVerifyOtpEndpoint,
        data: {
          'transactionId': transactionId,
          'ownerAadhar': ownerAadhar,
          'otp': otp,
        },
      );
      return TransactionModel.fromJson(response.data['transaction'] ?? response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TransactionModel>> getHistoryByAadhar(
    String aadhar, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.paymentHistoryEndpoint,
        queryParameters: {
          'aadhar': aadhar,
          'page': page,
          'limit': limit,
        },
      );
      final List<dynamic> transactions = response.data['transactions'] ?? response.data ?? [];
      return transactions.map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TransactionModel>> getAllTransactions({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Reuse the base payment history endpoint, but hit /all instead of /history
      final allEndpoint =
          AppConstants.paymentHistoryEndpoint.replaceFirst('/history', '/all');
      final response = await _dio.get(
        allEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final List<dynamic> transactions =
          response.data['transactions'] ?? response.data ?? [];
      return transactions
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TransactionModel>> getReceivedTransactions({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Get received transactions where receiverAadhar matches user's Aadhaar
      final receivedEndpoint =
          AppConstants.paymentHistoryEndpoint.replaceFirst('/history', '/received');
      final response = await _dio.get(
        receivedEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final List<dynamic> transactions =
          response.data['transactions'] ?? response.data ?? [];
      return transactions
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> getDocumentDownloadUrl(String documentUrl) async {
    try {
      final response = await _dio.get(
        AppConstants.documentDownloadUrlEndpoint,
        queryParameters: {
          'url': documentUrl,
        },
      );
      return response.data['url'] as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final message = error.response?.data['message'] ?? 
                       error.response?.data['error'] ?? 
                       'An error occurred';
        return Exception(message);
      } else {
        Logger.log('Network error: ${error.message}');
        return Exception('Network error');
      }
    }
    return Exception('Unexpected error: $error');
  }
}

