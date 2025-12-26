/// Search Use Case
/// 
/// Single Responsibility: Handles search business logic
/// Dependency Inversion: Depends on repository abstractions

import '../repositories/search_repository.dart';
import '../models/transaction_model.dart';
import '../utils/validators.dart';

class SearchUseCase {
  final SearchRepository _repository;

  SearchUseCase(this._repository);

  /// Search transactions by Aadhaar
  Future<SearchResult> searchByAadhar(
    String aadhar, {
    bool useCache = true,
  }) async {
    // Business logic validation
    if (aadhar.isEmpty) {
      return SearchResult.failure('Aadhaar number is required');
    }

    final aadharError = Validators.validateAadhar(aadhar);
    if (aadharError != null) {
      return SearchResult.failure(aadharError);
    }

    try {
      final transactions = await _repository.searchByAadhar(
        aadhar,
        useCache: useCache,
      );
      return SearchResult.success(transactions);
    } catch (e) {
      return SearchResult.failure(e.toString());
    }
  }
}

/// Search Result
class SearchResult {
  final bool success;
  final List<TransactionModel>? transactions;
  final String? error;

  SearchResult._({
    required this.success,
    this.transactions,
    this.error,
  });

  factory SearchResult.success(List<TransactionModel> transactions) {
    return SearchResult._(
      success: true,
      transactions: transactions,
    );
  }

  factory SearchResult.failure(String error) {
    return SearchResult._(
      success: false,
      error: error,
    );
  }
}

