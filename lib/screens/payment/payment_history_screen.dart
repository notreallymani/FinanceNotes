import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/time_utils.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/transaction_filter_util.dart';
import '../../models/transaction_filter.dart';
import '../../widgets/transaction_filter_bottom_sheet.dart';
import '../chat/chat_screen.dart';
import 'transaction_detail_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final List<TransactionModel>? transactions;

  const PaymentHistoryScreen({super.key, this.transactions});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _searchController = TextEditingController();
  TransactionFilter _filter = const TransactionFilter();

  @override
  void initState() {
    super.initState();
    // Load all payments when this screen is opened, unless an explicit
    // transactions list is injected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.transactions == null) {
        final paymentProvider =
            Provider.of<PaymentProvider>(context, listen: false);
        // Show only the transactions created by the current user
        // (senderAadhar == user Aadhaar) via the /payment/all endpoint.
        paymentProvider.fetchAll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterBottomSheet,
                tooltip: 'Filter transactions',
              ),
              if (_filter.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<AuthProvider, PaymentProvider>(
          builder: (context, authProvider, paymentProvider, _) {
            // Always show all transactions provided by the backend (either
            // from the provider history or injected from Search), and simply
            // sort them by most recent first. Any ownership filtering should
            // be handled server-side when fetching history.
            final base = widget.transactions ?? paymentProvider.history;
            final allItems = List<TransactionModel>.from(base);
            
            // Apply filters
            final filteredItems = TransactionFilterUtil.applyFilters(
              allItems,
              _filter,
            );
            
            final items = filteredItems;

            // Show skeleton loader while loading and no data
            if (paymentProvider.isLoading && items.isEmpty) {
              return const CardSkeletonLoader(itemCount: 5);
            }

            return Column(
              children: [
                // Active Filters Bar
                if (_filter.hasActiveFilters) _buildActiveFiltersBar(),
                // Quick Filter Chips
                _buildQuickFilters(),
                // Transaction List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
                      await paymentProvider.fetchAll(useCache: false);
                    },
                    child: items.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final transaction = items[index];
                              return _buildTransactionCard(context, transaction);
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _filter.hasActiveFilters
                  ? 'No transactions match your filters'
                  : 'No transactions found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_filter.hasActiveFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Clear Filters',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel transaction) {
    return InkWell(
      onTap: () => _openTransactionDetail(context, transaction),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (transaction.customerName != null && transaction.customerName!.isNotEmpty) ...[
                      Text(
                        transaction.customerName!,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '₹${transaction.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aadhaar: ${_maskAadhar(transaction.receiverAadhar)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.status.toLowerCase() == 'closed' && transaction.closedAt != null
                          ? 'Closed: ${TimeUtils.formatIST(transaction.closedAt!)}'
                          : 'Created: ${TimeUtils.formatIST(transaction.createdAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: transaction.status.toLowerCase() == 'closed' 
                            ? Colors.green[700] 
                            : Colors.grey[600],
                        fontWeight: transaction.status.toLowerCase() == 'closed' 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction.status)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(transaction.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final currentUserAadhar = authProvider.user?.aadhar ?? '';
                      final isOwner = transaction.senderAadhar == currentUserAadhar;
                      
                      return GestureDetector(
                        onTap: () => _openChat(context, transaction, isOwner),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isOwner ? Icons.person : Icons.chat_bubble_outline,
                            size: 20,
                            color: isOwner 
                                ? Colors.grey[600] 
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickFilterChip(
              'All',
              !_filter.hasActiveFilters,
              () => _clearFilters(),
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              'Pending',
              _filter.statuses?.contains('pending') ?? false,
              () {
                setState(() {
                  _filter = _filter.copyWith(
                    statuses: {'pending'},
                  );
                });
              },
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              'Closed',
              _filter.statuses?.contains('closed') ?? false,
              () {
                setState(() {
                  _filter = _filter.copyWith(
                    statuses: {'closed'},
                  );
                });
              },
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              'Today',
              _isTodayFilter(),
              () {
                final now = DateTime.now();
                setState(() {
                  _filter = _filter.copyWith(
                    startDate: DateTime(now.year, now.month, now.day),
                    endDate: now,
                  );
                });
              },
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              'This Week',
              _isThisWeekFilter(),
              () {
                final now = DateTime.now();
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                setState(() {
                  _filter = _filter.copyWith(
                    startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
                    endDate: now,
                  );
                });
              },
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              'This Month',
              _isThisMonthFilter(),
              () {
                final now = DateTime.now();
                setState(() {
                  _filter = _filter.copyWith(
                    startDate: DateTime(now.year, now.month, 1),
                    endDate: now,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              TransactionFilterUtil.getFilterSummary(_filter),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.blue[900],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  bool _isTodayFilter() {
    if (_filter.startDate == null || _filter.endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _filter.startDate!.isAtSameMomentAs(today) &&
        _filter.endDate!.day == now.day &&
        _filter.endDate!.month == now.month &&
        _filter.endDate!.year == now.year;
  }

  bool _isThisWeekFilter() {
    if (_filter.startDate == null || _filter.endDate == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _filter.startDate!.isAtSameMomentAs(weekStartDate) &&
        _filter.endDate!.day == now.day &&
        _filter.endDate!.month == now.month &&
        _filter.endDate!.year == now.year;
  }

  bool _isThisMonthFilter() {
    if (_filter.startDate == null || _filter.endDate == null) return false;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _filter.startDate!.isAtSameMomentAs(monthStart) &&
        _filter.endDate!.day == now.day &&
        _filter.endDate!.month == now.month &&
        _filter.endDate!.year == now.year;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TransactionFilterBottomSheet(
        initialFilter: _filter,
        onApply: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filter = const TransactionFilter();
    });
  }

  void _openChat(BuildContext context, TransactionModel t, bool isOwner) {
    // If user is the owner, show message
    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are the owner of this payment. You cannot chat with yourself.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Navigate to in-app chat screen with smooth transition
    NavigationHelper.fadeTo(
      context,
      ChatScreen(transaction: t),
    );
  }

  void _openTransactionDetail(BuildContext context, TransactionModel transaction) {
    NavigationHelper.fadeTo(
      context,
      TransactionDetailScreen(transaction: transaction),
    );
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} **** ${value.substring(8)}';
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
}

