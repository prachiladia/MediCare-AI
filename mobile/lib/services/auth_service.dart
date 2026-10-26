import 'dart:async';
import '../models/app_user.dart';

/// Exception thrown when authentication operations encounter errors.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Abstract contract for authentication in MediCare AI.
///
/// Keeps presentation layer decoupled from Firebase SDK specifics,
/// allowing seamless switching between Firebase Auth and In-Memory Demo mode.
abstract class AuthService {
  /// Emits whenever authentication status changes.
  Stream<AppUser?> get authStateChanges;

  /// Returns the currently authenticated user, or null if unauthenticated.
  AppUser? get currentUser;

  /// Whether the current session is executing in local in-memory demo mode.
  bool get isDemoMode;

  /// Signs in a user with their email address and password.
  /// Never stores or logs passwords.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new user account with their email, password, and display name.
  /// Never stores or logs passwords.
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  });

  /// Enters the application in local demonstration mode.
  Future<AppUser> signInWithDemoMode();

  /// Signs out the currently authenticated user.
  Future<void> signOut();
}

/// Central service locator holding the active [AuthService] instance.
class AuthManager {
  static AuthService? _instance;
  static bool isFirebaseInitialized = false;
  static String? initializationError;

  static AuthService get instance {
    _instance ??= _createDefault();
    return _instance!;
  }

  static void setInstance(AuthService service) {
    _instance = service;
  }

  static AuthService _createDefault() {
    // Default to in-memory auth until explicitly replaced by initialized FirebaseAuthService
    return _InMemoryAuthFallback();
  }

  static void reset() {
    _instance = null;
    isFirebaseInitialized = false;
    initializationError = null;
  }
}

/// Lightweight fallback implementation used before [InMemoryAuthService] is wired.
class _InMemoryAuthFallback implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isDemoMode => true;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _user = AppUser(
      uid: 'demo_${email.hashCode.abs()}',
      email: email,
      name: email.contains('@') ? email.split('@').first : 'Demo User',
      isDemoUser: true,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    _user = AppUser(
      uid: 'demo_${email.hashCode.abs()}',
      email: email,
      name: name,
      isDemoUser: true,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signInWithDemoMode() async {
    _user = AppUser.demoUser;
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
