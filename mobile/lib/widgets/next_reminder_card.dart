import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The hero reminder card emphasizing the user's next upcoming dose with a washi-tape accent.
class NextReminderCard extends StatelessWidget {
  final Medicine? medicine;
  final VoidCallback? onTakeAction;
  final VoidCallback? onTap;

  const NextReminderCard({
    super.key,
    required this.medicine,
    this.onTakeAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (medicine == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.roundedXl,
          border: Border.all(color: AppColors.border),
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.statusTakenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: AppColors.sageDeep,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Caught Up!',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No pending doses for today. Easygoing. No drama.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final med = medicine!;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main Card Container
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.rounded2xl,
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                // Top Row: Section Eyebrow + Upcoming Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.statusPending,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'NEXT UPCOMING DOSE',
                              style: AppTextStyles.eyebrow,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amber Pending pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusPendingBg,
                        borderRadius: AppSpacing.roundedPill,
                        border: Border.all(
                          color: AppColors.warningLight.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.alarm_rounded,
                            size: 13,
                            color: AppColors.statusPending,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            med.minutesUntil != null
                                ? 'in ${med.minutesUntil} min'
                                : 'Upcoming',
                            style: const TextStyle(
                              color: AppColors.statusPending,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Middle Row: Icon + Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Form icon in blush circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.blush,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: AppColors.sageDeep,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${med.dosage}${med.instructions.isNotEmpty ? " • ${med.instructions}" : ""}',
                            style: AppTextStyles.bodySecondary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Scheduled Time Badge & Action Button
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: AppSpacing.roundedPill,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: AppColors.forest,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            med.scheduledTime,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onTakeAction,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Mark as Taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(130, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 8,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedPill,
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),

                // Footnote
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Demo reminder • Timezone scheduling active in Phase 4',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),

        // Washi Tape Strip Accent
        Positioned(
          top: 0,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -0.025, // ~-1.4 degrees
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tapeYellow,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Text(
                  'STICK TO SCHEDULE',
                  style: TextStyle(
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
