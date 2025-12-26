/// Transaction Filter Model
/// 
/// Single Responsibility: Represents filter state
/// Immutable filter configuration

class TransactionFilter {
  final Set<String>? statuses; // null means all
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final bool? hasDocuments; // null means all, true = has docs, false = no docs
  final bool? hasInterest; // null means all, true = has interest, false = no interest
  final String? searchQuery; // Search by Aadhaar
  final SortOption sortBy;

  const TransactionFilter({
    this.statuses,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.hasDocuments,
    this.hasInterest,
    this.searchQuery,
    this.sortBy = SortOption.dateDesc,
  });

  TransactionFilter copyWith({
    Set<String>? statuses,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    bool? hasDocuments,
    bool? hasInterest,
    String? searchQuery,
    SortOption? sortBy,
  }) {
    return TransactionFilter(
      statuses: statuses ?? this.statuses,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      hasDocuments: hasDocuments ?? this.hasDocuments,
      hasInterest: hasInterest ?? this.hasInterest,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters {
    return statuses != null && statuses!.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        hasDocuments != null ||
        hasInterest != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  TransactionFilter clear() {
    return const TransactionFilter();
  }
}

enum SortOption {
  dateDesc, // Newest first
  dateAsc, // Oldest first
  amountDesc, // Highest first
  amountAsc, // Lowest first
  status,
}

