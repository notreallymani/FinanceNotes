/// Notification Service
/// 
/// Single Responsibility: Handles local notifications for downloads
/// Dependency Inversion: Can be extended for other notification types

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // Store file paths for notification actions
  final Map<int, String> _downloadFilePaths = {};

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _onNotificationTapped(response);
      },
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    _initialized = true;
  }

  /// Handle notification tap - opens file if it's a download completion
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (kDebugMode) {
      print('Notification tapped: ${response.id}, payload: ${response.payload}');
    }
    
    // Check if this is a download completion notification with file path
    final filePath = response.payload;
    if (filePath != null && filePath.isNotEmpty) {
      try {
        // Open the downloaded file
        final result = await OpenFile.open(filePath);
        if (kDebugMode) {
          print('File open result: ${result.message}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error opening file: $e');
        }
      }
    }
  }

  /// Show download started notification
  Future<void> showDownloadStarted(String filename, int notificationId) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'downloads',
      'Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: 0,
      ongoing: true,
      onlyAlertOnce: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      'Downloading',
      filename,
      details,
    );
  }

  /// Show download progress notification
  Future<void> showDownloadProgress(
    String filename,
    int notificationId,
    int progress,
  ) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'downloads',
      'Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      onlyAlertOnce: true,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      'Downloading',
      '$filename ($progress%)',
      details,
    );
  }

  /// Show download completed notification with action buttons
  Future<void> showDownloadCompleted(
    String filename,
    String filePath,
    int notificationId,
  ) async {
    if (!_initialized) await initialize();

    // Store file path for notification tap handler
    _downloadFilePaths[notificationId] = filePath;

    // Create action buttons for Android
    const openAction = AndroidNotificationAction(
      'open',
      'Open',
      showsUserInterface: false,
    );

    const shareAction = AndroidNotificationAction(
      'share',
      'Share',
      showsUserInterface: false,
    );

    final androidDetails = AndroidNotificationDetails(
      'downloads',
      'Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      actions: [openAction, shareAction],
      // Set payload to file path for tap handler
    );

    // iOS notification details with actions
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification with file path as payload
    await _notifications.show(
      notificationId,
      'Download Complete',
      'Downloaded: $filename',
      details,
      payload: filePath, // Pass file path as payload for tap handling
    );
  }

  /// Handle notification action button press
  Future<void> handleNotificationAction(
    int notificationId,
    String actionId,
    String? filePath,
  ) async {
    final path = filePath ?? _downloadFilePaths[notificationId];
    if (path == null) return;

    try {
      if (actionId == 'open') {
        // Open file
        await OpenFile.open(path);
      } else if (actionId == 'share') {
        // Share file - will be handled by document service
        // This requires platform channels, so we'll add it there
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification action: $e');
      }
    }
  }

  /// Clear stored file path when notification is dismissed
  void clearFilePath(int notificationId) {
    _downloadFilePaths.remove(notificationId);
  }

  /// Show download failed notification
  Future<void> showDownloadFailed(
    String filename,
    String error,
    int notificationId,
  ) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'downloads',
      'Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      'Download Failed',
      '$filename\n$error',
      details,
    );
  }

  /// Cancel notification and clear stored file path
  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
    clearFilePath(notificationId);
  }
}

