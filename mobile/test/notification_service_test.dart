import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/settings/settings_screen.dart';
import 'package:mobile/services/notification_service.dart';

void main() {
  group('Phase 4 - NotificationService Unit Tests', () {
    test('1. NotificationService has correct channel configuration', () {
      expect(NotificationService.channelId, equals('medicare_medicine_reminders'));
      expect(NotificationService.channelName, equals('Medicine Reminders'));
      expect(
        NotificationService.channelDescription,
        equals('Timely reminders and dosage alerts for scheduled medicines'),
      );
    });

    test('2. NotificationResult captures success and failure data accurately', () {
      const success = NotificationResult.success('All good');
      expect(success.success, isTrue);
      expect(success.message, equals('All good'));
      expect(success.error, isNull);

      const failure = NotificationResult.failure('Permission denied', 'Err403');
      expect(failure.success, isFalse);
      expect(failure.message, equals('Permission denied'));
      expect(failure.error, equals('Err403'));
      expect(failure.toString(), contains('Err403'));
    });
  });

  group('Phase 4 - SettingsScreen Notification Button Widget Tests', () {
    testWidgets('3. Renders Send Test Notification card and button in Settings',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATION TESTING'), findsOneWidget);
      expect(find.text('Test Local Notification'), findsOneWidget);
      expect(find.text('Send Test Notification'), findsOneWidget);
    });
  });
}
