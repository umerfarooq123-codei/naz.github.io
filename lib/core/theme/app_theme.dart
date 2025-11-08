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
    brightness: Brightness.light,

    // Color Scheme - Professional & Modern
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B57D0), // Google-inspired professional blue
      brightness: Brightness.light,
      primary: const Color(0xFF0B57D0),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFD3E3FD),
      onPrimaryContainer: const Color(0xFF001C38),
      secondary: const Color(0xFF535E6F),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFD7E3F7),
      onSecondaryContainer: const Color(0xFF101C2B),
      tertiary: const Color(0xFF6B5778),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFF2DAFF),
      onTertiaryContainer: const Color(0xFF251431),
      error: const Color(0xFFBA1A1A),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: const Color(0xFFFAFAFA),
      onSurface: const Color(0xFF1A1C1E),
      surfaceContainerHighest: const Color(0xFFE3E2E6),
      surfaceContainerHigh: const Color(0xFFE9E7EC),
      surfaceContainer: const Color(0xFFEFEDF1),
      surfaceContainerLow: const Color(0xFFF5F3F7),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      onSurfaceVariant: const Color(0xFF44474E),
      outline: const Color(0xFFD0D0D0),
      outlineVariant: const Color(0xFFE5E5E5),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFF2F3033),
      onInverseSurface: const Color(0xFFF1F0F4),
      inversePrimary: const Color(0xFFA4C9FF),
      surfaceTint: const Color(0xFF0B57D0),
    ),

    scaffoldBackgroundColor: const Color(0xFFF5F5F7),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(8),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF1A1C1E),
      iconTheme: const IconThemeData(color: Color(0xFF1A1C1E), size: 24),
      actionsIconTheme: const IconThemeData(color: Color(0xFF1A1C1E), size: 24),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1C1E),
        letterSpacing: 0,
      ),
      centerTitle: false,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFF1A1C1E),
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: const Color(0xFF1A1C1E),
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: const Color(0xFF1A1C1E),
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: const Color(0xFF1A1C1E),
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: const Color(0xFF1A1C1E),
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: const Color(0xFF1A1C1E),
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: const Color(0xFF1A1C1E),
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: const Color(0xFF1A1C1E),
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: const Color(0xFF1A1C1E),
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: const Color(0xFF44474E),
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: const Color(0xFF44474E),
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: const Color(0xFF5F6368),
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: const Color(0xFF44474E),
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: const Color(0xFF44474E),
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFF5F6368),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      hoverColor: const Color(0xFFF5F5F7),
      focusColor: const Color(0xFFD3E3FD),
      hintStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF9AA0A6),
      ),
      labelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF5F6368),
      ),
      floatingLabelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0B57D0),
      ),
      errorStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFBA1A1A),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0B57D0), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            foregroundColor: const Color(0xFFFFFFFF),
            backgroundColor: const Color(0xFF0B57D0),
            disabledForegroundColor: const Color(
              0xFFFFFFFF,
            ).withValues(alpha: 0.38),
            disabledBackgroundColor: const Color(
              0xFF1A1C1E,
            ).withValues(alpha: 0.12),
            textStyle: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFFFFFFF).withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFFFFFFFF).withValues(alpha: 0.12);
              }
              return null;
            }),
          ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: const BorderSide(color: Color(0xFF0B57D0), width: 1.5),
            foregroundColor: const Color(0xFF0B57D0),
            disabledForegroundColor: const Color(
              0xFF1A1C1E,
            ).withValues(alpha: 0.38),
            textStyle: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFF0B57D0).withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF0B57D0).withValues(alpha: 0.12);
              }
              return null;
            }),
          ),
    ),

    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            foregroundColor: const Color(0xFF0B57D0),
            disabledForegroundColor: const Color(
              0xFF1A1C1E,
            ).withValues(alpha: 0.38),
            textStyle: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFF0B57D0).withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF0B57D0).withValues(alpha: 0.12);
              }
              return null;
            }),
          ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: const Color(0xFFFFFFFF),
        backgroundColor: const Color(0xFF0B57D0),
        disabledForegroundColor: const Color(
          0xFFFFFFFF,
        ).withValues(alpha: 0.38),
        disabledBackgroundColor: const Color(
          0xFF1A1C1E,
        ).withValues(alpha: 0.12),
        textStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFF44474E),
        disabledForegroundColor: const Color(
          0xFF1A1C1E,
        ).withValues(alpha: 0.38),
        hoverColor: const Color(0xFF1A1C1E).withValues(alpha: 0.08),
        highlightColor: const Color(0xFF1A1C1E).withValues(alpha: 0.12),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 3,
      focusElevation: 4,
      hoverElevation: 4,
      highlightElevation: 6,
      backgroundColor: const Color(0xFF0B57D0),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Data Table Theme
    dataTableTheme: DataTableThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
      headingRowHeight: 56,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 72,
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFD3E3FD);
        }
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFFF5F5F7);
        }
        return const Color(0xFFFFFFFF);
      }),
      headingTextStyle: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1C1E),
        letterSpacing: 0.1,
      ),
      dataTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF44474E),
        letterSpacing: 0.1,
      ),
      horizontalMargin: 24,
      columnSpacing: 24,
      dividerThickness: 1,
      checkboxHorizontalMargin: 12,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      elevation: 8,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1C1E),
      ),
      contentTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF44474E),
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 8,
      modalElevation: 8,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.15),
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      elevation: 6,
      backgroundColor: const Color(0xFF1A1C1E),
      contentTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFFFFFFF),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
      actionTextColor: const Color(0xFFA4C9FF),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFD0D0D0), width: 1),
      ),
      side: const BorderSide(color: Color(0xFFD0D0D0), width: 1),
      backgroundColor: const Color(0xFFFAFAFA),
      selectedColor: const Color(0xFFD3E3FD),
      disabledColor: const Color(0xFFE5E5E5),
      deleteIconColor: const Color(0xFF5F6368),
      labelStyle: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF44474E),
      ),
      secondaryLabelStyle: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1A1C1E),
      ),
      brightness: Brightness.light,
    ),

    // List Tile Theme
    listTileTheme: ListTileThemeData(
      tileColor: const Color(0xFFFFFFFF),
      selectedTileColor: const Color(0xFFD3E3FD),
      selectedColor: const Color(0xFF0B57D0),
      iconColor: const Color(0xFF44474E),
      textColor: const Color(0xFF1A1C1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      style: ListTileStyle.list,
    ),

    // Drawer Theme
    drawerTheme: DrawerThemeData(
      elevation: 8,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.15),
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
    ),

    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      elevation: 3,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.1),
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFFD3E3FD),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B57D0),
          );
        }
        return GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF5F6368),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF0B57D0), size: 24);
        }
        return const IconThemeData(color: Color(0xFF5F6368), size: 24);
      }),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 8,
      backgroundColor: const Color(0xFFFFFFFF),
      selectedItemColor: const Color(0xFF0B57D0),
      unselectedItemColor: const Color(0xFF5F6368),
      selectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: const Color(0xFF0B57D0),
      unselectedLabelColor: const Color(0xFF5F6368),
      indicatorColor: const Color(0xFF0B57D0),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: const Color(0xFFE5E5E5),
      labelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFFFFF);
        }
        return const Color(0xFFFAFAFA);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0B57D0);
        }
        return const Color(0xFFD0D0D0);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0B57D0);
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
      side: const BorderSide(color: Color(0xFFD0D0D0), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0B57D0);
        }
        return const Color(0xFFD0D0D0);
      }),
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF0B57D0),
      inactiveTrackColor: const Color(0xFFD0D0D0),
      thumbColor: const Color(0xFF0B57D0),
      overlayColor: const Color(0xFF0B57D0).withValues(alpha: 0.12),
      valueIndicatorColor: const Color(0xFF0B57D0),
      valueIndicatorTextStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
      ),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF0B57D0),
      linearTrackColor: Color(0xFFD0D0D0),
      circularTrackColor: Color(0xFFD0D0D0),
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFFFFFFF),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      waitDuration: const Duration(milliseconds: 500),
    ),

    // Badge Theme
    badgeTheme: BadgeThemeData(
      backgroundColor: const Color(0xFFBA1A1A),
      textColor: const Color(0xFFFFFFFF),
      textStyle: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Expansion Tile Theme
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: const Color(0xFFFFFFFF),
      collapsedBackgroundColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF1A1C1E),
      collapsedTextColor: const Color(0xFF44474E),
      iconColor: const Color(0xFF44474E),
      collapsedIconColor: const Color(0xFF5F6368),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Popup Menu Theme
    popupMenuTheme: PopupMenuThemeData(
      elevation: 8,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.15),
      color: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1A1C1E),
      ),
    ),

    // Menu Theme
    menuTheme: MenuThemeData(
      style: MenuStyle(
        elevation: WidgetStateProperty.all(8),
        shadowColor: WidgetStateProperty.all(
          const Color(0xFF000000).withValues(alpha: 0.15),
        ),
        backgroundColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),

    // Dropdown Menu Theme
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1A1C1E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0B57D0), width: 2),
        ),
      ),
      menuStyle: MenuStyle(
        elevation: WidgetStateProperty.all(8),
        shadowColor: WidgetStateProperty.all(
          const Color(0xFF000000).withValues(alpha: 0.15),
        ),
        backgroundColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),

    // Search Bar Theme
    searchBarTheme: SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      side: WidgetStateProperty.all(
        const BorderSide(color: Color(0xFFD0D0D0), width: 1),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16),
      ),
      textStyle: WidgetStateProperty.all(
        GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1A1C1E),
        ),
      ),
      hintStyle: WidgetStateProperty.all(
        GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9AA0A6),
        ),
      ),
    ),

    // Search View Theme
    searchViewTheme: SearchViewThemeData(
      elevation: 8,
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      dividerColor: const Color(0xFFE5E5E5),
      headerTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1A1C1E),
      ),
      headerHintStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF9AA0A6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Banner Theme
    bannerTheme: MaterialBannerThemeData(
      backgroundColor: const Color(0xFFFAFAFA),
      contentTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1A1C1E),
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
      color: Color(0xFFE5E5E5),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: Color(0xFF44474E), size: 24),

    // Primary Icon Theme
    primaryIconTheme: const IconThemeData(color: Color(0xFF0B57D0), size: 24),

    // Action Icon Theme (for AppBar actions)
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => const Icon(Icons.arrow_back),
      closeButtonIconBuilder: (context) => const Icon(Icons.close),
      drawerButtonIconBuilder: (context) => const Icon(Icons.menu),
      endDrawerButtonIconBuilder: (context) => const Icon(Icons.menu),
    ),

    // Time Picker Theme
    timePickerTheme: TimePickerThemeData(
      backgroundColor: const Color(0xFFFFFFFF),
      hourMinuteTextColor: const Color(0xFF1A1C1E),
      hourMinuteColor: const Color(0xFFFAFAFA),
      dayPeriodTextColor: const Color(0xFF1A1C1E),
      dayPeriodColor: const Color(0xFFFAFAFA),
      dialHandColor: const Color(0xFF0B57D0),
      dialBackgroundColor: const Color(0xFFFAFAFA),
      dialTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFFFFF);
        }
        return const Color(0xFF1A1C1E);
      }),
      entryModeIconColor: const Color(0xFF44474E),
      hourMinuteTextStyle: GoogleFonts.montserrat(
        fontSize: 56,
        fontWeight: FontWeight.w400,
      ),
      dayPeriodTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      helpTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF44474E),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Date Picker Theme
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 8,
      shadowColor: const Color(0xFF000000).withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      headerBackgroundColor: const Color(0xFF0B57D0),
      headerForegroundColor: const Color(0xFFFFFFFF),
      headerHeadlineStyle: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headerHelpStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      weekdayStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF44474E),
      ),
      dayStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      dayForegroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFFFFF);
        }
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF9AA0A6);
        }
        return const Color(0xFF1A1C1E);
      }),
      dayBackgroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0B57D0);
        }
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFFFFF);
        }
        return const Color(0xFF0B57D0);
      }),
      todayBackgroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0B57D0);
        }
        return Colors.transparent;
      }),
      todayBorder: const BorderSide(color: Color(0xFF0B57D0), width: 1),
      yearStyle: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      yearForegroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFFFFF);
        }
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF9AA0A6);
        }
        return const Color(0xFF1A1C1E);
      }),
      yearBackgroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0B57D0);
        }
        return Colors.transparent;
      }),
      rangePickerBackgroundColor: const Color(0xFFFFFFFF),
      rangePickerHeaderBackgroundColor: const Color(0xFF0B57D0),
      rangePickerHeaderForegroundColor: const Color(0xFFFFFFFF),
      rangeSelectionBackgroundColor: const Color(0xFFD3E3FD),
    ),

    // Scrollbar Theme
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        const Color(0xFF9AA0A6).withValues(alpha: 0.5),
      ),
      trackColor: WidgetStateProperty.all(
        const Color(0xFFE5E5E5).withValues(alpha: 0.3),
      ),
      trackBorderColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(8),
      thumbVisibility: WidgetStateProperty.all(false),
      trackVisibility: WidgetStateProperty.all(false),
      interactive: true,
    ),

    // Page Transitions Theme
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),

    // Typography
    typography: Typography.material2021(platform: TargetPlatform.android),

    // Splash Color
    splashColor: const Color(0xFF0B57D0).withValues(alpha: 0.12),
    highlightColor: const Color(0xFF0B57D0).withValues(alpha: 0.08),
    hoverColor: const Color(0xFF1A1C1E).withValues(alpha: 0.08),
    focusColor: const Color(0xFF0B57D0).withValues(alpha: 0.12),

    // Disabled Color
    disabledColor: const Color(0xFF9AA0A6),

    // Unselected Widget Color
    unselectedWidgetColor: const Color(0xFF9AA0A6),

    // Secondary Header Color
    secondaryHeaderColor: const Color(0xFFD3E3FD),

    // Text Selection Theme
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xFF0B57D0),
      selectionColor: const Color(0xFF0B57D0).withValues(alpha: 0.3),
      selectionHandleColor: const Color(0xFF0B57D0),
    ),

    // Visual Density
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // Material Tap Target Size
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );

  // Dark Theme - Keeping your existing dark theme unchanged
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
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFFECEFF1),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFECEFF1),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFCFD8DC),
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFFB0BEC5),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFECEFF1)),
  );
}
