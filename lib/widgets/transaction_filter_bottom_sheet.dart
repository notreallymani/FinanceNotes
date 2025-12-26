/// Transaction Filter Bottom Sheet
/// 
/// Single Responsibility: UI for filter options
/// Dependency Inversion: Uses filter model

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter.dart';

class TransactionFilterBottomSheet extends StatefulWidget {
  final TransactionFilter initialFilter;
  final Function(TransactionFilter) onApply;

  const TransactionFilterBottomSheet({
    Key? key,
    required this.initialFilter,
    required this.onApply,
  }) : super(key: key);

  @override
  State<TransactionFilterBottomSheet> createState() =>
      _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState
    extends State<TransactionFilterBottomSheet> {
  late TransactionFilter _currentFilter;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _minAmountController.text = _currentFilter.minAmount?.toStringAsFixed(0) ?? '';
    _maxAmountController.text = _currentFilter.maxAmount?.toStringAsFixed(0) ?? '';
    _searchController.text = _currentFilter.searchQuery ?? '';
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Filter Transactions',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Filter
                  _buildStatusFilter(),
                  const SizedBox(height: 24),
                  // Date Range Filter
                  _buildDateRangeFilter(),
                  const SizedBox(height: 24),
                  // Amount Range Filter
                  _buildAmountRangeFilter(),
                  const SizedBox(height: 24),
                  // Other Filters
                  _buildOtherFilters(),
                  const SizedBox(height: 24),
                  // Sort Options
                  _buildSortOptions(),
                ],
              ),
            ),
          ),
          // Action Buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['pending', 'closed', 'cancelled'].map((status) {
            final isSelected = _currentFilter.statuses?.contains(status) ?? false;
            return FilterChip(
              label: Text(status.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final currentStatuses = Set<String>.from(
                    _currentFilter.statuses ?? [],
                  );
                  if (selected) {
                    currentStatuses.add(status);
                  } else {
                    currentStatuses.remove(status);
                  }
                  _currentFilter = _currentFilter.copyWith(
                    statuses: currentStatuses.isEmpty ? null : currentStatuses,
                  );
                });
              },
              selectedColor: _getStatusColor(status).withOpacity(0.2),
              checkmarkColor: _getStatusColor(status),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isSelected ? _getStatusColor(status) : Colors.grey[700],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                'From',
                _currentFilter.startDate,
                (date) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(startDate: date);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                'To',
                _currentFilter.endDate,
                (date) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(endDate: date);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime? date,
    Function(DateTime?) onDateSelected,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date != null
                ? DateFormat('dd MMM yyyy').format(date)
                : 'Select',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount Range',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Amount',
                  hintText: '0',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  _currentFilter = _currentFilter.copyWith(
                    minAmount: amount,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Amount',
                  hintText: '100000',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  _currentFilter = _currentFilter.copyWith(
                    maxAmount: amount,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Filters',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Search by Aadhaar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search by Aadhaar',
            hintText: 'Enter Aadhaar number',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            _currentFilter = _currentFilter.copyWith(
              searchQuery: value.isEmpty ? null : value,
            );
          },
        ),
        const SizedBox(height: 16),
        // Has Documents
        _buildToggleFilter(
          'Has Documents',
          _currentFilter.hasDocuments,
          (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(hasDocuments: value);
            });
          },
        ),
        const SizedBox(height: 12),
        // Has Interest
        _buildToggleFilter(
          'Has Interest',
          _currentFilter.hasInterest,
          (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(hasInterest: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildToggleFilter(
    String label,
    bool? value,
    Function(bool?) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption('All', value == null, () => onChanged(null)),
            const SizedBox(width: 8),
            _buildToggleOption('Yes', value == true, () => onChanged(true)),
            const SizedBox(width: 8),
            _buildToggleOption('No', value == false, () => onChanged(false)),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...SortOption.values.map((option) {
          return RadioListTile<SortOption>(
            title: Text(_getSortLabel(option)),
            value: option,
            groupValue: _currentFilter.sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentFilter = _currentFilter.copyWith(sortBy: value);
                });
              }
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
        return 'Newest First';
      case SortOption.dateAsc:
        return 'Oldest First';
      case SortOption.amountDesc:
        return 'Highest Amount';
      case SortOption.amountAsc:
        return 'Lowest Amount';
      case SortOption.status:
        return 'By Status';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _applyFilters() {
    widget.onApply(_currentFilter);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = const TransactionFilter();
      _minAmountController.clear();
      _maxAmountController.clear();
      _searchController.clear();
    });
  }
}

