/// Represents caregiver contact details and alert preferences.
class CaregiverInfo {
  final String name;
  final String relationship;
  final String phone;
  final String email;
  final bool alertOnThreeMisses;

  const CaregiverInfo({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.email,
    this.alertOnThreeMisses = true,
  });

  /// Default sample caregiver for demonstration and prototyping.
  static const CaregiverInfo defaultCaregiver = CaregiverInfo(
    name: 'Dr. Sarah Jenkins',
    relationship: 'Primary Care Physician',
    phone: '+1 (555) 019-2834',
    email: 'sarah.jenkins@clinic.org',
    alertOnThreeMisses: true,
  );

  CaregiverInfo copyWith({
    String? name,
    String? relationship,
    String? phone,
    String? email,
    bool? alertOnThreeMisses,
  }) {
    return CaregiverInfo(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      alertOnThreeMisses: alertOnThreeMisses ?? this.alertOnThreeMisses,
    );
  }

  // ---------------------------------------------------------------------------
  // Validation Rules (Section 17)
  // ---------------------------------------------------------------------------

  static String? validateName(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Caregiver name is required';
    }
    if (val.trim().length < 2) {
      return 'Caregiver name must be at least 2 characters';
    }
    return null;
  }

  static String? validateRelationship(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Relationship is required';
    }
    return null;
  }

  static String? validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      return 'Enter a valid phone number (at least 7 digits)';
    }
    return null;
  }

  static String? validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = val.trim();
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
