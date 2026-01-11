import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../models/transaction_model.dart';
import 'close_payment_confirmation_screen.dart';
import 'customer_close_screen.dart';

class ClosePaymentScreen extends StatefulWidget {
  const ClosePaymentScreen({super.key});

  @override
  State<ClosePaymentScreen> createState() => _ClosePaymentScreenState();
}

class _ClosePaymentScreenState extends State<ClosePaymentScreen> {
  final _filterFormKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  bool _isClosingPayment = false;
  String _selectedTab = 'sent'; // 'sent' or 'received'

  @override
  void initState() {
    super.initState();
    // Load owner-created and receiver transactions
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      final userAadhar = authProvider.user?.aadhar ?? '';
      await paymentProvider.fetchAll(); // owner-created
      if (userAadhar.isNotEmpty) {
        await paymentProvider.fetchReceived(); // as receiver
      }
    });
  }


  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final userAadhar = authProvider.user?.aadhar ?? '';
    
    // Refresh both sent and received transactions
    await paymentProvider.fetchAll(useCache: false);
    if (userAadhar.isNotEmpty) {
      await paymentProvider.fetchReceived(useCache: false);
    }
  }

  Future<void> _confirmAndClose(TransactionModel transaction) async {
    // Prevent multiple clicks
    if (_isClosingPayment) {
      return;
    }

    setState(() {
      _isClosingPayment = true;
    });

    // Navigate to confirmation screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClosePaymentConfirmationScreen(
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      await _loadPending();
    }

    setState(() {
      _isClosingPayment = false;
    });
  }

  Future<void> _startCustomerClose(BuildContext context, TransactionModel t) async {
    // Navigate to customer close screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerCloseScreen(transaction: t),
      ),
    );

    if (result == true) {
      await _loadPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userAadhar = authProvider.user?.aadhar ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Close Payment',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<PaymentProvider>(
          builder: (context, paymentProvider, _) {
                  final ownerPending = paymentProvider.history
                      .where((t) => t.status.toLowerCase() == 'pending')
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  final customerPending = paymentProvider.receivedHistory
                      .where((t) => t.status.toLowerCase() == 'pending')
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  
                  if (paymentProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final currentList = _selectedTab == 'sent' ? ownerPending : customerPending;
                  
                  return Column(
                    children: [
                      // Compact Tab Buttons
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                'Sent',
                                _selectedTab == 'sent',
                                () => setState(() => _selectedTab = 'sent'),
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                'Received',
                                _selectedTab == 'received',
                                () => setState(() => _selectedTab = 'received'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content List
                      Expanded(
                        child: currentList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.payment_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _selectedTab == 'sent'
                                            ? 'No pending transactions you created'
                                            : 'No pending transactions you received',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: currentList.length,
                                itemBuilder: (context, index) {
                                  final t = currentList[index];
                                  return _selectedTab == 'sent'
                                      ? _ownerCard(t)
                                      : _customerCard(t);
                                },
                              ),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} **** ${value.substring(8)}';
  }

  Widget _ownerCard(TransactionModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.customerName?.isNotEmpty == true
                              ? t.customerName!
                              : 'Customer',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(t.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(t.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${t.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aadhaar: ${_maskAadhar(t.receiverAadhar)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              height: 38,
              child: ElevatedButton(
                onPressed: () => _confirmAndClose(t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(TransactionModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment Request',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(t.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(t.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${t.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${_maskAadhar(t.senderAadhar)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              height: 38,
              child: ElevatedButton(
                onPressed: () => _startCustomerClose(context, t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
