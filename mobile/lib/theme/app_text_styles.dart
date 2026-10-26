import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles adhering to Section 4.3 & 4.4 design guidelines.
///
/// Features bold display headlines for hero moments, small uppercase eyebrow labels,
/// and high-contrast body typography calibrated for WCAG AA readability.
class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // Hero & Display Styles (Sweet Tape Inspired - Big, friendly, confident)
  // ---------------------------------------------------------------------------
  /// Display hero uppercase or large greetings ("WE'LL STICK BY YOUR DOSES")
  static const TextStyle heroLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.15,
    color: AppColors.forest,
  );

  /// Secondary hero headline
  static const TextStyle heroMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
    color: AppColors.forest,
  );

  // ---------------------------------------------------------------------------
  // Section Eyebrow Labels (Small uppercase, letter-spaced)
  // ---------------------------------------------------------------------------
  /// Eyebrow headers ("TODAY'S DOSES", "COMING UP", "RECENT ACTIVITY")
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  /// Small badge or sticker label
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Eyebrow alias for uppercase section labels
  static const TextStyle labelUppercase = eyebrow;

  /// Secondary hero headline alias
  static const TextStyle h2 = heroMedium;

  // ---------------------------------------------------------------------------
  // Titles & Section Headers
  // ---------------------------------------------------------------------------
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.forest,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.forest,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.forest,
  );

  // ---------------------------------------------------------------------------
  // Body & Microcopy (At least 14sp, line height ~1.4, high contrast)
  // ---------------------------------------------------------------------------
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.forest,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.forest,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Colors.white,
  );
}
