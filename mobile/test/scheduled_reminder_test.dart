import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/medicine.dart';
import 'package:mobile/screens/settings/settings_screen.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Phase 5 - Notification ID Scheme Tests', () {
    test('1. Deterministic and positive 31-bit integer constraint', () {
      final id1 = NotificationService.getNotificationId('med_123', 0);
      final id1Repeat = NotificationService.getNotificationId('med_123', 0);
      expect(id1, equals(id1Repeat));
      expect(id1, greaterThanOrEqualTo(0));
      expect(id1, lessThanOrEqualTo(0x7FFFFFFF)); // 2,147,483,647

      final id2 = NotificationService.getNotificationId('med_123', 1);
      expect(id1, isNot(equals(id2)));

      final idOtherMed = NotificationService.getNotificationId('med_999', 0);
      expect(id1, isNot(equals(idOtherMed)));
    });

    test('2. Multi-dose medicine collision-resistance across 50 simulated doses', () {
      final Set<int> ids = {};
      for (var m = 0; m < 10; m++) {
        for (var dose = 0; dose < 5; dose++) {
          final id = NotificationService.getNotificationId('medicine_id_$m', dose);
          expect(id, greaterThanOrEqualTo(0));
          expect(ids.contains(id), isFalse,
              reason: 'Notification ID collision detected for med $m dose $dose');
          ids.add(id);
        }
      }
      expect(ids.length, equals(50));
    });
  });

  group('Phase 5 - Time Parsing Tests', () {
    test('3. Parses standard 12-hour AM/PM formats accurately', () {
      final t1 = NotificationService.parseTimeString('08:00 AM');
      expect(t1.hour, equals(8));
      expect(t1.minute, equals(0));

      final t2 = NotificationService.parseTimeString('02:30 PM');
      expect(t2.hour, equals(14));
      expect(t2.minute, equals(30));

      final tNoon = NotificationService.parseTimeString('12:00 PM');
      expect(tNoon.hour, equals(12));
      expect(tNoon.minute, equals(0));

      final tMidnight = NotificationService.parseTimeString('12:00 AM');
      expect(tMidnight.hour, equals(0));
      expect(tMidnight.minute, equals(0));
    });

    test('4. Parses 24-hour military time accurately and falls back on garbage', () {
      final tMilitary = NotificationService.parseTimeString('19:45');
      expect(tMilitary.hour, equals(19));
      expect(tMilitary.minute, equals(45));

      final tFallback = NotificationService.parseTimeString('invalid-time-format');
      expect(tFallback.hour, equals(8));
      expect(tFallback.minute, equals(0));
    });
  });

  group('Phase 5 - Timezone Next Instance Calculation Tests', () {
    test('5. nextInstanceOfTime returns future timestamp with matching hour/minute', () {
      final now = tz.TZDateTime.now(tz.local);
      final targetHour = (now.hour + 2) % 24;
      final targetMinute = 15;

      final scheduled = NotificationService.nextInstanceOfTime(targetHour, targetMinute);
      expect(scheduled.hour, equals(targetHour));
      expect(scheduled.minute, equals(targetMinute));
      expect(scheduled.isAfter(now), isTrue);
    });
  });

  group('Phase 5 - SettingsScreen Scheduled Reminders UI Tests', () {
    testWidgets('6. Renders 1-minute test reminder card and Exact Alarms information card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify Phase 5 1-minute test reminder controls
      expect(find.text('Schedule Test Reminder (1 min)'), findsOneWidget);
      expect(find.text('Schedule a test reminder in 1 minute'), findsOneWidget);

      // Verify Android exact alarms policy notice
      expect(find.text('Exact Alarms & Battery Optimization'), findsOneWidget);
      expect(find.text('Check Alarms & Reminders Permission'), findsOneWidget);
    });
  });

  group('Phase 5 - Disabled Medicine Lifecycle Guard', () {
    test('7. scheduleMedicineReminders safely cancels and reports paused status for disabled medicines',
        () async {
      final disabledMed = Medicine(
        id: 'test_paused_med',
        name: 'Metformin',
        dosage: '500 mg',
        scheduledTime: '08:00 AM',
        status: MedicineStatus.pending,
        isEnabled: false,
      );

      final res = await NotificationService().scheduleMedicineReminders(disabledMed);
      expect(res.success, isTrue);
      expect(res.message, contains('is paused; active reminders removed'));
    });
  });
}
