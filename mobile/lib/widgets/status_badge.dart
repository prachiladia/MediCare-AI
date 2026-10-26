import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum StatusBadgeType {
  taken,
  pending,
  snoozed,
  skipped,
  missed,
  emergency,
}

/// Pill-shaped sticker badge indicating dose or system status.
///
/// Adheres strictly to WCAG accessibility: never relies on color alone,
/// always pairing semantic color with a recognizable icon and clear label.
class StatusBadge extends StatelessWidget {
  final StatusBadgeType type;
  final String? customLabel;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.type,
    this.customLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon, fgColor, bgColor, borderColor) = _getBadgeProperties();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: compact ? 13 : 15,
            color: fgColor,
          ),
          const SizedBox(width: 5),
          Text(
            customLabel ?? label,
            style: AppTextStyles.badge.copyWith(
              color: fgColor,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData, Color, Color, Color) _getBadgeProperties() {
    switch (type) {
      case StatusBadgeType.taken:
        return (
          'Taken',
          Icons.check_circle_rounded,
          AppColors.statusTaken,
          AppColors.statusTakenBg,
          AppColors.sageLight,
        );
      case StatusBadgeType.pending:
        return (
          'Pending',
          Icons.schedule_rounded,
          AppColors.statusPending,
          AppColors.statusPendingBg,
          AppColors.warningLight.withValues(alpha: 0.5),
        );
      case StatusBadgeType.snoozed:
        return (
          'Snoozed',
          Icons.snooze_rounded,
          AppColors.statusSnoozed,
          AppColors.statusSnoozedBg,
          AppColors.statusSnoozed.withValues(alpha: 0.35),
        );
      case StatusBadgeType.skipped:
        return (
          'Skipped',
          Icons.redo_rounded,
          AppColors.statusSkipped,
          AppColors.statusSkippedBg,
          AppColors.blush,
        );
      case StatusBadgeType.missed:
        return (
          'Missed',
          Icons.warning_amber_rounded,
          AppColors.statusMissed,
          AppColors.statusMissedBg,
          AppColors.statusMissed.withValues(alpha: 0.35),
        );
      case StatusBadgeType.emergency:
        return (
          'Emergency SOS',
          Icons.emergency_rounded,
          AppColors.emergency,
          AppColors.emergencyBg,
          AppColors.emergency.withValues(alpha: 0.4),
        );
    }
  }
}
