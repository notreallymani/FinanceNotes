import 'package:flutter/material.dart';

/// Optimized navigation helper with smooth transitions and route management

class NavigationHelper {
  /// Navigate with fade transition
  static Future<T?> fadeTo<T>(
    BuildContext context,
    Widget page, {
    bool fullscreenDialog = false,
  }) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  /// Navigate with slide transition
  static Future<T?> slideTo<T>(
    BuildContext context,
    Widget page, {
    AxisDirection direction = AxisDirection.right,
  }) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Replace current route with fade
  static Future<T?> fadeReplace<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.pushReplacement<T, T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Navigate and remove all previous routes
  static Future<T?> navigateAndClear<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
      (route) => false,
    );
  }

  /// Pop with result
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}

