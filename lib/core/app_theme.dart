import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF0A60FF),
        secondary: const Color(0xFF00BFA6),
      ),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF7ABAFE),
        secondary: const Color(0xFF00BFA6),
      ),
    );
  }
}
