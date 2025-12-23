# Flutter Payment App

A Flutter application for payment and transaction management with Aadhaar-based authentication.

## Project Structure

```
lib/
├── api/                    # API service classes
│   ├── auth_api.dart
│   ├── profile_api.dart
│   ├── payment_api.dart
│   └── aadhar_api.dart
├── models/                 # Data models
│   ├── user_model.dart
│   └── transaction_model.dart
├── providers/              # State management (Provider pattern)
│   ├── auth_provider.dart
│   ├── profile_provider.dart
│   ├── payment_provider.dart
│   └── search_provider.dart
├── screens/                # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── otp_screen.dart
│   ├── home/
│   │   └── dashboard_screen.dart
│   ├── payment/
│   │   ├── send_payment_screen.dart
│   │   ├── close_payment_screen.dart
│   │   ├── payment_success_screen.dart
│   │   └── payment_history_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/                # Reusable widgets
│   ├── primary_button.dart
│   ├── input_field.dart
│   └── loader.dart
├── utils/                  # Utilities
│   ├── env.dart
│   ├── app_constants.dart
│   └── validators.dart
└── main.dart               # App entry point
```

## Features

- **Authentication**: Login, Register, and OTP verification
- **Payment Management**: Send payment requests, close payments
- **Transaction Search**: Search transactions by Aadhaar number
- **Profile Management**: View and update user profile
- **Secure Storage**: JWT tokens stored securely using flutter_secure_storage

## Dependencies

- `dio`: HTTP client for API calls
- `provider`: State management
- `flutter_secure_storage`: Secure token storage
- `shared_preferences`: Local storage
- `intl`: Internationalization and date formatting
- `google_fonts`: Custom fonts
- `socket_io_client`: WebSocket support (for future chat feature)
- `url_launcher`: Launch external URLs (WhatsApp)

## Setup Instructions

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure API Base URL:**
   - Default: `http://10.0.2.2:5000` (for Android emulator)
   - For iOS simulator: `http://localhost:5000`
   - For production: Use `--dart-define` flag:
     ```bash
     flutter run --dart-define=API_BASE_URL=https://your-api-url.com
     ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## API Integration

The app expects a Node.js backend with the following endpoints:

### Authentication
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Register
- `POST /api/auth/verify-otp` - Verify OTP
- `POST /api/auth/logout` - Logout

### Profile
- `GET /api/profile` - Get user profile
- `PUT /api/profile` - Update profile

### Payment
- `POST /api/payment/send` - Send payment request
- `POST /api/payment/close` - Close payment
- `GET /api/payment/history` - Get payment history

### Aadhaar
- `POST /api/aadhar/generate-otp` - Generate OTP
- `POST /api/aadhar/verify-otp` - Verify Aadhaar OTP

All authenticated requests require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Features Overview

### Authentication Flow
1. User registers with name, phone, email, Aadhaar, and password
2. After registration, user is redirected to OTP screen
3. User enters OTP to verify Aadhaar
4. On successful verification, user is logged in and redirected to dashboard

### Payment Flow
1. **Send Payment**: Enter receiver Aadhaar, amount, and optional mobile number
2. **Close Payment**: Enter transaction ID to close a payment
3. **Search**: Search transactions by Aadhaar number

### Security
- JWT tokens stored securely using `flutter_secure_storage`
- Automatic token attachment to API requests via Dio interceptors
- Automatic retry for 500 errors
- Request/response logging for debugging

## Navigation Routes

- `/login` - Login screen
- `/register` - Registration screen
- `/otp` - OTP verification screen
- `/dashboard` - Main dashboard
- `/sendPayment` - Send payment request
- `/closePayment` - Close payment
- `/paymentSuccess` - Payment success confirmation
- `/search` - Search transactions
- `/profile` - User profile

## Theme

The app uses Google Fonts (Inter) and Material Design 3 with a modern, minimal UI.

## Notes

- The app includes a splash screen that checks for existing authentication tokens
- All API calls include error handling and loading states
- Form validation is implemented for all input fields
- WhatsApp integration for payment closure notifications (if mobile number is available)

