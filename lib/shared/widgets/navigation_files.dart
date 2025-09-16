import 'package:flutter/material.dart';

class NavigationHelper {
  // Navigate forward with fade
  static Future<T?> push<T extends Object?>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // Navigate back (default pop with fade reverse)
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  // Optional: pushReplacement with fade
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.pushReplacement<T, TO>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
