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
  String? _selectedTransactionId;
  

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
    final aadhaarInput = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirm Close',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction: ${transaction.id}',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Customer Aadhaar',
                hint: 'Enter customer Aadhaar to confirm',
                controller: aadhaarInput,
                validator: Validators.validateAadhar,
              ),
              const SizedBox(height: 24),
              Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  return PrimaryButton(
                    text: 'Close Payment',
                    isLoading: paymentProvider.isLoading,
                    onPressed: () async {
                      final formValid =
                          Validators.validateAadhar(aadhaarInput.text.trim()) ==
                              null;
                      if (!formValid) return;

                      // Customer Aadhaar must match receiverAadhar
                      final expectedAadhar = transaction.receiverAadhar;
                      if (aadhaarInput.text.trim() != expectedAadhar) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Aadhaar does not match customer'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final ok =
                          await paymentProvider.closePayment(transaction.id);
                      if (!mounted) return;
                      if (ok) {
                        Navigator.pop(context);
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
                            content: Text(paymentProvider.error ??
                                'Failed to close payment'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendCustomerOtp(BuildContext context, TransactionModel t) async {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final ok = await paymentProvider.sendCustomerCloseOtp(
      transactionId: t.id,
      ownerAadhar: _ownerAadharController.text.trim(),
    );
    if (!mounted) return;
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
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    final ok = await paymentProvider.verifyCustomerCloseOtp(
      transactionId: t.id,
      ownerAadhar: _ownerAadharController.text.trim(),
      otp: _otpController.text.trim(),
    );
    if (!mounted) return;
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
    _ownerAadharController.text = t.senderAadhar;
    _otpController.clear();
    setState(() {
      _otpSent = false;
      _selectedTransactionId = t.id;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Close as Customer',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter owner Aadhaar and verify OTP sent to owner to close this payment.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Owner Aadhaar',
                hint: 'Enter owner Aadhaar',
                controller: _ownerAadharController,
                validator: Validators.validateAadhar,
              ),
              const SizedBox(height: 12),
              if (_otpSent) ...[
                InputField(
                  label: 'OTP (sent to owner)',
                  hint: 'Enter 6-digit OTP',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ],
              const SizedBox(height: 16),
              Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        text: _otpSent ? 'Verify & Close' : 'Send OTP to Owner',
                        isLoading: _otpSent
                            ? paymentProvider.isLoading
                            : paymentProvider.isOtpSending,
                        onPressed: () async {
                          if (!_otpSent) {
                            final valid = Validators.validateAadhar(
                                  _ownerAadharController.text.trim(),
                                ) ==
                                null;
                            if (!valid) return;
                            await _sendCustomerOtp(context, t);
                          } else {
                            if (_otpController.text.trim().length != 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter valid 6-digit OTP'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            await _verifyCustomerOtp(context, t);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: paymentProvider.isOtpSending
                              ? null
                              : () => _sendCustomerOtp(context, t),
                          child: const Text('Resend OTP'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 24),
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
}
