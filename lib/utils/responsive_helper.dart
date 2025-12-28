/// Responsive Design Helper
/// 
/// Provides utilities for responsive design across different screen sizes
/// Helps maintain consistent UI/UX across various Android device sizes

import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if screen is small (phones in portrait)
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// Check if screen is medium (normal phones)
  static bool isMediumScreen(BuildContext context) {
    final width = screenWidth(context);
    return width >= 360 && width < 600;
  }

  /// Check if screen is large (tablets)
  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isLargeScreen(context)) {
      return const EdgeInsets.all(32.0);
    }
    return const EdgeInsets.all(24.0);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, {
    double small = 12,
    double medium = 14,
    double large = 16,
  }) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isLargeScreen(context)) {
      return large;
    }
    return medium;
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, {
    double small = 20,
    double medium = 24,
    double large = 28,
  }) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isLargeScreen(context)) {
      return large;
    }
    return medium;
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, {
    double small = 8,
    double medium = 12,
    double large = 16,
  }) {
    if (isSmallScreen(context)) {
      return small;
    } else if (isLargeScreen(context)) {
      return large;
    }
    return medium;
  }

  /// Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    if (isSmallScreen(context)) {
      return 44.0;
    } else if (isLargeScreen(context)) {
      return 56.0;
    }
    return 48.0;
  }

  /// Get responsive grid cross axis count
  static int getResponsiveGridCount(BuildContext context) {
    if (isSmallScreen(context)) {
      return 2;
    } else if (isLargeScreen(context)) {
      return 3;
    }
    return 2;
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get bottom padding considering keyboard
  static double getBottomPadding(BuildContext context, {double defaultPadding = 16}) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      return keyboardHeight + defaultPadding;
    }
    return defaultPadding;
  }
}

