import 'package:flutter/material.dart';

/// Central spacing, radius, and soft shadow definitions.
/// Adheres strictly to an 8pt grid with large soft rounded shapes (radii 20-28, pills 999).
class AppSpacing {
  AppSpacing._();

  // ---------------------------------------------------------------------------
  // Spacing Units
  // ---------------------------------------------------------------------------
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double heroPadding = 24.0;

  // Minimum touch target
  static const double minTouchTarget = 48.0;

  // ---------------------------------------------------------------------------
  // Radii
  // ---------------------------------------------------------------------------
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radius2xl = 28.0;
  static const double radiusPill = 999.0;

  static const BorderRadius roundedSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius rounded2xl =
      BorderRadius.all(Radius.circular(radius2xl));
  static const BorderRadius roundedPill =
      BorderRadius.all(Radius.circular(radiusPill));

  // ---------------------------------------------------------------------------
  // Soft, Low Elevation Shadows (Calm, never heavy or harsh)
  // ---------------------------------------------------------------------------
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF2F4A38).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF2F4A38).withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: const Color(0xFF2F4A38).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
