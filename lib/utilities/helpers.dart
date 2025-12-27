// Groovy Chord Generator
// Helper Functions
// Version 2.5
//
// Utility helper functions used across the application.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/types.dart';

/// Layout helpers for responsive design
class LayoutHelper {
  /// Screen size breakpoints
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  /// Get responsive value based on screen width.
  ///
  /// The [mobile] value is required and used as the default.
  /// If [tablet] is null, falls back to [mobile].
  /// If [desktop] is null, falls back to [tablet] (or [mobile] if [tablet] is also null).
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= tabletBreakpoint) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(
      responsive(context, mobile: 12.0, tablet: 16.0, desktop: 24.0),
    );
  }

  /// Get responsive grid cross axis count
  static int responsiveGridCount(BuildContext context) {
    return responsive(context, mobile: 2, tablet: 3, desktop: 4);
  }
}

/// Clipboard helper functions
class ClipboardHelper {
  /// Copy text to clipboard with optional feedback
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String? feedbackMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (feedbackMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Date and time helper functions
class DateTimeHelper {
  /// Format duration in mm:ss format
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get relative time string (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes${minutes == 1 ? ' minute' : ' minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours${hours == 1 ? ' hour' : ' hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days${days == 1 ? ' day' : ' days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks${weeks == 1 ? ' week' : ' weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months${months == 1 ? ' month' : ' months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years${years == 1 ? ' year' : ' years'} ago';
    }
  }
}

/// String helper functions
class StringHelper {
  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Convert camelCase to Title Case
  static String camelToTitle(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => capitalize(word))
        .join(' ');
  }
}

/// Color helper functions
class ColorHelper {
  /// Get chord color based on chord type
  static Color getChordTypeColor(ChordTypeName type) {
    switch (type) {
      case ChordTypeName.major:
      case ChordTypeName.major7:
      case ChordTypeName.major9:
        return const Color(0xFF10B981); // Success green
      case ChordTypeName.minor:
      case ChordTypeName.minor7:
      case ChordTypeName.minor9:
        return const Color(0xFF6366F1); // Indigo
      case ChordTypeName.diminished:
      case ChordTypeName.diminished7:
      case ChordTypeName.halfDim7:
        return const Color(0xFFEF4444); // Red
      case ChordTypeName.augmented:
        return const Color(0xFFF59E0B); // Warning amber
      case ChordTypeName.dominant7:
        return const Color(0xFF8B5CF6); // Purple
      case ChordTypeName.sus2:
      case ChordTypeName.sus4:
        return const Color(0xFF06B6D4); // Cyan
      case ChordTypeName.add9:
        return const Color(0xFFEC4899); // Pink
    }
  }

  /// Get harmony function color
  static Color getHarmonyFunctionColor(HarmonyFunction function) {
    switch (function) {
      case HarmonyFunction.tonic:
        return const Color(0xFF10B981); // Green - stable
      case HarmonyFunction.subdominant:
        return const Color(0xFF3B82F6); // Blue - moderate tension
      case HarmonyFunction.dominant:
        return const Color(0xFFEF4444); // Red - high tension
      case HarmonyFunction.passing:
        return const Color(0xFFF59E0B); // Amber - transitional
    }
  }

  /// Darken a color by a percentage (0.0 to 1.0)
  static Color darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Lighten a color by a percentage (0.0 to 1.0)
  static Color lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}

/// Random helper functions
class RandomHelper {
  static final Random _random = Random();

  /// Get random element from list
  static T choice<T>(List<T> list) {
    return list[_random.nextInt(list.length)];
  }

  /// Get random integer in range [min, max] (inclusive)
  static int randInt(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Get random double in range [min, max]
  static double randDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Shuffle a list and return new list
  static List<T> shuffled<T>(List<T> list) {
    final copy = List<T>.from(list);
    copy.shuffle(_random);
    return copy;
  }
}

/// Unique ID generator
class IdGenerator {
  /// Generate a unique ID based on timestamp and random component
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return '$timestamp$random';
  }
}
