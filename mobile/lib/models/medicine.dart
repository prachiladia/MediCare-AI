/// Represents the current adherence status of a scheduled medicine.
enum MedicineStatus {
  pending,
  taken,
}

/// Category / physical form of the medicine used for icons and styling.
enum MedicineType {
  pill('Pill'),
  capsule('Capsule'),
  tablet('Tablet'),
  liquid('Liquid'),
  injection('Injection');

  final String label;
  const MedicineType(this.label);

  static MedicineType fromString(String value) {
    for (final type in MedicineType.values) {
      if (type.name.toLowerCase() == value.trim().toLowerCase() ||
          type.label.toLowerCase() == value.trim().toLowerCase()) {
        return type;
      }
    }
    return MedicineType.tablet;
  }
}

/// Structured medication frequency options.
enum MedicineFrequency {
  onceDaily('Once daily'),
  twiceDaily('Twice daily'),
  threeTimesDaily('Three times daily'),
  every8Hours('Every 8 hours'),
  onceDailyNight('Once daily at night'),
  asNeeded('As needed');

  final String label;
  const MedicineFrequency(this.label);

  static MedicineFrequency fromString(String val) {
    for (final freq in MedicineFrequency.values) {
      if (freq.label.toLowerCase() == val.trim().toLowerCase() ||
          freq.name.toLowerCase() == val.trim().toLowerCase()) {
        return freq;
      }
    }
    return MedicineFrequency.onceDaily;
  }
}

/// Exception thrown when medication data fails validation constraints.
class MedicineValidationException implements Exception {
  final String message;
  const MedicineValidationException(this.message);

  @override
  String toString() => message;
}

/// Data model representing a scheduled medication item.
class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String scheduledTime;
  final List<String> scheduledTimes;
  final MedicineStatus status;
  final String instructions;
  final MedicineType type;
  final bool isHeroReminder;
  final int? minutesUntil;
  final String frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isEnabled;
  final bool isSampleData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduledTime,
    this.scheduledTimes = const [],
    required this.status,
    this.instructions = '',
    this.type = MedicineType.tablet,
    this.isHeroReminder = false,
    this.minutesUntil,
    this.frequency = 'Once daily',
    this.startDate,
    this.endDate,
    this.isEnabled = true,
    this.isSampleData = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isTaken => status == MedicineStatus.taken;
  bool get isPending => status == MedicineStatus.pending;

  /// Effective scheduled times list (falls back to single scheduledTime if empty)
  List<String> get effectiveTimes =>
      scheduledTimes.isNotEmpty ? scheduledTimes : [scheduledTime];

  /// Checks if medicine schedule is currently active (enabled and within date window).
  bool get isActive {
    if (!isEnabled) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (startDate != null) {
      final startDay = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (today.isBefore(startDay)) return false;
    }
    if (endDate != null) {
      final endDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (today.isAfter(endDay)) return false;
    }
    return true;
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? scheduledTime,
    List<String>? scheduledTimes,
    MedicineStatus? status,
    String? instructions,
    MedicineType? type,
    bool? isHeroReminder,
    int? minutesUntil,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isEnabled,
    bool? isSampleData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
      type: type ?? this.type,
      isHeroReminder: isHeroReminder ?? this.isHeroReminder,
      minutesUntil: minutesUntil ?? this.minutesUntil,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isEnabled: isEnabled ?? this.isEnabled,
      isSampleData: isSampleData ?? this.isSampleData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validation static helpers
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter medication name';
    }
    if (value.trim().length < 2) {
      return 'Medication name must be at least 2 characters';
    }
    return null;
  }

  static String? validateDosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter dosage (e.g. 500 mg)';
    }
    return null;
  }

  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null) {
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      if (endDay.isBefore(startDay)) {
        return 'End date cannot be before start date';
      }
    }
    return null;
  }
}
