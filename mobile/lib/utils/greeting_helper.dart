import '../models/app_user.dart';

/// Helper for time-of-day greetings, user display names, and initials.
class GreetingHelper {
  GreetingHelper._();

  // Named hour constants for greeting time bands
  static const int morningStartHour = 5; // 05:00
  static const int afternoonStartHour = 12; // 12:00
  static const int eveningStartHour = 17; // 17:00
  static const int nightStartHour = 21; // 21:00

  /// Computes the time-of-day greeting based on device's local time:
  /// - 05:00 - 11:59: "Good Morning"
  /// - 12:00 - 16:59: "Good Afternoon"
  /// - 17:00 - 20:59: "Good Evening"
  /// - 21:00 - 04:59: "Good Night"
  ///
  /// Supports clock injection via [currentTime] or [clock].
  static String getGreeting({DateTime? currentTime, DateTime Function()? clock}) {
    final now = currentTime ?? (clock != null ? clock() : DateTime.now());
    final hour = now.hour;
    if (hour >= morningStartHour && hour < afternoonStartHour) {
      return 'Good Morning';
    } else if (hour >= afternoonStartHour && hour < eveningStartHour) {
      return 'Good Afternoon';
    } else if (hour >= eveningStartHour && hour < nightStartHour) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  /// Resolves the user's full display name following the priority order:
  /// 1. users/{uid} "name" field or repository user profile
  /// 2. Firebase displayName
  /// 3. The part of the email before @
  /// 4. No name (null) - never returns "there"
  static String? resolveDisplayName({
    AppUser? user,
    String? profileName,
    String? authDisplayName,
    String? email,
    bool isDemo = false,
  }) {
    final pName = user?.name ?? profileName;
    if (pName != null && pName.trim().isNotEmpty) {
      return pName.trim();
    }

    final isDemoMode = isDemo || user?.isDemoUser == true;
    if (isDemoMode) {
      // In demo mode without a typed name, don't invent a person
      return null;
    }

    if (authDisplayName != null && authDisplayName.trim().isNotEmpty) {
      return authDisplayName.trim();
    }

    final targetEmail = user?.email ?? email;
    if (targetEmail != null && targetEmail.contains('@')) {
      final part = targetEmail.split('@').first.trim();
      if (part.isNotEmpty) {
        return part;
      }
    }

    return null;
  }

  /// Resolves the FIRST name of the user for the home greeting.
  static String? resolveFirstName({
    AppUser? user,
    String? profileName,
    String? authDisplayName,
    String? email,
    bool isDemo = false,
  }) {
    final fullName = resolveDisplayName(
      user: user,
      profileName: profileName,
      authDisplayName: authDisplayName,
      email: email,
      isDemo: isDemo,
    );
    if (fullName == null || fullName.trim().isEmpty) return null;

    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.first;
  }

  /// Extracts up to 2 uppercase initials from a name string.
  /// Handles empty strings, extra spaces, and single-word names safely.
  static String getInitials(String? name) {
    if (name == null) return '';
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
