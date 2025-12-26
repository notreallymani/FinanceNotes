/// OTP Verification Screen
/// 
/// Single Responsibility: OTP input and verification
/// Better UX: Full screen instead of bottom sheet

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../utils/validators.dart';
import '../../api/aadhar_api.dart';
import 'package:file_picker/file_picker.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String aadhar;
  final double amount;
  final String? mobile;
  final double? interest;
  final List<PlatformFile>? proofFiles;

  const OtpVerificationScreen({
    Key? key,
    required this.aadhar,
    required this.amount,
    this.mobile,
    this.interest,
    this.proofFiles,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final AadharApi _aadharApi = AadharApi();
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify OTP
      await _aadharApi.verifyAadharOtp(widget.aadhar, _otpController.text.trim());

      // Send payment
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final success = await paymentProvider.sendPayment(
        aadhar: widget.aadhar,
        amount: widget.amount,
        mobile: widget.mobile,
        interest: widget.interest,
        proofFiles: widget.proofFiles,
      );

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      if (success) {
        Navigator.pushReplacementNamed(
          context,
          '/paymentSuccess',
          arguments: paymentProvider.currentTransaction,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.error ?? 'Payment request failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
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
          'Verify OTP',
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
                const SizedBox(height: 40),
                // OTP Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sms_outlined,
                    size: 64,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Enter OTP',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  'Enter the 6-digit OTP sent to the customer\'s Aadhaar linked mobile number.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Transaction Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Summary',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      Text(
                        'Aadhaar: ${_maskAadhar(widget.aadhar)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // OTP Input
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
                const SizedBox(height: 32),
                // Verify Button
                Consumer<PaymentProvider>(
                  builder: (context, paymentProvider, _) {
                    final isLoading = _isVerifying || paymentProvider.isLoading;
                    return PrimaryButton(
                      text: 'Verify & Submit',
                      onPressed: isLoading ? null : _handleVerifyAndSubmit,
                      isLoading: isLoading,
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Resend OTP
                TextButton(
                  onPressed: _isVerifying
                      ? null
                      : () async {
                          try {
                            await _aadharApi.generateOtp(widget.aadhar);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP sent successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
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
            ),
          ),
        ),
      ),
    );
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} **** ${value.substring(8)}';
  }
}

