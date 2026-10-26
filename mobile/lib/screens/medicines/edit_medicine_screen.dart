import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_buttons.dart';

/// Screen allowing the user to view and edit an existing medication schedule, or delete it with confirmation.
class EditMedicineScreen extends StatefulWidget {
  final Medicine medicine;
  final Function(Medicine)? onMedicineUpdated;
  final Function(String)? onMedicineDeleted;

  const EditMedicineScreen({
    super.key,
    required this.medicine,
    this.onMedicineUpdated,
    this.onMedicineDeleted,
  });

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _instructionsController;

  late TimeOfDay _selectedTime;
  late String _selectedFrequency;
  late MedicineType _selectedType;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _hasEndDate;
  late bool _isEnabled;
  String? _dateRangeError;
  bool _isSaving = false;

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 8 hours',
    'Once daily at night',
    'As needed',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine.name);
    _dosageController = TextEditingController(text: widget.medicine.dosage);
    _instructionsController =
        TextEditingController(text: widget.medicine.instructions);
    _selectedFrequency = widget.medicine.frequency;
    _selectedType = widget.medicine.type;
    _startDate = widget.medicine.startDate ?? DateTime.now();
    _endDate = widget.medicine.endDate;
    _hasEndDate = widget.medicine.endDate != null;
    _isEnabled = widget.medicine.isEnabled;

    _selectedTime = _parseTimeString(widget.medicine.scheduledTime);
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.sageDeep,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.sageDeep,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _validateDates();
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial = _endDate ?? _startDate.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.sageDeep,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _validateDates();
      });
    }
  }

  void _validateDates() {
    if (_hasEndDate && _endDate != null) {
      setState(() {
        _dateRangeError = Medicine.validateDateRange(_startDate, _endDate);
      });
    } else {
      setState(() {
        _dateRangeError = null;
      });
    }
  }

  Future<void> _handleSave() async {
    // 1. Duplicate submission guard: if already saving, ignore
    if (_isSaving) return;

    // 2. Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 3. Validate date ranges
    _validateDates();
    if (_dateRangeError != null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final formattedHour =
          _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
      final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
      final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
      final formattedTime = '$formattedHour:$minuteStr $period';

      final updated = widget.medicine.copyWith(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        scheduledTime: formattedTime,
        scheduledTimes: [formattedTime],
        instructions: _instructionsController.text.trim(),
        type: _selectedType,
        frequency: _selectedFrequency,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        isEnabled: _isEnabled,
        updatedAt: DateTime.now(),
      );

      if (widget.onMedicineUpdated != null) {
        final res = widget.onMedicineUpdated!(updated);
        if (res is Future) {
          await res;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${updated.name}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Failed to update medicine: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text(
          'Are you sure you want to remove "${widget.medicine.name}" from your scheduled doses? This action cannot be undone.',
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (widget.onMedicineDeleted != null) {
                final res = widget.onMedicineDeleted!(widget.medicine.id);
                if (res is Future) {
                  await res;
                }
              }
              if (mounted) {
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${widget.medicine.name}"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedHour =
        _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    final timeDisplay = '$formattedHour:$minuteStr $period';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Edit Medication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.emergency),
            tooltip: 'Delete Medicine',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Reminder Switch Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _isEnabled ? 'Schedule Active' : 'Schedule Paused',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _isEnabled
                                  ? AppColors.forest
                                  : AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _isEnabled
                                ? 'Included in daily reminders & adherence.'
                                : 'Paused. Will not appear in pending reminders.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          activeThumbColor: AppColors.sageDeep,
                          activeTrackColor: AppColors.sageLight,
                          value: _isEnabled,
                          onChanged: (val) => setState(() => _isEnabled = val),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Medicine Name
                    Text(
                      'MEDICINE NAME',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.medication_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: Medicine.validateName,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Dosage
                    Text(
                      'DOSAGE & STRENGTH',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.scale_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: Medicine.validateDosage,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Medicine Type
                    Text(
                      'MEDICINE TYPE',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: MedicineType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(type.label),
                          selected: isSelected,
                          selectedColor: AppColors.blush,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.forest
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedPill,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.sageDeep
                                  : AppColors.border,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Scheduled Time
                    Text(
                      'SCHEDULED TIME',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Material(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.roundedMd,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.sageDeep,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                timeDisplay,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Change',
                                style: TextStyle(
                                  color: AppColors.sageDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Frequency
                    Text(
                      'FREQUENCY',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFrequency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.repeat_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      items: _frequencies
                          .map((freq) => DropdownMenuItem(
                                value: freq,
                                child: Text(freq, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFrequency = val);
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Date Range Pickers
                    Text(
                      'TREATMENT DURATION & DATES',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Start Date
                    Material(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.roundedMd,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _pickStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.sageDeep,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Date',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(_startDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                'Select',
                                style: TextStyle(
                                  color: AppColors.sageDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // End Date Toggle
                    Material(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.roundedMd,
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        title: const Text(
                          'Has Treatment End Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                        subtitle: Text(
                          _hasEndDate
                              ? 'Schedule stops after specified end date'
                              : 'Ongoing course (no planned stop date)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        activeThumbColor: AppColors.sageDeep,
                        activeTrackColor: AppColors.sageLight,
                        value: _hasEndDate,
                        onChanged: (val) {
                          setState(() {
                            _hasEndDate = val;
                            if (val && _endDate == null) {
                              _endDate = _startDate.add(const Duration(days: 7));
                            }
                            _validateDates();
                          });
                        },
                      ),
                    ),

                    if (_hasEndDate) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Material(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.roundedMd,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _pickEndDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(
                                color: _dateRangeError != null
                                    ? AppColors.emergency
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_available_rounded,
                                  color: _dateRangeError != null
                                      ? AppColors.emergency
                                      : AppColors.sageDeep,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _endDate != null
                                          ? _formatDate(_endDate!)
                                          : 'Select end date',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _dateRangeError != null
                                            ? AppColors.emergency
                                            : AppColors.forest,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  'Select',
                                  style: TextStyle(
                                    color: AppColors.sageDeep,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_dateRangeError != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _dateRangeError!,
                          style: const TextStyle(
                            color: AppColors.emergency,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Instructions
                    Text(
                      'INSTRUCTIONS / NOTES (OPTIONAL)',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.notes_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Save Changes Button with Duplicate Submission Guard
                    AppPrimaryButton(
                      label: _isSaving ? 'Saving Changes...' : 'Save Changes',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _handleSave,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Delete Button
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.emergency,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
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
      ),
    );
  }
}
