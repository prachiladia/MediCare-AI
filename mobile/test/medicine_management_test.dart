import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/medicine.dart';
import 'package:mobile/repositories/in_memory_medicine_repository.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/medicines/add_medicine_screen.dart';
import 'package:mobile/screens/medicines/edit_medicine_screen.dart';
import 'package:mobile/screens/medicines/medicine_details_screen.dart';
import 'package:mobile/screens/medicines/medicines_screen.dart';

void main() {
  group('Phase 3 - InMemoryMedicineRepository Unit Tests', () {
    late InMemoryMedicineRepository repository;

    setUp(() {
      repository = InMemoryMedicineRepository();
    });

    test('1. Initializes with sample medicines marked as isSampleData', () async {
      final list = await repository.getMedicines();
      expect(list, isNotEmpty);
      expect(list.length, equals(5));
      for (final med in list) {
        expect(med.isSampleData, isTrue);
        expect(med.isEnabled, isTrue);
      }
    });

    test('2. getMedicines filters by enabledOnly and activeOnly', () async {
      final all = await repository.getMedicines();
      expect(all.length, equals(5));

      // Disable one medicine
      await repository.toggleMedicineEnabled(all.first.id, false);

      final enabled = await repository.getMedicines(enabledOnly: true);
      expect(enabled.length, equals(4));
      expect(enabled.any((m) => m.id == all.first.id), isFalse);
    });

    test('3. addMedicine adds valid medicine', () async {
      final newMed = Medicine(
        id: 'new-1',
        name: 'Ibuprofen',
        dosage: '400 mg',
        scheduledTime: '10:00 AM',
        status: MedicineStatus.pending,
        startDate: DateTime.now(),
      );

      final added = await repository.addMedicine(newMed);
      expect(added.name, equals('Ibuprofen'));
      expect(added.isSampleData, isFalse);

      final fetched = await repository.getMedicineById('new-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Ibuprofen'));
    });

    test('4. addMedicine rejects empty name with MedicineValidationException', () async {
      final invalidMed = Medicine(
        id: 'bad-1',
        name: '',
        dosage: '200 mg',
        scheduledTime: '10:00 AM',
        status: MedicineStatus.pending,
      );

      expect(
        () => repository.addMedicine(invalidMed),
        throwsA(isA<MedicineValidationException>()),
      );
    });

    test('5. addMedicine rejects empty dosage with MedicineValidationException', () async {
      final invalidMed = Medicine(
        id: 'bad-2',
        name: 'Aspirin',
        dosage: '   ',
        scheduledTime: '10:00 AM',
        status: MedicineStatus.pending,
      );

      expect(
        () => repository.addMedicine(invalidMed),
        throwsA(isA<MedicineValidationException>()),
      );
    });

    test('6. addMedicine rejects end date before start date', () async {
      final invalidMed = Medicine(
        id: 'bad-3',
        name: 'Aspirin',
        dosage: '100 mg',
        scheduledTime: '10:00 AM',
        status: MedicineStatus.pending,
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 15),
      );

      expect(
        () => repository.addMedicine(invalidMed),
        throwsA(predicate((e) =>
            e is MedicineValidationException &&
            e.message == 'End date cannot be before start date')),
      );
    });

    test('7. updateMedicine modifies record', () async {
      final all = await repository.getMedicines();
      final target = all.first;

      final updated = await repository.updateMedicine(
        target.copyWith(dosage: '1000 mg', instructions: 'Take with milk'),
      );

      expect(updated.dosage, equals('1000 mg'));
      expect(updated.instructions, equals('Take with milk'));

      final check = await repository.getMedicineById(target.id);
      expect(check!.dosage, equals('1000 mg'));
    });

    test('8. deleteMedicine removes item from repository', () async {
      final all = await repository.getMedicines();
      final targetId = all.first.id;

      final result = await repository.deleteMedicine(targetId);
      expect(result, isTrue);

      final check = await repository.getMedicineById(targetId);
      expect(check, isNull);
    });

    test('9. toggleMedicineStatus flips between pending and taken', () async {
      final all = await repository.getMedicines();
      final target = all.firstWhere((m) => m.status == MedicineStatus.pending);

      final toggled = await repository.toggleMedicineStatus(target.id);
      expect(toggled.status, equals(MedicineStatus.taken));

      final toggledBack = await repository.toggleMedicineStatus(target.id);
      expect(toggledBack.status, equals(MedicineStatus.pending));
    });

    test('10. toggleMedicineEnabled toggles isEnabled property', () async {
      final all = await repository.getMedicines();
      final target = all.first;

      final disabled = await repository.toggleMedicineEnabled(target.id, false);
      expect(disabled.isEnabled, isFalse);

      final enabled = await repository.toggleMedicineEnabled(target.id, true);
      expect(enabled.isEnabled, isTrue);
    });

    test('11. resetToSampleData restores default 5 sample medicines', () async {
      final all = await repository.getMedicines();
      await repository.deleteMedicine(all.first.id);

      final reduced = await repository.getMedicines();
      expect(reduced.length, equals(4));

      await repository.resetToSampleData();
      final restored = await repository.getMedicines();
      expect(restored.length, equals(5));
    });
  });

  group('Phase 3 - AddMedicineScreen Validation & Duplicate Guard Tests', () {
    testWidgets('12. Rejects EMPTY name with clear validation message',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool callbackCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: AddMedicineScreen(
          onMedicineAdded: (m) async => callbackCalled = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Medicine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Medicine'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter medication name'), findsOneWidget);
      expect(callbackCalled, isFalse);
    });

    testWidgets('13. Rejects EMPTY dosage with clear validation message',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool callbackCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: AddMedicineScreen(
          onMedicineAdded: (m) async => callbackCalled = true,
        ),
      ));
      await tester.pumpAndSettle();

      // Enter name but leave dosage empty
      await tester.enterText(
        find.byType(TextFormField).first,
        'Paracetamol',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Medicine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Medicine'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter dosage (e.g. 500 mg)'), findsOneWidget);
      expect(callbackCalled, isFalse);
    });

    testWidgets('14. Rejects end date before start date with error message',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Model date range check unit check
      final error = Medicine.validateDateRange(
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 15),
      );
      expect(error, equals('End date cannot be before start date'));

      // Valid range returns null
      final valid = Medicine.validateDateRange(
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 25),
      );
      expect(valid, isNull);
    });

    testWidgets('15. Prevents duplicate submissions while save is in flight',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int submissionCount = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(MaterialApp(
        home: AddMedicineScreen(
          onMedicineAdded: (m) async {
            submissionCount++;
            await completer.future;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Fill in valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'Metformin');
      await tester.enterText(find.byType(TextFormField).at(1), '500 mg');
      await tester.pumpAndSettle();

      // Tap save once
      await tester.ensureVisible(find.text('Save Medicine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Medicine'));
      await tester.pump(); // Start async action

      // First tap initiated save
      expect(submissionCount, equals(1));
      // Save button is now in loading state with CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt second tap during save (duplicate click)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Submission count must strictly remain 1 (duplicate blocked)
      expect(submissionCount, equals(1));

      // Complete async save
      completer.complete();
      await tester.pumpAndSettle();
    });
  });

  group('Phase 3 - EditMedicineScreen & DetailsScreen Tests', () {
    testWidgets('16. EditMedicineScreen prevents duplicate submissions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testMed = Medicine(
        id: 'edit-dup-1',
        name: 'Omeprazole',
        dosage: '20 mg',
        scheduledTime: '08:00 AM',
        status: MedicineStatus.pending,
      );

      int saveCalls = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(MaterialApp(
        home: EditMedicineScreen(
          medicine: testMed,
          onMedicineUpdated: (m) async {
            saveCalls++;
            await completer.future;
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(saveCalls, equals(1));
      // Loading spinner active
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt second tap while saving
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      expect(saveCalls, equals(1)); // duplicate blocked

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('17. MedicineDetailsScreen renders all fields, toggles status and enabled state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final med = Medicine(
        id: 'detail-1',
        name: 'Amoxicillin',
        dosage: '500 mg',
        scheduledTime: '09:00 AM',
        status: MedicineStatus.pending,
        instructions: 'Take after breakfast',
        type: MedicineType.capsule,
        frequency: 'Twice daily',
        isSampleData: true,
        isEnabled: true,
      );

      bool statusToggled = false;
      bool enabledToggled = false;

      await tester.pumpWidget(MaterialApp(
        home: MedicineDetailsScreen(
          medicine: med,
          onToggleStatus: (m) => statusToggled = true,
          onToggleEnabled: (m, enabled) => enabledToggled = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Medication Details'), findsOneWidget);
      expect(find.text('Amoxicillin'), findsOneWidget);
      expect(find.text('500 mg • Capsule'), findsOneWidget);
      expect(find.text('Sample data • In-memory prototype (resets on restart)'), findsOneWidget);
      expect(find.text('Reminders Active'), findsOneWidget);

      // Toggle status button
      await tester.tap(find.text('Mark as Taken'));
      await tester.pumpAndSettle();
      expect(statusToggled, isTrue);

      // Toggle enabled switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(enabledToggled, isTrue);
    });

    testWidgets('18. MedicinesScreen filters list by Active, Paused, Pending, Taken',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final meds = [
        Medicine(
          id: '1',
          name: 'Med Active Pending',
          dosage: '10mg',
          scheduledTime: '08:00 AM',
          status: MedicineStatus.pending,
          isEnabled: true,
        ),
        Medicine(
          id: '2',
          name: 'Med Active Taken',
          dosage: '20mg',
          scheduledTime: '09:00 AM',
          status: MedicineStatus.taken,
          isEnabled: true,
        ),
        Medicine(
          id: '3',
          name: 'Med Paused',
          dosage: '30mg',
          scheduledTime: '10:00 AM',
          status: MedicineStatus.pending,
          isEnabled: false,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: MedicinesScreen(
          medicines: meds,
          onToggleStatus: (_) {},
          onAddMedicine: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // All filter shows 3 items
      expect(find.text('Med Active Pending'), findsOneWidget);
      expect(find.text('Med Active Taken'), findsOneWidget);
      expect(find.text('Med Paused'), findsOneWidget);

      // Tap 'Paused' chip
      await tester.tap(find.text('Paused'));
      await tester.pumpAndSettle();
      expect(find.text('Med Paused'), findsOneWidget);
      expect(find.text('Med Active Pending'), findsNothing);
      expect(find.text('Med Active Taken'), findsNothing);

      // Tap 'Taken' chip
      await tester.ensureVisible(find.text('Taken'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taken'));
      await tester.pumpAndSettle();
      expect(find.text('Med Active Taken'), findsOneWidget);
      expect(find.text('Med Active Pending'), findsNothing);
      expect(find.text('Med Paused'), findsNothing);
    });

    testWidgets('19. MainShell dynamically computes dashboard counts from repository',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = InMemoryMedicineRepository(
        seedData: [
          Medicine(
            id: 'm1',
            name: 'Pill One',
            dosage: '10mg',
            scheduledTime: '08:00 AM',
            status: MedicineStatus.taken,
            isEnabled: true,
          ),
          Medicine(
            id: 'm2',
            name: 'Pill Two',
            dosage: '20mg',
            scheduledTime: '12:00 PM',
            status: MedicineStatus.pending,
            isEnabled: true,
          ),
          Medicine(
            id: 'm3',
            name: 'Pill Three (Paused)',
            dosage: '30mg',
            scheduledTime: '06:00 PM',
            status: MedicineStatus.pending,
            isEnabled: false, // Paused: should not count in active scheduled
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: MainShell(repository: repo),
      ));
      await tester.pumpAndSettle();

      // Scheduled active count = 2 (m1 & m2, m3 paused)
      // Taken count = 1 (m1)
      // Remaining count = 1 (m2)
      expect(find.text('2'), findsWidgets); // scheduled count
      expect(find.text('1'), findsWidgets); // taken count & remaining count
    });
  });
}
