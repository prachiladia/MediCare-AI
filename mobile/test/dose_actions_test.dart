import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/dose_occurrence.dart';
import 'package:mobile/models/medicine.dart';
import 'package:mobile/repositories/in_memory_medicine_repository.dart';
import 'package:mobile/screens/reminder/medicine_reminder_screen.dart';

void main() {
  late InMemoryMedicineRepository repository;
  late Medicine testMedicine;
  late DoseOccurrence testOccurrence;

  setUp(() {
    testMedicine = const Medicine(
      id: 'med_test_1',
      name: 'Amoxicillin',
      dosage: '500 mg',
      scheduledTime: '08:00 AM',
      status: MedicineStatus.pending,
    );

    testOccurrence = DoseOccurrence(
      id: 'occ_test_1',
      medicineId: 'med_test_1',
      medicineName: 'Amoxicillin',
      dosage: '500 mg',
      originalScheduledTime: DateTime(2026, 10, 26, 8, 0),
      effectiveScheduledTime: DateTime(2026, 10, 26, 8, 0),
      status: DoseStatus.pending,
      snoozeCount: 0,
    );

    repository = InMemoryMedicineRepository(
      seedMedicines: [testMedicine],
      seedOccurrences: [testOccurrence],
    );
  });

  group('Phase 6 - TAKEN Action Unit Tests', () {
    test('1. Record dose Taken records timestamp and updates status', () async {
      final now = DateTime(2026, 10, 26, 8, 5);
      final updated = await repository.recordDoseTaken('occ_test_1', timestamp: now);

      expect(updated.status, equals(DoseStatus.taken));
      expect(updated.isTaken, isTrue);
      expect(updated.actionTimestamp, equals(now));

      // Verify repository persistence
      final fetched = await repository.getOccurrenceById('occ_test_1');
      expect(fetched?.isTaken, isTrue);
    });

    test('2. Repeated Taken taps are rejected to prevent duplicate records', () async {
      await repository.recordDoseTaken('occ_test_1');

      // Second attempt must throw DoseOccurrenceException
      expect(
        () => repository.recordDoseTaken('occ_test_1'),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('already been marked as Taken'),
          ),
        ),
      );
    });

    test('3. Taken-after-Skipped case: cannot mark Taken when already Skipped', () async {
      await repository.recordDoseSkipped('occ_test_1', 'Side Effects');

      expect(
        () => repository.recordDoseTaken('occ_test_1'),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('already recorded as Skipped and cannot be marked as Taken'),
          ),
        ),
      );
    });
  });

  group('Phase 6 - SNOOZE Action Unit Tests', () {
    test('4. Snooze allows 5, 10, 15 minutes, increments count, and NEVER marks dose Taken', () async {
      final baseTime = DateTime(2026, 10, 26, 8, 0);

      // Snooze 1: 5 minutes
      final s1 = await repository.recordDoseSnooze('occ_test_1', 5, timestamp: baseTime);
      expect(s1.snoozeCount, equals(1));
      expect(s1.status, equals(DoseStatus.snoozed));
      expect(s1.isTaken, isFalse);
      expect(s1.originalScheduledTime, equals(baseTime)); // Original time unchanged!
      expect(s1.effectiveScheduledTime, equals(baseTime.add(const Duration(minutes: 5))));

      // Snooze 2: 10 minutes
      final s2 = await repository.recordDoseSnooze('occ_test_1', 10, timestamp: baseTime.add(const Duration(minutes: 5)));
      expect(s2.snoozeCount, equals(2));
      expect(s2.status, equals(DoseStatus.snoozed));
      expect(s2.isTaken, isFalse);
      expect(s2.originalScheduledTime, equals(baseTime)); // Still preserved

      // Snooze 3: 15 minutes
      final s3 = await repository.recordDoseSnooze('occ_test_1', 15, timestamp: baseTime.add(const Duration(minutes: 15)));
      expect(s3.snoozeCount, equals(3));
      expect(s3.status, equals(DoseStatus.snoozed));
      expect(s3.isTaken, isFalse);
      expect(s3.originalScheduledTime, equals(baseTime)); // Still preserved
    });

    test('5. 3-Snooze limit: 4th snooze attempt is strictly rejected', () async {
      final baseTime = DateTime(2026, 10, 26, 8, 0);
      await repository.recordDoseSnooze('occ_test_1', 5, timestamp: baseTime);
      await repository.recordDoseSnooze('occ_test_1', 10, timestamp: baseTime);
      await repository.recordDoseSnooze('occ_test_1', 15, timestamp: baseTime);

      // 4th attempt must fail with 3-snooze limit exception
      expect(
        () => repository.recordDoseSnooze('occ_test_1', 5, timestamp: baseTime),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('Maximum snooze limit (3 times) reached'),
          ),
        ),
      );
    });

    test('6. Invalid snooze duration is rejected', () async {
      expect(
        () => repository.recordDoseSnooze('occ_test_1', 20),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('Allowed durations are 5, 10, or 15 minutes'),
          ),
        ),
      );
    });

    test('7. Completed dose cannot be snoozed', () async {
      await repository.recordDoseTaken('occ_test_1');
      expect(
        () => repository.recordDoseSnooze('occ_test_1', 5),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('Cannot snooze a completed dose'),
          ),
        ),
      );
    });
  });

  group('Phase 6 - SKIP Action Unit Tests', () {
    test('8. Skip records reason, timestamp, and preserves original scheduled time', () async {
      final skipTime = DateTime(2026, 10, 26, 8, 12);
      final skipped = await repository.recordDoseSkipped(
        'occ_test_1',
        'Doctor Advised to Skip',
        timestamp: skipTime,
      );

      expect(skipped.status, equals(DoseStatus.skipped));
      expect(skipped.isSkipped, isTrue);
      expect(skipped.skipReason, equals('Doctor Advised to Skip'));
      expect(skipped.actionTimestamp, equals(skipTime));
      expect(skipped.originalScheduledTime, equals(DateTime(2026, 10, 26, 8, 0)));
    });

    test('9. Duplicate Skip: cannot skip already skipped dose', () async {
      await repository.recordDoseSkipped('occ_test_1', 'Side Effects');

      expect(
        () => repository.recordDoseSkipped('occ_test_1', 'Forgot'),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('already been recorded as Skipped'),
          ),
        ),
      );
    });

    test('10. Taken dose cannot be skipped', () async {
      await repository.recordDoseTaken('occ_test_1');

      expect(
        () => repository.recordDoseSkipped('occ_test_1', 'Side Effects'),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('was already Taken and cannot be Skipped'),
          ),
        ),
      );
    });

    test('11. Empty skip reason is rejected', () async {
      expect(
        () => repository.recordDoseSkipped('occ_test_1', '   '),
        throwsA(
          isA<DoseOccurrenceException>().having(
            (e) => e.message,
            'message',
            contains('Please specify a valid reason'),
          ),
        ),
      );
    });
  });

  group('Phase 6 - Dashboard Counts from Occurrences', () {
    test('12. getDoseSummaryStats reflects real occurrence status breakdown', () async {
      final date = DateTime(2026, 10, 26);
      final statsInit = await repository.getDoseSummaryStats(date: date);
      expect(statsInit['scheduled'], equals(1));
      expect(statsInit['taken'], equals(0));
      expect(statsInit['remaining'], equals(1));
      expect(statsInit['skipped'], equals(0));

      await repository.recordDoseTaken('occ_test_1');
      final statsAfterTaken = await repository.getDoseSummaryStats(date: date);
      expect(statsAfterTaken['scheduled'], equals(1));
      expect(statsAfterTaken['taken'], equals(1));
      expect(statsAfterTaken['remaining'], equals(0));
      expect(statsAfterTaken['skipped'], equals(0));
    });
  });

  group('Phase 6 - MedicineReminderScreen Widget Tests', () {
    testWidgets('13. Renders reminder screen and disables Snooze button when snooze limit is reached',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final maxedOccurrence = testOccurrence.copyWith(
        snoozeCount: 3,
        status: DoseStatus.snoozed,
      );

      await tester.pumpWidget(MaterialApp(
        home: MedicineReminderScreen(
          medicine: testMedicine,
          occurrence: maxedOccurrence,
          repository: repository,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify original time and snooze badges are displayed
      expect(find.text('Scheduled for 08:00 AM'), findsOneWidget);
      expect(find.text('Snoozed 3/3 times'), findsOneWidget);

      // Verify Snooze button is disabled with limit label
      final snoozeButtonFinder = find.widgetWithText(OutlinedButton, 'Snooze (Limit 3/3)');
      expect(snoozeButtonFinder, findsOneWidget);
      final outlinedBtn = tester.widget<OutlinedButton>(snoozeButtonFinder);
      expect(outlinedBtn.onPressed, isNull); // Disabled!
    });

    testWidgets('14. Tapping Mark as Taken records dose and calls repository',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool takenCallbackCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: MedicineReminderScreen(
          medicine: testMedicine,
          occurrence: testOccurrence,
          repository: repository,
          onTaken: () => takenCallbackCalled = true,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Mark as Taken
      await tester.tap(find.text('Mark as Taken'));
      await tester.pumpAndSettle();

      expect(takenCallbackCalled, isTrue);
      final occ = await repository.getOccurrenceById('occ_test_1');
      expect(occ?.isTaken, isTrue);
    });
  });
}
