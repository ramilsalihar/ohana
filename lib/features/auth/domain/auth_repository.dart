import 'app_user.dart';

/// Sign-in operations. Implemented by Supabase in production and by fakes in
/// tests, so screens never depend on the backend SDK.
abstract interface class AuthRepository {
  /// The current user, or null when signed out.
  AppUser? get currentUser;

  /// Emits whenever the user signs in or out.
  Stream<AppUser?> authStateChanges();

  /// Emails a one-time sign-in link. Completes when the email is requested;
  /// the user is signed in later, when they open the link.
  Future<void> sendMagicLink(String email);

  /// Test-only sign-in with email and password (see `Env.testLoginEnabled`).
  Future<void> signInWithPassword(String email, String password);

  /// Test-only account creation. Returns false when the project requires the
  /// new address to be confirmed by email before the user is signed in.
  Future<bool> signUpWithPassword(String email, String password);

  Future<void> signInWithApple();

  Future<void> signInWithGoogle();

  Future<void> signOut();
}

/// A sign-in step failed. [message] is safe to show to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}
