import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/status_chip.dart';
import 'edit_medicine_screen.dart';

/// Screen displaying comprehensive details for a specific medication.
///
/// Provides actions to toggle adherence status (Taken/Pending), enable/disable
/// reminders, edit medication details, or delete with confirmation.
class MedicineDetailsScreen extends StatefulWidget {
  final Medicine medicine;
  final Function(Medicine)? onToggleStatus;
  final Function(Medicine, bool)? onToggleEnabled;
  final Function(Medicine)? onUpdateMedicine;
  final Function(String)? onDeleteMedicine;

  const MedicineDetailsScreen({
    super.key,
    required this.medicine,
    this.onToggleStatus,
    this.onToggleEnabled,
    this.onUpdateMedicine,
    this.onDeleteMedicine,
  });

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  late Medicine _currentMedicine;

  @override
  void initState() {
    super.initState();
    _currentMedicine = widget.medicine;
  }

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

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Not set';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _handleToggleStatus() {
    if (widget.onToggleStatus != null) {
      widget.onToggleStatus!(_currentMedicine);
    }
    setState(() {
      final nextStatus = _currentMedicine.isTaken
          ? MedicineStatus.pending
          : MedicineStatus.taken;
      _currentMedicine = _currentMedicine.copyWith(status: nextStatus);
    });
  }

  void _handleToggleEnabled(bool isEnabled) {
    if (widget.onToggleEnabled != null) {
      widget.onToggleEnabled!(_currentMedicine, isEnabled);
    }
    setState(() {
      _currentMedicine = _currentMedicine.copyWith(isEnabled: isEnabled);
    });
  }

  void _handleEdit() async {
    final updated = await Navigator.of(context).push<Medicine>(
      MaterialPageRoute(
        builder: (context) => EditMedicineScreen(
          medicine: _currentMedicine,
          onMedicineUpdated: (med) {
            if (widget.onUpdateMedicine != null) {
              widget.onUpdateMedicine!(med);
            }
            setState(() {
              _currentMedicine = med;
            });
          },
          onMedicineDeleted: (id) {
            if (widget.onDeleteMedicine != null) {
              widget.onDeleteMedicine!(id);
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentMedicine = updated;
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text(
          'Are you sure you want to remove "${_currentMedicine.name}" from your scheduled doses? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.onDeleteMedicine != null) {
                widget.onDeleteMedicine!(_currentMedicine.id);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTaken = _currentMedicine.isTaken;
    final isEnabled = _currentMedicine.isEnabled;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Medication Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Medication',
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.emergency),
            tooltip: 'Delete Medication',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sample data & in-memory disclaimer notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _currentMedicine.isSampleData
                                ? 'Sample data • In-memory prototype (resets on restart)'
                                : 'User created • In-memory only (resets on restart)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.forest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Hero Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isTaken
                                    ? AppColors.successTint
                                    : AppColors.primaryTint,
                                borderRadius: AppSpacing.roundedLg,
                                border: Border.all(
                                  color: isTaken
                                      ? AppColors.successLight.withValues(alpha: 0.3)
                                      : AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                _getIconForType(_currentMedicine.type),
                                color: isTaken ? AppColors.success : AppColors.primary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentMedicine.name,
                                    style: AppTextStyles.h2,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_currentMedicine.dosage} • ${_currentMedicine.type.label}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              status: _currentMedicine.status,
                              onTap: _handleToggleStatus,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: AppSpacing.md),

                        // Enable / Disable Reminder Switch
                        Material(
                          color: Colors.transparent,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              isEnabled ? 'Reminders Active' : 'Reminders Paused',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isEnabled ? AppColors.forest : AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              isEnabled
                                  ? 'This medicine is included in daily schedules & alerts.'
                                  : 'Reminders are paused. Excluded from daily active counts.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            activeThumbColor: AppColors.sageDeep,
                            activeTrackColor: AppColors.sageLight,
                            value: isEnabled,
                            onChanged: _handleToggleEnabled,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Schedule & Instructions Details Card
                  Text(
                    'SCHEDULE & DETAILS',
                    style: AppTextStyles.labelUppercase,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.roundedLg,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.schedule_rounded,
                          title: 'Scheduled Time',
                          value: _currentMedicine.scheduledTime,
                        ),
                        const Divider(color: AppColors.border, height: AppSpacing.lg),
                        _buildDetailRow(
                          icon: Icons.repeat_rounded,
                          title: 'Frequency',
                          value: _currentMedicine.frequency,
                        ),
                        const Divider(color: AppColors.border, height: AppSpacing.lg),
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          title: 'Date Window',
                          value: _currentMedicine.endDate != null
                              ? '${_formatDate(_currentMedicine.startDate)} – ${_formatDate(_currentMedicine.endDate)}'
                              : 'Ongoing (Started ${_formatDate(_currentMedicine.startDate)})',
                        ),
                        const Divider(color: AppColors.border, height: AppSpacing.lg),
                        _buildDetailRow(
                          icon: Icons.description_outlined,
                          title: 'Instructions',
                          value: _currentMedicine.instructions.isNotEmpty
                              ? _currentMedicine.instructions
                              : 'No specific instructions provided',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Primary Toggle Action Button
                  AppPrimaryButton(
                    label: isTaken ? 'Mark as Pending' : 'Mark as Taken',
                    icon: isTaken ? Icons.undo_rounded : Icons.check_circle_rounded,
                    onPressed: _handleToggleStatus,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Secondary Edit Action
                  AppSecondaryButton(
                    label: 'Edit Medication Details',
                    icon: Icons.edit_outlined,
                    onPressed: _handleEdit,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Delete Medication
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.emergency,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete this medication'),
                      onPressed: _confirmDelete,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.sageDeep),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
