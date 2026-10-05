import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/auth/domain/auth_repository.dart';
import 'package:ohana/features/auth/presentation/auth_providers.dart';
import 'package:ohana/features/auth/presentation/sign_in_screen.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;

  Future<void> pumpScreen(WidgetTester tester) async {
    auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );
  }

  testWidgets('sends a magic link and shows the confirmation', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), ' sam@example.com ');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();

    expect(auth.magicLinkEmails, ['sam@example.com']);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('sam@example.com'), findsOneWidget);
  });

  testWidgets('does not call the repository for an invalid email', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();

    expect(auth.magicLinkEmails, isEmpty);
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('"Use a different email" returns to the form', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), 'sam@example.com');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();

    expect(find.text('Email me a sign-in link'), findsOneWidget);
  });

  testWidgets('Apple and Google buttons call the repository', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(auth.appleCalls, 1);
    expect(auth.googleCalls, 1);
  });

  testWidgets('shows the failure message and stays on the form', (
    tester,
  ) async {
    await pumpScreen(tester);
    auth.nextError = const AuthFailure('Email rate limit exceeded');

    await tester.enterText(find.byType(TextFormField), 'sam@example.com');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();

    expect(find.text('Email rate limit exceeded'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
  });

  testWidgets('shows a generic message for unexpected errors', (tester) async {
    await pumpScreen(tester);
    auth.nextError = StateError('boom');

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('boom'), findsNothing);
  });
}
