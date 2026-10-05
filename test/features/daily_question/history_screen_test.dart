import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ohana/features/daily_question/domain/daily_question.dart';
import 'package:ohana/features/daily_question/presentation/daily_question_providers.dart';
import 'package:ohana/features/daily_question/presentation/history_screen.dart';

import 'fake_daily_question_repository.dart';

void main() {
  late FakeDailyQuestionRepository questions;

  Future<void> pumpHistory(
    WidgetTester tester, {
    void Function(FakeDailyQuestionRepository)? configure,
  }) async {
    questions = FakeDailyQuestionRepository();
    configure?.call(questions);
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(
          path: '/history/:date',
          builder: (_, state) =>
              HistoryDayScreen(date: state.pathParameters['date']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyQuestionRepositoryProvider.overrideWithValue(questions),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  void threeDays(FakeDailyQuestionRepository q) {
    q.pastDays[DateTime(2026, 10, 4)] = FakePastDay(
      'When do you feel most like yourself?',
      myAnswer: 'On long walks',
      partnerAnswer: 'Cooking for friends',
    );
    q.pastDays[DateTime(2026, 10, 3)] = FakePastDay(
      'What helps you most after a hard day?',
      myAnswer: 'Quiet',
    );
    q.pastDays[DateTime(2026, 10, 2)] = FakePastDay(
      'What are you looking forward to?',
      partnerAnswer: 'Partner secret',
    );
  }

  testWidgets('lists past questions newest first with the user\'s status', (
    tester,
  ) async {
    await pumpHistory(tester, configure: threeDays);

    final first = tester.getTopLeft(
      find.text('When do you feel most like yourself?'),
    );
    final last = tester.getTopLeft(
      find.text('What are you looking forward to?'),
    );
    expect(first.dy, lessThan(last.dy));

    expect(find.textContaining('Both answered'), findsOneWidget);
    expect(find.textContaining('Waiting for your partner'), findsOneWidget);
    expect(find.textContaining('· Answer'), findsOneWidget);
  });

  testWidgets('does not reveal that the partner answered an unanswered day', (
    tester,
  ) async {
    await pumpHistory(tester, configure: threeDays);

    expect(find.textContaining('Partner secret'), findsNothing);
    await tester.tap(find.text('What are you looking forward to?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Partner secret'), findsNothing);
    expect(find.text('Share answer'), findsOneWidget);
  });

  testWidgets('a missed day can be answered late and then reveals', (
    tester,
  ) async {
    await pumpHistory(tester, configure: threeDays);
    await tester.tap(find.text('What are you looking forward to?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Our trip');
    await tester.tap(find.text('Share answer'));
    await tester.pumpAndSettle();

    expect(questions.saves.single.date, DateTime(2026, 10, 2));
    expect(questions.saves.single.body, 'Our trip');
    expect(find.text('Partner secret'), findsOneWidget);

    // Back on the list the status is updated.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('· Answer'), findsNothing);
    expect(find.textContaining('Both answered'), findsNWidgets(2));
  });

  testWidgets('a revealed day shows both answers', (tester) async {
    await pumpHistory(tester, configure: threeDays);
    await tester.tap(find.text('When do you feel most like yourself?'));
    await tester.pumpAndSettle();

    expect(find.text('On long walks'), findsOneWidget);
    expect(find.text('Cooking for friends'), findsOneWidget);
    expect(find.text('Sunday, October 4, 2026'), findsOneWidget);
  });

  testWidgets('empty history shows a friendly message', (tester) async {
    await pumpHistory(tester);

    expect(find.text('Your past questions will appear here.'), findsOneWidget);
  });

  testWidgets('load failure offers a retry', (tester) async {
    await pumpHistory(
      tester,
      configure: (q) {
        threeDays(q);
        q.historyError = StateError('offline');
      },
    );
    expect(find.text('Could not load past questions.'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Both answered'), findsOneWidget);
  });

  testWidgets('a day without a question, or a bad link, shows a message', (
    tester,
  ) async {
    await pumpHistory(tester);
    final router = GoRouter.of(tester.element(find.byType(HistoryScreen)));

    router.go('/history/2020-01-01');
    await tester.pumpAndSettle();
    expect(find.text('There was no question on this day.'), findsOneWidget);

    router.go('/history/not-a-date');
    await tester.pumpAndSettle();
    expect(find.text('There was no question on this day.'), findsOneWidget);
  });

  test('unknown server status is treated as unanswered', () {
    expect(HistoryStatus.fromServer('revealed'), HistoryStatus.revealed);
    expect(HistoryStatus.fromServer('waiting'), HistoryStatus.waiting);
    expect(HistoryStatus.fromServer('unanswered'), HistoryStatus.unanswered);
    expect(HistoryStatus.fromServer('???'), HistoryStatus.unanswered);
  });
}
