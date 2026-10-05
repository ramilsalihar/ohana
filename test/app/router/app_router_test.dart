import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/app/router/app_router.dart';
import 'package:ohana/features/auth/domain/app_user.dart';
import 'package:ohana/features/auth/presentation/auth_providers.dart';
import 'package:ohana/features/auth/presentation/sign_in_screen.dart';
import 'package:ohana/features/home/presentation/home_screen.dart';
import 'package:ohana/features/welcome/presentation/welcome_screen.dart';

import '../../features/auth/fake_auth_repository.dart';

const _sam = AppUser(id: 'user-1', email: 'sam@example.com');

void main() {
  Future<ProviderContainer> pumpRouter(
    WidgetTester tester,
    FakeAuthRepository auth,
  ) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) =>
              MaterialApp.router(routerConfig: ref.watch(routerProvider)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('signed out: starts on /welcome', (tester) async {
    await pumpRouter(tester, FakeAuthRepository());

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('signed out: /home redirects to /welcome', (tester) async {
    final container = await pumpRouter(tester, FakeAuthRepository());

    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('welcome button opens the sign-in screen', (tester) async {
    await pumpRouter(tester, FakeAuthRepository());

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('signed in: starts on /home', (tester) async {
    await pumpRouter(tester, FakeAuthRepository(user: _sam));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('signing in moves from sign-in to /home', (tester) async {
    final auth = FakeAuthRepository();
    await pumpRouter(tester, auth);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    auth.emit(_sam);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('signing out returns to /welcome', (tester) async {
    final auth = FakeAuthRepository(user: _sam);
    await pumpRouter(tester, auth);

    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
