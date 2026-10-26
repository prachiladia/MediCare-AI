import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'adherence_ring.dart';

/// Card displaying the daily medication adherence with a Sweet Tape-inspired tape-roll progress ring.
class AdherenceCard extends StatelessWidget {
  final int takenCount;
  final int totalCount;
  final VoidCallback? onTap;

  const AdherenceCard({
    super.key,
    required this.takenCount,
    required this.totalCount,
    this.onTap,
  });

  double get ratio =>
      totalCount > 0 ? (takenCount / totalCount).clamp(0.0, 1.0) : 0.0;
  int get percentage => (ratio * 100).round();

  @override
  Widget build(BuildContext context) {
    final companionMessage = totalCount == 0
        ? 'No medications scheduled for today.'
        : takenCount == totalCount
            ? 'All $totalCount medications completed! Terrific job staying on track.'
            : "You've taken $takenCount of $totalCount doses today. Keep it up!";

    final semanticsLabel = onTap != null
        ? 'Daily adherence: $percentage percent. $companionMessage. Tap to view detailed progress report.'
        : 'Daily adherence: $percentage percent. $companionMessage';

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppSpacing.rounded2xl,
          border: Border.all(color: AppColors.border),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppSpacing.rounded2xl,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.rounded2xl,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  // Circular "Tape Roll" Style Adherence Ring
                  AdherenceTapeRoll(
                    percentage: ratio,
                    takenDoses: takenCount,
                    totalDoses: totalCount,
                    size: 84,
                    strokeWidth: 9,
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  // Text & Microcopy
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blush,
                                borderRadius: AppSpacing.roundedPill,
                              ),
                              child: const Text(
                                'DAILY ADHERENCE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                            if (onTap != null)
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.sageDeep,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          companionMessage,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consistent habits stick best.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
