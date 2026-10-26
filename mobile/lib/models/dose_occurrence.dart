import 'medicine.dart';

/// Current status of an individual dose occurrence.
enum DoseStatus {
  pending('Pending'),
  snoozed('Snoozed'),
  taken('Taken'),
  skipped('Skipped'),
  missed('Missed');

  final String label;
  const DoseStatus(this.label);
}

/// Exception thrown when dose occurrence actions fail validation constraints.
class DoseOccurrenceException implements Exception {
  final String message;
  const DoseOccurrenceException(this.message);

  @override
  String toString() => message;
}

/// Represents an individual scheduled dose event for a specific medicine at a specific date & time.
///
/// Section 10-13 requirements:
/// - Maintains the immutable [originalScheduledTime] regardless of snooze actions.
/// - Tracks [snoozeCount] (up to a maximum of 3).
/// - Records [actionTimestamp] when user marks Taken, Snoozed, or Skipped.
/// - Stores [skipReason] when skipped.
class DoseOccurrence {
  final String id;
  final String medicineId;
  final String medicineName;
  final String dosage;
  final DateTime originalScheduledTime;
  final DateTime? effectiveScheduledTime;
  final DoseStatus status;
  final int snoozeCount;
  final DateTime? actionTimestamp;
  final String? skipReason;
  final String instructions;
  final bool isSampleData;

  const DoseOccurrence({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.originalScheduledTime,
    this.effectiveScheduledTime,
    this.status = DoseStatus.pending,
    this.snoozeCount = 0,
    this.actionTimestamp,
    this.skipReason,
    this.instructions = '',
    this.isSampleData = false,
  });

  bool get isTaken => status == DoseStatus.taken;
  bool get isSkipped => status == DoseStatus.skipped;
  bool get isPending => status == DoseStatus.pending;
  bool get isSnoozed => status == DoseStatus.snoozed;
  bool get isMissed => status == DoseStatus.missed;

  /// A dose is completed by user action if it has already been either taken or skipped.
  bool get isCompleted => isTaken || isSkipped;

  /// A dose is finalized if it has reached a terminal state (taken, skipped, or missed).
  bool get isFinalized => isTaken || isSkipped || isMissed;

  /// Snooze is allowed only if dose is not completed and hasn't hit the 3-snooze limit.
  bool get canSnooze => !isFinalized && snoozeCount < 3;

  /// User can mark taken only if not already completed.
  bool get canTake => !isCompleted;

  /// User can skip only if not already completed.
  bool get canSkip => !isCompleted;

  /// Missed-dose policy named constants (Phase 7):
  /// - An un-snoozed dose is marked Missed 60 minutes after the scheduled time.
  /// - A snoozed dose is marked Missed 30 minutes after the latest snooze time.
  /// - Whichever deadline is later governs.
  /// - A dose is NEVER Missed when it first appears.
  static const Duration scheduledMissedGracePeriod = Duration(minutes: 60);
  static const Duration snoozedMissedGracePeriod = Duration(minutes: 30);

  /// Computes the exact deadline after which an untaken, unskipped dose becomes eligible to be marked Missed.
  DateTime get missedDeadline {
    final scheduledDeadline = originalScheduledTime.add(scheduledMissedGracePeriod);
    if (snoozeCount > 0 && effectiveScheduledTime != null) {
      final snoozeDeadline = effectiveScheduledTime!.add(snoozedMissedGracePeriod);
      return snoozeDeadline.isAfter(scheduledDeadline) ? snoozeDeadline : scheduledDeadline;
    }
    return scheduledDeadline;
  }

  /// Determines whether this occurrence has passed its missed deadline.
  /// A dose is NEVER eligible when it first appears.
  /// A Taken or Skipped dose must NEVER become Missed.
  /// An already Missed dose is not eligible again (idempotent reconciliation).
  bool isEligibleForMissed(DateTime currentTime) {
    if (isCompleted || isMissed) return false;
    return currentTime.isAfter(missedDeadline);
  }

  /// Formatted 12-hour time string for display (e.g. "08:00 AM").
  String get originalTimeFormatted {
    final hour = originalScheduledTime.hour;
    final minute = originalScheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final standardHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${standardHour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Formatted effective time (incorporates snooze delay).
  String get effectiveTimeFormatted {
    final target = effectiveScheduledTime ?? originalScheduledTime;
    final hour = target.hour;
    final minute = target.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final standardHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${standardHour.toString().padLeft(2, '0')}:$minute $period';
  }

  DoseOccurrence copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    String? dosage,
    DateTime? originalScheduledTime,
    DateTime? effectiveScheduledTime,
    DoseStatus? status,
    int? snoozeCount,
    DateTime? actionTimestamp,
    String? skipReason,
    String? instructions,
    bool? isSampleData,
  }) {
    return DoseOccurrence(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      originalScheduledTime: originalScheduledTime ?? this.originalScheduledTime,
      effectiveScheduledTime: effectiveScheduledTime ?? this.effectiveScheduledTime,
      status: status ?? this.status,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
      skipReason: skipReason ?? this.skipReason,
      instructions: instructions ?? this.instructions,
      isSampleData: isSampleData ?? this.isSampleData,
    );
  }

  /// Factory creating an occurrence from a [Medicine] for a specific time and date.
  static DoseOccurrence fromMedicine({
    required Medicine medicine,
    required DateTime date,
    required String timeStr,
    int doseIndex = 0,
    DoseStatus status = DoseStatus.pending,
    bool isSampleData = false,
  }) {
    final parsedTime = _parseTimeOfDay(timeStr);
    final scheduledDate = DateTime(
      date.year,
      date.month,
      date.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    final occurrenceId = 'occ_${medicine.id}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_$doseIndex';

    return DoseOccurrence(
      id: occurrenceId,
      medicineId: medicine.id,
      medicineName: medicine.name,
      dosage: medicine.dosage,
      originalScheduledTime: scheduledDate,
      effectiveScheduledTime: scheduledDate,
      status: status,
      snoozeCount: 0,
      instructions: medicine.instructions,
      isSampleData: isSampleData || medicine.isSampleData,
    );
  }

  static ({int hour, int minute}) _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim();
      final isPm = clean.toUpperCase().contains('PM');
      final isAm = clean.toUpperCase().contains('AM');
      final numPart = clean.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = numPart.split(':');
      if (parts.length >= 2) {
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return (hour: hour, minute: minute);
      }
    } catch (_) {}
    return (hour: 8, minute: 0);
  }
}
