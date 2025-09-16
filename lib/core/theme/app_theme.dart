import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextSizes {
  static const double heading = 24.0;
  static const double subheading = 18.0;
  static const double body = 14.0;
  static const double caption = 12.0;
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2), // Vibrant blue for primary actions
      secondary: Color(0xFF388E3C), // Forest green for secondary
      surface: Color(0xFFFFFFFF), // White surface for cards
      onSurface: Color(0xFF1A1A1A), // Dark gray for text/icons
      primaryContainer: Color(0xFFE8F0FE), // Light blue for backgrounds
      onPrimaryContainer: Color(0xFF1A1A1A), // Dark text on containers
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Light gray background
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFFFF), // White cards
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFFE8F0FE),
      foregroundColor: Color(0xFF1A1A1A),
    ),
    textTheme: GoogleFonts.montserratTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: TextSizes.heading,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
        titleLarge: TextStyle(
          fontSize: TextSizes.subheading,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        bodyMedium: TextStyle(
          fontSize: TextSizes.body,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
        labelSmall: TextStyle(
          fontSize: TextSizes.caption,
          fontWeight: FontWeight.w400,
          color: Color(0xFF555555),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF42A5F5), // Soft blue for primary actions
      secondary: Color(0xFF66BB6A), // Soft green for secondary
      surface: Color(0xFF263238), // Dark slate for cards
      onSurface: Color(0xFFECEFF1), // Off-white for text/icons
      primaryContainer: Color(0xFF121926), // Dark navy for backgrounds
      onPrimaryContainer: Color(0xFFECEFF1), // Off-white text on containers
    ),
    scaffoldBackgroundColor: const Color(0xFF121926), // Dark navy background
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF263238), // Dark slate cards
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFF121926),
      foregroundColor: Color(0xFFECEFF1),
    ),
    textTheme: GoogleFonts.montserratTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: TextSizes.heading,
          fontWeight: FontWeight.w700,
          color: Color(0xFFECEFF1),
        ),
        titleLarge: TextStyle(
          fontSize: TextSizes.subheading,
          fontWeight: FontWeight.w600,
          color: Color(0xFFECEFF1),
        ),
        bodyMedium: TextStyle(
          fontSize: TextSizes.body,
          fontWeight: FontWeight.w500,
          color: Color(0xFFCFD8DC),
        ),
        labelSmall: TextStyle(
          fontSize: TextSizes.caption,
          fontWeight: FontWeight.w400,
          color: Color(0xFFB0BEC5),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFECEFF1)),
  );
}
