import 'dart:async';

import 'package:ohana/features/auth/domain/app_user.dart';
import 'package:ohana/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? user}) : _user = user;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// When set, the next sign-in call throws it.
  Object? nextError;

  final List<String> magicLinkEmails = [];
  int appleCalls = 0;
  int googleCalls = 0;

  /// Simulates the backend reporting a sign-in or sign-out.
  void emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  void _throwIfNeeded() {
    final error = nextError;
    nextError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> sendMagicLink(String email) async {
    _throwIfNeeded();
    magicLinkEmails.add(email);
  }

  @override
  Future<void> signInWithApple() async {
    _throwIfNeeded();
    appleCalls++;
  }

  @override
  Future<void> signInWithGoogle() async {
    _throwIfNeeded();
    googleCalls++;
  }

  @override
  Future<void> signOut() async => emit(null);
}
