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
    );
  }

  @override
  Future<void> saveMyAnswer(DateTime date, String body) async {
    final error = saveError;
    saveError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
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
