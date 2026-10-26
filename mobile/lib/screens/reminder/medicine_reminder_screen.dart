import 'package:flutter/material.dart';
import '../../dialogs/skip_reason_dialog.dart';
import '../../models/dose_occurrence.dart';
import '../../models/medicine.dart';
import '../../repositories/medicine_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_buttons.dart';

/// Focused, calm reminder screen displaying an active dose alert with Taken, Snooze, and Skip actions.
///
/// Adheres strictly to Section 10, 11, 12, and 13:
/// - Prominent, accessible Taken action (Section 11).
/// - Snooze selection (5, 10, 15 min) with maximum 3 snoozes tracked (Section 12).
/// - Skip workflow triggering [SkipReasonDialog] (Section 13).
/// - All actions disabled while saving to prevent duplicate submissions.
class MedicineReminderScreen extends StatefulWidget {
  final Medicine medicine;
  final DoseOccurrence? occurrence;
  final MedicineRepository? repository;
  final VoidCallback? onTaken;
  final Function(int minutes)? onSnooze;
  final Function(String reason)? onSkip;

  const MedicineReminderScreen({
    super.key,
    required this.medicine,
    this.occurrence,
    this.repository,
    this.onTaken,
    this.onSnooze,
    this.onSkip,
  });

  @override
  State<MedicineReminderScreen> createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends State<MedicineReminderScreen> {
  late int _snoozeCount;
  static const int _maxSnoozes = 3;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _snoozeCount = widget.occurrence?.snoozeCount ?? 0;
  }

  Future<void> _handleTaken() async {
    if (_isSaving) return;

    if (widget.occurrence?.isCompleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusPending,
          content: Text(
            'This dose was already ${widget.occurrence!.status.label.toLowerCase()}.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.repository != null && widget.occurrence != null) {
        await widget.repository!.recordDoseTaken(widget.occurrence!.id);
      }
      if (widget.onTaken != null) {
        widget.onTaken!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sageDeep,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Dose recorded as Taken: ${widget.medicine.name}'),
                ),
              ],
            ),
          ),
        );
        if (Navigator.of(context).canPop()) {
          if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Could not mark dose taken: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnoozeOptions() {
    if (_isSaving) return;

    if (_snoozeCount >= _maxSnoozes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum snooze limit (3 times) reached for this dose.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radius2xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Snooze Dose', style: AppTextStyles.titleMedium),
                  Text(
                    'Snooze ${_snoozeCount + 1} of $_maxSnoozes',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Select when you would like to be gently reminded again:',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSnoozeTile(ctx, 5, '5 Minutes'),
              _buildSnoozeTile(ctx, 10, '10 Minutes'),
              _buildSnoozeTile(ctx, 15, '15 Minutes'),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnoozeTile(BuildContext ctx, int minutes, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceWarm,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          onTap: () async {
            Navigator.of(ctx).pop();
            await _handleSnooze(minutes);
          },
          borderRadius: AppSpacing.roundedMd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.snooze_rounded, color: AppColors.statusSnoozed, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSnooze(int minutes) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (widget.repository != null && widget.occurrence != null) {
        final updated = await widget.repository!.recordDoseSnooze(
          widget.occurrence!.id,
          minutes,
        );
        setState(() => _snoozeCount = updated.snoozeCount);
      } else {
        setState(() => _snoozeCount++);
      }

      if (widget.onSnooze != null) {
        widget.onSnooze!(minutes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder snoozed for $minutes minutes ($_snoozeCount/$_maxSnoozes).',
            ),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Could not snooze reminder: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    if (_isSaving) return;

    final reason = await SkipReasonDialog.show(
      context,
      medicineName: widget.medicine.name,
    );

    if (reason != null && mounted) {
      setState(() => _isSaving = true);

      try {
        if (widget.repository != null && widget.occurrence != null) {
          await widget.repository!.recordDoseSkipped(
            widget.occurrence!.id,
            reason,
          );
        }

        if (widget.onSkip != null) {
          widget.onSkip!(reason);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Skipped "${widget.medicine.name}" (Reason: $reason)'),
            ),
          );
          if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.emergency,
              content: Text('Could not skip dose: $e'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalTime = widget.occurrence?.originalTimeFormatted ?? widget.medicine.scheduledTime;
    final isSnoozeDisabled = _isSaving || _snoozeCount >= _maxSnoozes;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Washi Tape Header Accent
                  Transform.rotate(
                    angle: -0.02,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tapeYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DOSE TIME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Big Circular Icon with Blush background
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sage.withValues(alpha: 0.3), width: 2),
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      size: 46,
                      color: AppColors.sageDeep,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Scheduled Time Pill (Preserves Original Time)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.statusPendingBg,
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(color: AppColors.warningLight.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.statusPending),
                        const SizedBox(width: 5),
                        Text(
                          'Scheduled for $originalTime',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusPending,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Snooze status badge if previously snoozed
                  if (_snoozeCount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusSnoozedBg,
                        borderRadius: AppSpacing.roundedPill,
                        border: Border.all(color: AppColors.statusSnoozed.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Snoozed $_snoozeCount/$_maxSnoozes times',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusSnoozed,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Big Medicine Name
                  Text(
                    widget.medicine.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Dosage & Frequency
                  Text(
                    '${widget.medicine.dosage} • ${widget.medicine.frequency}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.sageDeep,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Instructions Card
                  if (widget.medicine.instructions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        widget.medicine.instructions,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Big Accessible Primary Action: Taken (Disabled while saving)
                  AppPrimaryButton(
                    label: _isSaving ? 'Recording...' : 'Mark as Taken',
                    icon: Icons.check_circle_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleTaken,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Secondary Actions: Snooze & Skip (Disabled while saving & when limit reached)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSnoozeDisabled ? null : _showSnoozeOptions,
                          icon: const Icon(Icons.snooze_rounded, size: 18),
                          label: Text(
                            _snoozeCount >= _maxSnoozes
                                ? 'Snooze (Limit 3/3)'
                                : (_snoozeCount > 0
                                    ? 'Snooze ($_snoozeCount/$_maxSnoozes)'
                                    : 'Snooze'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusSnoozed,
                            side: BorderSide(
                              color: isSnoozeDisabled
                                  ? AppColors.border
                                  : AppColors.statusSnoozed,
                            ),
                            minimumSize: const Size(0, AppSpacing.minTouchTarget),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _handleSkip,
                          icon: const Icon(Icons.redo_rounded, size: 18),
                          label: const Text('Skip Dose'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusSkipped,
                            side: BorderSide(
                              color: _isSaving ? AppColors.border : AppColors.statusSkipped,
                            ),
                            minimumSize: const Size(0, AppSpacing.minTouchTarget),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
