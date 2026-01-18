import 'dart:async';
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
import '../../api/profile_api.dart';

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
  final ProfileApi _profileApi = ProfileApi();
  Timer? _aadharCheckTimer;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isInitialized = false;
  bool _otpSent = false;
  String? _pendingAadhar;
  bool? _isAadharAvailable; // null = not checked, true = available, false = duplicate
  bool _isCheckingAadhar = false;
  String? _aadharCheckMessage;

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

  void _populateFields(dynamic user) {
    _nameController.text = user.name ?? '';
    _emailController.text = user.email ?? '';
    _mobileController.text = user.phone ?? '';
    _aadharController.text = user.aadhar ?? '';
  }

  @override
  void dispose() {
    _aadharCheckTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _aadharController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Check if Aadhaar is available (debounced)
  void _checkAadharAvailability(String aadhar) {
    // Cancel previous timer
    _aadharCheckTimer?.cancel();

    // Reset state if empty
    if (aadhar.trim().isEmpty || aadhar.trim().length != 12) {
      setState(() {
        _isAadharAvailable = null;
        _aadharCheckMessage = null;
        _isCheckingAadhar = false;
      });
      return;
    }

    // Validate format first
    final aadharError = Validators.validateAadhar(aadhar);
    if (aadharError != null) {
      setState(() {
        _isAadharAvailable = null;
        _aadharCheckMessage = aadharError;
        _isCheckingAadhar = false;
      });
      return;
    }

    // Check if it's the current user's Aadhaar
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserAadhar = authProvider.user?.aadhar ?? '';
    if (aadhar.trim() == currentUserAadhar) {
      setState(() {
        _isAadharAvailable = true;
        _aadharCheckMessage = 'This is your current Aadhaar';
        _isCheckingAadhar = false;
      });
      return;
    }

    // Show checking state
    setState(() {
      _isCheckingAadhar = true;
      _isAadharAvailable = null;
      _aadharCheckMessage = 'Checking availability...';
    });

    // Debounce: wait 800ms after user stops typing
    _aadharCheckTimer = Timer(const Duration(milliseconds: 800), () async {
      try {
        final result = await _profileApi.checkAadhar(aadhar);
        if (!mounted) return;
        
        setState(() {
          _isCheckingAadhar = false;
          _isAadharAvailable = result['available'] as bool? ?? false;
          _aadharCheckMessage = result['message'] as String?;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCheckingAadhar = false;
          _isAadharAvailable = null;
          _aadharCheckMessage = 'Unable to verify. Please try again.';
        });
      }
    });
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

    // If Aadhaar is new or not verified, show message to use Get OTP button
    if (!isAadharVerified && enteredAadhar != currentAadhar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use "Get OTP" button to verify Aadhaar first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If Aadhaar is already verified and unchanged, just update profile
    await _updateProfile(
      aadhar: currentAadhar,
    );
  }

  Future<void> _updateProfile({String? aadhar}) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // Ensure we have a valid token before updating
    final token = await authProvider.loadToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _mobileController.text.trim(),
      email: user?.email,
      aadhar: aadhar ?? user?.aadhar,
    );

    if (!mounted) return;

    if (success) {
      // Refresh user data from auth provider
      await authProvider.fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg = profileProvider.error ?? 'Failed to update profile';
      if (errorMsg.contains('401') || errorMsg.contains('Unauthorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendOtp() async {
    // Prevent multiple clicks
    if (_isSendingOtp) {
      return;
    }

    final aadhar = _aadharController.text.trim();
    
    if (aadhar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Aadhaar number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate Aadhaar format
    final aadharError = Validators.validateAadhar(aadhar);
    if (aadharError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aadharError),
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
        _otpSent = true;
        _pendingAadhar = aadhar;
      });
      _otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully to your Aadhaar linked mobile number'),
          backgroundColor: Colors.green,
        ),
      );
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


  Future<void> _verifyOtpAndSave() async {
    // Prevent multiple clicks
    if (_isVerifyingOtp) {
      return;
    }

    if (_pendingAadhar == null) {
      return;
    }

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
      await _aadharApi.verifyAadharOtp(_pendingAadhar!, otp);
      if (!mounted) return;

      // Automatically save profile after successful verification
      await _updateProfile(aadhar: _pendingAadhar);
      
      // Reset OTP state
      setState(() {
        _isVerifyingOtp = false;
        _otpSent = false;
        _pendingAadhar = null;
      });
      _otpController.clear();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aadhaar verified and profile saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isVerifyingOtp = false;
      });
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputField(
                      label: 'Aadhaar Number',
                      hint: 'Enter your Aadhaar number',
                      controller: _aadharController,
                      validator: Validators.validateAadhar,
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      enabled: !isAadharVerified && !_otpSent,
                      suffixIcon: _buildAadharStatusIcon(),
                      onChanged: (value) {
                        // Reset OTP state if user changes Aadhaar number
                        if (_otpSent && value.trim() != _pendingAadhar) {
                          setState(() {
                            _otpSent = false;
                            _pendingAadhar = null;
                            _otpController.clear();
                          });
                        }
                        // Check availability with debounce
                        if (!isAadharVerified && value.trim().length == 12) {
                          _checkAadharAvailability(value.trim());
                        } else if (value.trim().length != 12) {
                          setState(() {
                            _isAadharAvailable = null;
                            _aadharCheckMessage = null;
                            _isCheckingAadhar = false;
                          });
                        }
                      },
                    ),
                    // Show validation status message
                    if (_aadharCheckMessage != null && !isAadharVerified && !_otpSent)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                        child: Row(
                          children: [
                            if (_isCheckingAadhar)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[600]!,
                                  ),
                                ),
                              )
                            else if (_isAadharAvailable == true)
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green[600],
                              )
                            else if (_isAadharAvailable == false)
                              Icon(
                                Icons.error,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _aadharCheckMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _isAadharAvailable == false
                                      ? Colors.orange[700]
                                      : _isAadharAvailable == true
                                          ? Colors.green[600]
                                          : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (!isAadharVerified) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isSendingOtp || _isVerifyingOtp) ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isSendingOtp || _isVerifyingOtp)
                            ? Colors.grey[400]
                            : Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Get OTP',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
                if (_otpSent && !isAadharVerified) ...[
                  const SizedBox(height: 20),
                  InputField(
                    label: 'Enter OTP',
                    hint: 'Enter 6-digit OTP',
                    controller: _otpController,
                    validator: Validators.validateOtp,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isVerifyingOtp ? null : _verifyOtpAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifyingOtp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Verify OTP & Save',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
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

  /// Build status icon for Aadhaar field
  Widget? _buildAadharStatusIcon() {
    if (_isCheckingAadhar) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ),
      );
    } else if (_isAadharAvailable == true) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          Icons.check_circle,
          color: Colors.green[600],
          size: 24,
        ),
      );
    } else if (_isAadharAvailable == false) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          Icons.error,
          color: Colors.orange[700],
          size: 24,
        ),
      );
    }
    return null;
  }
}

