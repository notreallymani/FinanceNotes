/// FCM Service
/// 
/// Single Responsibility: Handles Firebase Cloud Messaging (FCM) operations
/// Dependency Inversion: Can be extended for other notification types

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/profile_api.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ProfileApi _profileApi = ProfileApi();
  final NotificationService _notificationService = NotificationService();
  
  String? _currentToken;
  bool _initialized = false;

  String? get currentToken => _currentToken;
  bool get isInitialized => _initialized;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('[FCM] Permission status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get FCM token
        await _getToken();

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from a notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        _initialized = true;
        if (kDebugMode) {
          print('[FCM] Initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('[FCM] Permission denied');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Initialization error: $e');
      }
    }
  }

  /// Get FCM token and register it with backend
  Future<String?> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null && _currentToken!.isNotEmpty) {
        if (kDebugMode) {
          print('[FCM] Token obtained: ${_currentToken!.substring(0, 20)}...');
        }
        
        // Register token with backend
        await registerToken(_currentToken!);
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          if (kDebugMode) {
            print('[FCM] Token refreshed: ${newToken.substring(0, 20)}...');
          }
          _currentToken = newToken;
          registerToken(newToken);
        });
      }
      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error getting token: $e');
      }
      return null;
    }
  }

  /// Register FCM token with backend
  Future<void> registerToken(String token) async {
    try {
      await _profileApi.updateFcmToken(token);
      if (kDebugMode) {
        print('[FCM] Token registered with backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error registering token: $e');
      }
      // Don't throw - token registration failure shouldn't break the app
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM Foreground] Received message: ${message.messageId}');
      print('[FCM Foreground] Title: ${message.notification?.title}');
      print('[FCM Foreground] Body: ${message.notification?.body}');
      print('[FCM Foreground] Data: ${message.data}');
    }

    // Show local notification for foreground messages
    if (message.notification != null) {
      _notificationService.showChatNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
  }

  /// Handle notification tap (when app is opened from notification)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM] Notification tapped: ${message.messageId}');
      print('[FCM] Data: ${message.data}');
    }

    // Handle navigation based on message data
    if (message.data.containsKey('type') && message.data['type'] == 'chat_message') {
      final transactionId = message.data['transactionId'] as String?;
      if (transactionId != null) {
        // Navigate to chat screen - this will be handled by the app's navigation
        // We'll use a callback or event system for this
        if (kDebugMode) {
          print('[FCM] Should navigate to chat: $transactionId');
        }
      }
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      if (kDebugMode) {
        print('[FCM] Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error deleting token: $e');
      }
    }
  }
}

