/// Customer Close Screen
/// 
/// Clean and simple UI for closing transactions as customer
/// Uses Aadhaar OTP verification for owner

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/payment_provider.dart';
import '../../api/aadhar_api.dart';
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
  final _aadharApi = AadharApi();
  
  bool _otpSent = false;
  bool _isGeneratingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill owner Aadhaar from transaction
    _ownerAadharController.text = widget.transaction.senderAadhar;
  }

  @override
  void dispose() {
    _ownerAadharController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _generateAadharOtp() async {
    if (_isGeneratingOtp) return;

    final ownerAadhar = _ownerAadharController.text.trim();
    
    if (ownerAadhar.isEmpty) {
      _showError('Please enter owner Aadhaar number');
      return;
    }

    // Validate Aadhaar format
    final aadharError = Validators.validateAadhar(ownerAadhar);
    if (aadharError != null) {
      _showError(aadharError);
      return;
    }

    // Verify owner Aadhaar matches transaction
    if (ownerAadhar != widget.transaction.senderAadhar) {
      _showError('Owner Aadhaar does not match this transaction');
      return;
    }

    setState(() {
      _isGeneratingOtp = true;
    });

    try {
      // Use Aadhaar OTP API to generate OTP
      await _aadharApi.generateOtp(ownerAadhar);
      
      if (!mounted) return;
      
      setState(() {
        _isGeneratingOtp = false;
        _otpSent = true;
      });
      
      _otpController.clear();
      FocusScope.of(context).unfocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OTP sent to owner Aadhaar linked mobile number',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isGeneratingOtp = false;
      });
      
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _verifyOtpAndClose() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isVerifyingOtp) return;

    final ownerAadhar = _ownerAadharController.text.trim();
    final otp = _otpController.text.trim();

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      // Step 1: Verify Aadhaar OTP first
      await _aadharApi.verifyAadharOtp(ownerAadhar, otp);
      
      // Step 2: If OTP verified, close the transaction via backend
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final success = await paymentProvider.verifyCustomerCloseOtp(
        transactionId: widget.transaction.id,
        ownerAadhar: ownerAadhar,
        otp: otp,
      );

      if (!mounted) return;

      setState(() {
        _isVerifyingOtp = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Transaction closed successfully',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Wait a moment for user to see success message
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showError(paymentProvider.error ?? 'Failed to close transaction');
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isVerifyingOtp = false;
      });
      
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Close Transaction',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Transaction Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.payment,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transaction Amount',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${widget.transaction.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.transaction.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Step 1: Owner Aadhaar
                Text(
                  'Step 1: Enter Owner Aadhaar',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                InputField(
                  label: 'Owner Aadhaar Number',
                  hint: 'Enter 12-digit Aadhaar',
                  controller: _ownerAadharController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: Validators.validateAadhar,
                  enabled: !_otpSent,
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 24),
                // Generate OTP Button
                if (!_otpSent)
                  PrimaryButton(
                    text: 'Generate Aadhaar OTP',
                    onPressed: _isGeneratingOtp ? null : _generateAadharOtp,
                    isLoading: _isGeneratingOtp,
                  ),
                // Step 2: OTP Input (if OTP sent)
                if (_otpSent) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'OTP sent to owner Aadhaar linked mobile number',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Step 2: Enter OTP',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputField(
                    label: 'Aadhaar OTP',
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
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  // Verify & Close Button
                  Consumer<PaymentProvider>(
                    builder: (context, paymentProvider, _) {
                      return PrimaryButton(
                        text: 'Verify OTP & Close',
                        onPressed: (_isVerifyingOtp || paymentProvider.isLoading) ? null : _verifyOtpAndClose,
                        isLoading: _isVerifyingOtp || paymentProvider.isLoading,
                        backgroundColor: Colors.green[700],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Resend OTP
                  TextButton.icon(
                    onPressed: _isGeneratingOtp ? null : () {
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                      });
                      _generateAadharOtp();
                    },
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    label: Text(
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
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
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
}
