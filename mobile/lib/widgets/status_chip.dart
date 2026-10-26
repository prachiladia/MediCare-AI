import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_spacing.dart';
import '../models/medicine.dart';

/// Pill-shaped status indicator showing Taken or Pending / Upcoming state.
class StatusChip extends StatelessWidget {
  final MedicineStatus status;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = status == MedicineStatus.taken;

    final backgroundColor =
        isTaken ? AppColors.successTint : AppColors.warningTint;
    final foregroundColor = isTaken ? AppColors.success : AppColors.warning;
    final borderColor = isTaken
        ? AppColors.successLight.withValues(alpha: 0.3)
        : AppColors.warningLight.withValues(alpha: 0.3);
    final iconData =
        isTaken ? Icons.check_circle_rounded : Icons.schedule_rounded;
    final label = isTaken ? 'Taken' : 'Pending';

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedPill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 14,
                  color: foregroundColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return chip;
  }
}
