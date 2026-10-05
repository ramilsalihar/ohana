import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ohana/features/couple/domain/couple_repository.dart';
import 'package:ohana/features/couple/domain/invite.dart';
import 'package:ohana/features/couple/presentation/couple_providers.dart';
import 'package:ohana/features/couple/presentation/join_couple_screen.dart';

import 'fake_couple_repository.dart';

void main() {
  late FakeCoupleRepository couples;

  Future<void> pumpScreen(WidgetTester tester, {String? initialCode}) async {
    couples = FakeCoupleRepository(
      invite: Invite(code: 'UNUSED', expiresAt: DateTime(2030)),
    );
    final router = GoRouter(
      initialLocation: '/join',
      routes: [
        GoRoute(
          path: '/join',
          builder: (_, _) => JoinCoupleScreen(initialCode: initialCode),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [coupleRepositoryProvider.overrideWithValue(couples)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterAndJoin(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextFormField), code);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
  }

  testWidgets('joins with the typed code and goes home', (tester) async {
    await pumpScreen(tester);
    await enterAndJoin(tester, 'v69nx6');

    expect(couples.joinCalls.single.leaveEmptySpace, isFalse);
    expect(couples.joinCalls.single.code, 'V69NX6');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('pre-fills the code from an invite link', (tester) async {
    await pumpScreen(tester, initialCode: 'v69nx6');

    expect(find.text('V69NX6'), findsOneWidget);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(couples.joinCalls.single.code, 'V69NX6');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('does not call the server for an incomplete code', (
    tester,
  ) async {
    await pumpScreen(tester);
    await enterAndJoin(tester, 'V69');

    expect(couples.joinCalls, isEmpty);
    expect(find.text('The code has 6 characters'), findsOneWidget);
  });

  testWidgets('shows why an invite was rejected and stays on the screen', (
    tester,
  ) async {
    const cases = {
      CoupleFailureReason.invalidInvite: 'does not match an invite',
      CoupleFailureReason.inviteUsed: 'already been used',
      CoupleFailureReason.inviteExpired: 'has expired',
      CoupleFailureReason.ownInvite: 'your own code',
      CoupleFailureReason.coupleFull: 'already has two people',
      CoupleFailureReason.alreadyInCouple: 'already in a couple space',
    };
    for (final entry in cases.entries) {
      await pumpScreen(tester);
      couples.joinErrors.add(CoupleFailure(entry.key));
      await enterAndJoin(tester, 'V69NX6');

      expect(find.textContaining(entry.value), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
    }
  });

  testWidgets('asks before replacing an empty space, then joins', (
    tester,
  ) async {
    await pumpScreen(tester);
    couples.joinErrors.add(
      const CoupleFailure(CoupleFailureReason.hasEmptySpace),
    );
    await enterAndJoin(tester, 'V69NX6');

    expect(find.textContaining('removes that empty space'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    expect(couples.joinCalls.single.leaveEmptySpace, isFalse);

    await tester.tap(find.text("Join partner's space instead"));
    await tester.pumpAndSettle();

    expect(couples.joinCalls.last.leaveEmptySpace, isTrue);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('unexpected errors show a generic message', (tester) async {
    await pumpScreen(tester);
    couples.joinErrors.add(StateError('socket closed'));
    await enterAndJoin(tester, 'V69NX6');

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('socket'), findsNothing);
  });

  testWidgets('"Not now" leaves without joining', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(couples.joinCalls, isEmpty);
    expect(find.text('HOME'), findsOneWidget);
  });
}
