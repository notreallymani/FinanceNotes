import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/loader.dart';
import '../../utils/validators.dart';
import '../../api/aadhar_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _aadharController;
  late TextEditingController _otpController;
  final AadharApi _aadharApi = AadharApi();
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _aadharController = TextEditingController();
    _otpController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    // Try to get user from auth provider first
    if (authProvider.user != null) {
      _populateFields(authProvider.user!);
      setState(() {
        _isInitialized = true;
      });
    } else {
      // Fetch from API
      await profileProvider.fetchProfile();
      if (profileProvider.user != null) {
        _populateFields(profileProvider.user!);
      }
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _populateFields(user) {
    _nameController.text = user.name ?? '';
    _emailController.text = user.email ?? '';
    _mobileController.text = user.phone ?? '';
    _aadharController.text = user.aadhar ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _aadharController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final isAadharVerified = user?.aadharVerified ?? false;
    final currentAadhar = user?.aadhar ?? '';
    final enteredAadhar = _aadharController.text.trim();

    // If Aadhaar is already verified and not changed, just update name/phone.
    if (isAadharVerified && enteredAadhar == currentAadhar) {
      await _updateProfile(
        aadhar: currentAadhar,
      );
      return;
    }

    // If Aadhaar is new or not verified, run Aadhaar OTP verification first.
    await _startAadharOtpFlow(enteredAadhar: enteredAadhar);
  }

  Future<void> _updateProfile({String? aadhar}) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final success = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _mobileController.text.trim(),
      email: user?.email,
      aadhar: aadhar ?? user?.aadhar,
    );

    if (!mounted) return;

    if (success) {
      await authProvider.fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.error ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startAadharOtpFlow({required String enteredAadhar}) async {
    if (enteredAadhar.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSendingOtp = true;
    });

    try {
      await _aadharApi.generateOtp(enteredAadhar);
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
      });
      _otpController.clear();
      _showAadharOtpBottomSheet(aadhar: enteredAadhar);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAadharOtpBottomSheet({required String aadhar}) {
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
                'Verify Aadhaar OTP',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit OTP sent to your Aadhaar linked mobile number.',
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
              PrimaryButton(
                text: 'Verify & Save',
                onPressed: _isVerifyingOtp
                    ? null
                    : () => _verifyAadharOtpAndSave(aadhar: aadhar),
                isLoading: _isVerifyingOtp,
              ),
              if (_isVerifyingOtp) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verifying OTP...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyAadharOtpAndSave({required String aadhar}) async {
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
      if (!mounted) return;

      Navigator.of(context).pop();
      await _updateProfile(aadhar: aadhar);
      _otpController.clear();
    } catch (e) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Loader(message: 'Loading profile...'),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAadharVerified = authProvider.user?.aadharVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
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
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isAadharVerified
                        ? Colors.green.withOpacity(0.08)
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isAadharVerified
                              ? Colors.green
                              : Colors.orange)
                          .withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isAadharVerified
                            ? Icons.verified_outlined
                            : Icons.error_outline,
                        size: 20,
                        color: isAadharVerified
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAadharVerified
                                  ? 'Aadhaar verified'
                                  : 'Aadhaar not verified',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAadharVerified
                                  ? 'Linked Aadhaar: ${_maskAadhar(_aadharController.text)}'
                                  : 'Please complete Aadhaar OTP verification to create payment requests.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                InputField(
                  label: 'Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 20),
                InputField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                ),
                const SizedBox(height: 20),
                InputField(
                  label: 'Mobile Number',
                  hint: 'Enter your mobile number',
                  controller: _mobileController,
                  validator: Validators.validatePhone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 20),
                InputField(
                  label: 'Aadhaar Number',
                  hint: 'Enter your Aadhaar number',
                  controller: _aadharController,
                  validator: Validators.validateAadhar,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  enabled: !isAadharVerified,
                ),
                const SizedBox(height: 32),
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, _) {
                    return PrimaryButton(
                      text: 'Save Changes',
                      onPressed: _handleUpdateProfile,
                      isLoading: profileProvider.isLoading,
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

  String _maskAadhar(String value) {
    final v = value.replaceAll(' ', '');
    if (v.length != 12) return value;
    return '${v.substring(0, 4)} **** ${v.substring(8)}';
  }
}

