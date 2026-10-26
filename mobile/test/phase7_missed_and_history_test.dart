import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/dose_occurrence.dart';
import 'package:mobile/models/medicine.dart';
import 'package:mobile/repositories/in_memory_medicine_repository.dart';
import 'package:mobile/screens/history/history_screen.dart';

void main() {
  group('Phase 7 - Missed Dose Policy & Reconciliation Unit Tests', () {
    late InMemoryMedicineRepository repository;
    final scheduledBase = DateTime(2026, 10, 26, 8, 0);

    setUp(() {
      final med = const Medicine(
        id: 'med_test_1',
        name: 'Metformin',
        dosage: '500 mg',
        scheduledTime: '08:00 AM',
        status: MedicineStatus.pending,
      );

      final occPending = DoseOccurrence(
        id: 'occ_pending_1',
        medicineId: 'med_test_1',
        medicineName: 'Metformin',
        dosage: '500 mg',
        originalScheduledTime: scheduledBase,
        effectiveScheduledTime: scheduledBase,
        status: DoseStatus.pending,
      );

      repository = InMemoryMedicineRepository(
        seedMedicines: [med],
        seedOccurrences: [occPending],
      );
    });

    test('1. Dose is NEVER Missed when it first appears (within 60m grace period)', () async {
      // 10 minutes past scheduled dose: should still be pending
      final currentTime = scheduledBase.add(const Duration(minutes: 10));
      final reconciled = await repository.reconcileMissedDoses(currentTime: currentTime);

      expect(reconciled, equals(0));
      final occ = await repository.getOccurrenceById('occ_pending_1');
      expect(occ?.status, equals(DoseStatus.pending));
      expect(occ?.isMissed, isFalse);
    });

    test('2. Reconciliation marks an unhandled dose Missed once after 60-min grace period', () async {
      // 61 minutes past scheduled dose
      final currentTime = scheduledBase.add(const Duration(minutes: 61));
      final reconciled = await repository.reconcileMissedDoses(currentTime: currentTime);

      expect(reconciled, equals(1));
      final occ = await repository.getOccurrenceById('occ_pending_1');
      expect(occ?.status, equals(DoseStatus.missed));
      expect(occ?.isMissed, isTrue);
      expect(occ?.actionTimestamp, equals(currentTime));
    });

    test('3. Repeated reconciliation on app resume is idempotent (never marks twice or duplicates)', () async {
      final currentTime = scheduledBase.add(const Duration(minutes: 70));
      // First resume / check
      final firstReconcile = await repository.reconcileMissedDoses(currentTime: currentTime);
      expect(firstReconcile, equals(1));

      // Second resume / check 10 minutes later
      final secondReconcile = await repository.reconcileMissedDoses(
        currentTime: currentTime.add(const Duration(minutes: 10)),
      );
      expect(secondReconcile, equals(0));

      final occ = await repository.getOccurrenceById('occ_pending_1');
      expect(occ?.status, equals(DoseStatus.missed));
      expect(occ?.actionTimestamp, equals(currentTime)); // Timestamp preserved from first reconcile
    });

    test('4. Snoozed occurrence deadline: 30 minutes after last snooze governed if later than 60m', () async {
      // Snooze dose at 8:45 AM for 15 minutes -> effective time is 9:00 AM
      final snoozeTime = scheduledBase.add(const Duration(minutes: 45));
      await repository.recordDoseSnooze('occ_pending_1', 15, timestamp: snoozeTime);

      // At 9:10 AM:
      // - 70 mins past 8:00 AM (> 60m), BUT only 10 mins past effective time (9:00 AM < 30m grace)
      // Must NOT be marked Missed yet!
      final check1 = await repository.reconcileMissedDoses(
        currentTime: scheduledBase.add(const Duration(minutes: 70)),
      );
      expect(check1, equals(0));
      var occ = await repository.getOccurrenceById('occ_pending_1');
      expect(occ?.status, equals(DoseStatus.snoozed));

      // At 9:31 AM: 31 mins past 9:00 AM -> deadline passed!
      final check2 = await repository.reconcileMissedDoses(
        currentTime: DateTime(2026, 10, 26, 9, 31),
      );
      expect(check2, equals(1));
      occ = await repository.getOccurrenceById('occ_pending_1');
      expect(occ?.status, equals(DoseStatus.missed));
    });

    test('5. TAKEN doses NEVER become Missed even if hours pass', () async {
      await repository.recordDoseTaken('occ_pending_1', timestamp: scheduledBase.add(const Duration(minutes: 5)));

      // Advance time by 12 hours
      final futureTime = scheduledBase.add(const Duration(hours: 12));
      final reconciled = await repository.reconcileMissedDoses(currentTime: futureTime);

      expect(reconciled, equals(0));
      final occ = await repository.getOccurrenceById('occ_pending_1');
      expect(occ?.status, equals(DoseStatus.taken));
      expect(occ?.isTaken, isTrue);
    });

    test('6. SKIPPED doses NEVER become Missed even if hours pass', () async {
      await repository.recordDoseSkipped(
        'occ_pending_1',
        'Side Effects',
        timestamp: scheduledBase.add(const Duration(minutes: 10)),
      );

      // Advance time by 24 hours
      final futureTime = scheduledBase.add(const Duration(hours: 24));
      final reconciled = await repository.reconcileMissedDoses(currentTime: futureTime);

      expect(reconciled, equals(0));
      final occ = await repository.getOccurrenceById('occ_pending_1');
      expect(occ?.status, equals(DoseStatus.skipped));
      expect(occ?.isSkipped, isTrue);
      expect(occ?.skipReason, equals('Side Effects'));
    });
  });

  group('Phase 7 - History Filtering & Ordering Tests', () {
    late InMemoryMedicineRepository repository;

    final occTaken = DoseOccurrence(
      id: 'occ_taken',
      medicineId: 'med_1',
      medicineName: 'Aspirin',
      dosage: '81 mg',
      originalScheduledTime: DateTime(2026, 10, 26, 8, 0),
      actionTimestamp: DateTime(2026, 10, 26, 8, 5),
      status: DoseStatus.taken,
    );
    final occSkipped = DoseOccurrence(
      id: 'occ_skipped',
      medicineId: 'med_2',
      medicineName: 'Lisinopril',
      dosage: '10 mg',
      originalScheduledTime: DateTime(2026, 10, 26, 12, 0),
      actionTimestamp: DateTime(2026, 10, 26, 12, 10),
      status: DoseStatus.skipped,
      skipReason: 'Felt dizzy',
    );
    final occMissed = DoseOccurrence(
      id: 'occ_missed',
      medicineId: 'med_3',
      medicineName: 'Metformin',
      dosage: '500 mg',
      originalScheduledTime: DateTime(2026, 10, 26, 18, 0),
      actionTimestamp: DateTime(2026, 10, 26, 19, 5),
      status: DoseStatus.missed,
    );

    setUp(() {
      repository = InMemoryMedicineRepository(
        seedMedicines: [],
        seedOccurrences: [occTaken, occSkipped, occMissed],
      );
    });

    test('7. History records are ordered newest first (descending by action/scheduled time)', () async {
      final all = await repository.getHistoryOccurrences();
      expect(all.length, equals(3));
      // occMissed (19:05) -> occSkipped (12:10) -> occTaken (08:05)
      expect(all[0].id, equals('occ_missed'));
      expect(all[1].id, equals('occ_skipped'));
      expect(all[2].id, equals('occ_taken'));
    });

    test('8. Filter by DoseStatus returns exact subsets', () async {
      final takenList = await repository.getHistoryOccurrences(filterStatus: DoseStatus.taken);
      expect(takenList.length, equals(1));
      expect(takenList.first.id, equals('occ_taken'));

      final skippedList = await repository.getHistoryOccurrences(filterStatus: DoseStatus.skipped);
      expect(skippedList.length, equals(1));
      expect(skippedList.first.id, equals('occ_skipped'));
      expect(skippedList.first.skipReason, equals('Felt dizzy'));

      final missedList = await repository.getHistoryOccurrences(filterStatus: DoseStatus.missed);
      expect(missedList.length, equals(1));
      expect(missedList.first.id, equals('occ_missed'));
    });
  });

  group('Phase 7 - HistoryScreen Widget & UI Tests', () {
    late InMemoryMedicineRepository repository;

    setUp(() {
      repository = InMemoryMedicineRepository(
        seedMedicines: [],
        seedOccurrences: [
          DoseOccurrence(
            id: 'occ_1',
            medicineId: 'med_1',
            medicineName: 'Atorvastatin',
            dosage: '20 mg',
            originalScheduledTime: DateTime(2026, 10, 26, 9, 0),
            actionTimestamp: DateTime(2026, 10, 26, 9, 2),
            status: DoseStatus.taken,
          ),
          DoseOccurrence(
            id: 'occ_2',
            medicineId: 'med_2',
            medicineName: 'Amoxicillin',
            dosage: '250 mg',
            originalScheduledTime: DateTime(2026, 10, 26, 13, 0),
            actionTimestamp: DateTime(2026, 10, 26, 13, 5),
            status: DoseStatus.skipped,
            skipReason: 'Nausea after meal',
          ),
        ],
      );
    });

    testWidgets('9. HistoryScreen renders filter chips and toggles views', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Verify filter chips exist
      expect(find.byKey(const ValueKey('filter_all')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_taken')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_skipped')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_missed')), findsOneWidget);

      // Verify All view shows both Atorvastatin and Amoxicillin
      expect(find.text('Atorvastatin'), findsOneWidget);
      expect(find.text('Amoxicillin'), findsOneWidget);
      expect(find.text('Reason: Nausea after meal'), findsOneWidget);

      // Tap 'Taken' filter chip
      await tester.tap(find.byKey(const ValueKey('filter_taken')));
      await tester.pumpAndSettle();

      expect(find.text('Atorvastatin'), findsOneWidget);
      expect(find.text('Amoxicillin'), findsNothing);

      // Tap 'Missed' filter chip (0 items) -> should show supportive empty state
      await tester.tap(find.byKey(const ValueKey('filter_missed')));
      await tester.pumpAndSettle();

      expect(find.text('Atorvastatin'), findsNothing);
      expect(find.text('Amoxicillin'), findsNothing);
      expect(find.text('No Missed Doses!'), findsOneWidget);
      expect(
        find.textContaining('Great job staying on track with your routine'),
        findsOneWidget,
      );
    });
  });
}
