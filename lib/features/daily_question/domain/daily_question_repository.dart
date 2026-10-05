import 'daily_question.dart';

/// Daily question operations. Implemented by Supabase in production and by
/// fakes in tests.
abstract interface class DailyQuestionRepository {
  /// Today's question with the current user's answer and, if the user has
  /// answered and the partner has too, the partner's answer.
  Future<DailyQuestionStatus> getToday();

  /// Creates or replaces the current user's answer for [date].
  ///
  /// Throws [DailyQuestionFailure] with
  /// [DailyQuestionFailureReason.answersLocked] if the partner has already
  /// answered, since revealed answers cannot change.
  Future<void> saveMyAnswer(DateTime date, String body);

  /// Sets the current user's reaction to the answer [answerId] (the partner's
  /// revealed answer). An empty [reaction] removes it.
  Future<void> setMyReaction(String answerId, Reaction reaction);
}

enum DailyQuestionFailureReason {
  notInCouple,
  noQuestions,
  answersLocked,
  unknown,
}

class DailyQuestionFailure implements Exception {
  const DailyQuestionFailure(this.reason);

  final DailyQuestionFailureReason reason;

  /// Text that is safe to show to the user.
  String get message => switch (reason) {
    DailyQuestionFailureReason.notInCouple =>
      'Create or join a space to get your daily question.',
    DailyQuestionFailureReason.noQuestions =>
      'There is no question for today yet.',
    DailyQuestionFailureReason.answersLocked =>
      'Your partner has answered, so your answers are now final.',
    DailyQuestionFailureReason.unknown =>
      'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'DailyQuestionFailure: ${reason.name}';
}
