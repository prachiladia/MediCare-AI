import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/repositories/in_memory_medicine_repository.dart';
import 'package:mobile/screens/home/home_screen.dart';
import 'package:mobile/screens/profile/profile_screen.dart';
import 'package:mobile/utils/greeting_helper.dart';
import 'package:mobile/widgets/greeting_header.dart';

void main() {
  group('TASK 1 - Dynamic Greeting Time Bands & Boundary Tests', () {
    test('1. Named hour thresholds exist and match specified values', () {
      expect(GreetingHelper.morningStartHour, equals(5));
      expect(GreetingHelper.afternoonStartHour, equals(12));
      expect(GreetingHelper.eveningStartHour, equals(17));
      expect(GreetingHelper.nightStartHour, equals(21));
    });

    test('2. Boundary 04:59 -> Good Night', () {
      final time = DateTime(2026, 10, 26, 4, 59);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Night'));
    });

    test('3. Boundary 05:00 -> Good Morning', () {
      final time = DateTime(2026, 10, 26, 5, 0);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Morning'));
    });

    test('4. Boundary 11:59 -> Good Morning', () {
      final time = DateTime(2026, 10, 26, 11, 59);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Morning'));
    });

    test('5. Boundary 12:00 -> Good Afternoon', () {
      final time = DateTime(2026, 10, 26, 12, 0);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Afternoon'));
    });

    test('6. Boundary 16:59 -> Good Afternoon', () {
      final time = DateTime(2026, 10, 26, 16, 59);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Afternoon'));
    });

    test('7. Boundary 17:00 -> Good Evening', () {
      final time = DateTime(2026, 10, 26, 17, 0);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Evening'));
    });

    test('8. Boundary 20:59 -> Good Evening', () {
      final time = DateTime(2026, 10, 26, 20, 59);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Evening'));
    });

    test('9. Boundary 21:00 -> Good Night', () {
      final time = DateTime(2026, 10, 26, 21, 0);
      expect(GreetingHelper.getGreeting(currentTime: time), equals('Good Night'));
    });

    test('10. Mid-band checks and injected clock function', () {
      expect(
        GreetingHelper.getGreeting(clock: () => DateTime(2026, 10, 26, 9, 30)),
        equals('Good Morning'),
      );
      expect(
        GreetingHelper.getGreeting(clock: () => DateTime(2026, 10, 26, 14, 15)),
        equals('Good Afternoon'),
      );
      expect(
        GreetingHelper.getGreeting(clock: () => DateTime(2026, 10, 26, 19, 0)),
        equals('Good Evening'),
      );
      expect(
        GreetingHelper.getGreeting(clock: () => DateTime(2026, 10, 26, 23, 45)),
        equals('Good Night'),
      );
      expect(
        GreetingHelper.getGreeting(clock: () => DateTime(2026, 10, 26, 0, 0)),
        equals('Good Night'),
      );
    });
  });

  group('TASK 1 - User Name Source Order & Fallbacks', () {
    test('11. Priority 1: users/{uid} profile name is preferred', () {
      const user = AppUser(
        uid: 'u1',
        email: 'priya.sharma@example.com',
        name: 'Priya Sharma',
      );
      final firstName = GreetingHelper.resolveFirstName(
        user: user,
        authDisplayName: 'Firebase Name',
      );
      expect(firstName, equals('Priya'));
    });

    test('12. Priority 2: Firebase displayName used when profile name is empty', () {
      const user = AppUser(
        uid: 'u2',
        email: 'fallback@example.com',
        name: '',
      );
      final firstName = GreetingHelper.resolveFirstName(
        user: user,
        authDisplayName: 'Rohan Verma',
      );
      expect(firstName, equals('Rohan'));
    });

    test('13. Priority 3: Part of email before @ used when displayName is absent', () {
      const user = AppUser(
        uid: 'u3',
        email: 'prachi@example.com',
        name: '',
      );
      final firstName = GreetingHelper.resolveFirstName(user: user);
      expect(firstName, equals('prachi'));
    });

    test('14. Priority 4: No name returns null (never "there")', () {
      const user = AppUser(
        uid: 'u4',
        email: '',
        name: '',
      );
      final firstName = GreetingHelper.resolveFirstName(user: user);
      expect(firstName, isNull);
    });

    test('15. Demo mode without typed name does not invent a person', () {
      const demoUser = AppUser(
        uid: 'demo_1',
        email: 'demo@medicare.ai',
        name: '',
        isDemoUser: true,
      );
      final firstName = GreetingHelper.resolveFirstName(user: demoUser);
      expect(firstName, isNull);
    });

    test('16. Demo mode with typed name uses the typed name', () {
      const demoUser = AppUser(
        uid: 'demo_1',
        email: 'demo@medicare.ai',
        name: 'Prachi Ladia',
        isDemoUser: true,
      );
      final firstName = GreetingHelper.resolveFirstName(user: demoUser);
      expect(firstName, equals('Prachi'));
    });
  });

  group('TASK 1 - Initials Extraction Tests', () {
    test('17. Handles empty string and extra whitespace safely', () {
      expect(GreetingHelper.getInitials(null), equals(''));
      expect(GreetingHelper.getInitials(''), equals(''));
      expect(GreetingHelper.getInitials('   '), equals(''));
    });

    test('18. Single-word name returns 1 uppercase letter', () {
      expect(GreetingHelper.getInitials('Prachi'), equals('P'));
      expect(GreetingHelper.getInitials('  alex  '), equals('A'));
    });

    test('19. Multi-word name returns max 2 uppercase letters', () {
      expect(GreetingHelper.getInitials('Prachi Ladia'), equals('PL'));
      expect(GreetingHelper.getInitials('   john    smith   '), equals('JS'));
      expect(GreetingHelper.getInitials('Dr. Sarah Jenkins MD'), equals('DS'));
    });
  });

  group('TASK 1 - GreetingHeader & ProfileScreen Widget Tests', () {
    testWidgets('20. GreetingHeader renders plain greeting with no name and person icon when user is anonymous',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GreetingHeader(
              greeting: 'Good Evening',
              userName: null,
            ),
          ),
        ),
      );

      // Must be plain "GOOD EVENING!" with NO name and definitely NOT "there"
      expect(find.text('GOOD EVENING!'), findsOneWidget);
      expect(find.textContaining('there'), findsNothing);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('21. GreetingHeader renders first name and initials when user is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GreetingHeader(
              greeting: 'Good Morning',
              userName: 'Prachi',
            ),
          ),
        ),
      );

      expect(find.text('GOOD MORNING, Prachi!'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('22. Very long name does not cause layout overflow and renders with single line ellipsis',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const longName = 'Alexander Bartholomew Christopher Montgomery';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GreetingHeader(
              greeting: 'Good Afternoon',
              userName: longName,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('GOOD AFTERNOON, $longName!'), findsOneWidget);
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('23. ProfileScreen displays person icon when no name is set and opens edit dialog',
        (tester) async {
      final repo = InMemoryMedicineRepository();
      await repo.updateUserProfile(name: '');

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Person icon shown in avatar badge
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.text('Demo User'), findsOneWidget);

      // Tap Edit Name icon button
      final editBtn = find.byTooltip('Edit Name');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Edit dialog appears
      expect(find.text('Edit Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      // Enter new name and tap Save
      await tester.enterText(find.byType(TextFormField), 'Prachi Ladia');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verified updated on profile screen
      expect(find.text('Prachi Ladia'), findsOneWidget);
      expect(find.text('PL'), findsOneWidget);
    });

    testWidgets('24. HomeScreen reflects injected clock and dynamic user name',
        (tester) async {
      final repo = InMemoryMedicineRepository();
      const user = AppUser(
        uid: 'user_live',
        email: 'prachi@example.com',
        name: 'Prachi Ladia',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              medicines: const [],
              repository: repo,
              user: user,
              clock: () => DateTime(2026, 10, 26, 18, 0), // 18:00 -> Evening
              onToggleStatus: (_) {},
              onAddMedicine: (_) {},
              onNavigateToHistory: () {},
              onNavigateToMedicines: () {},
              onNavigateToProfile: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GOOD EVENING, Prachi!'), findsOneWidget);
      expect(find.text('PL'), findsOneWidget);
    });
  });
}
