import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/caregiver.dart';
import 'package:mobile/models/dose_occurrence.dart';
import 'package:mobile/models/medicine.dart';
import 'package:mobile/repositories/firestore_medicine_repository.dart';
import 'package:mobile/repositories/in_memory_medicine_repository.dart';
import 'package:mobile/repositories/medicine_repository.dart';
import 'package:mobile/repositories/repository_manager.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/in_memory_auth_service.dart';

/// Mock repository implementation simulating network failures and empty states for widget tests.
///
/// NOTE: Firebase is mocked for unit and widget testing in Section 18 / Phase 9 per rules.
class MockFailingMedicineRepository implements MedicineRepository {
  final bool shouldFail;
  final bool isOfflineError;
  final List<Medicine> medicinesToReturn;

  MockFailingMedicineRepository({
    this.shouldFail = false,
    this.isOfflineError = false,
    this.medicinesToReturn = const [],
  });

  @override
  Future<List<Medicine>> getMedicines({bool? activeOnly, bool? enabledOnly}) async {
    if (shouldFail) {
      if (isOfflineError) {
        throw Exception('FirebaseException: [cloud_firestore/unavailable] The service is currently offline.');
      }
      throw Exception('Simulated Firestore permission-denied error');
    }
    return medicinesToReturn;
  }

  @override
  Future<List<DoseOccurrence>> getOccurrences({DateTime? date, bool? todayOnly}) async => [];

  @override
  Future<int> reconcileMissedDoses({DateTime? currentTime}) async => 0;

  @override
  Future<Medicine?> getMedicineById(String id) async => null;

  @override
  Future<Medicine> addMedicine(Medicine medicine) async => medicine;

  @override
  Future<Medicine> updateMedicine(Medicine medicine) async => medicine;

  @override
  Future<bool> deleteMedicine(String id) async => true;

  @override
  Future<Medicine> toggleMedicineStatus(String id) async => throw UnimplementedError();

  @override
  Future<Medicine> toggleMedicineEnabled(String id, bool isEnabled) async => throw UnimplementedError();

  @override
  Future<void> resetToSampleData() async {}

  @override
  Future<DoseOccurrence?> getOccurrenceById(String id) async => null;

  @override
  Future<DoseOccurrence> getOrCreateOccurrenceForMedicine(Medicine medicine, {DateTime? date, int doseIndex = 0}) async =>
      throw UnimplementedError();

  @override
  Future<DoseOccurrence> recordDoseTaken(String occurrenceId, {DateTime? timestamp}) async => throw UnimplementedError();

  @override
  Future<DoseOccurrence> recordDoseSnooze(String occurrenceId, int minutes, {DateTime? timestamp}) async =>
      throw UnimplementedError();

  @override
  Future<DoseOccurrence> recordDoseSkipped(String occurrenceId, String reason, {DateTime? timestamp}) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, int>> getDoseSummaryStats({DateTime? date}) async => {
        'scheduled': 0,
        'taken': 0,
        'remaining': 0,
        'skipped': 0,
        'missed': 0,
      };

  @override
  Future<List<DoseOccurrence>> getHistoryOccurrences({DoseStatus? filterStatus}) async => [];

  @override
  Future<CaregiverInfo> getCaregiverInfo() async => CaregiverInfo.defaultCaregiver;

  @override
  Future<CaregiverInfo> updateCaregiverInfo(CaregiverInfo info) async => info;

  @override
  Future<int> getConsecutiveMissedCount() async => 0;

  @override
  Future<bool> shouldTriggerConsecutiveMissedAlert({int threshold = 3}) async => false;

  @override
  Future<AppUser?> getUserProfile() async => AppUser.demoUser;

  @override
  Future<void> updateUserProfile({String? name, String? phone}) async {}
}

void main() {
  setUp(() {
    AuthManager.reset();
    RepositoryManager.reset();
  });

  tearDown(() {
    AuthManager.reset();
    RepositoryManager.reset();
  });

  group('Phase 9 - Step 3: Deterministic DoseHistory ID Generation', () {
    test('1. Generates deterministic ID with format {userID}_{medicineId}_{scheduledTime}', () {
      final scheduled = DateTime(2026, 10, 26, 8, 30);
      final id = FirestoreMedicineRepository.buildDoseHistoryId(
        userId: 'user_abc123',
        medicineId: 'med_lisinopril_10',
        scheduledTime: scheduled,
      );

      expect(id, equals('user_abc123_med_lisinopril_10_20261026_0830'));
    });

    test('2. Identical parameters produce the EXACT same ID to prevent duplicate records', () {
      final scheduled = DateTime(2026, 10, 26, 14, 0);
      final id1 = FirestoreMedicineRepository.buildDoseHistoryId(
        userId: 'uid_test',
        medicineId: 'med_metformin',
        scheduledTime: scheduled,
      );
      final id2 = FirestoreMedicineRepository.buildDoseHistoryId(
        userId: 'uid_test',
        medicineId: 'med_metformin',
        scheduledTime: scheduled,
      );

      expect(id1, equals(id2));
    });

    test('3. Different times or different users generate distinct IDs', () {
      final t1 = DateTime(2026, 10, 26, 8, 0);
      final t2 = DateTime(2026, 10, 26, 20, 0);

      final idMorning = FirestoreMedicineRepository.buildDoseHistoryId(
        userId: 'user_1',
        medicineId: 'med_1',
        scheduledTime: t1,
      );
      final idEvening = FirestoreMedicineRepository.buildDoseHistoryId(
        userId: 'user_1',
        medicineId: 'med_1',
        scheduledTime: t2,
      );
      final idOtherUser = FirestoreMedicineRepository.buildDoseHistoryId(
        userId: 'user_2',
        medicineId: 'med_1',
        scheduledTime: t1,
      );

      expect(idMorning, isNot(equals(idEvening)));
      expect(idMorning, isNot(equals(idOtherUser)));
    });
  });

  group('Phase 9 - Step 3: Schema Conformance & Safe Defaults', () {
    test('4. medicines/{autoId}: Maps full model to Firestore document matching schema', () {
      final med = Medicine(
        id: 'med_123',
        name: 'Atorvastatin',
        dosage: '20mg',
        scheduledTime: '09:00 PM',
        scheduledTimes: ['09:00 PM'],
        status: MedicineStatus.pending,
        instructions: 'Take with evening meal',
        type: MedicineType.tablet,
        frequency: 'Once daily at night',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        isEnabled: true,
      );

      final map = FirestoreMedicineRepository.medicineToFirestoreMap(med, 'uid_456');

      expect(map['medicineName'], equals('Atorvastatin'));
      expect(map['dosage'], equals('20mg'));
      expect(map['time'], equals('09:00 PM'));
      expect(map['userID'], equals('uid_456'));
      expect(map['type'], equals('Tablet'));
      expect(map['instructions'], equals('Take with evening meal'));
      expect(map['notes'], equals('Take with evening meal'));
      expect(map['times'], equals(['09:00 PM']));
      expect(map['frequency'], equals('Once daily at night'));
      expect(map['isActive'], isTrue);
    });

    test('5. medicines/{autoId}: Decodes old legacy test documents with safe default fallbacks', () {
      // Old document containing only the legacy fields without optional additions
      final legacyDocData = <String, dynamic>{
        'medicineName': 'Amoxicillin',
        'dosage': '500mg',
        'time': '08:00 AM',
        'userID': 'uid_legacy',
      };

      final med = FirestoreMedicineRepository.medicineFromMap('auto_id_789', legacyDocData);

      expect(med.id, equals('auto_id_789'));
      expect(med.name, equals('Amoxicillin'));
      expect(med.dosage, equals('500mg'));
      expect(med.scheduledTime, equals('08:00 AM'));
      // Safe defaults
      expect(med.type, equals(MedicineType.tablet));
      expect(med.frequency, equals('Once daily'));
      expect(med.scheduledTimes, equals(['08:00 AM']));
      expect(med.isEnabled, isTrue);
      expect(med.instructions, isEmpty);
      expect(med.startDate, isNull);
      expect(med.endDate, isNull);
    });

    test('6. doseHistory/{id}: Maps occurrence to deterministic history document format', () {
      final scheduled = DateTime(2026, 10, 26, 8, 0);
      final actionTime = DateTime(2026, 10, 26, 8, 5);

      final occ = DoseOccurrence(
        id: 'doc_id',
        medicineId: 'med_001',
        medicineName: 'Metformin',
        dosage: '500mg',
        originalScheduledTime: scheduled,
        status: DoseStatus.taken,
        snoozeCount: 0,
        actionTimestamp: actionTime,
      );

      final map = FirestoreMedicineRepository.doseHistoryToFirestoreMap(occ, 'uid_abc');

      expect(map['userID'], equals('uid_abc'));
      expect(map['medicineId'], equals('med_001'));
      expect(map['medicineName'], equals('Metformin'));
      expect(map['dosage'], equals('500mg'));
      expect(map['status'], equals('taken'));
      expect(map['snoozeCount'], equals(0));
    });

    test('7. users/{uid}: Decodes user profile and caregiver mapping according to schema', () {
      final userDocData = <String, dynamic>{
        'email': 'sarah@example.com',
        'name': 'Sarah Connor',
        'phone': '+1 (555) 234-5678',
        'caregiver': {
          'name': 'John Connor',
          'relationship': 'Son',
          'phone': '+1 (555) 876-5432',
          'email': 'john@example.com',
        },
      };

      final user = AppUser.fromMap(
        uid: 'uid_sarah',
        data: userDocData,
      );

      expect(user.uid, equals('uid_sarah'));
      expect(user.email, equals('sarah@example.com'));
      expect(user.name, equals('Sarah Connor'));
      expect(user.phone, equals('+1 (555) 234-5678'));
      expect(user.caregiver, isNotNull);
      expect(user.caregiver!.name, equals('John Connor'));
      expect(user.caregiver!.relationship, equals('Son'));
      expect(user.caregiver!.phone, equals('+1 (555) 876-5432'));
      expect(user.caregiver!.email, equals('john@example.com'));
    });
  });

  group('Phase 9 - Step 3: RepositoryManager Switching & Demo Mode Isolation', () {
    test('8. Supplies InMemoryMedicineRepository when unauthenticated or in demo mode', () {
      AuthManager.setInstance(InMemoryAuthService());
      final repo = RepositoryManager.instance;

      expect(repo, isA<InMemoryMedicineRepository>());
    });

    test('9. Injects custom repository override for testing and resets cleanly', () {
      final mock = MockFailingMedicineRepository();
      RepositoryManager.setRepository(mock);

      expect(RepositoryManager.instance, same(mock));

      RepositoryManager.reset();
      expect(RepositoryManager.instance, isA<InMemoryMedicineRepository>());
    });
  });

  group('Phase 9 - Step 3: UI Loading, Empty, Offline & Error States', () {
    testWidgets('10. MainShell renders loading indicator while fetching medications', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final repo = InMemoryMedicineRepository.defaultInstance;
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(repository: repo),
        ),
      );

      // Immediately upon pump, _isLoading is true
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('11. MainShell displays connection error state with Try Again button when cloud fetch fails',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final mockRepo = MockFailingMedicineRepository(shouldFail: true);
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(repository: mockRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Error headline and retry button
      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('12. MainShell displays Offline Mode state when cloud service is unavailable', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final mockRepo = MockFailingMedicineRepository(shouldFail: true, isOfflineError: true);
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(repository: mockRepo),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('13. HomeScreen renders supportive empty state when medicine list is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final mockRepo = MockFailingMedicineRepository(medicinesToReturn: const []);
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(repository: mockRepo),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No medications scheduled for today.'), findsAtLeastNWidgets(1));
    });
  });
}
