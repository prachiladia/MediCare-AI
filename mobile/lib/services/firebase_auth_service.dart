import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

/// Firebase implementation of [AuthService] backed by Firebase Authentication and Cloud Firestore.
///
/// Section 18 / Phase 9 Rules:
/// - users/{uid} document matches auth uid.
/// - Created at registration; created if missing at login.
/// - Never stores or logs passwords.
/// - Human-friendly error translation for all Firebase Auth error codes.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  bool get isDemoMode => false;

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? (user.email?.split('@').first ?? 'User'),
      isDemoUser: false,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;

      try {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          return AppUser.fromMap(
            uid: fbUser.uid,
            data: doc.data()!,
            isDemoUser: false,
          );
        }
      } catch (_) {
        // Fall back to Firebase Auth credentials if Firestore is briefly unreachable
      }

      return AppUser(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        name: fbUser.displayName ?? (fbUser.email?.split('@').first ?? 'User'),
        isDemoUser: false,
      );
    });
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          'Failed to obtain authenticated user credentials.',
          code: 'null-user',
        );
      }

      // Check for user document; create if missing (Phase 9 requirement)
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final doc = await userDocRef.get();

      if (!doc.exists || doc.data() == null) {
        final fallbackName = user.displayName ?? (user.email?.split('@').first ?? 'User');
        final initialData = {
          'email': user.email ?? email.trim(),
          'name': fallbackName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await userDocRef.set(initialData, SetOptions(merge: true));
        return AppUser.fromMap(uid: user.uid, data: initialData);
      }

      return AppUser.fromMap(uid: user.uid, data: doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseAuthError(e.code, e.message), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'An unexpected error occurred during sign in. Please try again.',
        code: 'unknown',
      );
    }
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          'Failed to create user account.',
          code: 'null-user',
        );
      }

      // Update Firebase Auth display name
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {}

      // Create users/{uid} document in Firestore
      final initialData = {
        'email': email.trim(),
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(
        initialData,
        SetOptions(merge: true),
      );

      return AppUser.fromMap(uid: user.uid, data: initialData);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseAuthError(e.code, e.message), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'An unexpected error occurred during account creation. Please try again.',
        code: 'unknown',
      );
    }
  }

  @override
  Future<AppUser> signInWithDemoMode() async {
    return AppUser.demoUser;
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
        'Failed to sign out cleanly: ${e.toString()}',
        code: 'sign-out-failed',
      );
    }
  }

  /// Maps technical Firebase Auth error codes to compassionate, friendly user messages.
  static String mapFirebaseAuthError(String code, [String? rawMessage]) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please check your email or create an account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please sign in instead.';
      case 'weak-password':
        return 'The password is too weak. Please choose a password with at least 6 characters.';
      case 'invalid-email':
        return 'The email address is improperly formatted.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please wait a few moments and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      default:
        return rawMessage?.isNotEmpty == true
            ? rawMessage!
            : 'Authentication failed ($code). Please try again.';
    }
  }
}
