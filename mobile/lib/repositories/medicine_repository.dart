import '../models/app_user.dart';
import '../models/caregiver.dart';
import '../models/dose_occurrence.dart';
import '../models/medicine.dart';

/// Abstract contract for managing medications and dose occurrences in MediCare AI.
///
/// Keeps data access completely decoupled from Flutter UI widgets.
/// Implementations can be in-memory for prototypes, or later backed by
/// persistent storage (SQLite/Hive/API) when authorized.
abstract class MedicineRepository {
  /// Retrieves all medications, optionally filtered by active or enabled state.
  Future<List<Medicine>> getMedicines({
    bool? activeOnly,
    bool? enabledOnly,
  });

  /// Retrieves a single medication by unique identifier.
  Future<Medicine?> getMedicineById(String id);

  /// Adds a new medication schedule to the repository after validating constraints.
  /// Throws [MedicineValidationException] if constraints are violated.
  Future<Medicine> addMedicine(Medicine medicine);

  /// Updates an existing medication record after validating constraints.
  /// Throws [MedicineValidationException] if constraints are violated.
  Future<Medicine> updateMedicine(Medicine medicine);

  /// Deletes a medication record by its ID.
  /// Returns `true` if removed, `false` if not found.
  Future<bool> deleteMedicine(String id);

  /// Toggles status between [MedicineStatus.taken] and [MedicineStatus.pending].
  Future<Medicine> toggleMedicineStatus(String id);

  /// Enables or disables a medication (pausing/unpausing reminders).
  Future<Medicine> toggleMedicineEnabled(String id, bool isEnabled);

  /// Resets the repository back to the default pre-seeded sample data.
  Future<void> resetToSampleData();

  // ===========================================================================
  // Phase 6: Dose Occurrences Contract (Taken, Snooze, Skip)
  // ===========================================================================

  /// Retrieves dose occurrences, optionally filtered by a specific date.
  Future<List<DoseOccurrence>> getOccurrences({
    DateTime? date,
    bool? todayOnly,
  });

  /// Retrieves a specific dose occurrence by its ID.
  Future<DoseOccurrence?> getOccurrenceById(String id);

  /// Retrieves or creates an occurrence for a medicine on a given date.
  Future<DoseOccurrence> getOrCreateOccurrenceForMedicine(
    Medicine medicine, {
    DateTime? date,
    int doseIndex = 0,
  });

  /// Records a dose occurrence as [DoseStatus.taken].
  /// Validates that the dose has not already been completed (taken or skipped).
  /// Cancels any scheduled reminders for this occurrence.
  /// Throws [DoseOccurrenceException] if invalid.
  Future<DoseOccurrence> recordDoseTaken(
    String occurrenceId, {
    DateTime? timestamp,
  });

  /// Snoozes a dose occurrence by [minutes] (5, 10, or 15).
  /// Preserves the [DoseOccurrence.originalScheduledTime] and increments [snoozeCount].
  /// Maximum 3 snoozes allowed per occurrence.
  /// Cancels and reschedules notifications to prevent duplicates.
  /// Throws [DoseOccurrenceException] if max snoozes exceeded or invalid.
  Future<DoseOccurrence> recordDoseSnooze(
    String occurrenceId,
    int minutes, {
    DateTime? timestamp,
  });

  /// Records a dose occurrence as [DoseStatus.skipped] with a recorded [reason].
  /// Validates that the dose has not already been completed.
  /// Cancels any scheduled reminders for this occurrence.
  /// Throws [DoseOccurrenceException] if invalid or duplicate.
  Future<DoseOccurrence> recordDoseSkipped(
    String occurrenceId,
    String reason, {
    DateTime? timestamp,
  });

  /// Dynamically computes summary counts for dose occurrences (e.g. for today).
  /// Returns a map containing: 'scheduled', 'taken', 'remaining', 'skipped'.
  Future<Map<String, int>> getDoseSummaryStats({DateTime? date});

  // ===========================================================================
  // Phase 7: Missed Doses and History Contract
  // ===========================================================================

  /// Reconciles pending and snoozed occurrences that have surpassed their
  /// missed-dose response window (60 min after scheduled time, or 30 min after last snooze).
  /// Marks each qualifying occurrence as [DoseStatus.missed] exactly once.
  /// Returns the number of occurrences newly transitioned to missed.
  Future<int> reconcileMissedDoses({DateTime? currentTime});

  /// Retrieves history occurrences filtered optionally by [filterStatus] (Taken, Skipped, Missed, etc.).
  /// Returns records ordered newest first (descending chronological order).
  Future<List<DoseOccurrence>> getHistoryOccurrences({DoseStatus? filterStatus});

  // ===========================================================================
  // Phase 8: Caregiver & Escalation Contract
  // ===========================================================================

  /// Retrieves the current caregiver profile and notification preferences.
  Future<CaregiverInfo> getCaregiverInfo();

  /// Updates caregiver details after verifying constraints.
  /// Throws [ArgumentError] if fields violate validation constraints.
  Future<CaregiverInfo> updateCaregiverInfo(CaregiverInfo info);

  /// Computes the current streak of consecutive missed doses in chronological order.
  /// A Taken or Skipped dose resets the streak to 0.
  Future<int> getConsecutiveMissedCount();

  /// Determines whether the 3-consecutive-misses escalation alert condition is met.
  Future<bool> shouldTriggerConsecutiveMissedAlert({int threshold = 3});

  // ===========================================================================
  // Phase 9: User Profile Contract (users/{uid})
  // ===========================================================================

  /// Retrieves the current user profile from users/{uid}.
  Future<AppUser?> getUserProfile();

  /// Updates the user's profile information (name, phone) in users/{uid}.
  Future<void> updateUserProfile({String? name, String? phone});
}
