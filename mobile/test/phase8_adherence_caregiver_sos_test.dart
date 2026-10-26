import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/adherence_summary.dart';
import 'package:mobile/models/caregiver.dart';
import 'package:mobile/models/dose_occurrence.dart';
import 'package:mobile/repositories/in_memory_medicine_repository.dart';
import 'package:mobile/screens/caregiver/caregiver_screen.dart';
import 'package:mobile/screens/sos/sos_confirmation_screen.dart';

void main() {
  group('Phase 8 - Adherence Math & Formula Unit Tests', () {
    test('1. Normal case: Taken / (Taken + Skipped + Missed)', () {
      final occurrences = [
        DoseOccurrence(
          id: '1',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 8, 0),
          status: DoseStatus.taken,
        ),
        DoseOccurrence(
          id: '2',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 12, 0),
          status: DoseStatus.taken,
        ),
        DoseOccurrence(
          id: '3',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 16, 0),
          status: DoseStatus.skipped,
        ),
        DoseOccurrence(
          id: '4',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 20, 0),
          status: DoseStatus.missed,
        ),
        DoseOccurrence(
          id: '5',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 23, 0),
          status: DoseStatus.pending,
        ),
      ];

      final metrics = AdherenceCalculator.calculate(occurrences);
      expect(metrics.taken, equals(2));
      expect(metrics.skipped, equals(1));
      expect(metrics.missed, equals(1));
      expect(metrics.pending, equals(1));
      expect(metrics.eligible, equals(4)); // 2 taken + 1 skipped + 1 missed
      expect(metrics.totalScheduled, equals(5));
      // 2 / 4 = 50.0%
      expect(metrics.percentage, closeTo(50.0, 0.01));
      expect(metrics.roundedPercentage, equals(50));
    });

    test('2. Divide-by-zero protection: zero doses scheduled produces 0.0% without error', () {
      final metrics = AdherenceCalculator.calculate([]);
      expect(metrics.eligible, equals(0));
      expect(metrics.totalScheduled, equals(0));
      expect(metrics.percentage, equals(0.0));
    });

    test('3. Divide-by-zero protection: all doses pending (no doses due yet) returns 100.0%', () {
      final occurrences = [
        DoseOccurrence(
          id: '1',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 18, 0),
          status: DoseStatus.pending,
        ),
        DoseOccurrence(
          id: '2',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 22, 0),
          status: DoseStatus.pending,
        ),
      ];

      final metrics = AdherenceCalculator.calculate(occurrences);
      expect(metrics.eligible, equals(0));
      expect(metrics.pending, equals(2));
      expect(metrics.percentage, equals(100.0)); // 100% when no eligible past doses
    });

    test('4. Skipped doses count in denominator but NOT as taken', () {
      final occurrences = [
        DoseOccurrence(
          id: '1',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 8, 0),
          status: DoseStatus.skipped,
          skipReason: 'Felt dizzy',
        ),
      ];

      final metrics = AdherenceCalculator.calculate(occurrences);
      expect(metrics.taken, equals(0));
      expect(metrics.skipped, equals(1));
      expect(metrics.eligible, equals(1));
      expect(metrics.percentage, equals(0.0)); // 0 taken out of 1 eligible = 0%
    });

    test('5. 100% adherence when all eligible doses are taken', () {
      final occurrences = [
        DoseOccurrence(
          id: '1',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 8, 0),
          status: DoseStatus.taken,
        ),
        DoseOccurrence(
          id: '2',
          medicineId: 'm1',
          medicineName: 'A',
          dosage: '10mg',
          originalScheduledTime: DateTime(2026, 10, 26, 12, 0),
          status: DoseStatus.taken,
        ),
      ];

      final metrics = AdherenceCalculator.calculate(occurrences);
      expect(metrics.percentage, equals(100.0));
      expect(metrics.roundedPercentage, equals(100));
    });
  });

  group('Phase 8 - 3-Consecutive-Missed Rule & Streak Reset Tests', () {
    test('6. 3 consecutive missed occurrences in chronological order triggers escalation alert', () async {
      final base = DateTime(2026, 10, 26);
      final repo = InMemoryMedicineRepository(
        seedMedicines: [],
        seedOccurrences: [
          DoseOccurrence(
            id: '1',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 8)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '2',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 12)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '3',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 18)),
            status: DoseStatus.missed,
          ),
        ],
      );

      final streak = await repo.getConsecutiveMissedCount();
      expect(streak, equals(3));
      final shouldAlert = await repo.shouldTriggerConsecutiveMissedAlert();
      expect(shouldAlert, isTrue);
    });

    test('7. 2 consecutive misses does NOT trigger escalation alert', () async {
      final base = DateTime(2026, 10, 26);
      final repo = InMemoryMedicineRepository(
        seedMedicines: [],
        seedOccurrences: [
          DoseOccurrence(
            id: '1',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 8)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '2',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 12)),
            status: DoseStatus.missed,
          ),
        ],
      );

      final streak = await repo.getConsecutiveMissedCount();
      expect(streak, equals(2));
      final shouldAlert = await repo.shouldTriggerConsecutiveMissedAlert();
      expect(shouldAlert, isFalse);
    });

    test('8. Chronological streak reset: subsequent Taken dose resets streak to 0', () async {
      final base = DateTime(2026, 10, 26);
      final repo = InMemoryMedicineRepository(
        seedMedicines: [],
        seedOccurrences: [
          DoseOccurrence(
            id: '1',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 8)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '2',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 12)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '3',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 16)),
            status: DoseStatus.missed,
          ),
          // Dose 4 taken at 20:00 -> resets streak!
          DoseOccurrence(
            id: '4',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 20)),
            status: DoseStatus.taken,
          ),
        ],
      );

      final streak = await repo.getConsecutiveMissedCount();
      expect(streak, equals(0));
      final shouldAlert = await repo.shouldTriggerConsecutiveMissedAlert();
      expect(shouldAlert, isFalse);
    });

    test('9. Chronological streak reset: subsequent Skipped dose resets streak to 0', () async {
      final base = DateTime(2026, 10, 26);
      final repo = InMemoryMedicineRepository(
        seedMedicines: [],
        seedOccurrences: [
          DoseOccurrence(
            id: '1',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 8)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '2',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 12)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '3',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 16)),
            status: DoseStatus.missed,
          ),
          // Dose 4 skipped with reason at 20:00 -> resets streak!
          DoseOccurrence(
            id: '4',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 20)),
            status: DoseStatus.skipped,
            skipReason: 'Doctor advised pause',
          ),
        ],
      );

      final streak = await repo.getConsecutiveMissedCount();
      expect(streak, equals(0));
      final shouldAlert = await repo.shouldTriggerConsecutiveMissedAlert();
      expect(shouldAlert, isFalse);
    });

    test('10. Disabled escalation toggle suppresses alert even with 3 consecutive misses', () async {
      final base = DateTime(2026, 10, 26);
      final repo = InMemoryMedicineRepository(
        seedMedicines: [],
        seedCaregiver: CaregiverInfo.defaultCaregiver.copyWith(alertOnThreeMisses: false),
        seedOccurrences: [
          DoseOccurrence(
            id: '1',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 8)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '2',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 12)),
            status: DoseStatus.missed,
          ),
          DoseOccurrence(
            id: '3',
            medicineId: 'm1',
            medicineName: 'A',
            dosage: '10mg',
            originalScheduledTime: base.add(const Duration(hours: 18)),
            status: DoseStatus.missed,
          ),
        ],
      );

      final streak = await repo.getConsecutiveMissedCount();
      expect(streak, equals(3));
      final shouldAlert = await repo.shouldTriggerConsecutiveMissedAlert();
      expect(shouldAlert, isFalse); // Suppressed by caregiver preference
    });
  });

  group('Phase 8 - Caregiver Validation & Repository Storage Tests', () {
    test('11. Caregiver format validation rules: name, relationship, phone, email', () {
      // Name
      expect(CaregiverInfo.validateName(''), isNotNull);
      expect(CaregiverInfo.validateName('A'), isNotNull);
      expect(CaregiverInfo.validateName('Dr. Sarah Jenkins'), isNull);

      // Relationship
      expect(CaregiverInfo.validateRelationship(''), isNotNull);
      expect(CaregiverInfo.validateRelationship('Physician'), isNull);

      // Phone
      expect(CaregiverInfo.validatePhone(''), isNotNull);
      expect(CaregiverInfo.validatePhone('12345'), isNotNull); // < 7 digits
      expect(CaregiverInfo.validatePhone('+1 (555) 019-2834'), isNull);

      // Email
      expect(CaregiverInfo.validateEmail(''), isNotNull);
      expect(CaregiverInfo.validateEmail('invalid-email'), isNotNull);
      expect(CaregiverInfo.validateEmail('test@domain'), isNotNull);
      expect(CaregiverInfo.validateEmail('sarah@clinic.org'), isNull);
    });

    test('12. updateCaregiverInfo stores valid caregiver in repository and rejects invalid', () async {
      final repo = InMemoryMedicineRepository(seedMedicines: []);

      const valid = CaregiverInfo(
        name: 'Maria Rossi',
        relationship: 'Daughter',
        phone: '+1 (555) 987-6543',
        email: 'maria.rossi@example.com',
        alertOnThreeMisses: true,
      );

      final updated = await repo.updateCaregiverInfo(valid);
      expect(updated.name, equals('Maria Rossi'));
      expect(updated.relationship, equals('Daughter'));

      final fetched = await repo.getCaregiverInfo();
      expect(fetched.name, equals('Maria Rossi'));
      expect(fetched.phone, equals('+1 (555) 987-6543'));

      // Reject invalid
      expect(
        () => repo.updateCaregiverInfo(valid.copyWith(email: 'not-an-email')),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('13. CaregiverScreen renders form, updates details, and shows in-app demo alert', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = InMemoryMedicineRepository(seedMedicines: []);

      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Support'), findsOneWidget);
      expect(find.text('PRIMARY CAREGIVER DETAILS'), findsOneWidget);
      expect(find.text('Alert on 3 Consecutive Misses'), findsOneWidget);

      // Simulate 3-misses alert button
      await tester.tap(find.text('Simulate 3-Misses Alert (Demo)'));
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Escalation Alert'), findsOneWidget);
      expect(
        find.text('In-app demo alert. No SMS, call or email was sent.'),
        findsOneWidget,
      );

      // Dismiss simulation
      await tester.tap(find.text('Dismiss Simulation'));
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Escalation Alert'), findsNothing);
    });
  });

  group('Phase 8 - SOS Prototype & Feedback Tests', () {
    testWidgets('14. SosConfirmationDialog shows emergency contact, confirms demo, and never reports placed call', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testCaregiver = CaregiverInfo(
        name: 'Dr. Sarah Jenkins',
        relationship: 'Primary Care Physician',
        phone: '+1 (555) 019-2834',
        email: 'sarah.jenkins@clinic.org',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SosConfirmationDialog.show(ctx, caregiver: testCaregiver),
                child: const Text('Open SOS'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open SOS'));
      await tester.pumpAndSettle();

      // Verify contact and disclaimer
      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('DEMONSTRATION ONLY'), findsOneWidget);
      expect(find.text('Dr. Sarah Jenkins (Primary Care Physician)'), findsOneWidget);
      expect(find.text('+1 (555) 019-2834'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm (Demo)'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Emergency SOS'), findsNothing);

      // SnackBar shows prototype notice and NEVER reports a completed call
      expect(
        find.text('Prototype: no call was placed. In-app demo alert only.'),
        findsOneWidget,
      );
      expect(find.textContaining('Call completed'), findsNothing);
      expect(find.textContaining('Calling...'), findsNothing);
    });
  });
}
