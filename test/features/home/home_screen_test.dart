import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ohana/core/utils/clock.dart';
import 'package:ohana/features/auth/domain/app_user.dart';
import 'package:ohana/features/auth/presentation/auth_providers.dart';
import 'package:ohana/features/couple/domain/couple_repository.dart';
import 'package:ohana/features/couple/domain/invite.dart';
import 'package:ohana/features/couple/presentation/couple_providers.dart';
import 'package:ohana/features/daily_question/presentation/daily_question_providers.dart';
import 'package:ohana/features/home/presentation/home_screen.dart';

import '../auth/fake_auth_repository.dart';
import '../couple/fake_couple_repository.dart';
import '../daily_question/fake_daily_question_repository.dart';

class _FailingOnceCoupleRepository extends FakeCoupleRepository {
  _FailingOnceCoupleRepository({required super.invite});

  bool failed = false;

  @override
  Future<CoupleSpace?> getMyCouple() async {
    if (!failed) {
      failed = true;
      throw StateError('offline');
    }
    return super.getMyCouple();
  }
}

void main() {
  late FakeAuthRepository auth;
  late FakeCoupleRepository couples;
  final invite = Invite(code: 'UNUSED', expiresAt: DateTime(2030));

  Future<void> pumpHome(
    WidgetTester tester, {
    CoupleSpace? couple,
    DateTime? today,
    FakeCoupleRepository? repository,
  }) async {
    auth = FakeAuthRepository(user: const AppUser(id: 'u1'));
    couples = (repository ?? FakeCoupleRepository(invite: invite))
      ..couple = couple;
    Widget page(String name) => Scaffold(body: Text(name));
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/couple/create', builder: (_, _) => page('CREATE')),
        GoRoute(path: '/join', builder: (_, _) => page('JOIN')),
        GoRoute(path: '/profile/setup', builder: (_, _) => page('PROFILE')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          coupleRepositoryProvider.overrideWithValue(couples),
          dailyQuestionRepositoryProvider.overrideWithValue(
            FakeDailyQuestionRepository(),
          ),
          clockProvider.overrideWithValue(
            () => today ?? DateTime(2026, 10, 5, 9),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no couple: offers to create or join a space', (tester) async {
    await pumpHome(tester);

    expect(find.text('Start your space'), findsOneWidget);
    await tester.tap(find.text('Create our space'));
    await tester.pumpAndSettle();
    expect(find.text('CREATE'), findsOneWidget);
  });

  testWidgets('no couple: join opens the join screen', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();
    expect(find.text('JOIN'), findsOneWidget);
  });

  testWidgets('alone in a space: shows waiting state, no counter', (
    tester,
  ) async {
    await pumpHome(
      tester,
      couple: CoupleSpace(
        id: 'c1',
        memberCount: 1,
        togetherSince: DateTime(2023, 5, 14),
      ),
    );

    expect(find.text('Waiting for your partner'), findsOneWidget);
    expect(find.text('together'), findsNothing);

    // "Check again" picks up the partner joining.
    couples.couple = CoupleSpace(
      id: 'c1',
      togetherSince: DateTime(2023, 5, 14),
    );
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('together'), findsOneWidget);
  });

  testWidgets('paired without a date: asks for "together since"', (
    tester,
  ) async {
    await pumpHome(tester, couple: const CoupleSpace(id: 'c1'));

    expect(find.text('When did you get together?'), findsOneWidget);
    await tester.tap(find.text('Add the date'));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE'), findsOneWidget);
  });

  testWidgets('shows the day count with thousands separator and milestone', (
    tester,
  ) async {
    // 2023-05-14 → 2026-10-11 is day 1,247; day 1,300 is 53 days away.
    await pumpHome(
      tester,
      couple: CoupleSpace(id: 'c1', togetherSince: DateTime(2023, 5, 14)),
      today: DateTime(2026, 10, 11),
    );

    expect(find.text('1,247'), findsOneWidget);
    expect(find.text('together'), findsOneWidget);
    expect(find.text('Day 1,300 in 53 days'), findsOneWidget);
  });

  testWidgets('anniversary today', (tester) async {
    await pumpHome(
      tester,
      couple: CoupleSpace(id: 'c1', togetherSince: DateTime(2023, 5, 14)),
      today: DateTime(2026, 5, 14),
    );

    expect(find.text('Today: 3 years together'), findsOneWidget);
  });

  testWidgets('milestone tomorrow uses singular wording', (tester) async {
    await pumpHome(
      tester,
      couple: CoupleSpace(id: 'c1', togetherSince: DateTime(2025, 5, 14)),
      today: DateTime(2026, 5, 13),
    );

    expect(find.text('1 year together is tomorrow'), findsOneWidget);
  });

  testWidgets('a future start date asks for the date instead of counting', (
    tester,
  ) async {
    await pumpHome(
      tester,
      couple: CoupleSpace(id: 'c1', togetherSince: DateTime(2027)),
      today: DateTime(2026, 10, 5),
    );

    expect(find.text('When did you get together?'), findsOneWidget);
  });

  testWidgets('load failure shows a retry that recovers', (tester) async {
    await pumpHome(
      tester,
      repository: _FailingOnceCoupleRepository(invite: invite),
    );
    expect(find.text('Could not load your space'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Start your space'), findsOneWidget);
  });

  testWidgets('sign out is available from the menu', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
  });

  testWidgets('profile button opens profile setup', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Your profile'));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE'), findsOneWidget);
  });

  const question = 'What small thing made you smile today?';

  testWidgets('paired: shows today\'s question with an editor', (tester) async {
    await pumpHome(
      tester,
      couple: CoupleSpace(id: 'c1', togetherSince: DateTime(2023, 5, 14)),
    );

    expect(find.text(question), findsOneWidget);
    expect(find.text('Share answer'), findsOneWidget);
  });

  testWidgets('waiting for partner: question is a read-only preview', (
    tester,
  ) async {
    await pumpHome(tester, couple: const CoupleSpace(id: 'c1', memberCount: 1));

    expect(find.text(question), findsOneWidget);
    expect(find.text('Share answer'), findsNothing);
  });

  testWidgets('no couple: no question is shown', (tester) async {
    await pumpHome(tester);

    expect(find.text(question), findsNothing);
  });
}
