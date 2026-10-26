import 'package:flutter/material.dart';

/// Semantic color palette for MediCare AI.
///
/// Implements the warm pastel visual identity inspired by the Sweet Tape aesthetic.
/// Centralizes all design tokens in one place so they can be fine-tuned easily.
/// Text/background combinations are calibrated to meet or exceed WCAG AA (4.5:1).
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand Palette (from design spec)
  // ---------------------------------------------------------------------------
  /// Soft pink (#F5E1E7). Hero areas, highlighted cards, selected states, friendly accents.
  static const Color blush = Color(0xFFF5E1E7);

  /// Main app background canvas (#FDF8F1). Warm, soft, comforting.
  static const Color cream = Color(0xFFFDF8F1);

  /// Secondary surfaces, chips, progress track, "Taken" tint (#B8CFB3).
  static const Color sageLight = Color(0xFFB8CFB3);

  /// Brand mid-green (#84A082). Icons, outlines, illustrations, large decorative shapes.
  static const Color sage = Color(0xFF84A082);

  // ---------------------------------------------------------------------------
  // Derived Accessibility Colors (High Contrast)
  // ---------------------------------------------------------------------------
  /// Primary text, headings, text on pastel surfaces (#2F4A38).
  /// Exceeds WCAG AA 4.5:1 against blush, cream, and sageLight.
  static const Color forest = Color(0xFF2F4A38);

  /// Primary buttons, active nav item, links (#4F7455).
  /// White text on sageDeep passes WCAG AA contrast.
  static const Color sageDeep = Color(0xFF4F7455);

  /// Secondary text (#5E6B62).
  static const Color textSecondary = Color(0xFF5E6B62);

  /// Hints, disabled text, placeholder (#8A968D).
  static const Color textMuted = Color(0xFF8A968D);

  /// Pure card surface (#FFFFFF).
  static const Color surface = Color(0xFFFFFFFF);

  /// Slightly warm card surface (#FAF6F0).
  static const Color surfaceWarm = Color(0xFFFAF6F0);

  /// Subtle warm border / divider (#E8E2D9).
  static const Color border = Color(0xFFE8E2D9);

  // ---------------------------------------------------------------------------
  // Status Colors (Always paired with Icon + Label)
  // ---------------------------------------------------------------------------
  /// Taken status (#4F7455)
  static const Color statusTaken = Color(0xFF4F7455);
  static const Color statusTakenBg = Color(0xFFE8F1E7);

  /// Pending status (#D9962B - Soft amber)
  static const Color statusPending = Color(0xFFD9962B);
  static const Color statusPendingBg = Color(0xFFFEF7EA);

  /// Snoozed status (#6B8CA8 - Dusty blue-gray)
  static const Color statusSnoozed = Color(0xFF6B8CA8);
  static const Color statusSnoozedBg = Color(0xFFF0F5FA);

  /// Skipped status (#A66A82 - Dusty mauve)
  static const Color statusSkipped = Color(0xFFA66A82);
  static const Color statusSkippedBg = Color(0xFFFAF0F3);

  /// Missed status (#C2413A - Muted red)
  static const Color statusMissed = Color(0xFFC2413A);
  static const Color statusMissedBg = Color(0xFFFDF2F1);

  /// SOS / Emergency (#DC2626 - Strong red, intentionally exempt from pastel styling)
  static const Color emergency = Color(0xFFDC2626);
  static const Color emergencyBg = Color(0xFFFEF2F2);

  // ---------------------------------------------------------------------------
  // Washi Tape & Sticker Accents (Subtle decorative motifs)
  // ---------------------------------------------------------------------------
  /// Warm butter washi tape accent (#F7E7B4)
  static const Color tapeYellow = Color(0xFFF7E7B4);

  /// Soft pink washi tape accent (#F4D4DC)
  static const Color tapeBlush = Color(0xFFF4D4DC);

  /// Soft sage washi tape accent (#D0E1CB)
  static const Color tapeSage = Color(0xFFD0E1CB);

  // ---------------------------------------------------------------------------
  // Compatibility Aliases (Allows seamless reuse of existing widgets)
  // ---------------------------------------------------------------------------
  static const Color primary = sageDeep;
  static const Color primaryLight = sage;
  static const Color primaryDark = forest;
  static const Color primaryTint = blush;

  static const Color background = cream;
  static const Color textPrimary = forest;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color surfaceVariant = surfaceWarm;
  static const Color borderSubtle = border;

  static const Color success = statusTaken;
  static const Color successLight = sage;
  static const Color successTint = statusTakenBg;

  static const Color warning = statusPending;
  static const Color warningLight = Color(0xFFE8B257);
  static const Color warningTint = statusPendingBg;

  static const Color error = emergency;
  static const Color errorLight = statusMissed;
  static const Color errorTint = emergencyBg;
}
