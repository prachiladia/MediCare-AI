import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/models/medicine.dart';
import 'package:mobile/screens/adherence/adherence_screen.dart';
import 'package:mobile/screens/auth/login_screen.dart';
import 'package:mobile/screens/auth/register_screen.dart';
import 'package:mobile/screens/caregiver/caregiver_screen.dart';
import 'package:mobile/screens/main_shell.dart';
import 'package:mobile/screens/medicines/edit_medicine_screen.dart';
import 'package:mobile/screens/reminder/medicine_reminder_screen.dart';
import 'package:mobile/screens/settings/settings_screen.dart';

void main() {
  group('Auth Form Validation & Bug Fix Regression Tests', () {
    testWidgets('1. SplashScreen renders and transitions to LoginScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MediCareApp());
      await tester.pump();

      expect(find.text('MediCare AI'), findsWidgets);
      expect(find.text("WE'LL STICK BY\nYOUR DOSES."), findsOneWidget);
      expect(find.text('Continue →'), findsOneWidget);

      await tester.tap(find.text('Continue →'));
      await tester.pumpAndSettle();

      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue in demo mode'), findsOneWidget);
    });

    testWidgets('2. LoginScreen rejects EMPTY fields: dashboard NOT shown and error text IS shown', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
        routes: {
          '/home': (_) => const MainShell(),
        },
      ));
      await tester.pumpAndSettle();

      // Fields are empty by default
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Tap Sign In with completely empty fields
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // STRICT ASSERTIONS: Dashboard must NOT be shown, validation errors MUST be shown
      expect(find.byType(MainShell), findsNothing, reason: 'Dashboard must not be shown on empty submit');
      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('3. LoginScreen rejects INVALID email format', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
        routes: {
          '/home': (_) => const MainShell(),
        },
      ));
      await tester.pumpAndSettle();

      // Enter invalid email and valid password
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.enterText(find.byType(TextFormField).last, 'validpass123');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // STRICT ASSERTIONS: Dashboard must NOT be shown, email format error must be shown
      expect(find.byType(MainShell), findsNothing, reason: 'Dashboard must not be shown on invalid email');
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('4. LoginScreen navigates to dashboard on VALID credentials', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
        routes: {
          '/home': (_) => const MainShell(),
        },
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'securepass123');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('5. LoginScreen demo bypass button ("Continue in demo mode") is separate and works', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: const LoginScreen(),
        routes: {
          '/home': (_) => const MainShell(),
        },
      ));
      await tester.pumpAndSettle();

      // Tap the separate demo bypass button without touching form fields
      await tester.ensureVisible(find.text('Continue in demo mode'));
      await tester.tap(find.text('Continue in demo mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('6. RegisterScreen rejects empty fields, invalid email, short password, mismatched passwords', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: const RegisterScreen(),
        routes: {
          '/home': (_) => const MainShell(),
        },
      ));
      await tester.pumpAndSettle();

      // 6a: Empty fields
      await tester.ensureVisible(find.text('Register Account'));
      await tester.tap(find.text('Register Account'));
      await tester.pump();

      expect(find.byType(MainShell), findsNothing, reason: 'Dashboard must not be shown on empty registration');
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // 6b: Invalid email format
      await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'bademail');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');
      await tester.enterText(find.byType(TextFormField).at(3), '123456');
      await tester.tap(find.text('Register Account'));
      await tester.pump();

      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // 6c: Password under 6 characters
      await tester.enterText(find.byType(TextFormField).at(1), 'jane@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '12345');
      await tester.enterText(find.byType(TextFormField).at(3), '12345');
      await tester.tap(find.text('Register Account'));
      await tester.pump();

      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // 6d: Mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different456');
      await tester.tap(find.text('Register Account'));
      await tester.pump();

      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Passwords do not match'), findsOneWidget);

      // 6e: Valid registration succeeds
      await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
      await tester.tap(find.text('Register Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('7. MainShell tabs switch cleanly without assertion errors', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MainShell()));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S MEDICINES"), findsOneWidget);
      expect(find.text('DAILY ADHERENCE'), findsOneWidget);

      await tester.tap(find.text('Medicines'));
      await tester.pumpAndSettle();
      expect(find.text('My Medications'), findsOneWidget);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Adherence History'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('EMERGENCY CONTACTS'), findsOneWidget);
    });

    testWidgets('8. AdherenceScreen renders progress breakdown and adherence formula', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: AdherenceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Adherence & Progress'), findsOneWidget);
      expect(find.text("TODAY'S DOSE BREAKDOWN"), findsOneWidget);
      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
    });

    testWidgets('9. CaregiverScreen renders emergency contacts and escalation rule', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: CaregiverScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Support'), findsOneWidget);
      expect(find.text('PRIMARY CAREGIVER DETAILS'), findsOneWidget);
      expect(find.text('AUTOMATIC ESCALATION RULE'), findsOneWidget);
      expect(find.text('Alert on 3 Consecutive Misses'), findsOneWidget);
      expect(find.text('Simulate 3-Misses Alert (Demo)'), findsOneWidget);
    });

    testWidgets('10. SettingsScreen renders reminder controls and sign out dialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('REMINDER PREFERENCES'), findsOneWidget);
      expect(find.text('DATA & STORAGE'), findsOneWidget);
      expect(find.text('Reset Sample Data'), findsOneWidget);

      await tester.ensureVisible(find.text('Sign Out (Demo Session)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out (Demo Session)'));
      await tester.pumpAndSettle();
      expect(find.text('Sign Out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Sign Out?'), findsNothing);
    });

    testWidgets('11. EditMedicineScreen pre-populates fields and validates edits', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleMed = Medicine(
        id: 'test-1',
        name: 'Amoxicillin',
        dosage: '500 mg',
        scheduledTime: '08:00 AM',
        status: MedicineStatus.pending,
        instructions: 'Take with food',
        type: MedicineType.capsule,
        frequency: 'Twice daily',
      );

      bool updated = false;
      await tester.pumpWidget(MaterialApp(
        home: EditMedicineScreen(
          medicine: sampleMed,
          onMedicineUpdated: (m) => updated = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Medication'), findsOneWidget);
      expect(find.text('Amoxicillin'), findsOneWidget);
      expect(find.text('500 mg'), findsOneWidget);

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(updated, isTrue);
    });

    testWidgets('12. MedicineReminderScreen handles Snooze bottom sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleMed = Medicine(
        id: 'test-2',
        name: 'Metformin',
        dosage: '500 mg',
        scheduledTime: '09:00 AM',
        status: MedicineStatus.pending,
        instructions: 'Take after meals',
        type: MedicineType.tablet,
        frequency: 'Twice daily',
      );

      await tester.pumpWidget(MaterialApp(
        home: MedicineReminderScreen(medicine: sampleMed),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Medicine Reminder'), findsOneWidget);
      expect(find.text('Metformin'), findsOneWidget);
      expect(find.text('500 mg • Twice daily'), findsOneWidget);
      expect(find.text('Mark as Taken'), findsOneWidget);

      await tester.ensureVisible(find.text('Snooze'));
      await tester.tap(find.text('Snooze'));
      await tester.pumpAndSettle();

      expect(find.text('Snooze Dose'), findsOneWidget);
      expect(find.text('5 Minutes'), findsOneWidget);
      expect(find.text('10 Minutes'), findsOneWidget);
      expect(find.text('15 Minutes'), findsOneWidget);

      await tester.tap(find.text('10 Minutes'));
      await tester.pumpAndSettle();
    });

    testWidgets('13. MedicineReminderScreen handles SkipReasonDialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleMed = Medicine(
        id: 'test-3',
        name: 'Lisinopril',
        dosage: '10 mg',
        scheduledTime: '10:00 AM',
        status: MedicineStatus.pending,
        instructions: 'Take in morning',
        type: MedicineType.pill,
        frequency: 'Once daily',
      );

      await tester.pumpWidget(MaterialApp(
        home: MedicineReminderScreen(medicine: sampleMed),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Skip Dose'));
      await tester.tap(find.text('Skip Dose'));
      await tester.pumpAndSettle();

      expect(find.text('Skip Dose'), findsWidgets);
      expect(find.text('Side Effects'), findsOneWidget);
      expect(find.text('Confirm Skip'), findsOneWidget);

      await tester.tap(find.text('Side Effects'));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Skip'), findsNothing);
    });
  });
}
