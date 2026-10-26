import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Modal dialog requesting a reason when the user decides to skip a dose.
///
/// Adheres strictly to Section 13:
/// - Provides required reasons: Already Taken, Medicine Unavailable, Doctor Advised to Skip,
///   Side Effects, Forgot, Travelling, Other.
/// - When "Other" is selected, dynamically reveals a custom text field.
/// - Does not give medical advice; neutrally and respectfully records the decision.
class SkipReasonDialog extends StatefulWidget {
  final String medicineName;

  const SkipReasonDialog({
    super.key,
    required this.medicineName,
  });

  static Future<String?> show(BuildContext context, {required String medicineName}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SkipReasonDialog(medicineName: medicineName),
    );
  }

  @override
  State<SkipReasonDialog> createState() => _SkipReasonDialogState();
}

class _SkipReasonDialogState extends State<SkipReasonDialog> {
  static const List<String> _predefinedReasons = [
    'Already Taken',
    'Medicine Unavailable',
    'Doctor Advised to Skip',
    'Side Effects',
    'Forgot',
    'Travelling',
    'Other',
  ];

  String _selectedReason = 'Already Taken';
  final TextEditingController _otherReasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_selectedReason == 'Other') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      Navigator.of(context).pop(_otherReasonController.text.trim());
    } else {
      Navigator.of(context).pop(_selectedReason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _selectedReason == 'Other';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.rounded2xl,
        side: BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Dusty Mauve Skip Icon
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.statusSkippedBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.redo_rounded,
                          color: AppColors.statusSkipped,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Skip Dose',
                              style: AppTextStyles.titleMedium,
                            ),
                            Text(
                              widget.medicineName,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Please select a reason for your records. This helps track adherence accurately without judgment.',
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Reason Radio List
                  ..._predefinedReasons.map((reason) {
                    final isSelected = _selectedReason == reason;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: isSelected ? AppColors.statusSkippedBg : AppColors.surface,
                        borderRadius: AppSpacing.roundedMd,
                        child: InkWell(
                          onTap: () => setState(() => _selectedReason = reason),
                          borderRadius: AppSpacing.roundedMd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.statusSkipped.withValues(alpha: 0.5)
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected
                                      ? AppColors.statusSkipped
                                      : AppColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.forest : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Dynamic "Other" text field
                  if (isOther) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _otherReasonController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Specify reason',
                        hintText: 'Enter reason for skipping...',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide a reason';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusSkipped,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('Confirm Skip'),
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
    );
  }
}
