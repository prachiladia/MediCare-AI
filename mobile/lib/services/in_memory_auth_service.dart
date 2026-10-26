import 'dart:async';
import '../models/app_user.dart';
import 'auth_service.dart';

/// In-memory mock implementation of [AuthService] for demonstration mode and tests.
///
/// Features:
/// - Emits authentication state transitions over a broadcast stream.
/// - Validates email and password constraints.
/// - Supports registered user map in volatile memory.
/// - Never persists passwords.
class InMemoryAuthService implements AuthService {
  final Duration simulatedDelay;
  final Map<String, AppUser> _usersByEmail = {};
  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  InMemoryAuthService({
    this.simulatedDelay = Duration.zero,
    AppUser? initialUser,
  }) {
    if (initialUser != null) {
      _currentUser = initialUser;
      _usersByEmail[initialUser.email.toLowerCase()] = initialUser;
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isDemoMode => true;

  Future<void> _maybeDelay() async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _maybeDelay();

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email address is required', code: 'invalid-email');
    }
    if (password.isEmpty) {
      throw const AuthException('Password is required', code: 'wrong-password');
    }

    // In demo mode, sign in existing demo user or auto-provision session
    AppUser user = _usersByEmail[cleanEmail] ??
        AppUser(
          uid: 'demo_${cleanEmail.hashCode.abs()}',
          email: email.trim(),
          name: email.contains('@') ? email.split('@').first : 'Demo User',
          isDemoUser: true,
        );

    _usersByEmail[cleanEmail] = user;
    _currentUser = user;
    _authController.add(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    await _maybeDelay();

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email address is required', code: 'invalid-email');
    }
    if (password.length < 6) {
      throw const AuthException(
        'The password is too weak. Please choose at least 6 characters.',
        code: 'weak-password',
      );
    }
    if (name.trim().isEmpty) {
      throw const AuthException('Name is required', code: 'invalid-name');
    }

    final newUser = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}_${cleanEmail.hashCode.abs()}',
      email: email.trim(),
      name: name.trim(),
      isDemoUser: true,
    );

    _usersByEmail[cleanEmail] = newUser;
    _currentUser = newUser;
    _authController.add(newUser);
    return newUser;
  }

  @override
  Future<AppUser> signInWithDemoMode() async {
    await _maybeDelay();
    _currentUser = AppUser.demoUser;
    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await _maybeDelay();
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}
