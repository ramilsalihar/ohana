import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  /// Deep link the app is reopened with after a magic link or OAuth sign-in.
  /// Must be registered in the iOS/Android manifests and allow-listed in the
  /// Supabase dashboard (Authentication → URL Configuration).
  static const redirectUrl = 'com.ramilsalihar.ohana://login-callback';

  final GoTrueClient _auth;

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.onAuthStateChange.map((state) => _toAppUser(state.session?.user));

  @override
  Future<void> sendMagicLink(String email) => _guard(
    () =>
        _auth.signInWithOtp(email: email.trim(), emailRedirectTo: redirectUrl),
  );

  @override
  Future<void> signInWithPassword(String email, String password) => _guard(
    () => _auth.signInWithPassword(email: email.trim(), password: password),
  );

  @override
  Future<bool> signUpWithPassword(String email, String password) async {
    var signedIn = false;
    await _guard(() async {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
      );
      signedIn = response.session != null;
    });
    return signedIn;
  }

  @override
  Future<void> signInWithApple() => _oauth(OAuthProvider.apple);

  @override
  Future<void> signInWithGoogle() => _oauth(OAuthProvider.google);

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  Future<void> _oauth(OAuthProvider provider) => _guard(() async {
    final launched = await _auth.signInWithOAuth(
      provider,
      redirectTo: redirectUrl,
    );
    if (!launched) {
      throw const AuthFailure('Could not open the sign-in page.');
    }
  });

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  static AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email);
}
