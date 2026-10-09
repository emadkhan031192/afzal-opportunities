import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Email/password authentication for the Private Teaching Jobs module.
///
/// Uses the project's existing Firebase Auth instance. No SMS OTP, no
/// paid phone auth. Email verification is required before an
/// organization can submit vacancies or a teacher can publish their
/// profile.
class TeachingAuth extends ChangeNotifier {
  TeachingAuth({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Refreshes the user (e.g. after clicking the verification link).
  Future<void> reload() async {
    await _auth.currentUser?.reload();
    notifyListeners();
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.sendEmailVerification();
    notifyListeners();
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    notifyListeners();
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Permanently deletes the signed-in Firebase Auth user. Call
  /// [TeachingService.deleteMyAccountData] first to remove the user's
  /// Firestore documents. May throw `requires-recent-login`, in which
  /// case the user must sign in again before retrying.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
    notifyListeners();
  }

  /// Firebase Auth error codes mapped to short, localizable keys.
  static String errorKey(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'invalidEmail';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'loginFailed';
        case 'email-already-in-use':
          return 'emailInUse';
        case 'weak-password':
          return 'passwordTooShort';
        case 'too-many-requests':
          return 'tooManyRequests';
        case 'network-request-failed':
          return 'networkError';
      }
    }
    return 'unknownError';
  }
}
