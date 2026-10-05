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

/// One person's response to the other's revealed answer: an emoji, a short
/// comment, or both.
class Reaction {
  const Reaction({this.emoji, this.comment});

  final String? emoji;
  final String? comment;

  bool get isEmpty => emoji == null && comment == null;
}

/// Quick reactions offered under the partner's answer.
const reactionEmojis = ['❤️', '😂', '🥹', '🤗', '👏'];

const reactionCommentMaxLength = 280;

/// Returns an error message for a reaction comment, or null when it can be
/// saved. An empty comment is allowed (it clears the comment).
String? validateReactionComment(String? input) {
  final text = input?.trim() ?? '';
  if (answerLength(text) > reactionCommentMaxLength) {
    return 'Keep it to $reactionCommentMaxLength characters';
  }
  return null;
}

/// Everything the current user may see about one day's question.
class DailyQuestionStatus {
  const DailyQuestionStatus({
    required this.question,
    this.myAnswer,
    this.partnerAnswer,
    this.partnerName,
    this.myReaction,
    this.partnerReaction,
  });

  final DailyQuestion question;
  final Answer? myAnswer;

  /// Only ever present once the current user has answered (mutual reveal is
  /// enforced by the server).
  final Answer? partnerAnswer;

  /// The partner's display name, when revealed and set.
  final String? partnerName;

  /// The current user's reaction to the partner's answer.
  final Reaction? myReaction;

  /// The partner's reaction to the current user's answer.
  final Reaction? partnerReaction;

  bool get hasAnswered => myAnswer != null;

  /// Both partners answered: answers are revealed and can no longer change.
  bool get isRevealed => myAnswer != null && partnerAnswer != null;
}

/// Where the current user stands on a past question. It describes only
/// their own side: a day they have not answered is [unanswered] whether or
/// not the partner has answered it.
enum HistoryStatus {
  unanswered,
  waiting,
  revealed;

  static HistoryStatus fromServer(String value) => switch (value) {
    'revealed' => revealed,
    'waiting' => waiting,
    _ => unanswered,
  };
}

class QuestionHistoryEntry {
  const QuestionHistoryEntry({required this.question, required this.status});

  final DailyQuestion question;
  final HistoryStatus status;
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
