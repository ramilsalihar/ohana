/// The couple's question for one day.
class DailyQuestion {
  const DailyQuestion({
    required this.date,
    required this.questionId,
    required this.text,
    required this.category,
  });

  /// The question day (rolls over at 04:00 in the couple's time zone).
  final DateTime date;
  final String questionId;
  final String text;
  final String category;
}

class Answer {
  const Answer({required this.id, required this.userId, required this.body});

  final String id;
  final String userId;
  final String body;
}

/// Everything the current user may see about one day's question.
class DailyQuestionStatus {
  const DailyQuestionStatus({
    required this.question,
    this.myAnswer,
    this.partnerAnswer,
  });

  final DailyQuestion question;
  final Answer? myAnswer;

  /// Only ever present once the current user has answered (mutual reveal is
  /// enforced by the server).
  final Answer? partnerAnswer;

  bool get hasAnswered => myAnswer != null;

  /// Both partners answered: answers are revealed and can no longer change.
  bool get isRevealed => myAnswer != null && partnerAnswer != null;
}

const answerMaxLength = 500;

/// Length the way the server counts it (Unicode code points), so a message
/// that passes here is not rejected there.
int answerLength(String text) => text.runes.length;

/// Returns an error message for [input], or null when it can be saved.
String? validateAnswer(String? input) {
  final text = input?.trim() ?? '';
  if (text.isEmpty) return 'Write your answer first';
  if (answerLength(text) > answerMaxLength) {
    return 'Keep it to $answerMaxLength characters';
  }
  return null;
}
