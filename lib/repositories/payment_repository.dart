import '../api/payment_api.dart';
import '../models/transaction_model.dart';

class PaymentRepository {
  final PaymentApi _api = PaymentApi();
  final Map<String, List<TransactionModel>> _historyCache = {};

  Future<TransactionModel> sendPayment({
    required String aadhar,
    required double amount,
    String? mobile,
    double? interest,
    List<dynamic>? documents,
  }) async {
    return _api.sendPayment(
      aadhar: aadhar,
      amount: amount,
      mobile: mobile,
      interest: interest,
      documents: documents?.cast(),
    );
  }

  Future<TransactionModel> closePayment(String transactionId) async {
    final t = await _api.closePayment(transactionId);
    _historyCache.update(t.receiverAadhar, (list) {
      return list.map((e) => e.id == t.id ? t : e).toList();
    }, ifAbsent: () => []);
    _historyCache.update(t.senderAadhar, (list) {
      return list.map((e) => e.id == t.id ? t : e).toList();
    }, ifAbsent: () => []);
    return t;
  }

  Future<void> sendCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
  }) {
    return _api.sendCustomerCloseOtp(
      transactionId: transactionId,
      ownerAadhar: ownerAadhar,
    );
  }

  Future<TransactionModel> verifyCustomerCloseOtp({
    required String transactionId,
    required String ownerAadhar,
    required String otp,
  }) async {
    final t = await _api.verifyCustomerCloseOtp(
      transactionId: transactionId,
      ownerAadhar: ownerAadhar,
      otp: otp,
    );
    _historyCache.update(t.receiverAadhar, (list) {
      return list.map((e) => e.id == t.id ? t : e).toList();
    }, ifAbsent: () => []);
    _historyCache.update(t.senderAadhar, (list) {
      return list.map((e) => e.id == t.id ? t : e).toList();
    }, ifAbsent: () => []);
    return t;
  }

  Future<List<TransactionModel>> getHistoryByAadhar(
    String aadhar, {
    int page = 1,
    int limit = 50,
  }) async {
    final cached = _historyCache[aadhar];
    if (cached != null && cached.isNotEmpty && page == 1) {
      // Only use cache for the first page; pagination beyond page 1
      // should always hit the API.
      return cached;
    }
    final fetched = await _api.getHistoryByAadhar(
      aadhar,
      page: page,
      limit: limit,
    );
    _historyCache[aadhar] = fetched;
    return fetched;
  }

  Future<List<TransactionModel>> getAll({
    int page = 1,
    int limit = 50,
  }) async {
    final fetched = await _api.getAllTransactions(
      page: page,
      limit: limit,
    );
    return fetched;
  }

  void clearCache() {
    _historyCache.clear();
  }
}
