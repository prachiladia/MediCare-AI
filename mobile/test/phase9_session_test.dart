import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/medicine.dart';
import 'package:mobile/repositories/in_memory_medicine_repository.dart';
import 'package:mobile/repositories/repository_manager.dart';
import 'package:mobile/screens/profile/profile_screen.dart';
import 'package:mobile/screens/settings/settings_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/in_memory_auth_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/services/session_manager.dart';

void main() {
  setUp(() {
    AuthManager.reset();
    RepositoryManager.reset();
    InMemoryMedicineRepository.resetDefaultInstance();
    NotificationService.medicineResolver = null;
  });

  tearDown(() {
    AuthManager.reset();
    RepositoryManager.reset();
    InMemoryMedicineRepository.resetDefaultInstance();
    NotificationService.medicineResolver = null;
  });

  group('Phase 9 - Step 4: SessionManager Sign Out & State Teardown', () {
    test('1. SessionManager.signOut clears auth, repository cache, and medicine resolver', () async {
      final auth = InMemoryAuthService();
      AuthManager.setInstance(auth);
      await auth.signInWithDemoMode();

      expect(AuthManager.instance.currentUser, isNotNull);

      // Register dummy resolver
      NotificationService.medicineResolver = (id) => null;
      expect(NotificationService.medicineResolver, isNotNull);

      // Sign out
      await SessionManager.signOut();

      expect(AuthManager.instance.currentUser, isNull);
      expect(NotificationService.medicineResolver, isNull);
    });

    test('2. SessionManager.signOut resets in-memory repository default instance', () async {
      final repoBefore = InMemoryMedicineRepository.defaultInstance;
      await repoBefore.addMedicine(
        const Medicine(
          id: 'temp_user_med',
          name: 'Temporary Med',
          dosage: '10mg',
          scheduledTime: '08:00 AM',
          status: MedicineStatus.pending,
        ),
      );

      final medsBefore = await repoBefore.getMedicines();
      expect(medsBefore.any((m) => m.id == 'temp_user_med'), isTrue);

      // Sign out clears and resets the repository instance
      await SessionManager.signOut();

      final repoAfter = InMemoryMedicineRepository.defaultInstance;
      final medsAfter = await repoAfter.getMedicines();
      // The custom medicine from previous session is gone
      expect(medsAfter.any((m) => m.id == 'temp_user_med'), isFalse);
    });
  });

  group('Phase 9 - Step 4: Account Switching & Isolation', () {
    test('3. Switching accounts rebinds medicineResolver exclusively to new user data', () async {
      // Step A: User A logs in
      final medA = const Medicine(
        id: 'med_userA_1',
        name: 'Aspirin Cardio',
        dosage: '81mg',
        scheduledTime: '08:00 AM',
        status: MedicineStatus.pending,
      );
      final repoA = InMemoryMedicineRepository(seedMedicines: [medA]);
      RepositoryManager.setRepository(repoA);

      // Simulate MainShell loading User A medicines
      final listA = await repoA.getMedicines();
      NotificationService.medicineResolver = (id) {
        for (final m in listA) {
          if (m.id == id) return m;
        }
        return null;
      };

      // Verify User A medicine resolves
      expect(NotificationService.medicineResolver!('med_userA_1')?.name, equals('Aspirin Cardio'));
      expect(NotificationService.medicineResolver!('med_userB_1'), isNull);

      // Step B: User A signs out
      await SessionManager.signOut();
      expect(NotificationService.medicineResolver, isNull);

      // Step C: User B logs in
      final medB = const Medicine(
        id: 'med_userB_1',
        name: 'Metformin XR',
        dosage: '500mg',
        scheduledTime: '07:00 PM',
        status: MedicineStatus.pending,
      );
      final repoB = InMemoryMedicineRepository(seedMedicines: [medB]);
      RepositoryManager.setRepository(repoB);

      // Simulate MainShell loading User B medicines
      final listB = await repoB.getMedicines();
      NotificationService.medicineResolver = (id) {
        for (final m in listB) {
          if (m.id == id) return m;
        }
        return null;
      };

      // Verify User B's resolver ONLY resolves User B's medicine and NEVER User A's medicine
      expect(NotificationService.medicineResolver!('med_userB_1')?.name, equals('Metformin XR'));
      expect(NotificationService.medicineResolver!('med_userA_1'), isNull);
    });
  });

  group('Phase 9 - Step 4: UI Sign Out Triggers & Navigation', () {
    testWidgets('4. SettingsScreen Sign Out confirmation dialog triggers SessionManager.signOut',
        (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = InMemoryAuthService();
      AuthManager.setInstance(auth);
      await auth.signInWithDemoMode();

      bool didNavigateToLogin = false;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const SettingsScreen(),
            '/login': (context) {
              didNavigateToLogin = true;
              return const Scaffold(body: Text('Login Screen'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find Sign Out button at bottom of settings
      final signOutBtn = find.text('Sign Out (Demo Session)');
      expect(signOutBtn, findsOneWidget);

      await tester.scrollUntilVisible(signOutBtn, 200);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Alert dialog appears
      expect(find.text('Sign Out?'), findsOneWidget);
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Confirm user is logged out and routed to /login
      expect(AuthManager.instance.currentUser, isNull);
      expect(didNavigateToLogin, isTrue);
    });

    testWidgets('5. ProfileScreen Sign Out confirmation dialog terminates session and routes to login',
        (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = InMemoryAuthService();
      AuthManager.setInstance(auth);
      await auth.signInWithDemoMode();

      bool didNavigateToLogin = false;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const ProfileScreen(),
            '/login': (context) {
              didNavigateToLogin = true;
              return const Scaffold(body: Text('Login Screen'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Sign Out button in ProfileScreen
      final signOutBtn = find.widgetWithText(OutlinedButton, 'Sign Out');
      expect(signOutBtn, findsOneWidget);

      await tester.scrollUntilVisible(signOutBtn, 200);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Sign Out?'), findsOneWidget);
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(AuthManager.instance.currentUser, isNull);
      expect(didNavigateToLogin, isTrue);
    });
  });
}
