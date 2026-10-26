import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_buttons.dart';

/// Form screen to configure and add a new medication schedule.
///
/// Implements duplicate submission locking, field validation, and start/end date range checks.
class AddMedicineScreen extends StatefulWidget {
  final Function(Medicine)? onMedicineAdded;

  const AddMedicineScreen({super.key, this.onMedicineAdded});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedFrequency = 'Once daily';
  MedicineType _selectedType = MedicineType.tablet;

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
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
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
    // 1. Duplicate submission guard: if already saving, reject immediately
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
      final formattedHour = _selectedTime.hourOfPeriod == 0
          ? 12
          : _selectedTime.hourOfPeriod;
      final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
      final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
      final formattedTime = '$formattedHour:$minuteStr $period';

      final newMed = Medicine(
        id: 'med_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        scheduledTime: formattedTime,
        scheduledTimes: [formattedTime],
        status: MedicineStatus.pending,
        instructions: _instructionController.text.trim().isEmpty
            ? 'Take as directed'
            : _instructionController.text.trim(),
        type: _selectedType,
        frequency: _selectedFrequency,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        isEnabled: true,
        isSampleData: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.onMedicineAdded != null) {
        final res = widget.onMedicineAdded!(newMed);
        if (res is Future) {
          await res;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(newMed);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added "${newMed.name}" to today\'s schedule (in-memory demo).',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emergency,
            content: Text('Failed to save medicine: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedHour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    final timeString = '$formattedHour:$minuteStr $period';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Add Medicine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                    // Demo data banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.sageDeep,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'In-memory prototype: New medicines exist during this session only. Data resets on restart.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Medicine Name
                    Text(
                      'MEDICINE NAME',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Amoxicillin, Metformin',
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
                        hintText: 'e.g. 500 mg, 1 tablet, 10 ml',
                        prefixIcon: Icon(
                          Icons.scale_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: Medicine.validateDosage,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Form factor / Medicine Type
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

                    // Schedule Time Picker
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
                        borderRadius: AppSpacing.roundedMd,
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
                                timeString,
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

                    // Frequency Dropdown
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

                    // Date Range Section
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
                      controller: _instructionController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Take after food with water',
                        prefixIcon: Icon(
                          Icons.notes_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Save Button with Duplicate Submission Guard
                    AppPrimaryButton(
                      label: _isSaving ? 'Saving...' : 'Save Medicine',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                    const SizedBox(height: AppSpacing.md),
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
