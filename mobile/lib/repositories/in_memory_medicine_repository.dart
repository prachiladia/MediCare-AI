import 'dart:async';
import '../data/sample_medicines.dart';
import '../models/app_user.dart';
import '../models/caregiver.dart';
import '../models/dose_occurrence.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import 'medicine_repository.dart';

/// In-memory implementation of [MedicineRepository] for demonstration and college prototyping.
///
/// ============================================================================
/// PERSISTENCE LIMITATION DISCLAIMER:
/// All records, modifications, status toggles, dose occurrences, and additions
/// are stored exclusively in volatile device/browser memory. All data will be reset
/// to default sample data whenever the application process terminates, hot restarts,
/// or browser refreshes.
/// ============================================================================
class InMemoryMedicineRepository implements MedicineRepository {
  static InMemoryMedicineRepository? _defaultInstance;
  static InMemoryMedicineRepository get defaultInstance =>
      _defaultInstance ??= InMemoryMedicineRepository();
  static void resetDefaultInstance() {
    _defaultInstance = null;
  }

  final Duration simulatedDelay;
  final List<Medicine> _medicines = [];
  final List<DoseOccurrence> _occurrences = [];
  CaregiverInfo _caregiverInfo = CaregiverInfo.defaultCaregiver;

  InMemoryMedicineRepository({
    this.simulatedDelay = Duration.zero,
    List<Medicine>? seedData,
    List<Medicine>? seedMedicines,
    List<DoseOccurrence>? seedOccurrences,
    CaregiverInfo? seedCaregiver,
  }) {
    if (seedCaregiver != null) {
      _caregiverInfo = seedCaregiver;
    }

    final initialMeds = seedMedicines ?? seedData;
    if (initialMeds != null) {
      _medicines.addAll(initialMeds);
    } else {
      _resetWithSampleData();
    }

    if (seedOccurrences != null) {
      _occurrences.addAll(seedOccurrences);
    }
  }

  void _resetWithSampleData() {
    _medicines.clear();
    _occurrences.clear();

    for (final sample in initialSampleMedicines) {
      _medicines.add(sample.copyWith(isSampleData: true));
    }

    // Seed initial occurrences for today from sample medicines
    final now = DateTime.now();
    for (final med in _medicines) {
      if (med.isEnabled && med.isActive) {
        final times = med.effectiveTimes;
        for (var i = 0; i < times.length; i++) {
          final timeStr = times[i];
          final occ = DoseOccurrence.fromMedicine(
            medicine: med,
            date: now,
            timeStr: timeStr,
            doseIndex: i,
            status: med.isTaken ? DoseStatus.taken : DoseStatus.pending,
            isSampleData: true,
          );
          _occurrences.add(occ);
        }
      }
    }
  }

  Future<void> _maybeDelay() async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
  }

  void _validateMedicine(Medicine medicine) {
    final nameError = Medicine.validateName(medicine.name);
    if (nameError != null) {
      throw MedicineValidationException(nameError);
    }

    final dosageError = Medicine.validateDosage(medicine.dosage);
    if (dosageError != null) {
      throw MedicineValidationException(dosageError);
    }

    final dateError = Medicine.validateDateRange(medicine.startDate, medicine.endDate);
    if (dateError != null) {
      throw MedicineValidationException(dateError);
    }
  }

  @override
  Future<List<Medicine>> getMedicines({
    bool? activeOnly,
    bool? enabledOnly,
  }) async {
    await _maybeDelay();
    Iterable<Medicine> result = _medicines;

    if (enabledOnly == true) {
      result = result.where((m) => m.isEnabled);
    }

    if (activeOnly == true) {
      result = result.where((m) => m.isActive);
    }

    // Return a defensive copy to prevent outside mutation
    return List<Medicine>.from(result);
  }

  @override
  Future<Medicine?> getMedicineById(String id) async {
    await _maybeDelay();
    try {
      return _medicines.firstWhere((m) => m.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Medicine> addMedicine(Medicine medicine) async {
    await _maybeDelay();
    _validateMedicine(medicine);

    // Ensure non-sample flag for user additions unless explicitly marked
    final toAdd = medicine.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _medicines.add(toAdd);

    // Generate occurrences for today if active
    if (toAdd.isEnabled && toAdd.isActive) {
      final now = DateTime.now();
      final times = toAdd.effectiveTimes;
      for (var i = 0; i < times.length; i++) {
        final occ = DoseOccurrence.fromMedicine(
          medicine: toAdd,
          date: now,
          timeStr: times[i],
          doseIndex: i,
          status: toAdd.isTaken ? DoseStatus.taken : DoseStatus.pending,
        );
        _occurrences.add(occ);
      }
    }

    return toAdd;
  }

  @override
  Future<Medicine> updateMedicine(Medicine medicine) async {
    await _maybeDelay();
    _validateMedicine(medicine);

    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index == -1) {
      throw MedicineValidationException('Medicine with ID "${medicine.id}" not found.');
    }

    final updated = medicine.copyWith(
      updatedAt: DateTime.now(),
    );
    _medicines[index] = updated;

    // Synchronize pending occurrences metadata
    for (var i = 0; i < _occurrences.length; i++) {
      if (_occurrences[i].medicineId == updated.id && !_occurrences[i].isCompleted) {
        _occurrences[i] = _occurrences[i].copyWith(
          medicineName: updated.name,
          dosage: updated.dosage,
          instructions: updated.instructions,
        );
      }
    }

    return updated;
  }

  @override
  Future<bool> deleteMedicine(String id) async {
    await _maybeDelay();
    final initialCount = _medicines.length;
    _medicines.removeWhere((m) => m.id == id);
    _occurrences.removeWhere((o) => o.medicineId == id);
    return _medicines.length < initialCount;
  }

  @override
  Future<Medicine> toggleMedicineStatus(String id) async {
    await _maybeDelay();
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index == -1) {
      throw MedicineValidationException('Medicine with ID "$id" not found.');
    }

    final current = _medicines[index];
    final nextStatus = current.isTaken ? MedicineStatus.pending : MedicineStatus.taken;
    final updated = current.copyWith(
      status: nextStatus,
      updatedAt: DateTime.now(),
    );
    _medicines[index] = updated;

    // Sync corresponding occurrences for today
    final now = DateTime.now();
    for (var i = 0; i < _occurrences.length; i++) {
      final o = _occurrences[i];
      if (o.medicineId == id &&
          o.originalScheduledTime.year == now.year &&
          o.originalScheduledTime.month == now.month &&
          o.originalScheduledTime.day == now.day) {
        _occurrences[i] = o.copyWith(
          status: nextStatus == MedicineStatus.taken ? DoseStatus.taken : DoseStatus.pending,
          actionTimestamp: nextStatus == MedicineStatus.taken ? DateTime.now() : null,
        );
      }
    }

    return updated;
  }

  @override
  Future<Medicine> toggleMedicineEnabled(String id, bool isEnabled) async {
    await _maybeDelay();
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index == -1) {
      throw MedicineValidationException('Medicine with ID "$id" not found.');
    }

    final current = _medicines[index];
    final updated = current.copyWith(
      isEnabled: isEnabled,
      updatedAt: DateTime.now(),
    );
    _medicines[index] = updated;
    return updated;
  }

  @override
  Future<void> resetToSampleData() async {
    await _maybeDelay();
    _resetWithSampleData();
  }

  // ===========================================================================
  // Phase 6: Dose Occurrence Management (Taken, Snooze, Skip)
  // ===========================================================================

  @override
  Future<List<DoseOccurrence>> getOccurrences({
    DateTime? date,
    bool? todayOnly,
  }) async {
    await _maybeDelay();
    final targetDate = date ?? (todayOnly == true ? DateTime.now() : null);

    Iterable<DoseOccurrence> result = _occurrences;
    if (targetDate != null) {
      result = result.where((o) =>
          o.originalScheduledTime.year == targetDate.year &&
          o.originalScheduledTime.month == targetDate.month &&
          o.originalScheduledTime.day == targetDate.day);
    }

    final list = List<DoseOccurrence>.from(result);
    list.sort((a, b) {
      final aTime = a.effectiveScheduledTime ?? a.originalScheduledTime;
      final bTime = b.effectiveScheduledTime ?? b.originalScheduledTime;
      return aTime.compareTo(bTime);
    });
    return list;
  }

  @override
  Future<DoseOccurrence?> getOccurrenceById(String id) async {
    await _maybeDelay();
    try {
      return _occurrences.firstWhere((o) => o.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<DoseOccurrence> getOrCreateOccurrenceForMedicine(
    Medicine medicine, {
    DateTime? date,
    int doseIndex = 0,
  }) async {
    await _maybeDelay();
    final targetDate = date ?? DateTime.now();

    for (final o in _occurrences) {
      if (o.medicineId == medicine.id &&
          o.originalScheduledTime.year == targetDate.year &&
          o.originalScheduledTime.month == targetDate.month &&
          o.originalScheduledTime.day == targetDate.day) {
        return o;
      }
    }

    // Create new occurrence if not existing
    final times = medicine.effectiveTimes;
    final timeStr = doseIndex < times.length ? times[doseIndex] : medicine.scheduledTime;
    final newOcc = DoseOccurrence.fromMedicine(
      medicine: medicine,
      date: targetDate,
      timeStr: timeStr,
      doseIndex: doseIndex,
      status: medicine.isTaken ? DoseStatus.taken : DoseStatus.pending,
    );
    _occurrences.add(newOcc);
    return newOcc;
  }

  @override
  Future<DoseOccurrence> recordDoseTaken(
    String occurrenceId, {
    DateTime? timestamp,
  }) async {
    await _maybeDelay();
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) {
      throw DoseOccurrenceException(
          'Dose occurrence with ID "$occurrenceId" not found.');
    }

    final current = _occurrences[index];

    // Validation rule 1: Prevent duplicate taken records on repeated taps
    if (current.isTaken) {
      throw DoseOccurrenceException(
          'Dose for "${current.medicineName}" has already been marked as Taken.');
    }

    // Validation rule 2: Taken-after-Skipped guard
    if (current.isSkipped) {
      throw DoseOccurrenceException(
          'Dose for "${current.medicineName}" was already recorded as Skipped and cannot be marked as Taken.');
    }

    final recordTime = timestamp ?? DateTime.now();
    final updated = current.copyWith(
      status: DoseStatus.taken,
      actionTimestamp: recordTime,
    );

    _occurrences[index] = updated;

    // Sync medicine status if today's dose
    final medIndex = _medicines.indexWhere((m) => m.id == current.medicineId);
    if (medIndex != -1) {
      _medicines[medIndex] = _medicines[medIndex].copyWith(
        status: MedicineStatus.taken,
        updatedAt: recordTime,
      );
    }

    // Cancel remaining notifications for that occurrence
    try {
      final notifId = NotificationService.getNotificationId(current.medicineId, 0);
      await NotificationService().cancelById(notifId);
    } catch (_) {}

    return updated;
  }

  @override
  Future<DoseOccurrence> recordDoseSnooze(
    String occurrenceId,
    int minutes, {
    DateTime? timestamp,
  }) async {
    await _maybeDelay();

    // Validation rule 1: Snooze minutes must be 5, 10, or 15
    if (minutes != 5 && minutes != 10 && minutes != 15) {
      throw DoseOccurrenceException(
          'Invalid snooze duration of $minutes minutes. Allowed durations are 5, 10, or 15 minutes.');
    }

    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) {
      throw DoseOccurrenceException(
          'Dose occurrence with ID "$occurrenceId" not found.');
    }

    final current = _occurrences[index];

    // Validation rule 2: Completed doses cannot be snoozed
    if (current.isCompleted) {
      throw DoseOccurrenceException(
          'Cannot snooze a completed dose for "${current.medicineName}" (status: ${current.status.label}).');
    }

    // Validation rule 3: Maximum 3 snoozes allowed per occurrence
    if (current.snoozeCount >= 3) {
      throw DoseOccurrenceException(
          'Maximum snooze limit (3 times) reached for "${current.medicineName}". Cannot snooze further.');
    }

    final now = timestamp ?? DateTime.now();
    final newEffectiveTime = now.add(Duration(minutes: minutes));
    final newSnoozeCount = current.snoozeCount + 1;

    // Selecting snooze must NEVER mark the dose Taken!
    // Original scheduled time is preserved without alteration.
    final updated = current.copyWith(
      status: DoseStatus.snoozed,
      snoozeCount: newSnoozeCount,
      effectiveScheduledTime: newEffectiveTime,
      actionTimestamp: now,
    );

    _occurrences[index] = updated;

    // Cancel existing notification before rescheduling to prevent duplicates
    try {
      final notifId = NotificationService.getNotificationId(current.medicineId, 0);
      await NotificationService().cancelById(notifId);
      // Schedule snoozed alert
      await NotificationService().scheduleSnoozedReminder(
        occurrence: updated,
        minutes: minutes,
      );
    } catch (_) {}

    return updated;
  }

  @override
  Future<DoseOccurrence> recordDoseSkipped(
    String occurrenceId,
    String reason, {
    DateTime? timestamp,
  }) async {
    await _maybeDelay();

    if (reason.trim().isEmpty) {
      throw const DoseOccurrenceException(
          'Please specify a valid reason for skipping this dose.');
    }

    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) {
      throw DoseOccurrenceException(
          'Dose occurrence with ID "$occurrenceId" not found.');
    }

    final current = _occurrences[index];

    // Validation rule 1: Prevent duplicate skip records
    if (current.isSkipped) {
      throw DoseOccurrenceException(
          'Dose for "${current.medicineName}" has already been recorded as Skipped.');
    }

    // Validation rule 2: Taken doses cannot be skipped
    if (current.isTaken) {
      throw DoseOccurrenceException(
          'Dose for "${current.medicineName}" was already Taken and cannot be Skipped.');
    }

    final recordTime = timestamp ?? DateTime.now();
    final updated = current.copyWith(
      status: DoseStatus.skipped,
      skipReason: reason.trim(),
      actionTimestamp: recordTime,
    );

    _occurrences[index] = updated;

    // Cancel remaining notifications for that occurrence
    try {
      final notifId = NotificationService.getNotificationId(current.medicineId, 0);
      await NotificationService().cancelById(notifId);
    } catch (_) {}

    return updated;
  }

  @override
  Future<Map<String, int>> getDoseSummaryStats({DateTime? date}) async {
    await _maybeDelay();
    final targetDate = date ?? DateTime.now();

    final todays = _occurrences.where((o) =>
        o.originalScheduledTime.year == targetDate.year &&
        o.originalScheduledTime.month == targetDate.month &&
        o.originalScheduledTime.day == targetDate.day);

    final scheduled = todays.length;
    final taken = todays.where((o) => o.isTaken).length;
    final remaining = todays.where((o) => o.isPending || o.isSnoozed).length;
    final skipped = todays.where((o) => o.isSkipped).length;
    final missed = todays.where((o) => o.isMissed).length;

    return {
      'scheduled': scheduled,
      'taken': taken,
      'remaining': remaining,
      'skipped': skipped,
      'missed': missed,
    };
  }

  // ===========================================================================
  // Phase 7: Missed Doses and History Reconciliation
  // ===========================================================================

  @override
  Future<int> reconcileMissedDoses({DateTime? currentTime}) async {
    await _maybeDelay();
    final now = currentTime ?? DateTime.now();
    int reconciledCount = 0;

    for (var i = 0; i < _occurrences.length; i++) {
      final current = _occurrences[i];

      // Transition validation rule:
      // Taken and Skipped doses must NEVER become Missed.
      // Already Missed doses must not be modified again (idempotent reconciliation).
      if (current.isTaken || current.isSkipped || current.isMissed) {
        continue;
      }

      // Check if current time has passed the missed deadline:
      // 60 minutes after scheduled time, or 30 minutes after last snooze (whichever is later)
      if (current.isEligibleForMissed(now)) {
        _occurrences[i] = current.copyWith(
          status: DoseStatus.missed,
          actionTimestamp: now,
        );
        reconciledCount++;
      }
    }

    return reconciledCount;
  }

  @override
  Future<List<DoseOccurrence>> getHistoryOccurrences({
    DoseStatus? filterStatus,
  }) async {
    await _maybeDelay();
    Iterable<DoseOccurrence> list = _occurrences;

    if (filterStatus != null) {
      list = list.where((o) => o.status == filterStatus);
    }

    final result = List<DoseOccurrence>.from(list);

    // Sort newest first: descending by actionTimestamp (if present) or originalScheduledTime
    result.sort((a, b) {
      final aTime = a.actionTimestamp ?? a.originalScheduledTime;
      final bTime = b.actionTimestamp ?? b.originalScheduledTime;
      return bTime.compareTo(aTime);
    });

    return result;
  }

  // ===========================================================================
  // Phase 8: Caregiver & Escalation Implementation
  // ===========================================================================

  @override
  Future<CaregiverInfo> getCaregiverInfo() async {
    await _maybeDelay();
    return _caregiverInfo;
  }

  @override
  Future<CaregiverInfo> updateCaregiverInfo(CaregiverInfo info) async {
    await _maybeDelay();
    final nameErr = CaregiverInfo.validateName(info.name);
    if (nameErr != null) throw ArgumentError(nameErr);

    final relErr = CaregiverInfo.validateRelationship(info.relationship);
    if (relErr != null) throw ArgumentError(relErr);

    final phoneErr = CaregiverInfo.validatePhone(info.phone);
    if (phoneErr != null) throw ArgumentError(phoneErr);

    final emailErr = CaregiverInfo.validateEmail(info.email);
    if (emailErr != null) throw ArgumentError(emailErr);

    _caregiverInfo = info;
    return _caregiverInfo;
  }

  @override
  Future<int> getConsecutiveMissedCount() async {
    await _maybeDelay();
    // Sort occurrences in chronological order (earliest scheduled dose first)
    final sorted = List<DoseOccurrence>.from(_occurrences)
      ..sort((a, b) => a.originalScheduledTime.compareTo(b.originalScheduledTime));

    int streak = 0;
    for (final occ in sorted) {
      if (occ.isMissed) {
        streak++;
      } else if (occ.isTaken || occ.isSkipped) {
        streak = 0; // Streak strictly resets on Taken or Skipped
      }
    }
    return streak;
  }

  @override
  Future<bool> shouldTriggerConsecutiveMissedAlert({int threshold = 3}) async {
    final streak = await getConsecutiveMissedCount();
    return streak >= threshold && _caregiverInfo.alertOnThreeMisses;
  }

  // ===========================================================================
  // Phase 9: User Profile Demo Implementation (users/{uid})
  // ===========================================================================

  AppUser _userProfile = AppUser.demoUser;

  @override
  Future<AppUser?> getUserProfile() async => _userProfile;

  @override
  Future<void> updateUserProfile({String? name, String? phone}) async {
    _userProfile = _userProfile.copyWith(
      name: name ?? _userProfile.name,
      phone: phone ?? _userProfile.phone,
    );
  }
}
