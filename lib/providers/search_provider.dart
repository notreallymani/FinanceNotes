import 'package:flutter/foundation.dart';
import '../api/payment_api.dart';
import '../models/transaction_model.dart';

class SearchProvider with ChangeNotifier {
  final PaymentApi _paymentApi = PaymentApi();

  List<TransactionModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> searchByAadhar(String aadhar) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _paymentApi.getHistoryByAadhar(aadhar);
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

  void clearResults() {
    _searchResults = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

