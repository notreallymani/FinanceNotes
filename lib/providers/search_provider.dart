/// Search Provider (Refactored with SOLID Principles)
/// 
/// Single Responsibility: State management only
/// Dependency Inversion: Depends on use case abstraction

import 'package:flutter/foundation.dart';
import '../use_cases/search_use_case.dart';
import '../repositories/search_repository.dart';
import '../models/transaction_model.dart';

class SearchProvider with ChangeNotifier {
  final SearchUseCase _useCase;

  SearchProvider({SearchUseCase? useCase})
      : _useCase = useCase ?? SearchUseCase(SearchRepository());

  List<TransactionModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Search transactions by Aadhaar
  Future<bool> searchByAadhar(String aadhar, {bool useCache = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.searchByAadhar(aadhar, useCache: useCache);

    _isLoading = false;
    if (result.success && result.transactions != null) {
      _searchResults = result.transactions!;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
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

