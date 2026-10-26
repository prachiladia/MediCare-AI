import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/demo_data_banner.dart';
import '../../widgets/section_eyebrow.dart';

/// App Settings screen for notifications, preferences, and demonstration controls.
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onResetData;
  final NotificationService? notificationService;

  const SettingsScreen({
    super.key,
    this.onResetData,
    this.notificationService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsActive = true;
  bool _soundChime = true;
  int _defaultSnoozeMinutes = 10;
  bool _isSendingTestNotification = false;
  bool _isSchedulingTestReminder = false;
  bool _isCheckingExactAlarms = false;

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'In demonstration mode, signing out returns you to the login screen. Local session data will reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Cancel all scheduled reminders and clear session state
              await SessionManager.signOut(
                notificationService: widget.notificationService,
              );
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleResetSampleData() {
    if (widget.onResetData != null) {
      widget.onResetData!();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demonstration medicine list has been reset to defaults.'),
      ),
    );
  }

  Future<void> _handleSendTestNotification() async {
    if (_isSendingTestNotification) return;

    setState(() => _isSendingTestNotification = true);

    try {
      final service = widget.notificationService ?? NotificationService();

      if (!service.isInitialized) {
        final initResult = await service.initialize();
        if (!initResult.success) {
          throw Exception(initResult.message);
        }
      }

      final permissionGranted = await service.requestPermission();
      if (!permissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.emergency,
              content: Text(
                'Notification permission denied. Please enable notifications in device settings.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final result = await service.showTestNotification(
        medicineName: 'Amoxicillin',
        dosage: '500 mg',
        instructions: 'Take after breakfast with water',
      );

      if (!result.success) {
        throw Exception(result.message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.sageDeep,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Test notification sent: "Amoxicillin (500 mg)"'),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Notification Error'),
            content: Text(
              'Could not dispatch test notification:\n\n$e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTestNotification = false);
      }
    }
  }

  Future<void> _handleScheduleOneMinuteTestReminder() async {
    if (_isSchedulingTestReminder) return;

    setState(() => _isSchedulingTestReminder = true);

    try {
      final service = widget.notificationService ?? NotificationService();

      if (!service.isInitialized) {
        final initResult = await service.initialize();
        if (!initResult.success) {
          throw Exception(initResult.message);
        }
      }

      final permissionGranted = await service.requestPermission();
      if (!permissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.emergency,
              content: Text(
                'Notification permission denied. Please enable notifications in device settings.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final result = await service.scheduleOneMinuteTestReminder(
        medicineName: 'Amoxicillin',
        dosage: '500 mg',
        instructions: 'Test reminder (1 minute)',
      );

      if (!result.success) {
        throw Exception(result.message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sageDeep,
            content: Row(
              children: [
                const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(result.message),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Scheduling Error'),
            content: Text(
              'Could not schedule 1-minute test reminder:\n\n$e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSchedulingTestReminder = false);
      }
    }
  }

  Future<void> _handleCheckExactAlarmPermission() async {
    if (_isCheckingExactAlarms) return;
    setState(() => _isCheckingExactAlarms = true);

    try {
      final service = widget.notificationService ?? NotificationService();
      final granted = await service.requestExactAlarmsPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: granted ? AppColors.sageDeep : AppColors.statusPending,
            content: Text(
              granted
                  ? 'Exact alarms are permitted on this device.'
                  : 'Exact alarms not granted. Android may slightly delay background alarms.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking exact alarms: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingExactAlarms = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DemoDataBanner(
                    text: 'Demo Preferences • Local demonstration storage',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const SectionEyebrow(title: 'REMINDER PREFERENCES'),
                  const SizedBox(height: AppSpacing.sm),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.rounded2xl,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.rounded2xl,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _notificationsActive,
                            activeThumbColor: AppColors.sageDeep,
                            activeTrackColor: AppColors.sageLight,
                            title: const Text('Dose Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: const Text('Local reminder scheduling', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            onChanged: (val) => setState(() => _notificationsActive = val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            value: _soundChime,
                            activeThumbColor: AppColors.sageDeep,
                            activeTrackColor: AppColors.sageLight,
                            title: const Text('Gentle Chime', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: const Text('Play soft alert on reminder time', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            onChanged: (val) => setState(() => _soundChime = val),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Default Snooze', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Text('Interval for quick snooze', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                DropdownButton<int>(
                                  value: _defaultSnoozeMinutes,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 5, child: Text('5 min')),
                                    DropdownMenuItem(value: 10, child: Text('10 min')),
                                    DropdownMenuItem(value: 15, child: Text('15 min')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _defaultSnoozeMinutes = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Notification Foundation & Scheduled Reminders (Phase 4 & 5 Testing)
                  const SectionEyebrow(title: 'NOTIFICATION TESTING'),
                  const SizedBox(height: AppSpacing.sm),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.rounded2xl,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: AppSpacing.roundedMd,
                              ),
                              child: const Icon(
                                Icons.notification_important_rounded,
                                color: AppColors.sageDeep,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Test Local Notification',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Initializes service, creates Android channel & triggers dose alert',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppPrimaryButton(
                          label: _isSendingTestNotification
                              ? 'Sending Test...'
                              : 'Send Test Notification',
                          icon: Icons.notifications_active_rounded,
                          isLoading: _isSendingTestNotification,
                          onPressed: _isSendingTestNotification
                              ? null
                              : _handleSendTestNotification,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 1-Minute Scheduled Reminder Card (Phase 5 Testing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.rounded2xl,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: AppSpacing.roundedMd,
                              ),
                              child: const Icon(
                                Icons.alarm_rounded,
                                color: AppColors.forest,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Schedule Test Reminder (1 min)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sets a real alarm 60 seconds away. You can background the app to verify delivery.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppSecondaryButton(
                          label: _isSchedulingTestReminder
                              ? 'Scheduling (1 min)...'
                              : 'Schedule a test reminder in 1 minute',
                          icon: Icons.schedule_rounded,
                          isLoading: _isSchedulingTestReminder,
                          onPressed: _isSchedulingTestReminder
                              ? null
                              : _handleScheduleOneMinuteTestReminder,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Exact Alarms & System Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: AppSpacing.roundedLg,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.forest),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Exact Alarms & Battery Optimization',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'On Android 12+, exact reminder delivery requires the "Alarms & Reminders" permission. In Doze mode or aggressive battery saver modes, non-exact alarms may be coalesced by the OS by several minutes.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _isCheckingExactAlarms
                              ? null
                              : _handleCheckExactAlarmPermission,
                          icon: const Icon(Icons.security_update_good_rounded,
                              size: 16, color: AppColors.sageDeep),
                          label: Text(
                            _isCheckingExactAlarms
                                ? 'Checking...'
                                : 'Check Alarms & Reminders Permission',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const SectionEyebrow(title: 'DATA & STORAGE'),
                  const SizedBox(height: AppSpacing.sm),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.rounded2xl,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.rounded2xl,
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: AppColors.blush,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh_rounded, color: AppColors.sageDeep, size: 20),
                              ),
                              title: const Text('Reset Sample Data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: const Text('Restore initial sample medications', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              trailing: TextButton(
                                onPressed: _handleResetSampleData,
                                child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.sageDeep)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Sign Out Button
                  AppSecondaryButton(
                    label: 'Sign Out (Demo Session)',
                    icon: Icons.logout_rounded,
                    onPressed: _handleSignOut,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
