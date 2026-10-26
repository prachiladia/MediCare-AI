import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'status_badge.dart';

/// Reusable medicine card displaying dosage, scheduled time, instructions, and status.
///
/// Implements safe Material + InkWell ink effects (preventing ListTile assertion errors).
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    this.onToggleStatus,
  });

  IconData _getIconForType(MedicineType type) {
    switch (type) {
      case MedicineType.capsule:
        return Icons.medication_liquid_rounded;
      case MedicineType.liquid:
        return Icons.water_drop_rounded;
      case MedicineType.injection:
        return Icons.vaccines_rounded;
      case MedicineType.pill:
      case MedicineType.tablet:
        return Icons.medication_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTaken = medicine.isTaken;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedXl,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Material(
        color: isTaken ? AppColors.surfaceWarm : AppColors.surface,
        borderRadius: AppSpacing.roundedXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedXl,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedXl,
              border: Border.all(
                color: isTaken
                    ? AppColors.sageLight.withValues(alpha: 0.6)
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Form-specific icon with pastel tinted circular background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isTaken ? AppColors.statusTakenBg : AppColors.blush,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(medicine.type),
                    color: isTaken ? AppColors.sageDeep : AppColors.forest,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name, dosage, and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          decoration: isTaken ? TextDecoration.lineThrough : null,
                          color: isTaken ? AppColors.textSecondary : AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            medicine.dosage,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            medicine.scheduledTime,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      if (medicine.instructions.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          medicine.instructions,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Status Badge or Toggle Button
                if (onToggleStatus != null)
                  InkWell(
                    onTap: onToggleStatus,
                    borderRadius: AppSpacing.roundedPill,
                    child: StatusBadge(
                      type: isTaken ? StatusBadgeType.taken : StatusBadgeType.pending,
                      compact: true,
                    ),
                  )
                else
                  StatusBadge(
                    type: isTaken ? StatusBadgeType.taken : StatusBadgeType.pending,
                    compact: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
