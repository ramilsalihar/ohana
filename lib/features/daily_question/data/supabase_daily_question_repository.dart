import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/date_only.dart';
import '../domain/daily_question.dart';
import '../domain/daily_question_repository.dart';

class SupabaseDailyQuestionRepository implements DailyQuestionRepository {
  SupabaseDailyQuestionRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const DailyQuestionFailure(DailyQuestionFailureReason.unknown);
    }
    return id;
  }

  @override
  Future<DailyQuestionStatus> getToday() => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>('get_daily_question');
    final row = rows.single as Map<String, dynamic>;
    final question = DailyQuestion(
      date: DateTime.parse(row['question_date'] as String),
      questionId: row['question_id'] as String,
      text: row['text'] as String,
      category: row['category'] as String,
    );

    final mine = await _myAnswerRow(question.date);
    // The server returns the partner's answer only when the caller has
    // answered, so there is nothing to ask for before that.
    final partner = mine == null
        ? null
        : await _partnerAnswerRow(question.date);

    return DailyQuestionStatus(
      question: question,
      myAnswer: mine == null ? null : _toAnswer(mine),
      partnerAnswer: partner == null ? null : _toAnswer(partner),
    );
  });

  @override
  Future<void> saveMyAnswer(DateTime date, String body) => _guard(() async {
    final text = body.trim();
    final existing = await _myAnswerRow(date);

    if (existing == null) {
      final membership = await _client
          .from('couple_members')
          .select('couple_id')
          .eq('user_id', _userId)
          .maybeSingle();
      if (membership == null) {
        throw const DailyQuestionFailure(
          DailyQuestionFailureReason.notInCouple,
        );
      }
      await _client.from('answers').insert({
        'couple_id': membership['couple_id'],
        'daily_question_date': formatDateOnly(date),
        'user_id': _userId,
        'body': text,
      });
      return;
    }

    // Row Level Security stops matching the row once the partner has
    // answered, so "nothing updated" means the answers are locked.
    final updated = await _client
        .from('answers')
        .update({'body': text})
        .eq('id', existing['id'] as String)
        .select('id');
    if (updated.isEmpty) {
      throw const DailyQuestionFailure(
        DailyQuestionFailureReason.answersLocked,
      );
    }
  });

  Future<Map<String, dynamic>?> _myAnswerRow(DateTime date) => _client
      .from('answers')
      .select('id, user_id, body')
      .eq('user_id', _userId)
      .eq('daily_question_date', formatDateOnly(date))
      .maybeSingle();

  Future<Map<String, dynamic>?> _partnerAnswerRow(DateTime date) async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_partner_answer',
      params: {'question_date': formatDateOnly(date)},
    );
    return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
  }

  static Answer _toAnswer(Map<String, dynamic> row) => Answer(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    body: row['body'] as String,
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw DailyQuestionFailure(switch (e.message.trim()) {
        'not_in_couple' => DailyQuestionFailureReason.notInCouple,
        'no_questions' => DailyQuestionFailureReason.noQuestions,
        _ => DailyQuestionFailureReason.unknown,
      });
    }
  }
}
