import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/search_provider.dart';
import 'chat/presentation/chat_provider_refactored.dart' show ChatProvider;
import 'screens/auth/login_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/payment/send_payment_screen.dart';
import 'screens/payment/close_payment_screen.dart';
import 'screens/payment/payment_success_screen.dart';
import 'screens/payment/payment_history_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/help/help_support_screen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handle background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  // Note: Can't use debugPrint in top-level function, but this is acceptable for background handler
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Set up background message handler BEFORE initializing Firebase
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize Firebase first (required for FCM)
    try {
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firebase initialization timed out');
        },
      );
    } catch (e) {
      // Firebase initialization failed - continue anyway
      // App will work without Firebase features
      debugPrint('[Main] Firebase initialization failed: $e');
    }
    
    // Initialize other services in parallel (non-blocking)
    Future.wait([
      // Pre-cache fonts for faster rendering
      GoogleFonts.pendingFonts([
        GoogleFonts.inter(),
      ]).catchError((e) {
        debugPrint('[Main] Font loading failed: $e');
      }),
      // Initialize notification service for download notifications
      NotificationService().initialize().catchError((e) {
        debugPrint('[Main] Notification service initialization failed: $e');
      }),
      // Initialize FCM service for push notifications (after Firebase)
      FcmService().initialize().catchError((e) {
        debugPrint('[Main] FCM service initialization failed: $e');
      }),
    ]).catchError((e) {
      debugPrint('[Main] Service initialization error: $e');
    });
    
    // Don't wait for non-critical services - start app immediately
  } catch (e) {
    // Critical error - log but continue
    debugPrint('[Main] Initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()), // Using refactored version
      ],
      child: MaterialApp(
        title: 'Finance Notes',
        debugShowCheckedModeBanner: false,
        // Optimize navigation with smooth transitions
        themeMode: ThemeMode.light,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue[700],
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[900],
            elevation: 0,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          // Optimize: Use page transitions for smooth navigation
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/chats': (context) => const ChatListScreen(),
          '/sendPayment': (context) => const SendPaymentScreen(),
          '/closePayment': (context) => const ClosePaymentScreen(),
          '/paymentSuccess': (context) => const PaymentSuccessScreen(),
          '/search': (context) => const SearchScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/paymentHistory': (context) => const PaymentHistoryScreen(),
          '/help': (context) => const HelpSupportScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Optimize: Run initialization in parallel for faster startup
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      
      // Start initialization with timeout to prevent hanging
      try {
        await authProvider.initialize().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('[Splash] Auth initialization timed out');
          },
        );
      } catch (e) {
        debugPrint('[Splash] Auth initialization error: $e');
        // Continue even if initialization fails
      }

      if (!mounted) return;
      
      String? token;
      try {
        token = await authProvider.loadToken().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('[Splash] Token loading timed out');
            return null;
          },
        );
      } catch (e) {
        debugPrint('[Splash] Error loading token: $e');
        token = null;
      }
      
      // Check if user is authenticated (has token and user data)
      if (token != null && token.isNotEmpty && authProvider.isAuthenticated) {
        final user = authProvider.user;
        // Load payment history in background (don't wait for it)
        if (user != null && user.aadhar.isNotEmpty) {
          paymentProvider.fetchHistory(user.aadhar).catchError((_) {
            // Silently fail - user can refresh later
            return false;
          });
        }
        // Navigate immediately - don't wait for payment history
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // No token or not authenticated, navigate to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('[Splash] Error in _checkAuth: $e');
      // If everything fails, navigate to login as fallback
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with smooth animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to icon if logo not found
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  Icons.payment,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // App name with fade-in
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      'Finance Notes',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                        letterSpacing: -0.5,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      'Secure Payment Management',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              // Optimized loader
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
