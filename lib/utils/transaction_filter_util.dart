/// Transaction Filter Utility
/// 
/// Single Responsibility: Filtering logic for transactions
/// Pure functions - no side effects

import '../models/transaction_model.dart';
import '../models/transaction_filter.dart';

class TransactionFilterUtil {
  /// Apply filters to transaction list
  static List<TransactionModel> applyFilters(
    List<TransactionModel> transactions,
    TransactionFilter filter,
  ) {
    var filtered = List<TransactionModel>.from(transactions);

    // Filter by status
    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      filtered = filtered.where((t) {
        return filter.statuses!.contains(t.status.toLowerCase());
      }).toList();
    }

    // Filter by date range
    if (filter.startDate != null) {
      filtered = filtered.where((t) {
        return t.createdAt.isAfter(filter.startDate!) ||
            t.createdAt.isAtSameMomentAs(filter.startDate!);
      }).toList();
    }

    if (filter.endDate != null) {
      filtered = filtered.where((t) {
        final endOfDay = DateTime(
          filter.endDate!.year,
          filter.endDate!.month,
          filter.endDate!.day,
          23,
          59,
          59,
        );
        return t.createdAt.isBefore(endOfDay) ||
            t.createdAt.isAtSameMomentAs(endOfDay);
      }).toList();
    }

    // Filter by amount range
    if (filter.minAmount != null) {
      filtered = filtered.where((t) => t.amount >= filter.minAmount!).toList();
    }

    if (filter.maxAmount != null) {
      filtered = filtered.where((t) => t.amount <= filter.maxAmount!).toList();
    }

    // Filter by documents
    if (filter.hasDocuments != null) {
      filtered = filtered.where((t) {
        if (filter.hasDocuments!) {
          return t.documents.isNotEmpty;
        } else {
          return t.documents.isEmpty;
        }
      }).toList();
    }

    // Filter by interest
    if (filter.hasInterest != null) {
      filtered = filtered.where((t) {
        if (filter.hasInterest!) {
          return t.interest > 0;
        } else {
          return t.interest == 0;
        }
      }).toList();
    }

    // Filter by search query (Aadhaar)
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      filtered = filtered.where((t) {
        return t.senderAadhar.contains(query) ||
            t.receiverAadhar.contains(query);
      }).toList();
    }

    // Sort
    filtered = _sortTransactions(filtered, filter.sortBy);

    return filtered;
  }

  /// Sort transactions
  static List<TransactionModel> _sortTransactions(
    List<TransactionModel> transactions,
    SortOption sortBy,
  ) {
    final sorted = List<TransactionModel>.from(transactions);

    switch (sortBy) {
      case SortOption.dateDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.amountDesc:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountAsc:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortOption.status:
        sorted.sort((a, b) => a.status.compareTo(b.status));
        break;
    }

    return sorted;
  }

  /// Get filter summary text
  static String getFilterSummary(TransactionFilter filter) {
    final parts = <String>[];

    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      parts.add('${filter.statuses!.length} status${filter.statuses!.length > 1 ? 'es' : ''}');
    }

    if (filter.startDate != null || filter.endDate != null) {
      parts.add('Date range');
    }

    if (filter.minAmount != null || filter.maxAmount != null) {
      parts.add('Amount range');
    }

    if (filter.hasDocuments != null) {
      parts.add(filter.hasDocuments! ? 'With docs' : 'No docs');
    }

    if (filter.hasInterest != null) {
      parts.add(filter.hasInterest! ? 'With interest' : 'No interest');
    }

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      parts.add('Search');
    }

    return parts.isEmpty ? 'No filters' : parts.join(', ');
  }
}

