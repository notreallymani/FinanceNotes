import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../utils/validators.dart';
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
  final _ownerAadharController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isClosingPayment = false;
  bool _isBottomSheetShowing = false;
  String? _selectedTransactionId;
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
        await paymentProvider.fetchHistory(userAadhar); // as receiver
      }
    });
  }


  @override
  void dispose() {
    _aadharController.dispose();
    _ownerAadharController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    if (!_filterFormKey.currentState!.validate()) return;
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final success =
        await paymentProvider.fetchHistory(_aadharController.text.trim());
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.error ?? 'Failed to load transactions'),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> _sendCustomerOtp(BuildContext context, TransactionModel t) async {
    // Prevent multiple clicks
    if (_isSendingOtp) {
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final ok = await paymentProvider.sendCustomerCloseOtp(
      transactionId: t.id,
      ownerAadhar: _ownerAadharController.text.trim(),
    );
    
    if (!mounted) {
      setState(() {
        _isSendingOtp = false;
      });
      return;
    }

    setState(() {
      _isSendingOtp = false;
    });

    if (ok) {
      setState(() {
        _otpSent = true;
        _selectedTransactionId = t.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to owner'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.error ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCustomerOtp(BuildContext context, TransactionModel t) async {
    // Prevent multiple clicks
    if (_isVerifyingOtp) {
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final ok = await paymentProvider.verifyCustomerCloseOtp(
      transactionId: t.id,
      ownerAadhar: _ownerAadharController.text.trim(),
      otp: _otpController.text.trim(),
    );
    
    if (!mounted) {
      setState(() {
        _isVerifyingOtp = false;
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = false;
    });

    if (ok) {
      setState(() {
        _otpSent = false;
        _selectedTransactionId = null;
        _otpController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment closed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadPending();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.error ?? 'Failed to verify OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  final ownerPending = paymentProvider.history
                      .where((t) => t.status.toLowerCase() == 'pending')
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  final customerPending = paymentProvider.history
                      .where((t) =>
                          t.status.toLowerCase() == 'pending' &&
                          t.receiverAadhar == userAadhar)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  
                  if (paymentProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab Buttons
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
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
                      // Content based on selected tab
                      if (_selectedTab == 'sent') ...[
                        Text(
                          'You are the Owner (Sent)',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (ownerPending.isEmpty)
                          Text(
                            'No pending transactions you created.',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.grey[600]),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ownerPending.length,
                            itemBuilder: (context, index) {
                              final t = ownerPending[index];
                              return _ownerCard(t);
                            },
                          ),
                      ] else ...[
                        Text(
                          'You are the Customer (Received)',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (customerPending.isEmpty)
                          Text(
                            'No pending transactions you received.',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.grey[600]),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: customerPending.length,
                            itemBuilder: (context, index) {
                              final t = customerPending[index];
                              return _customerCard(t);
                            },
                          ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
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
                  Text(
                    '₹${t.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer Aadhaar: ${_maskAadhar(t.receiverAadhar)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                    color: _getStatusColor(t.status)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    t.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(t.status),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  child: PrimaryButton(
                    text: 'Close',
                    onPressed: () => _confirmAndClose(t),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(TransactionModel t) {
    return Container(
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
                  Text(
                    '₹${t.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner Aadhaar: ${_maskAadhar(t.senderAadhar)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(t.createdAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                    color: _getStatusColor(t.status)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    t.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(t.status),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 140,
                  child: PrimaryButton(
                    text: 'Close as Customer',
                    onPressed: () => _startCustomerClose(context, t),
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
