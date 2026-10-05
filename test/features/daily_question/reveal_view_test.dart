import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/daily_question/domain/daily_question.dart';
import 'package:ohana/features/daily_question/presentation/daily_question_card.dart';
import 'package:ohana/features/daily_question/presentation/daily_question_providers.dart';

import 'fake_daily_question_repository.dart';

void main() {
  late FakeDailyQuestionRepository questions;

  Future<void> pumpRevealed(
    WidgetTester tester, {
    void Function(FakeDailyQuestionRepository)? configure,
    double width = 400,
  }) async {
    questions = FakeDailyQuestionRepository(
      myAnswer: 'Coffee in the sun',
      partnerAnswer: 'Your terrible pun',
    );
    configure?.call(questions);
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyQuestionRepositoryProvider.overrideWithValue(questions),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DailyQuestionCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows both answers labelled with the partner\'s name', (
    tester,
  ) async {
    await pumpRevealed(tester);

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Coffee in the sun'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Your terrible pun'), findsOneWidget);
  });

  testWidgets('falls back to "Your partner" when no name is set', (
    tester,
  ) async {
    await pumpRevealed(tester, configure: (q) => q.partnerName = null);

    expect(find.text('Your partner'), findsOneWidget);
  });

  testWidgets(
    'answers sit side by side on a wide layout, stacked when narrow',
    (tester) async {
      await pumpRevealed(tester, width: 800);
      final mineWide = tester.getTopLeft(find.text('Coffee in the sun'));
      final theirsWide = tester.getTopLeft(find.text('Your terrible pun'));
      expect(theirsWide.dx, greaterThan(mineWide.dx));
      expect(theirsWide.dy, mineWide.dy);

      await pumpRevealed(tester, width: 360);
      final mineNarrow = tester.getTopLeft(find.text('Coffee in the sun'));
      final theirsNarrow = tester.getTopLeft(find.text('Your terrible pun'));
      expect(theirsNarrow.dy, greaterThan(mineNarrow.dy));
    },
  );

  testWidgets('tapping an emoji reacts to the partner\'s answer', (
    tester,
  ) async {
    await pumpRevealed(tester);

    await tester.tap(find.text('😂'));
    await tester.pumpAndSettle();

    final call = questions.reactionCalls.single;
    expect(call.answerId, 'a-partner');
    expect(call.reaction.emoji, '😂');
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '😂')).selected,
      isTrue,
    );
  });

  testWidgets('tapping the selected emoji removes the reaction', (
    tester,
  ) async {
    await pumpRevealed(
      tester,
      configure: (q) => q.myReaction = const Reaction(emoji: '❤️'),
    );

    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();

    expect(questions.reactionCalls.single.reaction.isEmpty, isTrue);
    expect(questions.myReaction, isNull);
  });

  testWidgets('changing emoji keeps the comment', (tester) async {
    await pumpRevealed(
      tester,
      configure: (q) =>
          q.myReaction = const Reaction(emoji: '❤️', comment: 'So true'),
    );

    await tester.tap(find.text('👏'));
    await tester.pumpAndSettle();

    final reaction = questions.reactionCalls.single.reaction;
    expect(reaction.emoji, '👏');
    expect(reaction.comment, 'So true');
  });

  testWidgets('sends a short comment and keeps the emoji', (tester) async {
    await pumpRevealed(
      tester,
      configure: (q) => q.myReaction = const Reaction(emoji: '❤️'),
    );
    expect(find.text('Send comment'), findsNothing);

    await tester.enterText(find.byType(TextFormField), '  Classic you  ');
    await tester.pump();
    await tester.tap(find.text('Send comment'));
    await tester.pumpAndSettle();

    final reaction = questions.reactionCalls.single.reaction;
    expect(reaction.comment, 'Classic you');
    expect(reaction.emoji, '❤️');
    expect(find.text('Send comment'), findsNothing);
  });

  testWidgets('clearing the comment removes it', (tester) async {
    await pumpRevealed(
      tester,
      configure: (q) => q.myReaction = const Reaction(comment: 'So true'),
    );

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    await tester.tap(find.text('Remove comment'));
    await tester.pumpAndSettle();

    expect(questions.reactionCalls.single.reaction.isEmpty, isTrue);
  });

  testWidgets('rejects a comment over 280 characters', (tester) async {
    await pumpRevealed(tester);

    await tester.enterText(find.byType(TextFormField), 'a' * 281);
    await tester.pump();
    await tester.tap(find.text('Send comment'));
    await tester.pumpAndSettle();

    expect(questions.reactionCalls, isEmpty);
    expect(find.text('Keep it to 280 characters'), findsOneWidget);
  });

  testWidgets('shows the partner\'s reaction to my answer', (tester) async {
    await pumpRevealed(
      tester,
      configure: (q) =>
          q.partnerReaction = const Reaction(emoji: '🥹', comment: 'Love this'),
    );

    expect(find.text('Sam reacted 🥹'), findsOneWidget);
    expect(find.text('Sam: Love this'), findsOneWidget);
  });

  testWidgets('shows nothing about reactions when the partner left none', (
    tester,
  ) async {
    await pumpRevealed(tester);

    expect(find.textContaining('reacted'), findsNothing);
    // No "has not reacted" or similar absence signal.
    expect(find.textContaining('not'), findsNothing);
  });

  testWidgets('a failed reaction shows a message and changes nothing', (
    tester,
  ) async {
    await pumpRevealed(
      tester,
      configure: (q) => q.reactionError = StateError('socket closed'),
    );

    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(questions.myReaction, isNull);
  });
}
