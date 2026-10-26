import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../models/medicine.dart';
import 'status_chip.dart';

/// Card list tile representing a single medication item in today's schedule.
/// Tapping the tile body triggers [onTap] (e.g. view details / edit), while the status chip toggles its Taken/Pending state.
class MedicineListTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onToggleStatus;
  final VoidCallback? onTap;

  const MedicineListTile({
    super.key,
    required this.medicine,
    required this.onToggleStatus,
    this.onTap,
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
    final isEnabled = medicine.isEnabled;

    return Semantics(
      button: true,
      label:
          '${medicine.name}, ${medicine.dosage}, scheduled for ${medicine.scheduledTime}. Status: ${isTaken ? "Taken" : "Pending"}. ${isEnabled ? "" : "Paused."} Tap to view details.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.roundedXl,
          border: Border.all(
            color: !isEnabled
                ? AppColors.border
                : isTaken
                    ? AppColors.successLight.withValues(alpha: 0.25)
                    : AppColors.border,
          ),
          boxShadow: isTaken || !isEnabled ? [] : AppSpacing.cardShadow,
        ),
        child: Material(
          color: !isEnabled
              ? AppColors.surfaceWarm.withValues(alpha: 0.6)
              : isTaken
                  ? AppColors.surfaceVariant.withValues(alpha: 0.5)
                  : AppColors.surface,
          borderRadius: AppSpacing.roundedXl,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? onToggleStatus,
            borderRadius: AppSpacing.roundedXl,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Form-specific icon with tinted background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: !isEnabled
                          ? AppColors.border.withValues(alpha: 0.4)
                          : isTaken
                              ? AppColors.successTint
                              : AppColors.primaryTint,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(
                        color: !isEnabled
                            ? AppColors.border
                            : isTaken
                                ? AppColors.successLight.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      _getIconForType(medicine.type),
                      color: !isEnabled
                          ? AppColors.textMuted
                          : isTaken
                              ? AppColors.success
                              : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Title, dosage & time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                medicine.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: isTaken
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: !isEnabled
                                          ? AppColors.textMuted
                                          : isTaken
                                              ? AppColors.textSecondary
                                              : AppColors.textPrimary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isEnabled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                                child: const Text(
                                  'PAUSED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            if (medicine.isSampleData) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blush.withValues(alpha: 0.6),
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                                child: const Text(
                                  'SAMPLE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${medicine.dosage} • ${medicine.instructions}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              medicine.scheduledTime,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '• ${medicine.frequency}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Status chip with toggle callback
                  StatusChip(
                    status: medicine.status,
                    onTap: onToggleStatus,
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
