import 'caregiver.dart';

/// Represents an authenticated user profile in MediCare AI.
///
/// Section 18 / Phase 9 schema:
/// - users/{uid} (doc ID = Auth uid): existing email, name.
/// - Optional: phone, caregiver (map: name, relationship, phone, email).
/// - Supports both cloud-authenticated Firebase users and in-memory demo sessions.
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final CaregiverInfo? caregiver;
  final bool isDemoUser;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.caregiver,
    this.isDemoUser = false,
  });

  /// Default demo user profile for testing and offline/demo fallback.
  static const AppUser demoUser = AppUser(
    uid: 'demo_user_123',
    email: 'demo@medicare.ai',
    name: '',
    phone: '',
    caregiver: CaregiverInfo.defaultCaregiver,
    isDemoUser: true,
  );

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    CaregiverInfo? caregiver,
    bool? isDemoUser,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      caregiver: caregiver ?? this.caregiver,
      isDemoUser: isDemoUser ?? this.isDemoUser,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (caregiver != null)
        'caregiver': {
          'name': caregiver!.name,
          'relationship': caregiver!.relationship,
          'phone': caregiver!.phone,
          'email': caregiver!.email,
        },
    };
  }

  factory AppUser.fromMap({
    required String uid,
    required Map<String, dynamic> data,
    bool isDemoUser = false,
  }) {
    CaregiverInfo? caregiverInfo;
    final cRaw = data['caregiver'];
    if (cRaw is Map) {
      caregiverInfo = CaregiverInfo(
        name: cRaw['name'] as String? ?? '',
        relationship: cRaw['relationship'] as String? ?? '',
        phone: cRaw['phone'] as String? ?? '',
        email: cRaw['email'] as String? ?? '',
      );
    }

    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      caregiver: caregiverInfo,
      isDemoUser: isDemoUser,
    );
  }
}
