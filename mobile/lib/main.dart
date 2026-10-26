import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/in_memory_auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize NotificationService for Android channel registration
  await NotificationService().initialize();

  // Initialize Firebase with graceful fallback to Demonstration Mode
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthManager.isFirebaseInitialized = true;
    AuthManager.setInstance(FirebaseAuthService());
    debugPrint(
      'Firebase initialized successfully for project ${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
  } catch (e) {
    AuthManager.isFirebaseInitialized = false;
    AuthManager.initializationError = e.toString();
    AuthManager.setInstance(InMemoryAuthService());
    debugPrint(
      'Firebase initialization notice: $e. Falling back cleanly to Demo Mode.',
    );
  }

  runApp(const MediCareApp());
}

/// Compatibility alias preserving references to MyApp.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MediCareApp();
  }
}
