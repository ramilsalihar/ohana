import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/app/router/app_router.dart';
import 'package:ohana/features/home/presentation/home_screen.dart';
import 'package:ohana/features/welcome/presentation/welcome_screen.dart';

void main() {
  Future<ProviderContainer> pumpRouter(WidgetTester tester) async {
    final container = ProviderContainer();
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

  testWidgets('starts on /welcome', (tester) async {
    await pumpRouter(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('navigates to /home through the router provider', (tester) async {
    final container = await pumpRouter(tester);

    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('welcome button goes to /home', (tester) async {
    await pumpRouter(tester);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
