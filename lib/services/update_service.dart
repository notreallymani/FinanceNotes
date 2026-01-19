/// Update Service
/// 
/// Single Responsibility: Handles app version checking and update prompts
/// Dependency Inversion: Can be extended for different update mechanisms

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:io';
import '../api/update_api.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final UpdateApi _updateApi = UpdateApi();
  PackageInfo? _packageInfo;
  bool _isChecking = false;

  /// Initialize the update service
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('[UpdateService] Failed to get package info: $e');
    }
  }

  /// Get current app version
  String get currentVersion => _packageInfo?.version ?? '1.0.0';
  String get currentBuildNumber => _packageInfo?.buildNumber ?? '0';

  /// Check for app updates
  /// Returns UpdateInfo if update is available, null otherwise
  Future<UpdateInfo?> checkForUpdate() async {
    if (_isChecking) return null;
    _isChecking = true;

    try {
      // Get version info from server
      final serverVersion = await _updateApi.checkVersion();
      
      if (serverVersion == null) {
        _isChecking = false;
        return null;
      }

      final currentVersionCode = int.tryParse(currentBuildNumber) ?? 0;
      final latestVersionCode = serverVersion['buildNumber'] as int? ?? 0;
      final latestVersion = serverVersion['version'] as String? ?? '1.0.0';
      final isForceUpdate = serverVersion['forceUpdate'] as bool? ?? false;
      final updateMessage = serverVersion['message'] as String? ?? 
          'A new version is available. Please update to continue.';

      // Check if update is needed
      if (latestVersionCode > currentVersionCode) {
        _isChecking = false;
        return UpdateInfo(
          isUpdateAvailable: true,
          latestVersion: latestVersion,
          latestBuildNumber: latestVersionCode,
          currentVersion: currentVersion,
          currentBuildNumber: currentVersionCode,
          isForceUpdate: isForceUpdate,
          updateMessage: updateMessage,
        );
      }

      _isChecking = false;
      return null;
    } catch (e) {
      debugPrint('[UpdateService] Error checking for update: $e');
      _isChecking = false;
      return null;
    }
  }

  /// Perform in-app update (Android only)
  Future<bool> performInAppUpdate() async {
    if (!Platform.isAndroid) {
      debugPrint('[UpdateService] In-app update only available on Android');
      return false;
    }

    try {
      final updateAvailability = await InAppUpdate.checkForUpdate();
      
      if (updateAvailability.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateAvailability.immediateUpdateAllowed) {
          // Immediate update (blocking)
          final result = await InAppUpdate.performImmediateUpdate();
          return result == AppUpdateResult.success;
        } else if (updateAvailability.flexibleUpdateAllowed) {
          // Flexible update (background)
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            await InAppUpdate.completeFlexibleUpdate();
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('[UpdateService] Error performing in-app update: $e');
      return false;
    }
  }

  /// Open app store for manual update
  Future<void> openAppStore() async {
    try {
      if (Platform.isAndroid) {
        // Open Google Play Store
        final packageName = _packageInfo?.packageName ?? 'com.financenotes';
        await InAppUpdate.openStoreListing(appStoreId: packageName);
      } else if (Platform.isIOS) {
        // For iOS, you would use url_launcher to open App Store
        // This requires the App Store URL
        debugPrint('[UpdateService] iOS App Store update not implemented');
      }
    } catch (e) {
      debugPrint('[UpdateService] Error opening app store: $e');
    }
  }
}

/// Update information model
class UpdateInfo {
  final bool isUpdateAvailable;
  final String latestVersion;
  final int latestBuildNumber;
  final String currentVersion;
  final int currentBuildNumber;
  final bool isForceUpdate;
  final String updateMessage;

  UpdateInfo({
    required this.isUpdateAvailable,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.isForceUpdate,
    required this.updateMessage,
  });

  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion+$currentBuildNumber, latest: $latestVersion+$latestBuildNumber, force: $isForceUpdate)';
  }
}
