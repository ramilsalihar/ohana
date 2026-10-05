import 'package:ohana/features/daily_question/domain/daily_question.dart';
import 'package:ohana/features/daily_question/domain/daily_question_repository.dart';

class FakeDailyQuestionRepository implements DailyQuestionRepository {
  FakeDailyQuestionRepository({this.myAnswer, this.partnerAnswer});

  static final question = DailyQuestion(
    date: DateTime(2026, 10, 5),
    questionId: 'q1',
    text: 'What small thing made you smile today?',
    category: 'fun',
  );

  String? myAnswer;
  String? partnerAnswer;

  /// When set, the matching call throws it once.
  Object? loadError;
  Object? saveError;

  /// Simulates the partner answering between load and save.
  bool partnerAnswersBeforeSave = false;

  final List<({DateTime date, String body})> saves = [];

  @override
  Future<DailyQuestionStatus> getToday() async {
    final error = loadError;
    loadError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    final mine = myAnswer;
    final partner = partnerAnswer;
    return DailyQuestionStatus(
      question: question,
      myAnswer: mine == null
          ? null
          : Answer(id: 'a-me', userId: 'me', body: mine),
      // Mirrors the server: no partner answer until the caller has answered.
      partnerAnswer: mine == null || partner == null
          ? null
          : Answer(id: 'a-partner', userId: 'partner', body: partner),
      partnerName: mine == null || partner == null ? null : partnerName,
      myReaction: myReaction,
      partnerReaction: partnerReaction,
    );
  }

  String? partnerName = 'Sam';
  Reaction? myReaction;
  Reaction? partnerReaction;
  Object? reactionError;
  final List<({String answerId, Reaction reaction})> reactionCalls = [];

  @override
  Future<void> setMyReaction(String answerId, Reaction reaction) async {
    final error = reactionError;
    reactionError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    reactionCalls.add((answerId: answerId, reaction: reaction));
    myReaction = reaction.isEmpty ? null : reaction;
  }

  /// Past days, keyed by date.
  final Map<DateTime, FakePastDay> pastDays = {};
  Object? historyError;

  @override
  Future<DailyQuestionStatus?> getDay(DateTime date) async {
    final day = pastDays[date];
    if (day == null) return null;
    final mine = day.myAnswer;
    final partner = day.partnerAnswer;
    return DailyQuestionStatus(
      question: day.question(date),
      myAnswer: mine == null
          ? null
          : Answer(id: 'a-me', userId: 'me', body: mine),
      partnerAnswer: mine == null || partner == null
          ? null
          : Answer(id: 'a-partner', userId: 'partner', body: partner),
      partnerName: partnerName,
    );
  }

  @override
  Future<List<QuestionHistoryEntry>> getHistory() async {
    final error = historyError;
    historyError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    final dates = pastDays.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final date in dates)
        QuestionHistoryEntry(
          question: pastDays[date]!.question(date),
          status: pastDays[date]!.myAnswer == null
              ? HistoryStatus.unanswered
              : pastDays[date]!.partnerAnswer == null
              ? HistoryStatus.waiting
              : HistoryStatus.revealed,
        ),
    ];
  }

  @override
  Future<void> saveMyAnswer(DateTime date, String body) async {
    final error = saveError;
    saveError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    final past = pastDays[date];
    if (past != null) {
      saves.add((date: date, body: body));
      past.myAnswer = body;
      return;
    }
    if (partnerAnswersBeforeSave) {
      partnerAnswersBeforeSave = false;
      partnerAnswer = 'Partner got there first';
    }
    if (myAnswer != null && partnerAnswer != null) {
      throw const DailyQuestionFailure(
        DailyQuestionFailureReason.answersLocked,
      );
    }
    saves.add((date: date, body: body));
    myAnswer = body;
  }
}

class FakePastDay {
  FakePastDay(this.text, {this.myAnswer, this.partnerAnswer});

  final String text;
  String? myAnswer;
  String? partnerAnswer;

  DailyQuestion question(DateTime date) => DailyQuestion(
    date: date,
    questionId: 'q-${date.day}',
    text: text,
    category: 'deep',
  );
}
