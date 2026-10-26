import 'package:flutter/foundation.dart';
import '../repositories/in_memory_medicine_repository.dart';
import '../repositories/repository_manager.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Manages application-wide user session lifecycle:
/// - Clean account logout
/// - Complete alarm/notification cancellation
/// - In-memory state and resolver wipes
/// - Account isolation enforcement
class SessionManager {
  SessionManager._();

  /// Completely signs out the active user session and clears all state:
  /// 1. Cancels all pending local notifications and exact alarms.
  /// 2. Clears the in-memory notification medicine resolver.
  /// 3. Resets in-memory demo repository data.
  /// 4. Resets repository manager caches.
  /// 5. Signs out of Firebase Auth / AuthManager.
  ///
  /// Guarantees switching accounts never leaks or fires another user's reminders.
  static Future<void> signOut({NotificationService? notificationService}) async {
    final notifService = notificationService ?? NotificationService();

    try {
      await notifService.cancelAllReminders();
    } catch (e) {
      debugPrint('SessionManager: Error cancelling notifications on logout: $e');
    }

    // Clear medicine resolver so no notification tap can resolve previous user data
    NotificationService.medicineResolver = null;

    // Reset in-memory demo repository to clear any session-cached medications
    InMemoryMedicineRepository.resetDefaultInstance();

    // Reset repository manager override
    RepositoryManager.reset();

    // Terminate auth session
    await AuthManager.instance.signOut();
  }
}
