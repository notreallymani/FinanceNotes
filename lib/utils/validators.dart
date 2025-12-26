/// Validators
/// 
/// Single Responsibility: Input validation
/// Reusable validation functions

class Validators {
  /// Validate Aadhaar
  static String? validateAadhar(String? aadhar) {
    if (aadhar == null || aadhar.isEmpty) {
      return 'Aadhaar is required';
    }
    if (aadhar.length != 12) {
      return 'Aadhaar must be 12 digits';
    }
    if (!RegExp(r'^\d{12}$').hasMatch(aadhar)) {
      return 'Aadhaar must contain only digits';
    }
    return null;
  }

  /// Validate email
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate phone
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Optional
    }
    if (phone.length != 10) {
      return 'Phone must be 10 digits';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Phone must contain only digits';
    }
    return null;
  }

  /// Validate OTP
  static String? validateOtp(String? otp) {
    if (otp == null || otp.isEmpty) {
      return 'OTP is required';
    }
    if (otp.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'OTP must contain only digits';
    }
    return null;
  }

  /// Validate amount
  static String? validateAmount(double? amount) {
    if (amount == null) {
      return 'Amount is required';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (name.length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }
}
