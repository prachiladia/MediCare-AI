import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Container displaying compact stat cards computed dynamically from the medicine dataset.
class SummaryStatCards extends StatelessWidget {
  final int scheduledCount;
  final int takenCount;
  final int remainingCount;
  final int skippedCount;

  const SummaryStatCards({
    super.key,
    required this.scheduledCount,
    required this.takenCount,
    required this.remainingCount,
    this.skippedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: 'Scheduled',
            count: scheduledCount,
            accentColor: AppColors.forest,
            tintColor: AppColors.blush,
            icon: Icons.calendar_today_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatItem(
            label: 'Taken',
            count: takenCount,
            accentColor: AppColors.sageDeep,
            tintColor: AppColors.statusTakenBg,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatItem(
            label: 'Pending',
            count: remainingCount,
            accentColor: AppColors.statusPending,
            tintColor: AppColors.statusPendingBg,
            icon: Icons.hourglass_top_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color accentColor;
  final Color tintColor;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.count,
    required this.accentColor,
    required this.tintColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tintColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: accentColor,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
