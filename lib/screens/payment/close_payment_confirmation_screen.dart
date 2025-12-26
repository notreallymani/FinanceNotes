/// Close Payment Confirmation Screen
/// 
/// Single Responsibility: Confirm and close payment transaction
/// Better UX: Full screen instead of dialog/bottom sheet

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../utils/validators.dart';

class ClosePaymentConfirmationScreen extends StatefulWidget {
  final TransactionModel transaction;

  const ClosePaymentConfirmationScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<ClosePaymentConfirmationScreen> createState() =>
      _ClosePaymentConfirmationScreenState();
}

class _ClosePaymentConfirmationScreenState
    extends State<ClosePaymentConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  bool _hasConfirmed = false;

  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _handleClosePayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate Aadhaar matches
    if (_aadharController.text.trim() != widget.transaction.receiverAadhar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aadhaar does not match customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _hasConfirmed = true;
    });

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final success = await paymentProvider.closePayment(widget.transaction.id);

    if (!mounted) return;

    setState(() {
      _hasConfirmed = false;
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
          content: Text(paymentProvider.error ?? 'Failed to close payment'),
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
          'Close Payment',
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
                // Warning Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Close Payment Transaction',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Warning Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Important Reminder',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This action cannot be reverted. Once you close this transaction, it will be marked as closed permanently.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Transaction Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Transaction ID', widget.transaction.id),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Amount',
                        '₹${widget.transaction.amount.toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Customer Aadhaar',
                        _maskAadhar(widget.transaction.receiverAadhar),
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Status',
                        widget.transaction.status.toUpperCase(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Aadhaar Confirmation
                Text(
                  'Confirm Customer Aadhaar',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the customer\'s Aadhaar number to confirm closing this payment.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                InputField(
                  label: 'Customer Aadhaar',
                  hint: 'Enter 12-digit Aadhaar',
                  controller: _aadharController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: Validators.validateAadhar,
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Consumer<PaymentProvider>(
                  builder: (context, paymentProvider, _) {
                    return PrimaryButton(
                      text: 'Close Payment',
                      onPressed: _hasConfirmed || paymentProvider.isLoading
                          ? null
                          : _handleClosePayment,
                      isLoading: _hasConfirmed || paymentProvider.isLoading,
                      backgroundColor: Colors.orange[700],
                    );
                  },
                ),
                const SizedBox(height: 12),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} **** ${value.substring(8)}';
  }
}

