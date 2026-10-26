import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Configures the modern Material Design 3 theme for MediCare AI.
///
/// Implements the Section 4 warm pastel visual identity:
/// - Cream background (#FDF8F1)
/// - Soft blush highlights (#F5E1E7)
/// - Sage and SageDeep primary accents (#84A082, #4F7455)
/// - Deep forest primary text (#2F4A38)
/// - Pill navigation indicators and chunky rounded cards (radius 20-24)
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.sageDeep,
      brightness: Brightness.light,
      primary: AppColors.sageDeep,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blush,
      onPrimaryContainer: AppColors.forest,
      secondary: AppColors.sage,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.sageLight,
      onSecondaryContainer: AppColors.forest,
      surface: AppColors.surface,
      onSurface: AppColors.forest,
      error: AppColors.emergency,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,

      // Typography scale configured with Section 4 styles
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.heroLarge,
        headlineMedium: AppTextStyles.heroMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.eyebrow,
        labelSmall: AppTextStyles.badge,
      ),

      // Card Theme: chunky rounded corners (24dp), crisp white surface with warm border
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedXl,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Navigation Bar: soft blush pill indicator with sageDeep selected icon/label
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.blush,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.sageDeep,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.sageDeep, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 24);
        }),
      ),

      // App Bar Theme: seamless cream canvas
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.forest),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.forest,
          letterSpacing: -0.3,
        ),
      ),

      // Elevated Button: fully rounded pill, sageDeep fill, white text
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedPill,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Outlined Button: sageDeep border & text
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageDeep,
          side: const BorderSide(color: AppColors.sageDeep, width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedPill,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Input Decoration Theme: soft surface fill, sageDeep focus ring
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.sageDeep, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: const BorderSide(color: AppColors.statusMissed, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.rounded2xl,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
