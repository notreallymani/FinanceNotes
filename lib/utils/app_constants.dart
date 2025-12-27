class AppConstants {
  // API Endpoints
  static const String verifyOtpEndpoint = '/api/auth/verify-otp';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String googleAuthEndpoint = '/api/auth/google';
  static const String emailRegisterEndpoint = '/api/auth/email-register';
  static const String emailLoginEndpoint = '/api/auth/email-login';
  static const String forgotPasswordEndpoint = '/api/auth/forgot-password';
  static const String profileEndpoint = '/api/profile';
  static const String sendPaymentEndpoint = '/api/payment/send';
  static const String closePaymentEndpoint = '/api/payment/close';
  static const String paymentHistoryEndpoint = '/api/payment/history';
  static const String generateOtpEndpoint = '/api/aadhar/generate-otp';
  static const String verifyAadharOtpEndpoint = '/api/aadhar/verify-otp';
  static const String chatMessagesEndpoint = '/api/chat/transaction';
  static const String sendChatMessageEndpoint = '/api/chat/send';
  static const String chatListEndpoint = '/api/chat/list';
  static const String unreadCountEndpoint = '/api/chat/unread-count';
  static const String customerCloseSendOtpEndpoint = '/api/payment/customer-close/send-otp';
  static const String customerCloseVerifyOtpEndpoint = '/api/payment/customer-close/verify';
  static const String documentDownloadUrlEndpoint = '/api/payment/document-download-url';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // App Constants
  static const int otpLength = 6;
  static const int aadharLength = 12;
}
