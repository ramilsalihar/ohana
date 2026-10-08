import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/core/config/env.dart';
import 'package:ohana/features/auth/presentation/auth_providers.dart';
import 'package:ohana/features/auth/presentation/sign_in_screen.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;

  Future<void> pumpScreen(WidgetTester tester, {required bool enabled}) async {
    auth = FakeAuthRepository();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          testLoginEnabledProvider.overrideWithValue(enabled),
        ],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );
  }

  Finder field(String key) => find.byKey(Key(key));

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(field('test-login-email'), email);
    await tester.enterText(field('test-login-password'), password);
  }

  testWidgets('hidden unless enabled', (tester) async {
    await pumpScreen(tester, enabled: false);

    expect(find.text('Test sign-in (debug only)'), findsNothing);
    expect(find.text('Email me a sign-in link'), findsOneWidget);
  });

  testWidgets('creates a test account and signs in', (tester) async {
    await pumpScreen(tester, enabled: true);

    await fill(tester, 'tester@example.com', 'secret123');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.email, 'tester@example.com');
  });

  testWidgets('signs in to an existing test account', (tester) async {
    await pumpScreen(tester, enabled: true);
    auth.passwordAccounts['tester@example.com'] = 'secret123';

    await fill(tester, ' tester@example.com ', 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.email, 'tester@example.com');
  });

  testWidgets('wrong password shows the server message', (tester) async {
    await pumpScreen(tester, enabled: true);
    auth.passwordAccounts['tester@example.com'] = 'secret123';

    await fill(tester, 'tester@example.com', 'wrong-one');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(find.text('Invalid login credentials'), findsOneWidget);
  });

  testWidgets('explains when the project requires email confirmation', (
    tester,
  ) async {
    await pumpScreen(tester, enabled: true);
    auth.signUpNeedsConfirmation = true;

    await fill(tester, 'tester@example.com', 'secret123');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(find.textContaining('requires email confirmation'), findsOneWidget);
  });

  testWidgets('validates email and password length before calling', (
    tester,
  ) async {
    await pumpScreen(tester, enabled: true);

    await fill(tester, 'not-an-email', '123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('At least 6 characters'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  test('the flag alone is not enough outside debug builds', () {
    const requested = Env(
      supabaseUrl: 'u',
      supabaseAnonKey: 'k',
      testLoginRequested: true,
    );
    const notRequested = Env(supabaseUrl: 'u', supabaseAnonKey: 'k');

    // Tests run in debug mode, so the flag decides here; release builds
    // compile kDebugMode to false and the feature disappears.
    expect(requested.testLoginEnabled, isTrue);
    expect(notRequested.testLoginEnabled, isFalse);
  });
}
