/// Chord Flow
/// App Theme
/// Phase 5.2 visual system
library;

import 'package:flutter/material.dart';

class AppTheme {
  // "Night Bloom" palette: keeps Chord Flow's dark-violet identity while
  // introducing mint and coral accents for clearer hierarchy and a fresher feel.
  static const Color bgPrimary = Color(0xFF090B12); // Obsidian Ink
  static const Color bgSecondary = Color(0xFF111522); // Midnight Slate
  static const Color bgTertiary = Color(0xFF191F30); // Studio Navy
  static const Color bgElevated = Color(0xFF242B3F); // Lifted Slate
  static const Color surfaceGlow = Color(0xFF2D3550);

  static const Color textPrimary = Color(0xFFF7F8FC);
  static const Color textSecondary = Color(0xFFB9C1D6);
  static const Color textMuted = Color(0xFF77819D);

  static const Color accentPrimary = Color(0xFF7C6CF2); // Bloom Violet
  static const Color accentSecondary = Color(0xFFB39AF8); // Soft Orchid
  static const Color accentPink = Color(0xFFFF6B8A); // Coral Pulse
  static const Color accentCyan = Color(0xFF45E0D1); // Electric Mint
  static const Color producerGold = Color(0xFFF5C875); // Studio Gold

  static const Color success = Color(0xFF4DD6A8);
  static const Color warning = Color(0xFFF5C875);
  static const Color error = Color(0xFFFF5F73);

  static const Color borderColor = Color(0xFF2C3550);
  static const Color borderLight = Color(0xFF3C4868);

  // Chord colors remain differentiated, but are tuned to the Night Bloom set.
  static const Color chordMajor = Color(0xFF4DD6A8);
  static const Color chordMinor = Color(0xFF7187FF);
  static const Color chordDim = Color(0xFFFF667D);
  static const Color chordAug = Color(0xFFF2B86B);
  static const Color chordDom = Color(0xFF9B7CFF);
  static const Color chordSus = Color(0xFF43D5D0);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPrimary, accentPink],
  );

  static const LinearGradient producerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPrimary, accentCyan],
  );

  static const LinearGradient stageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF171C2B), Color(0xFF10131F)],
  );

  static const LinearGradient spiceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A62), accentPink],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF2FB88C)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, Color(0xFF4BA7FF)],
  );

  static const double borderRadius = 16.0;
  static const double borderRadiusSm = 10.0;
  static const double borderRadiusLg = 24.0;
  static const double borderRadiusXl = 32.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double headerHeight = 60.0;
  static const double navHeight = 70.0;
  static const double fabSize = 60.0;

  static const double mobileBreakpoint = 480.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.26),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.34),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.46),
          blurRadius: 28,
          offset: const Offset(0, 9),
        ),
      ];

  static List<BoxShadow> get shadowGlow => [
        BoxShadow(
          color: accentPrimary.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowColorGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.34),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgPrimary,
        primaryColor: accentPrimary,
        colorScheme: const ColorScheme.dark(
          primary: accentPrimary,
          secondary: accentCyan,
          tertiary: accentPink,
          surface: bgSecondary,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgSecondary,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: bgSecondary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: const BorderSide(color: borderColor),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentPrimary,
            foregroundColor: textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
            ),
            minimumSize: const Size(double.infinity, 52),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: accentCyan, width: 1.8),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textMuted),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accentCyan,
          inactiveTrackColor: bgTertiary,
          thumbColor: accentPrimary,
          overlayColor: accentPrimary.withValues(alpha: 0.18),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          trackHeight: 5,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return textPrimary;
            return textSecondary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return accentPrimary;
            return bgTertiary;
          }),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bgSecondary,
          selectedItemColor: accentCyan,
          unselectedItemColor: textMuted,
          type: BottomNavigationBarType.fixed,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: bgElevated,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bgSecondary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.6,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: textPrimary,
            height: 1.45,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: textSecondary,
            height: 1.45,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: textMuted,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 0.5,
          ),
        ),
      );
}
