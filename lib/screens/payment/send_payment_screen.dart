import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../api/aadhar_api.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../utils/validators.dart';
import '../profile/profile_screen.dart';
import 'otp_verification_screen.dart';

class SendPaymentScreen extends StatefulWidget {
  const SendPaymentScreen({super.key});

  @override
  State<SendPaymentScreen> createState() => _SendPaymentScreenState();
}

class _SendPaymentScreenState extends State<SendPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _aadharController = TextEditingController();
  final _amountController = TextEditingController();
  final _mobileController = TextEditingController();
  final _interestController = TextEditingController();
  final _otpController = TextEditingController();
  final AadharApi _aadharApi = AadharApi();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSendingOtp = false;
  bool _isOtpBottomSheetShowing = false;
  List<PlatformFile> _proofFiles = [];
  bool? _isProfileAadharVerified; // null = not checked yet, true/false = cached result

  @override
  void initState() {
    super.initState();
    _checkProfileVerificationOnce();
  }

  Future<void> _checkProfileVerificationOnce() async {
    // Check only once - use cached user data first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cachedUser = authProvider.user;
    
    // If user is already verified in cache, use that (no API call)
    if (cachedUser?.aadharVerified == true) {
      if (mounted) {
        setState(() {
          _isProfileAadharVerified = true;
        });
      }
      return;
    }
    
    // Only fetch from backend if not verified in cache (one-time check)
    final updatedUser = await authProvider.fetchProfile();
    if (mounted) {
      setState(() {
        _isProfileAadharVerified = updatedUser?.aadharVerified ?? 
                                   authProvider.user?.aadharVerified ?? 
                                   false;
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
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
      final fileName = photo.name.isNotEmpty ? photo.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
    // Prevent multiple clicks
    if (_isSendingOtp || _isOtpBottomSheetShowing) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Check profile Aadhaar verification - show error if not verified
    if (_isProfileAadharVerified == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your Aadhaar number in Profile before sending payment requests.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

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
      
      // Prevent showing multiple bottom sheets
      if (!_isOtpBottomSheetShowing) {
        _isOtpBottomSheetShowing = true;
        _showOtpBottomSheet(
          aadhar: aadhar,
          amount: amount,
          customerName: _customerNameController.text.trim(),
          mobile: _mobileController.text.trim().isNotEmpty
              ? _mobileController.text.trim()
              : null,
          interest: _interestController.text.trim().isNotEmpty
              ? double.tryParse(_interestController.text.trim())
              : null,
        );
      }
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
    required String customerName,
    String? mobile,
    double? interest,
  }) {
    // Navigate to OTP verification screen instead of bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          aadhar: aadhar,
          amount: amount,
          customerName: customerName,
          mobile: mobile,
          interest: interest,
          proofFiles: _proofFiles,
        ),
      ),
    );
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
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                InputField(
                  label: 'Customer Name',
                  hint: 'Enter customer name',
                  controller: _customerNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Customer name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Invalid amount';
                    }
                    return Validators.validateAmount(amount);
                  },
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
                // Profile Aadhaar Verification Warning Banner
                if (_isProfileAadharVerified == false)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Profile Aadhaar Not Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'To enable "Send Payment Request" button, please verify your Aadhaar number in Profile first.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.orange[800],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                              // Refresh verification status when returning from profile
                              if (mounted) {
                                _checkProfileVerificationOnce();
                              }
                            },
                            icon: const Icon(Icons.person, size: 18),
                            label: const Text('Go to Profile & Verify'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Consumer<PaymentProvider>(
                  builder: (context, paymentProvider, _) {
                    final isLoading =
                        paymentProvider.isLoading || _isSendingOtp;
                    // Disable button if profile Aadhaar is not verified
                    final isButtonDisabled = isLoading || _isProfileAadharVerified == false;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryButton(
                          text: 'Send Payment Request',
                          onPressed: isButtonDisabled ? null : _handleSendPayment,
                          isLoading: isLoading,
                        ),
                        if (isButtonDisabled && !isLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Button disabled: Profile Aadhaar verification required',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
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

