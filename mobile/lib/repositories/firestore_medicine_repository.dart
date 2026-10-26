import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/caregiver.dart';
import '../models/dose_occurrence.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import 'medicine_repository.dart';

/// Cloud Firestore implementation of [MedicineRepository].
///
/// Phase 9 Specifications:
/// - medicines/{autoId}: existing medicineName, dosage, time, userID (= Firebase Auth uid).
///   Optional additions: type, instructions, times, frequency, startDate, endDate, notes, isActive, createdAt, updatedAt.
///   Old documents without new fields load safely with defaults.
/// - users/{uid}: existing email, name. Optional: phone, caregiver map.
/// - doseHistory/{userID_medicineId_scheduledTime}: deterministic ID prevents duplicate actions/reconciliation.
///   Fields: userID, medicineId, medicineName, dosage, scheduledAt, status, actionAt, skipReason, snoozeCount.
/// - Every query strictly filters by userID == current uid.
class FirestoreMedicineRepository implements MedicineRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  FirestoreMedicineRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _userId => userId;

  CollectionReference<Map<String, dynamic>> get _medicinesRef =>
      _firestore.collection('medicines');

  CollectionReference<Map<String, dynamic>> get _doseHistoryRef =>
      _firestore.collection('doseHistory');

  DocumentReference<Map<String, dynamic>> get _userDocRef =>
      _firestore.collection('users').doc(userId);

  /// Generates a deterministic document ID for a dose occurrence.
  /// Format: ${userID}_${medicineId}_${scheduledTime}
  static String buildDoseHistoryId({
    required String userId,
    required String medicineId,
    required DateTime scheduledTime,
  }) {
    final y = scheduledTime.year.toString().padLeft(4, '0');
    final m = scheduledTime.month.toString().padLeft(2, '0');
    final d = scheduledTime.day.toString().padLeft(2, '0');
    final h = scheduledTime.hour.toString().padLeft(2, '0');
    final min = scheduledTime.minute.toString().padLeft(2, '0');
    return '${userId}_${medicineId}_$y$m${d}_$h$min';
  }

  // ===========================================================================
  // Medicines Management
  // ===========================================================================

  @override
  Future<List<Medicine>> getMedicines({
    bool? activeOnly,
    bool? enabledOnly,
  }) async {
    try {
      // Query STRICTLY filtered by userID == current uid
      Query<Map<String, dynamic>> query =
          _medicinesRef.where('userID', isEqualTo: _userId);

      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) => _medicineFromDoc(doc)).toList();

      Iterable<Medicine> result = list;
      if (enabledOnly == true) {
        result = result.where((m) => m.isEnabled);
      }
      if (activeOnly == true) {
        result = result.where((m) => m.isActive);
      }

      return result.toList();
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.getMedicines error: $e');
      rethrow;
    }
  }

  @override
  Future<Medicine?> getMedicineById(String id) async {
    try {
      final doc = await _medicinesRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      // Strict ownership check
      if (data['userID'] != _userId) return null;
      return _medicineFromDoc(doc);
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.getMedicineById error: $e');
      return null;
    }
  }

  @override
  Future<Medicine> addMedicine(Medicine medicine) async {
    _validateMedicine(medicine);

    try {
      final data = _medicineToMap(medicine);
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _medicinesRef.add(data);
      return medicine.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.addMedicine error: $e');
      rethrow;
    }
  }

  @override
  Future<Medicine> updateMedicine(Medicine medicine) async {
    _validateMedicine(medicine);

    try {
      final data = _medicineToMap(medicine);
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _medicinesRef.doc(medicine.id).set(data, SetOptions(merge: true));
      return medicine.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.updateMedicine error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteMedicine(String id) async {
    try {
      final doc = await _medicinesRef.doc(id).get();
      if (!doc.exists) return false;
      if (doc.data()?['userID'] != _userId) return false;

      await _medicinesRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.deleteMedicine error: $e');
      return false;
    }
  }

  @override
  Future<Medicine> toggleMedicineStatus(String id) async {
    final med = await getMedicineById(id);
    if (med == null) {
      throw MedicineValidationException('Medicine with ID "$id" not found.');
    }
    final newStatus =
        med.isTaken ? MedicineStatus.pending : MedicineStatus.taken;
    final updated = med.copyWith(status: newStatus);
    await updateMedicine(updated);
    return updated;
  }

  @override
  Future<Medicine> toggleMedicineEnabled(String id, bool isEnabled) async {
    final med = await getMedicineById(id);
    if (med == null) {
      throw MedicineValidationException('Medicine with ID "$id" not found.');
    }
    final updated = med.copyWith(isEnabled: isEnabled);
    await updateMedicine(updated);
    return updated;
  }

  @override
  Future<void> resetToSampleData() async {
    // Cloud Firestore does not reset test data destructively per rule:
    // "Never touch or delete the existing test documents."
    debugPrint('Firestore repository preserves cloud documents.');
  }

  // ===========================================================================
  // Dose Occurrences & History Management
  // ===========================================================================

  @override
  Future<List<DoseOccurrence>> getOccurrences({
    DateTime? date,
    bool? todayOnly,
  }) async {
    final targetDate = date ?? DateTime.now();
    final medicines = await getMedicines(enabledOnly: true);

    // Fetch existing doseHistory records for this user
    final historyMap = await _fetchDoseHistoryMapForDate(targetDate);

    final List<DoseOccurrence> result = [];

    for (final med in medicines) {
      if (!med.isActive) continue;
      final times = med.effectiveTimes;
      for (var i = 0; i < times.length; i++) {
        final baseOcc = DoseOccurrence.fromMedicine(
          medicine: med,
          date: targetDate,
          timeStr: times[i],
          doseIndex: i,
        );

        final docId = buildDoseHistoryId(
          userId: _userId,
          medicineId: med.id,
          scheduledTime: baseOcc.originalScheduledTime,
        );

        final recorded = historyMap[docId];
        if (recorded != null) {
          result.add(recorded);
        } else {
          result.add(baseOcc.copyWith(id: docId));
        }
      }
    }

    return result;
  }

  @override
  Future<DoseOccurrence?> getOccurrenceById(String id) async {
    try {
      final doc = await _doseHistoryRef.doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['userID'] == _userId) {
          return _occurrenceFromDoc(doc);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<DoseOccurrence> getOrCreateOccurrenceForMedicine(
    Medicine medicine, {
    DateTime? date,
    int doseIndex = 0,
  }) async {
    final targetDate = date ?? DateTime.now();
    final times = medicine.effectiveTimes;
    final timeStr = doseIndex < times.length ? times[doseIndex] : medicine.scheduledTime;

    final base = DoseOccurrence.fromMedicine(
      medicine: medicine,
      date: targetDate,
      timeStr: timeStr,
      doseIndex: doseIndex,
    );

    final docId = buildDoseHistoryId(
      userId: _userId,
      medicineId: medicine.id,
      scheduledTime: base.originalScheduledTime,
    );

    final existing = await getOccurrenceById(docId);
    if (existing != null) return existing;

    return base.copyWith(id: docId);
  }

  @override
  Future<DoseOccurrence> recordDoseTaken(
    String occurrenceId, {
    DateTime? timestamp,
  }) async {
    final occ = await _resolveOccurrence(occurrenceId);
    if (occ.isTaken) {
      throw DoseOccurrenceException(
        'Dose for "${occ.medicineName}" has already been marked as Taken.',
      );
    }
    if (occ.isSkipped) {
      throw DoseOccurrenceException(
        'Dose for "${occ.medicineName}" was already recorded as Skipped and cannot be marked as Taken.',
      );
    }

    final actionTime = timestamp ?? DateTime.now();
    final updated = occ.copyWith(
      status: DoseStatus.taken,
      actionTimestamp: actionTime,
    );

    // Save deterministically to doseHistory
    await _saveDoseHistoryDoc(updated);

    // Cancel remaining notifications for this dose
    try {
      final notifId = NotificationService.getNotificationId(occ.medicineId, 0);
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
    if (minutes != 5 && minutes != 10 && minutes != 15) {
      throw const DoseOccurrenceException(
        'Invalid snooze duration. Please choose 5, 10, or 15 minutes.',
      );
    }

    final occ = await _resolveOccurrence(occurrenceId);
    if (occ.isFinalized) {
      throw DoseOccurrenceException(
        'Cannot snooze a dose for "${occ.medicineName}" that has already been ${occ.status.label.toLowerCase()}.',
      );
    }
    if (occ.snoozeCount >= 3) {
      throw DoseOccurrenceException(
        'Maximum snooze limit (3 times) reached for "${occ.medicineName}". Cannot snooze further.',
      );
    }

    final now = timestamp ?? DateTime.now();
    final newEffectiveTime = now.add(Duration(minutes: minutes));
    final updated = occ.copyWith(
      status: DoseStatus.snoozed,
      snoozeCount: occ.snoozeCount + 1,
      effectiveScheduledTime: newEffectiveTime,
      actionTimestamp: now,
    );

    await _saveDoseHistoryDoc(updated);

    // Reschedule local reminder alert
    try {
      final notifId = NotificationService.getNotificationId(occ.medicineId, 0);
      await NotificationService().cancelById(notifId);
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
    if (reason.trim().isEmpty) {
      throw const DoseOccurrenceException(
        'Please specify a valid reason for skipping this dose.',
      );
    }

    final occ = await _resolveOccurrence(occurrenceId);
    if (occ.isSkipped) {
      throw DoseOccurrenceException(
        'Dose for "${occ.medicineName}" has already been recorded as Skipped.',
      );
    }
    if (occ.isTaken) {
      throw DoseOccurrenceException(
        'Dose for "${occ.medicineName}" was already Taken and cannot be Skipped.',
      );
    }

    final now = timestamp ?? DateTime.now();
    final updated = occ.copyWith(
      status: DoseStatus.skipped,
      skipReason: reason.trim(),
      actionTimestamp: now,
    );

    await _saveDoseHistoryDoc(updated);

    try {
      final notifId = NotificationService.getNotificationId(occ.medicineId, 0);
      await NotificationService().cancelById(notifId);
    } catch (_) {}

    return updated;
  }

  @override
  Future<Map<String, int>> getDoseSummaryStats({DateTime? date}) async {
    final occurrences = await getOccurrences(date: date);
    final scheduled = occurrences.length;
    final taken = occurrences.where((o) => o.isTaken).length;
    final remaining = occurrences.where((o) => o.isPending || o.isSnoozed).length;
    final skipped = occurrences.where((o) => o.isSkipped).length;
    final missed = occurrences.where((o) => o.isMissed).length;

    return {
      'scheduled': scheduled,
      'taken': taken,
      'remaining': remaining,
      'skipped': skipped,
      'missed': missed,
    };
  }

  @override
  Future<int> reconcileMissedDoses({DateTime? currentTime}) async {
    final now = currentTime ?? DateTime.now();
    final occurrences = await getOccurrences(date: now);
    int reconciled = 0;

    for (final occ in occurrences) {
      if (occ.isFinalized) continue;

      if (occ.isEligibleForMissed(now)) {
        final updated = occ.copyWith(
          status: DoseStatus.missed,
          actionTimestamp: now,
        );
        await _saveDoseHistoryDoc(updated);
        reconciled++;
      }
    }

    return reconciled;
  }

  @override
  Future<List<DoseOccurrence>> getHistoryOccurrences({
    DoseStatus? filterStatus,
  }) async {
    try {
      final snapshot = await _doseHistoryRef
          .where('userID', isEqualTo: _userId)
          .get();

      var list = snapshot.docs.map((d) => _occurrenceFromDoc(d)).toList();

      if (filterStatus != null) {
        list = list.where((o) => o.status == filterStatus).toList();
      }

      // Sort newest first: descending by actionTimestamp (or originalScheduledTime)
      list.sort((a, b) {
        final aTime = a.actionTimestamp ?? a.originalScheduledTime;
        final bTime = b.actionTimestamp ?? b.originalScheduledTime;
        return bTime.compareTo(aTime);
      });

      return list;
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.getHistoryOccurrences error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Profile & Caregiver Management (users/{uid})
  // ===========================================================================

  @override
  Future<CaregiverInfo> getCaregiverInfo() async {
    try {
      final doc = await _userDocRef.get();
      if (doc.exists && doc.data() != null) {
        final raw = doc.data()!['caregiver'];
        if (raw is Map) {
          return CaregiverInfo(
            name: raw['name'] as String? ?? '',
            relationship: raw['relationship'] as String? ?? '',
            phone: raw['phone'] as String? ?? '',
            email: raw['email'] as String? ?? '',
            alertOnThreeMisses: raw['alertOnThreeMisses'] as bool? ?? true,
          );
        }
      }
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.getCaregiverInfo error: $e');
    }
    return CaregiverInfo.defaultCaregiver;
  }

  @override
  Future<CaregiverInfo> updateCaregiverInfo(CaregiverInfo info) async {
    final nameErr = CaregiverInfo.validateName(info.name);
    if (nameErr != null) throw ArgumentError(nameErr);

    final relErr = CaregiverInfo.validateRelationship(info.relationship);
    if (relErr != null) throw ArgumentError(relErr);

    final phoneErr = CaregiverInfo.validatePhone(info.phone);
    if (phoneErr != null) throw ArgumentError(phoneErr);

    final emailErr = CaregiverInfo.validateEmail(info.email);
    if (emailErr != null) throw ArgumentError(emailErr);

    try {
      await _userDocRef.set({
        'caregiver': {
          'name': info.name.trim(),
          'relationship': info.relationship.trim(),
          'phone': info.phone.trim(),
          'email': info.email.trim(),
          'alertOnThreeMisses': info.alertOnThreeMisses,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return info;
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.updateCaregiverInfo error: $e');
      rethrow;
    }
  }

  @override
  Future<int> getConsecutiveMissedCount() async {
    try {
      final snapshot = await _doseHistoryRef
          .where('userID', isEqualTo: _userId)
          .get();

      final list = snapshot.docs.map((d) => _occurrenceFromDoc(d)).toList();
      // Sort chronologically (earliest scheduled dose first)
      list.sort((a, b) => a.originalScheduledTime.compareTo(b.originalScheduledTime));

      int streak = 0;
      for (final occ in list) {
        if (occ.isMissed) {
          streak++;
        } else if (occ.isTaken || occ.isSkipped) {
          streak = 0; // Streak strictly resets on Taken or Skipped
        }
      }
      return streak;
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.getConsecutiveMissedCount error: $e');
      return 0;
    }
  }

  @override
  Future<bool> shouldTriggerConsecutiveMissedAlert({int threshold = 3}) async {
    final streak = await getConsecutiveMissedCount();
    final info = await getCaregiverInfo();
    return streak >= threshold && info.alertOnThreeMisses;
  }

  // ===========================================================================
  // Phase 9: User Profile Management (users/{uid})
  // ===========================================================================

  @override
  Future<AppUser?> getUserProfile() async {
    try {
      final doc = await _userDocRef.get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(
          uid: _userId,
          data: doc.data()!,
          isDemoUser: false,
        );
      }
    } catch (e) {
      debugPrint('FirestoreMedicineRepository.getUserProfile error: $e');
    }
    return null;
  }

  @override
  Future<void> updateUserProfile({String? name, String? phone}) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (phone != null) 'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (updates.isNotEmpty) {
      await _userDocRef.set(updates, SetOptions(merge: true));
    }
  }

  // ===========================================================================
  // Internal Helpers & Serialization (Schema Conformance)
  // ===========================================================================

  void _validateMedicine(Medicine medicine) {
    final nameError = Medicine.validateName(medicine.name);
    if (nameError != null) throw MedicineValidationException(nameError);

    final dosageError = Medicine.validateDosage(medicine.dosage);
    if (dosageError != null) throw MedicineValidationException(dosageError);

    final dateError = Medicine.validateDateRange(medicine.startDate, medicine.endDate);
    if (dateError != null) throw MedicineValidationException(dateError);
  }

  /// Maps a [Medicine] to Firestore document format conforming strictly to schema:
  /// - medicines/{autoId}: existing medicineName, dosage, time, userID
  /// - optional additions: type, instructions, times, frequency, startDate, endDate, notes, isActive, updatedAt
  Map<String, dynamic> _medicineToMap(Medicine m) =>
      medicineToFirestoreMap(m, _userId);

  Medicine _medicineFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      medicineFromMap(doc.id, doc.data() ?? {});

  /// Public static mapper for schema serialization testing.
  static Map<String, dynamic> medicineToFirestoreMap(Medicine m, String userId) {
    return {
      'medicineName': m.name,
      'dosage': m.dosage,
      'time': m.scheduledTime,
      'userID': userId,
      'type': m.type.label,
      'instructions': m.instructions,
      'notes': m.instructions,
      'times': m.effectiveTimes,
      'frequency': m.frequency,
      'startDate': m.startDate != null ? Timestamp.fromDate(m.startDate!) : null,
      'endDate': m.endDate != null ? Timestamp.fromDate(m.endDate!) : null,
      'isActive': m.isEnabled,
    };
  }

  /// Safely decodes a map from medicines collection.
  /// Backward compatible: old documents with missing optional fields load with safe defaults.
  static Medicine medicineFromMap(String id, Map<String, dynamic> data) {
    // Existing fields with fallback compatibility
    final name = (data['medicineName'] ?? data['name'] ?? 'Medication').toString();
    final dosage = (data['dosage'] ?? '').toString();
    final time = (data['time'] ?? data['scheduledTime'] ?? '08:00 AM').toString();

    // Optional fields with safe fallbacks
    final typeStr = data['type']?.toString() ?? 'Tablet';
    final type = MedicineType.fromString(typeStr);

    final instructions = (data['instructions'] ?? data['notes'] ?? '').toString();

    List<String> times = [];
    if (data['times'] is List) {
      times = (data['times'] as List).map((e) => e.toString()).toList();
    }
    if (times.isEmpty) times = [time];

    final frequency = (data['frequency'] ?? 'Once daily').toString();

    DateTime? startDate;
    if (data['startDate'] is Timestamp) {
      startDate = (data['startDate'] as Timestamp).toDate();
    } else if (data['startDate'] is String) {
      startDate = DateTime.tryParse(data['startDate'] as String);
    }

    DateTime? endDate;
    if (data['endDate'] is Timestamp) {
      endDate = (data['endDate'] as Timestamp).toDate();
    } else if (data['endDate'] is String) {
      endDate = DateTime.tryParse(data['endDate'] as String);
    }

    final isEnabled = data['isActive'] as bool? ?? data['isEnabled'] as bool? ?? true;

    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime? updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    return Medicine(
      id: id,
      name: name,
      dosage: dosage,
      scheduledTime: time,
      scheduledTimes: times,
      status: MedicineStatus.pending,
      instructions: instructions,
      type: type,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      isEnabled: isEnabled,
      isSampleData: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Resolves an occurrence by ID or creates a fallback if not yet in doseHistory.
  Future<DoseOccurrence> _resolveOccurrence(String occurrenceId) async {
    final existing = await getOccurrenceById(occurrenceId);
    if (existing != null) return existing;

    // Search through today's generated occurrences
    final occurrences = await getOccurrences();
    for (final occ in occurrences) {
      if (occ.id == occurrenceId) return occ;
    }

    throw DoseOccurrenceException(
      'Dose occurrence with ID "$occurrenceId" not found.',
    );
  }

  /// Writes or merges a [DoseOccurrence] into the deterministic `doseHistory` document.
  /// Schema: userID, medicineId, medicineName, dosage, scheduledAt, status, actionAt, skipReason, snoozeCount.
  Future<void> _saveDoseHistoryDoc(DoseOccurrence occ) async {
    final docId = occ.id.startsWith('${_userId}_')
        ? occ.id
        : buildDoseHistoryId(
            userId: _userId,
            medicineId: occ.medicineId,
            scheduledTime: occ.originalScheduledTime,
          );

    final data = doseHistoryToFirestoreMap(occ, _userId);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _doseHistoryRef.doc(docId).set(data, SetOptions(merge: true));
  }

  /// Fetches a map of existing doseHistory documents for a given date.
  Future<Map<String, DoseOccurrence>> _fetchDoseHistoryMapForDate(
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      // Query strictly filtered by userID == current uid
      // In-memory date filter ensures zero composite index dependency
      final snapshot = await _doseHistoryRef
          .where('userID', isEqualTo: _userId)
          .get();

      final Map<String, DoseOccurrence> map = {};
      for (final doc in snapshot.docs) {
        final occ = _occurrenceFromDoc(doc);
        final sched = occ.originalScheduledTime;
        if (sched.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
            sched.isBefore(endOfDay.add(const Duration(milliseconds: 1)))) {
          map[doc.id] = occ;
        }
      }
      return map;
    } catch (e) {
      debugPrint('FirestoreMedicineRepository._fetchDoseHistoryMap error: $e');
      return {};
    }
  }

  /// Decodes a [DocumentSnapshot] from `doseHistory` collection into a [DoseOccurrence].
  DoseOccurrence _occurrenceFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      doseHistoryFromMap(doc.id, doc.data() ?? {});

  /// Public static mapper for doseHistory serialization testing.
  static Map<String, dynamic> doseHistoryToFirestoreMap(
    DoseOccurrence occ,
    String userId,
  ) {
    return <String, dynamic>{
      'userID': userId,
      'medicineId': occ.medicineId,
      'medicineName': occ.medicineName,
      'dosage': occ.dosage,
      'scheduledAt': Timestamp.fromDate(occ.originalScheduledTime),
      'status': occ.status.name,
      'snoozeCount': occ.snoozeCount,
      if (occ.actionTimestamp != null)
        'actionAt': Timestamp.fromDate(occ.actionTimestamp!),
      if (occ.effectiveScheduledTime != null)
        'effectiveScheduledAt': Timestamp.fromDate(occ.effectiveScheduledTime!),
      if (occ.skipReason != null && occ.skipReason!.isNotEmpty)
        'skipReason': occ.skipReason,
    };
  }

  /// Safely decodes a map from `doseHistory` collection into a [DoseOccurrence].
  static DoseOccurrence doseHistoryFromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final medicineId = (data['medicineId'] ?? '').toString();
    final medicineName = (data['medicineName'] ?? 'Medication').toString();
    final dosage = (data['dosage'] ?? '').toString();

    DateTime scheduledAt = DateTime.now();
    if (data['scheduledAt'] is Timestamp) {
      scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
    } else if (data['scheduledAt'] is String) {
      scheduledAt = DateTime.tryParse(data['scheduledAt'] as String) ?? DateTime.now();
    }

    DateTime? actionAt;
    if (data['actionAt'] is Timestamp) {
      actionAt = (data['actionAt'] as Timestamp).toDate();
    } else if (data['actionAt'] is String) {
      actionAt = DateTime.tryParse(data['actionAt'] as String);
    }

    DateTime? effectiveScheduledAt;
    if (data['effectiveScheduledAt'] is Timestamp) {
      effectiveScheduledAt = (data['effectiveScheduledAt'] as Timestamp).toDate();
    } else if (data['effectiveScheduledAt'] is String) {
      effectiveScheduledAt = DateTime.tryParse(data['effectiveScheduledAt'] as String);
    }

    final statusStr = (data['status'] ?? 'pending').toString().toLowerCase();
    DoseStatus status = DoseStatus.pending;
    for (final s in DoseStatus.values) {
      if (s.name.toLowerCase() == statusStr) {
        status = s;
        break;
      }
    }

    final snoozeCount = (data['snoozeCount'] as num?)?.toInt() ?? 0;
    final skipReason = data['skipReason']?.toString();

    return DoseOccurrence(
      id: id,
      medicineId: medicineId,
      medicineName: medicineName,
      dosage: dosage,
      originalScheduledTime: scheduledAt,
      effectiveScheduledTime: effectiveScheduledAt ?? scheduledAt,
      status: status,
      snoozeCount: snoozeCount,
      actionTimestamp: actionAt,
      skipReason: skipReason,
      isSampleData: false,
    );
  }
}
