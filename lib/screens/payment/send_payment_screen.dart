import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../api/aadhar_api.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../utils/validators.dart';

class SendPaymentScreen extends StatefulWidget {
  const SendPaymentScreen({Key? key}) : super(key: key);

  @override
  State<SendPaymentScreen> createState() => _SendPaymentScreenState();
}

class _SendPaymentScreenState extends State<SendPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  final _amountController = TextEditingController();
  final _mobileController = TextEditingController();
  final _interestController = TextEditingController();
  final _otpController = TextEditingController();
  final AadharApi _aadharApi = AadharApi();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  List<PlatformFile> _proofFiles = [];

  @override
  void dispose() {
    _aadharController.dispose();
    _amountController.dispose();
    _mobileController.dispose();
    _interestController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _pickProofFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null) {
      setState(() {
        _proofFiles = result.files;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      final file = File(photo.path);
      final fileName = p.basename(photo.path);
      setState(() {
        _proofFiles.add(
          PlatformFile(
            name: fileName,
            path: photo.path,
            size: file.lengthSync(),
          ),
        );
      });
    }
  }

  Future<void> _handleSendPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final aadhar = _aadharController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSendingOtp = true;
    });

    try {
      await _aadharApi.generateOtp(aadhar);
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
      });
      _otpController.clear();
      _showOtpBottomSheet(
        aadhar: aadhar,
        amount: amount,
        mobile: _mobileController.text.trim().isNotEmpty
            ? _mobileController.text.trim()
            : null,
        interest: _interestController.text.trim().isNotEmpty
            ? double.tryParse(_interestController.text.trim())
            : null,
      );
    } catch (e) {
      setState(() {
        _isSendingOtp = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOtpBottomSheet({
    required String aadhar,
    required double amount,
    String? mobile,
    double? interest,
  }) {
    showModalBottomSheet(
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
                'Verify OTP',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit OTP sent to the customer’s Aadhaar linked mobile number.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              InputField(
                label: 'OTP',
                hint: 'Enter 6-digit OTP',
                controller: _otpController,
                validator: Validators.validateOtp,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  final isLoading =
                      _isVerifyingOtp || paymentProvider.isLoading;
                  return PrimaryButton(
                    text: 'Verify & Submit',
                    onPressed: isLoading
                        ? null
                        : () => _verifyOtpAndSubmit(
                              aadhar: aadhar,
                              amount: amount,
                              mobile: mobile,
                              interest: interest,
                            ),
                    isLoading: isLoading,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyOtpAndSubmit({
    required String aadhar,
    required double amount,
    String? mobile,
    double? interest,
  }) async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      await _aadharApi.verifyAadharOtp(aadhar, otp);
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final success = await paymentProvider.sendPayment(
        aadhar: aadhar,
        amount: amount,
        mobile: mobile,
        interest: interest,
        proofFiles: _proofFiles,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(); // Close OTP sheet
        Navigator.pushReplacementNamed(
          context,
          '/paymentSuccess',
          arguments: paymentProvider.currentTransaction,
        );
        _otpController.clear();
        _proofFiles = [];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.error ?? 'Payment request failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  Widget _buildProofFilesList() {
    if (_proofFiles.isEmpty) {
      return Text(
        'No documents selected',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _proofFiles
          .map(
            (file) => Chip(
              label: Text(
                file.name,
                overflow: TextOverflow.ellipsis,
              ),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  _proofFiles.remove(file);
                });
              },
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Send Payment Request',
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
                InputField(
                  label: 'Receiver Aadhaar Number',
                  hint: 'Enter 12-digit Aadhaar',
                  controller: _aadharController,
                  validator: Validators.validateAadhar,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                ),
                const SizedBox(height: 20),
                InputField(
                  label: 'Amount',
                  hint: 'Enter amount',
                  controller: _amountController,
                  validator: Validators.validateAmount,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                InputField(
                  label: 'Mobile Number (Optional)',
                  hint: 'Enter mobile number',
                  controller: _mobileController,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return Validators.validatePhone(value);
                    }
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 20),
                InputField(
                  label: 'Interest (Optional)',
                  hint: 'Enter interest amount / percentage',
                  controller: _interestController,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final interest = double.tryParse(value);
                      if (interest == null) {
                        return 'Enter a valid number';
                      }
                    }
                    return null;
                  },
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                Text(
                  'Proof Documents / Media',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickProofFiles,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Files'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _capturePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProofFilesList(),
                const SizedBox(height: 32),
                Consumer<PaymentProvider>(
                  builder: (context, paymentProvider, _) {
                    final isLoading =
                        paymentProvider.isLoading || _isSendingOtp;
                    return PrimaryButton(
                      text: 'Send Payment Request',
                      onPressed: isLoading ? null : _handleSendPayment,
                      isLoading: isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

