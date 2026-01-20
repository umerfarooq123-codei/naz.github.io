import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standardized snackbars for the application
/// Provides three types: error, warning, and success
/// All snackbars include a close button for manual dismissal
class AppSnackBars {
  static const Duration _defaultDuration = Duration(seconds: 4);
  static const EdgeInsets _defaultMargin = EdgeInsets.all(16);
  static const double _borderRadius = 8;

  /// Show error snackbar
  ///
  /// Example:
  /// ```dart
  /// AppSnackBars.showError('Error', 'Something went wrong');
  /// ```
  static void showError(
    String title,
    String message, {
    Duration duration = _defaultDuration,
    VoidCallback? onClose,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: duration,
      margin: _defaultMargin,
      borderRadius: _borderRadius,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      shouldIconPulse: false,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          onClose?.call();
        },
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
      dismissDirection: DismissDirection.endToStart,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }

  /// Show warning snackbar
  ///
  /// Example:
  /// ```dart
  /// AppSnackBars.showWarning('Warning', 'Please review this');
  /// ```
  static void showWarning(
    String title,
    String message, {
    Duration duration = _defaultDuration,
    VoidCallback? onClose,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: duration,
      margin: _defaultMargin,
      borderRadius: _borderRadius,
      icon: const Icon(Icons.warning_amber, color: Colors.white),
      shouldIconPulse: false,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          onClose?.call();
        },
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
      dismissDirection: DismissDirection.endToStart,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }

  /// Show success snackbar
  ///
  /// Example:
  /// ```dart
  /// AppSnackBars.showSuccess('Success', 'Operation completed');
  /// ```
  static void showSuccess(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onClose,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: duration,
      margin: _defaultMargin,
      borderRadius: _borderRadius,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      shouldIconPulse: false,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          onClose?.call();
        },
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
      dismissDirection: DismissDirection.endToStart,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }

  /// Show info snackbar (alternative to warning)
  ///
  /// Example:
  /// ```dart
  /// AppSnackBars.showInfo('Info', 'Did you know?');
  /// ```
  static void showInfo(
    String title,
    String message, {
    Duration duration = _defaultDuration,
    VoidCallback? onClose,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: duration,
      margin: _defaultMargin,
      borderRadius: _borderRadius,
      icon: const Icon(Icons.info_outline, color: Colors.white),
      shouldIconPulse: false,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          onClose?.call();
        },
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
      dismissDirection: DismissDirection.endToStart,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }

  /// Close current snackbar if any is showing
  static void close() {
    if (Get.isSnackbarOpen) {
      Get.back();
    }
  }
}
