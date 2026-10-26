import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/caregiver.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/firebase_auth_service.dart';
import 'package:mobile/services/in_memory_auth_service.dart';

void main() {
  group('Phase 9 - AppUser Model Tests', () {
    test('1. AppUser toMap and fromMap serialization with nested caregiver', () {
      const caregiver = CaregiverInfo(
        name: 'Dr. Sarah Jenkins',
        relationship: 'Primary Care Physician',
        phone: '+1 (555) 019-2834',
        email: 'sarah.jenkins@clinic.org',
      );

      const user = AppUser(
        uid: 'user_123',
        email: 'test.user@example.com',
        name: 'Test User',
        phone: '+1 (555) 012-3456',
        caregiver: caregiver,
        isDemoUser: false,
      );

      final map = user.toMap();
      expect(map['email'], equals('test.user@example.com'));
      expect(map['name'], equals('Test User'));
      expect(map['phone'], equals('+1 (555) 012-3456'));
      expect(map['caregiver'], isA<Map<String, dynamic>>());
      expect(map['caregiver']['name'], equals('Dr. Sarah Jenkins'));

      final restored = AppUser.fromMap(uid: 'user_123', data: map);
      expect(restored.uid, equals('user_123'));
      expect(restored.email, equals(user.email));
      expect(restored.name, equals(user.name));
      expect(restored.phone, equals(user.phone));
      expect(restored.caregiver?.name, equals('Dr. Sarah Jenkins'));
      expect(restored.caregiver?.phone, equals('+1 (555) 019-2834'));
    });

    test('2. AppUser handles missing optional fields safely', () {
      final minimal = AppUser.fromMap(
        uid: 'user_min',
        data: {
          'email': 'minimal@example.com',
          'name': 'Minimal User',
        },
      );

      expect(minimal.uid, equals('user_min'));
      expect(minimal.email, equals('minimal@example.com'));
      expect(minimal.name, equals('Minimal User'));
      expect(minimal.phone, isNull);
      expect(minimal.caregiver, isNull);
      expect(minimal.isDemoUser, isFalse);
    });
  });

  group('Phase 9 - InMemoryAuthService Unit Tests', () {
    late InMemoryAuthService authService;

    setUp(() {
      authService = InMemoryAuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('3. signInWithEmailAndPassword rejects empty email and password', () async {
      expect(
        () => authService.signInWithEmailAndPassword(email: '', password: 'password123'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-email')),
      );

      expect(
        () => authService.signInWithEmailAndPassword(email: 'user@example.com', password: ''),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'wrong-password')),
      );
    });

    test('4. signInWithEmailAndPassword succeeds with valid inputs and emits authStateChanges', () async {
      expectLater(
        authService.authStateChanges,
        emits(isA<AppUser>().having((u) => u.email, 'email', 'patient@clinic.org')),
      );

      final user = await authService.signInWithEmailAndPassword(
        email: 'patient@clinic.org',
        password: 'securePassword123',
      );

      expect(user.email, equals('patient@clinic.org'));
      expect(user.isDemoUser, isTrue);
      expect(authService.currentUser?.email, equals('patient@clinic.org'));
    });

    test('5. registerWithEmailAndPassword validates password length >= 6 and requires name', () async {
      expect(
        () => authService.registerWithEmailAndPassword(
          email: 'new@example.com',
          password: '123', // < 6 chars
          name: 'New User',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'weak-password')),
      );

      expect(
        () => authService.registerWithEmailAndPassword(
          email: 'new@example.com',
          password: 'validPassword123',
          name: '', // Empty name
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-name')),
      );

      final registered = await authService.registerWithEmailAndPassword(
        email: 'new@example.com',
        password: 'validPassword123',
        name: 'Jordan Lee',
      );

      expect(registered.name, equals('Jordan Lee'));
      expect(registered.email, equals('new@example.com'));
      expect(authService.currentUser?.name, equals('Jordan Lee'));
    });

    test('6. signInWithDemoMode sets AppUser.demoUser', () async {
      final user = await authService.signInWithDemoMode();
      expect(user.uid, equals('demo_user_123'));
      expect(user.name, equals(''));
      expect(user.isDemoUser, isTrue);
      expect(authService.isDemoMode, isTrue);
    });

    test('7. signOut resets currentUser and emits null', () async {
      await authService.signInWithDemoMode();
      expect(authService.currentUser, isNotNull);

      expectLater(authService.authStateChanges, emits(isNull));

      await authService.signOut();
      expect(authService.currentUser, isNull);
    });
  });

  group('Phase 9 - FirebaseAuthService Error Mapping Tests', () {
    test('8. Error code translation maps Firebase Auth error codes to friendly messages', () {
      expect(
        FirebaseAuthService.mapFirebaseAuthError('user-not-found'),
        contains('No account found with this email'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('wrong-password'),
        contains('Incorrect password'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('invalid-credential'),
        contains('Invalid email or password'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('email-already-in-use'),
        contains('already exists with this email'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('weak-password'),
        contains('The password is too weak'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('invalid-email'),
        contains('improperly formatted'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('network-request-failed'),
        contains('Network connection error'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('user-disabled'),
        contains('disabled'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('too-many-requests'),
        contains('Too many unsuccessful attempts'),
      );

      expect(
        FirebaseAuthService.mapFirebaseAuthError('custom-error-code', 'Detailed message'),
        equals('Detailed message'),
      );
    });
  });

  group('Phase 9 - AuthManager Service Locator Tests', () {
    tearDown(() {
      AuthManager.reset();
    });

    test('9. AuthManager defaults to in-memory fallback and allows setting custom instance', () {
      expect(AuthManager.instance, isNotNull);
      expect(AuthManager.instance.isDemoMode, isTrue);
      expect(AuthManager.isFirebaseInitialized, isFalse);

      final customMock = InMemoryAuthService(
        initialUser: const AppUser(
          uid: 'custom_1',
          email: 'custom@example.com',
          name: 'Custom User',
        ),
      );

      AuthManager.setInstance(customMock);
      expect(AuthManager.instance.currentUser?.email, equals('custom@example.com'));

      AuthManager.reset();
      expect(AuthManager.instance.currentUser, isNull);
    });
  });
}
