/// Customer Close Screen
/// 
/// Single Responsibility: Customer close payment flow
/// Better UX: Full screen instead of bottom sheet

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../utils/validators.dart';

class CustomerCloseScreen extends StatefulWidget {
  final TransactionModel transaction;

  const CustomerCloseScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<CustomerCloseScreen> createState() => _CustomerCloseScreenState();
}

class _CustomerCloseScreenState extends State<CustomerCloseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerAadharController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void initState() {
    super.initState();
    _ownerAadharController.text = widget.transaction.senderAadhar;
  }

  @override
  void dispose() {
    _ownerAadharController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    if (_ownerAadharController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter owner Aadhaar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final success = await paymentProvider.sendCustomerCloseOtp(
      transactionId: widget.transaction.id,
      ownerAadhar: _ownerAadharController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
    });

    if (success) {
      setState(() {
        _otpSent = true;
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

  Future<void> _verifyAndClose() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isVerifyingOtp) return;

    setState(() {
      _isVerifyingOtp = true;
    });

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final success = await paymentProvider.verifyCustomerCloseOtp(
      transactionId: widget.transaction.id,
      ownerAadhar: _ownerAadharController.text.trim(),
      otp: _otpController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isVerifyingOtp = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment closed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.error ?? 'Failed to verify OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Close as Customer',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Transaction Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Transaction Details',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Amount', '₹${widget.transaction.amount.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Status', widget.transaction.status.toUpperCase()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Owner Aadhaar
                InputField(
                  label: 'Owner Aadhaar',
                  hint: 'Enter owner Aadhaar',
                  controller: _ownerAadharController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: Validators.validateAadhar,
                  enabled: !_otpSent,
                ),
                const SizedBox(height: 24),
                // Send OTP Button (if not sent)
                if (!_otpSent)
                  Consumer<PaymentProvider>(
                    builder: (context, paymentProvider, _) {
                      return PrimaryButton(
                        text: 'Send OTP to Owner',
                        onPressed: _isSendingOtp || paymentProvider.isOtpSending
                            ? null
                            : _sendOtp,
                        isLoading: _isSendingOtp || paymentProvider.isOtpSending,
                      );
                    },
                  ),
                // OTP Input (if sent)
                if (_otpSent) ...[
                  InputField(
                    label: 'OTP',
                    hint: 'Enter 6-digit OTP',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: Validators.validateOtp,
                    prefixIcon: Icons.lock_outline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Verify Button
                  Consumer<PaymentProvider>(
                    builder: (context, paymentProvider, _) {
                      return PrimaryButton(
                        text: 'Verify & Close',
                        onPressed: _isVerifyingOtp || paymentProvider.isLoading
                            ? null
                            : _verifyAndClose,
                        isLoading: _isVerifyingOtp || paymentProvider.isLoading,
                        backgroundColor: Colors.green[700],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Resend OTP
                  TextButton(
                    onPressed: _isSendingOtp
                        ? null
                        : _sendOtp,
                    child: Text(
                      'Resend OTP',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Cancel Button
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }
}

