import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/daily_question/domain/daily_question_repository.dart';
import 'package:ohana/features/daily_question/presentation/daily_question_card.dart';
import 'package:ohana/features/daily_question/presentation/daily_question_providers.dart';

import 'fake_daily_question_repository.dart';

void main() {
  late FakeDailyQuestionRepository questions;
  const questionText = 'What small thing made you smile today?';

  Future<void> pumpCard(
    WidgetTester tester, {
    FakeDailyQuestionRepository? repository,
    bool previewOnly = false,
  }) async {
    questions = repository ?? FakeDailyQuestionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyQuestionRepositoryProvider.overrideWithValue(questions),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyQuestionCard(previewOnly: previewOnly),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows today\'s question and saves an answer', (tester) async {
    await pumpCard(tester);
    expect(find.text(questionText), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '  Coffee in the sun ');
    await tester.tap(find.text('Share answer'));
    await tester.pumpAndSettle();

    expect(questions.saves.single.body, 'Coffee in the sun');
    expect(questions.saves.single.date, DateTime(2026, 10, 5));
    expect(find.text('Coffee in the sun'), findsOneWidget);
    expect(find.text('Waiting for your partner…'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('does not save an empty answer', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Share answer'));
    await tester.pumpAndSettle();

    expect(questions.saves, isEmpty);
    expect(find.text('Write your answer first'), findsOneWidget);
  });

  testWidgets('does not save an answer over 500 characters', (tester) async {
    await pumpCard(tester);

    await tester.enterText(find.byType(TextFormField), 'a' * 501);
    await tester.pump();
    expect(find.text('501 / 500'), findsOneWidget);
    await tester.tap(find.text('Share answer'));
    await tester.pumpAndSettle();

    expect(questions.saves, isEmpty);
    expect(find.text('Keep it to 500 characters'), findsOneWidget);
  });

  testWidgets('an answer can be edited while waiting for the partner', (
    tester,
  ) async {
    await pumpCard(
      tester,
      repository: FakeDailyQuestionRepository(myAnswer: 'First try'),
    );
    expect(find.text('Waiting for your partner…'), findsOneWidget);

    await tester.tap(find.text('Edit answer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Second try');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(questions.saves.single.body, 'Second try');
    expect(find.text('Second try'), findsOneWidget);
    expect(find.text('Waiting for your partner…'), findsOneWidget);
  });

  testWidgets('cancelling an edit keeps the saved answer', (tester) async {
    await pumpCard(
      tester,
      repository: FakeDailyQuestionRepository(myAnswer: 'First try'),
    );

    await tester.tap(find.text('Edit answer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Discard me');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(questions.saves, isEmpty);
    expect(find.text('First try'), findsOneWidget);
    expect(find.text('Discard me'), findsNothing);
  });

  testWidgets('once both answered, the answer is final', (tester) async {
    await pumpCard(
      tester,
      repository: FakeDailyQuestionRepository(
        myAnswer: 'Mine',
        partnerAnswer: 'Theirs',
      ),
    );

    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('Theirs'), findsOneWidget);
    expect(find.text('Edit answer'), findsNothing);
    expect(find.text('Waiting for your partner…'), findsNothing);
  });

  testWidgets('partner answering mid-edit keeps the saved answer and reveals', (
    tester,
  ) async {
    await pumpCard(
      tester,
      repository: FakeDailyQuestionRepository(myAnswer: 'First try'),
    );
    await tester.tap(find.text('Edit answer'));
    await tester.pumpAndSettle();
    questions.partnerAnswersBeforeSave = true;

    await tester.enterText(find.byType(TextFormField), 'Too late');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(questions.saves, isEmpty);
    expect(questions.myAnswer, 'First try');
    expect(
      find.text('Your partner has answered, so your answers are now final.'),
      findsOneWidget,
    );
    // The card reloads into the reveal, with the original answer intact.
    expect(find.text('First try'), findsOneWidget);
    expect(find.text('Partner got there first'), findsOneWidget);
    expect(find.text('Too late'), findsNothing);
  });

  testWidgets('never shows the partner\'s answer before the user answers', (
    tester,
  ) async {
    await pumpCard(
      tester,
      repository: FakeDailyQuestionRepository(partnerAnswer: 'Partner secret'),
    );

    expect(find.textContaining('Partner secret'), findsNothing);
    expect(find.text('Share answer'), findsOneWidget);
    // No hint that the partner has or has not answered.
    expect(find.textContaining('partner has answered'), findsNothing);
  });

  testWidgets('preview mode shows the question without an editor', (
    tester,
  ) async {
    await pumpCard(tester, previewOnly: true);

    expect(find.text(questionText), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(
      find.text('You can both answer once your partner joins.'),
      findsOneWidget,
    );
  });

  testWidgets('save failure keeps the draft and shows a message', (
    tester,
  ) async {
    await pumpCard(tester);
    questions.saveError = StateError('socket closed');

    await tester.enterText(find.byType(TextFormField), 'My draft');
    await tester.tap(find.text('Share answer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('socket'), findsNothing);
    expect(find.text('My draft'), findsOneWidget);
  });

  testWidgets('load failure offers a retry', (tester) async {
    await pumpCard(
      tester,
      repository: FakeDailyQuestionRepository()
        ..loadError = const DailyQuestionFailure(
          DailyQuestionFailureReason.noQuestions,
        ),
    );
    expect(find.text('There is no question for today yet.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text(questionText), findsOneWidget);
  });
}
