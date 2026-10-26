import 'package:flutter/material.dart';
import 'screens/adherence/adherence_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/caregiver/caregiver_screen.dart';
import 'screens/main_shell.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// Top-level application widget configuring Material Design 3, theme, and application routes.
class MediCareApp extends StatefulWidget {
  const MediCareApp({super.key});

  @override
  State<MediCareApp> createState() => _MediCareAppState();
}

class _MediCareAppState extends State<MediCareApp> {
  @override
  void initState() {
    super.initState();
    // Check if cold start was triggered by tapping a scheduled reminder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkNotificationLaunchDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'MediCare AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainShell(),
        '/adherence': (context) => const AdherenceScreen(),
        '/caregiver': (context) => const CaregiverScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
