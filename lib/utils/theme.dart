/// Groovy Chord Generator
/// App Theme
/// Version 2.5
/// 
/// Centralized theme configuration with:
/// - Dark color palette optimized for music creation
/// - Purple accent colors for modern UI
/// - Chord type-specific colors for visual differentiation
/// - Consistent spacing, sizing, and animation durations
/// - Material Design 3 components

import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================================
  // PRIMARY COLOR PALETTE
  // ============================================================================
  // Dark background colors with increasing elevation
  static const Color bgPrimary = Color(0xFF0A0A14);      // Darkest - main background
  static const Color bgSecondary = Color(0xFF14142B);    // Cards and panels
  static const Color bgTertiary = Color(0xFF1F1F3D);     // Input fields and controls
  static const Color bgElevated = Color(0xFF2A2A4A);     // Elevated elements
  
  // Text colors with semantic hierarchy
  static const Color textPrimary = Color(0xFFFAFAFC);    // Main text
  static const Color textSecondary = Color(0xFFB8B8D0);  // Secondary text
  static const Color textMuted = Color(0xFF6C6C8A);      // Subtle text
  
  // Accent colors - purple theme
  static const Color accentPrimary = Color(0xFF8B5CF6);    // Main accent
  static const Color accentSecondary = Color(0xFFA78BFA);  // Secondary accent
  static const Color accentPink = Color(0xFFF472B6);       // Complementary accent
  static const Color accentCyan = Color(0xFF22D3EE);       // Alternative accent
  
  // Semantic colors
  static const Color success = Color(0xFF10B981);  // Success states, confirmations
  static const Color warning = Color(0xFFFBBF24);  // Warnings, cautions
  static const Color error = Color(0xFFF43F5E);    // Errors, destructive actions
  
  // Borders
  static const Color borderColor = Color(0xFF3A3A5C);   // Default borders
  static const Color borderLight = Color(0xFF4A4A6C);   // Lighter borders

  // ============================================================================
  // CHORD TYPE COLORS
  // ============================================================================
  // Visual differentiation for different chord types
  static const Color chordMajor = Color(0xFF10B981);  // Major - bright, positive
  static const Color chordMinor = Color(0xFF6366F1);  // Minor - calm, introspective
  static const Color chordDim = Color(0xFFEF4444);    // Diminished - tense
  static const Color chordAug = Color(0xFFF59E0B);    // Augmented - bright, unusual
  static const Color chordDom = Color(0xFF8B5CF6);    // Dominant - leading
  static const Color chordSus = Color(0xFF06B6D4);    // Suspended - floating

  // ============================================================================
  // GRADIENTS
  // ============================================================================
  // Pre-defined gradients for consistent visual effects
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPrimary, accentPink],
  );

  static const LinearGradient spiceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, Color(0xFF0EA5E9)],
  );

  // ============================================================================
  // DIMENSIONS
  // ============================================================================
  // Border radius values
  static const double borderRadius = 16.0;      // Standard radius
  static const double borderRadiusSm = 10.0;    // Small elements
  static const double borderRadiusLg = 24.0;    // Large elements
  static const double borderRadiusXl = 32.0;    // Extra large elements

  // Spacing scale - use these for consistent padding/margins
  static const double spacingXs = 4.0;   // Extra small spacing
  static const double spacingSm = 8.0;   // Small spacing
  static const double spacingMd = 16.0;  // Medium spacing (most common)
  static const double spacingLg = 24.0;  // Large spacing
  static const double spacingXl = 32.0;  // Extra large spacing
  static const double spacingXxl = 48.0; // Extra extra large spacing

  // Component sizes
  static const double headerHeight = 60.0;  // App header height
  static const double navHeight = 70.0;     // Bottom navigation height
  static const double fabSize = 60.0;       // Floating action button size

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================
  static const double mobileBreakpoint = 480.0;   // Small mobile devices
  static const double tabletBreakpoint = 768.0;   // Tablets
  static const double desktopBreakpoint = 1024.0; // Desktop screens

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  // Optimized for smooth, snappy animations
  static const Duration animationFast = Duration(milliseconds: 150);    // Quick transitions
  static const Duration animationNormal = Duration(milliseconds: 300);  // Standard
  static const Duration animationSlow = Duration(milliseconds: 500);    // Slow reveals

  // ============================================================================
  // SHADOWS
  // ============================================================================
  // Pre-configured shadow effects for elevation hierarchy
  
  /// Small shadow for subtle elevation (e.g., buttons, cards)
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium shadow for moderate elevation (e.g., dialogs, menus)
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Large shadow for high elevation (e.g., modals, FAB)
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Glowing shadow with accent color (e.g., focused elements)
  static List<BoxShadow> get shadowGlow => [
    BoxShadow(
      color: accentPrimary.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  /// Create a colored glow shadow with any color
  static List<BoxShadow> shadowColorGlow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================================================
  // THEME DATA
  // ============================================================================
  /// Main dark theme with Material Design 3 components
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgPrimary,
    primaryColor: accentPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: bgSecondary,
      error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgSecondary,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: borderColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPrimary,
        foregroundColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
        ),
        minimumSize: const Size(double.infinity, 52),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
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
        borderSide: const BorderSide(color: accentPrimary, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentPrimary,
      inactiveTrackColor: bgTertiary,
      thumbColor: accentPrimary,
      overlayColor: accentPrimary.withValues(alpha: 0.2),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      trackHeight: 6,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textPrimary;
        }
        return textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentPrimary;
        }
        return bgTertiary;
      }),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgSecondary,
      selectedItemColor: accentSecondary,
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
    dialogTheme: DialogTheme(
      backgroundColor: bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textMuted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.5,
      ),
    ),
  );
}
