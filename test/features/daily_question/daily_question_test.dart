import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/daily_question/domain/daily_question.dart';

void main() {
  test('answer must not be empty', () {
    expect(validateAnswer(null), 'Write your answer first');
    expect(validateAnswer('  \n '), 'Write your answer first');
    expect(validateAnswer('Coffee in the sun'), isNull);
  });

  test('answer is limited to 500 characters after trimming', () {
    expect(validateAnswer('a' * 500), isNull);
    expect(validateAnswer('  ${'a' * 500}  '), isNull);
    expect(validateAnswer('a' * 501), 'Keep it to 500 characters');
  });

  test('length is counted in code points, like the server', () {
    // One emoji is 2 UTF-16 units but 1 code point.
    expect(answerLength('😀'), 1);
    expect(validateAnswer('😀' * 500), isNull);
    expect(validateAnswer('😀' * 501), isNotNull);
  });

  test('status flags', () {
    final q = DailyQuestion(
      date: DateTime(2026, 10, 5),
      questionId: 'q',
      text: 't?',
      category: 'fun',
    );
    const mine = Answer(id: '1', userId: 'me', body: 'x');
    const theirs = Answer(id: '2', userId: 'p', body: 'y');

    expect(DailyQuestionStatus(question: q).hasAnswered, isFalse);
    expect(
      DailyQuestionStatus(question: q, myAnswer: mine).isRevealed,
      isFalse,
    );
    expect(
      DailyQuestionStatus(
        question: q,
        myAnswer: mine,
        partnerAnswer: theirs,
      ).isRevealed,
      isTrue,
    );
  });
}
