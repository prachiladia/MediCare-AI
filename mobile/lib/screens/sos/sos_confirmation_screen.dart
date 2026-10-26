import 'package:flutter/material.dart';
import '../../models/caregiver.dart';
import '../../repositories/in_memory_medicine_repository.dart';
import '../../repositories/medicine_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Modal dialog for Emergency SOS Confirmation.
///
/// Phase 8 Specifications:
/// - Requires explicit user confirmation before action.
/// - Shows emergency contact details (Caregiver Name & Phone).
/// - Realistic feedback with mandatory disclaimer: "Prototype: no call was placed".
/// - Strictly NEVER initiates external telephone calls or reports a completed call.
/// - Completely independent from reminder/dose logic.
class SosConfirmationDialog extends StatefulWidget {
  final CaregiverInfo? caregiver;
  final MedicineRepository? repository;

  const SosConfirmationDialog({
    super.key,
    this.caregiver,
    this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    CaregiverInfo? caregiver,
    MedicineRepository? repository,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SosConfirmationDialog(
        caregiver: caregiver,
        repository: repository,
      ),
    );
  }

  @override
  State<SosConfirmationDialog> createState() => _SosConfirmationDialogState();
}

class _SosConfirmationDialogState extends State<SosConfirmationDialog> {
  CaregiverInfo _caregiver = CaregiverInfo.defaultCaregiver;

  @override
  void initState() {
    super.initState();
    if (widget.caregiver != null) {
      _caregiver = widget.caregiver!;
    } else {
      _loadCaregiver();
    }
  }

  Future<void> _loadCaregiver() async {
    final repo = widget.repository ?? InMemoryMedicineRepository.defaultInstance;
    try {
      final info = await repo.getCaregiverInfo();
      if (mounted) {
        setState(() {
          _caregiver = info;
        });
      }
    } catch (_) {}
  }

  void _handleConfirmSos() {
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emergency,
        duration: Duration(seconds: 4),
        content: Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Prototype: no call was placed. In-app demo alert only.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.rounded2xl,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Urgent Red SOS Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.emergencyBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.emergency.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.emergency_rounded,
                  color: AppColors.emergency,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'Emergency SOS',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.emergency,
                    letterSpacing: -0.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Demo disclaimer box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.emergencyBg,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(
                  color: AppColors.emergency.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.emergency,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'DEMONSTRATION ONLY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.emergency,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This is a prototype feature. No real emergency calls, SMS messages, or dispatches will be made.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.emergency,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Designated emergency contact preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESIGNATED EMERGENCY CONTACT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: AppColors.sageDeep,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_caregiver.name} (${_caregiver.relationship})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _caregiver.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Action Buttons (Confirmation step before action)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleConfirmSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergency,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm (Demo)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
