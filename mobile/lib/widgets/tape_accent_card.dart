import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A card featuring a subtle washi-tape strip at the top.
///
/// Inspired by the Sweet Tape visual motif: adds tactile warmth while remaining
/// clean and functional. Decorative elements are wrapped in [IgnorePointer]
/// to prevent touch event interception.
class TapeAccentCard extends StatelessWidget {
  final Widget child;
  final Color tapeColor;
  final String? tapeText;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double tapeRotation; // in radians, keep small (1-2 degrees)

  const TapeAccentCard({
    super.key,
    required this.child,
    this.tapeColor = AppColors.tapeYellow,
    this.tapeText,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.tapeRotation = -0.03, // ~-1.7 degrees
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main Card Surface
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedXl,
            boxShadow: AppSpacing.cardShadow,
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: AppSpacing.roundedXl,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppSpacing.roundedXl,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedXl,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),

        // Washi Tape Strip Accent
        Positioned(
          top: 0,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: tapeRotation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: tapeColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  tapeText ?? 'NEXT DOSE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
