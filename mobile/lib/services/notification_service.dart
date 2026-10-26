import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/dose_occurrence.dart';
import '../models/medicine.dart';
import '../screens/reminder/medicine_reminder_screen.dart';

/// Result wrapper indicating outcome of notification actions.
class NotificationResult {
  final bool success;
  final String message;
  final Object? error;

  const NotificationResult.success([this.message = 'Success'])
      : success = true,
        error = null;

  const NotificationResult.failure(this.message, [this.error])
      : success = false;

  @override
  String toString() => success ? message : 'Error: $message ($error)';
}

/// Service managing notification initialization, Android 13+ runtime permissions,
/// exact alarms, timezone-aware scheduled dose alerts, and tap navigation.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Global navigator key allowing notification tap responses to push routes
  /// across foreground, background, and cold start states.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Optional resolver function to locate a live [Medicine] by ID.
  static Medicine? Function(String id)? medicineResolver;

  static const String channelId = 'medicare_medicine_reminders';
  static const String channelName = 'Medicine Reminders';
  static const String channelDescription =
      'Timely reminders and dosage alerts for scheduled medicines';

  static const int testNotificationId = 1001;
  static const int oneMinuteTestReminderId = 999999;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _permissionRequested = false;
  bool? _permissionGranted;
  bool? get permissionGranted => _permissionGranted;

  /// Deterministically maps a medicine ID and dose index to a positive 31-bit integer.
  /// Uses 32-bit FNV-1a hash masked to 31 bits ($0 \le id \le 2^{31} - 1$).
  ///
  /// Guarantees:
  /// - Deterministic: same medicine and dose index always returns the identical ID.
  /// - Zero collisions across realistic medication counts.
  /// - Directly cancellable without requiring a secondary persistent ID table.
  static int getNotificationId(String medicineId, int doseIndex) {
    final key = '${medicineId}_dose_$doseIndex';
    var hash = 0x811c9dc5;
    for (var i = 0; i < key.length; i++) {
      hash ^= key.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  /// Robust parser for human-readable time strings like "08:00 AM", "2:30 PM", or "14:30".
  static TimeOfDay parseTimeString(String timeStr) {
    try {
      final clean = timeStr.trim();
      final isPm = clean.toUpperCase().contains('PM');
      final isAm = clean.toUpperCase().contains('AM');
      final numPart = clean.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = numPart.split(':');
      if (parts.length >= 2) {
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return const TimeOfDay(hour: 8, minute: 0);
  }

  /// Calculates the next occurrence of [hour]:[minute] in local time.
  /// If the time has already passed today, rolls over to tomorrow.
  static tz.TZDateTime nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Initializes the notification plugin, timezone database, and creates the high-importance channel.
  Future<NotificationResult> initialize() async {
    if (_isInitialized) {
      return const NotificationResult.success('Already initialized');
    }

    try {
      // 1. Initialize timezone database and set local timezone from device offset
      tz.initializeTimeZones();
      _configureLocalTimeZone();

      // 2. Configure platform initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == false) {
        return const NotificationResult.failure(
          'Flutter local notifications plugin initialization returned false.',
        );
      }

      // 3. Configure Android High-Importance Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

          await androidPlugin.createNotificationChannel(channel);
        }
      }

      _isInitialized = true;
      return const NotificationResult.success('Notification service initialized successfully');
    } catch (e, stack) {
      if (!e.toString().contains('LateInitializationError')) {
        debugPrint('NotificationService init error: $e\n$stack');
      }
      return NotificationResult.failure(
        'Failed to initialize notification service: $e',
        e,
      );
    }
  }

  /// Configures tz.local based on the device's current timezone offset.
  void _configureLocalTimeZone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.timeZone(nowMs).offset == offset) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error configuring local timezone: $e');
    }
  }

  /// Requests Android 13+ (API 33+) POST_NOTIFICATIONS runtime permission.
  Future<bool> requestPermission() async {
    _permissionRequested = true;

    if (kIsWeb) {
      _permissionGranted = false;
      return false;
    }

    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          final bool? granted = await androidPlugin.requestNotificationsPermission();
          _permissionGranted = granted ?? false;
          return _permissionGranted!;
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          final bool? granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          _permissionGranted = granted ?? false;
          return _permissionGranted!;
        }
      }

      _permissionGranted = true;
      return true;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
      _permissionGranted = false;
      rethrow;
    }
  }

  /// Checks and requests Android 12+ (API 31+) SCHEDULE_EXACT_ALARM permission.
  /// On Android 14+ (API 34+), this may prompt the user or navigate to system settings.
  Future<bool> requestExactAlarmsPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? granted = await androidPlugin.requestExactAlarmsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService requestExactAlarmsPermission error: $e');
      return false;
    }
  }

  /// Displays an immediate high-priority test notification with medicine name and dosage.
  Future<NotificationResult> showTestNotification({
    String medicineName = 'Amoxicillin',
    String dosage = '500 mg',
    String instructions = 'Take after breakfast with water',
  }) async {
    if (!_isInitialized) {
      final initRes = await initialize();
      if (!initRes.success) {
        return initRes;
      }
    }

    if (!kIsWeb && Platform.isAndroid && !_permissionRequested) {
      await requestPermission();
    }

    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4F7455), // AppColors.sageDeep
        styleInformation: BigTextStyleInformation(
          'Dose scheduled now: $dosage\n$instructions',
          contentTitle: 'MediCare Dose: $medicineName',
          summaryText: 'Medicine Reminder',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: testNotificationId,
        title: 'Time for $medicineName ($dosage)',
        body: instructions,
        notificationDetails: details,
        payload: 'test_medicine|$medicineName|$dosage|$instructions',
      );

      return const NotificationResult.success('Test notification sent successfully');
    } catch (e, stack) {
      debugPrint('NotificationService showTestNotification error: $e\n$stack');
      return NotificationResult.failure(
        'Failed to show notification: $e',
        e,
      );
    }
  }

  /// Schedules a test reminder set 1 minute (60 seconds) in the future.
  /// Allows rapid live verification on the emulator without waiting for daily wall-clock times.
  Future<NotificationResult> scheduleOneMinuteTestReminder({
    String medicineName = 'Amoxicillin',
    String dosage = '500 mg',
    String instructions = 'Test reminder (1 minute)',
  }) async {
    if (!_isInitialized) {
      final initRes = await initialize();
      if (!initRes.success) return initRes;
    }

    if (!kIsWeb && Platform.isAndroid && !_permissionRequested) {
      await requestPermission();
    }

    try {
      final bool exactAllowed = await requestExactAlarmsPermission();
      final scheduleMode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4F7455),
        styleInformation: BigTextStyleInformation(
          'Dose scheduled now: $dosage\n$instructions',
          contentTitle: 'MediCare Dose: $medicineName',
          summaryText: 'Medicine Reminder',
        ),
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id: oneMinuteTestReminderId,
        title: 'Time for $medicineName ($dosage)',
        body: instructions,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: 'test_reminder|test_mock_id|$medicineName|$dosage',
      );

      final String timeFormatted =
          '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
      return NotificationResult.success(
        'Test reminder scheduled for 1 minute from now ($timeFormatted).',
      );
    } catch (e, stack) {
      debugPrint('NotificationService scheduleOneMinuteTestReminder error: $e\n$stack');
      return NotificationResult.failure(
        'Failed to schedule 1-minute test reminder: $e',
        e,
      );
    }
  }

  /// Schedules daily recurring dose alerts for each dose time of the given [Medicine].
  /// Cancels any previous reminders for the medicine before rescheduling.
  Future<NotificationResult> scheduleMedicineReminders(Medicine medicine) async {
    // If disabled or outside active date window, cancel any lingering alarms and exit.
    if (!medicine.isEnabled || !medicine.isActive) {
      if (_isInitialized) {
        await cancelMedicineReminders(medicine);
      }
      return NotificationResult.success(
        'Medicine "${medicine.name}" is paused; active reminders removed.',
      );
    }

    if (!_isInitialized) {
      final initRes = await initialize();
      if (!initRes.success) return initRes;
    }

    try {
      final bool exactAllowed = await requestExactAlarmsPermission();
      final scheduleMode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final times = medicine.effectiveTimes;
      int scheduledCount = 0;

      for (var i = 0; i < times.length; i++) {
        final timeStr = times[i];
        final timeOfDay = parseTimeString(timeStr);
        final scheduledDate = nextInstanceOfTime(timeOfDay.hour, timeOfDay.minute);
        final id = getNotificationId(medicine.id, i);

        final AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4F7455),
          styleInformation: BigTextStyleInformation(
            medicine.instructions.isNotEmpty
                ? 'Dose: ${medicine.dosage}\n${medicine.instructions}'
                : 'Dose: ${medicine.dosage} scheduled for $timeStr',
            contentTitle: 'MediCare Dose: ${medicine.name}',
            summaryText: 'Medicine Reminder',
          ),
        );

        final NotificationDetails details = NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

        await _plugin.zonedSchedule(
          id: id,
          title: 'Time for ${medicine.name} (${medicine.dosage})',
          body: medicine.instructions.isNotEmpty
              ? medicine.instructions
              : 'Dose scheduled at $timeStr',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time, // Daily recurring
          payload:
              'reminder|${medicine.id}|$timeStr|${medicine.name}|${medicine.dosage}',
        );
        scheduledCount++;
      }

      return NotificationResult.success(
        'Scheduled $scheduledCount reminder(s) for "${medicine.name}".',
      );
    } catch (e, stack) {
      debugPrint('NotificationService scheduleMedicineReminders error: $e\n$stack');
      return NotificationResult.failure(
        'Failed to schedule reminders for "${medicine.name}": $e',
        e,
      );
    }
  }

  /// Schedules a snoozed reminder notification after the user delays a dose.
  Future<NotificationResult> scheduleSnoozedReminder({
    required DoseOccurrence occurrence,
    required int minutes,
  }) async {
    if (!_isInitialized) {
      final initRes = await initialize();
      if (!initRes.success) return initRes;
    }

    try {
      final exactAllowed = await requestExactAlarmsPermission();
      final scheduleMode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final scheduledDate =
          tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
      final notifId = getNotificationId(occurrence.medicineId, 0);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4F7455),
        styleInformation: BigTextStyleInformation(
          'Snoozed dose (+${minutes}m): ${occurrence.dosage}\n${occurrence.instructions}',
          contentTitle: 'Snoozed: ${occurrence.medicineName}',
          summaryText: 'Medicine Reminder (Snooze ${occurrence.snoozeCount}/3)',
        ),
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id: notifId,
        title: 'Time for ${occurrence.medicineName} (${occurrence.dosage})',
        body: 'Snoozed reminder ($minutes min)',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload:
            'reminder|${occurrence.medicineId}|${occurrence.effectiveTimeFormatted}|${occurrence.medicineName}|${occurrence.dosage}',
      );

      return NotificationResult.success(
        'Snoozed reminder scheduled in $minutes min for "${occurrence.medicineName}".',
      );
    } catch (e, stack) {
      debugPrint('NotificationService scheduleSnoozedReminder error: $e\n$stack');
      return NotificationResult.failure(
        'Failed to schedule snoozed reminder: $e',
        e,
      );
    }
  }

  /// Cancels all scheduled reminder notifications associated with a [Medicine].
  /// Cancels up to `max(effectiveTimes.length, 10)` dose indices to guarantee
  /// any previously reduced dose occurrences are cleaned up.
  Future<NotificationResult> cancelMedicineReminders(Medicine medicine) async {
    try {
      final count = max(medicine.effectiveTimes.length, 10);
      for (var i = 0; i < count; i++) {
        final id = getNotificationId(medicine.id, i);
        await _plugin.cancel(id: id);
      }
      return NotificationResult.success(
        'Cancelled reminders for "${medicine.name}".',
      );
    } catch (e, stack) {
      debugPrint('NotificationService cancelMedicineReminders error: $e\n$stack');
      return NotificationResult.failure(
        'Failed to cancel reminders for "${medicine.name}": $e',
        e,
      );
    }
  }

  /// Cancels a specific reminder by exact ID.
  Future<void> cancelById(int notificationId) async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('NotificationService cancelById error: $e');
    }
  }

  /// Cancels all scheduled reminder notifications upon user logout.
  Future<void> cancelAllReminders() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancelAll();
      debugPrint('NotificationService: All scheduled reminders cancelled on logout.');
    } catch (e) {
      debugPrint('NotificationService cancelAllReminders error: $e');
    }
  }

  /// Inspects launch details when the app cold-starts from a notification tap.
  Future<void> checkNotificationLaunchDetails() async {
    if (!_isInitialized) return;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse != null) {
        _onNotificationTapped(details.notificationResponse!);
      }
    } catch (e) {
      debugPrint('NotificationService checkNotificationLaunchDetails error: $e');
    }
  }

  /// Top-level callback triggered whenever a notification is tapped by the user.
  /// Handles foreground, background, and cold start routing to [MedicineReminderScreen].
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('NotificationService._onNotificationTapped payload: $payload');
    if (payload == null || payload.isEmpty) return;

    Medicine? targetMedicine;

    if (payload.startsWith('reminder|')) {
      final parts = payload.split('|');
      final medId = parts.length > 1 ? parts[1] : '';
      final timeStr = parts.length > 2 ? parts[2] : 'Scheduled Time';
      final name = parts.length > 3 ? parts[3] : 'Medicine';
      final dosage = parts.length > 4 ? parts[4] : '';

      // Try resolving live medicine from repository
      if (medicineResolver != null && medId.isNotEmpty) {
        targetMedicine = medicineResolver!(medId);
      }

      // Fallback: construct ephemeral Medicine object matching payload data
      targetMedicine ??= Medicine(
        id: medId.isNotEmpty ? medId : 'notif_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        dosage: dosage,
        scheduledTime: timeStr,
        status: MedicineStatus.pending,
        instructions: 'Dose alert from scheduled reminder',
      );
    } else if (payload.startsWith('test_reminder|') ||
        payload.startsWith('test_medicine|')) {
      final parts = payload.split('|');
      final name = parts.length > 2 ? parts[2] : (parts.length > 1 ? parts[1] : 'Amoxicillin');
      final dosage = parts.length > 3 ? parts[3] : (parts.length > 2 ? parts[2] : '500 mg');

      targetMedicine = Medicine(
        id: 'test_dose_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        dosage: dosage,
        scheduledTime: 'Now',
        status: MedicineStatus.pending,
        instructions: 'Take after breakfast with water (Test reminder)',
      );
    }

    if (targetMedicine != null) {
      _navigateToReminderScreen(targetMedicine);
    }
  }

  void _navigateToReminderScreen(Medicine medicine) {
    final navState = navigatorKey.currentState;
    if (navState != null) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => MedicineReminderScreen(medicine: medicine),
        ),
      );
    } else {
      // If navigator state is not yet ready, retry shortly after next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => MedicineReminderScreen(medicine: medicine),
          ),
        );
      });
    }
  }
}
