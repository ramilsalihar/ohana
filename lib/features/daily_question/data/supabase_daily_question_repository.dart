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
    return _statusFor(_toQuestion(rows.single as Map<String, dynamic>));
  });

  @override
  Future<DailyQuestionStatus?> getDay(DateTime date) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_question_on',
      params: {'question_date': formatDateOnly(date)},
    );
    if (rows.isEmpty) return null;
    return _statusFor(_toQuestion(rows.first as Map<String, dynamic>));
  });

  @override
  Future<List<QuestionHistoryEntry>> getHistory() => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>('get_question_history');
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        QuestionHistoryEntry(
          question: _toQuestion(row),
          status: HistoryStatus.fromServer(row['status'] as String),
        ),
    ];
  });

  static DailyQuestion _toQuestion(Map<String, dynamic> row) => DailyQuestion(
    date: DateTime.parse(row['question_date'] as String),
    questionId: row['question_id'] as String,
    text: row['text'] as String,
    category: row['category'] as String,
  );

  Future<DailyQuestionStatus> _statusFor(DailyQuestion question) async {
    final mine = await _myAnswerRow(question.date);
    // The server returns the partner's answer only when the caller has
    // answered, so there is nothing to ask for before that.
    final partner = mine == null
        ? null
        : await _partnerAnswerRow(question.date);

    if (mine == null || partner == null) {
      return DailyQuestionStatus(
        question: question,
        myAnswer: mine == null ? null : _toAnswer(mine),
      );
    }

    final myAnswer = _toAnswer(mine);
    final partnerAnswer = _toAnswer(partner);

    final partnerProfile = await _client
        .from('profiles')
        .select('display_name')
        .eq('id', partnerAnswer.userId)
        .maybeSingle();

    final reactions = await _client
        .from('answer_reactions')
        .select('answer_id, user_id, emoji, comment')
        .inFilter('answer_id', [myAnswer.id, partnerAnswer.id]);
    Reaction? reactionOn(String answerId, String byUserId) {
      for (final row in reactions) {
        if (row['answer_id'] == answerId && row['user_id'] == byUserId) {
          return Reaction(
            emoji: row['emoji'] as String?,
            comment: row['comment'] as String?,
          );
        }
      }
      return null;
    }

    return DailyQuestionStatus(
      question: question,
      myAnswer: myAnswer,
      partnerAnswer: partnerAnswer,
      partnerName: partnerProfile?['display_name'] as String?,
      myReaction: reactionOn(partnerAnswer.id, myAnswer.userId),
      partnerReaction: reactionOn(myAnswer.id, partnerAnswer.userId),
    );
  }

  @override
  Future<void> setMyReaction(String answerId, Reaction reaction) =>
      _guard(() async {
        final userId = _userId;
        final comment = reaction.comment?.trim();
        final values = {
          'emoji': reaction.emoji,
          'comment': comment == null || comment.isEmpty ? null : comment,
        };

        if (values.values.every((v) => v == null)) {
          await _client
              .from('answer_reactions')
              .delete()
              .eq('answer_id', answerId)
              .eq('user_id', userId);
          return;
        }

        // Not an upsert: clients may only update the emoji and comment
        // columns, and an upsert would also "update" the key columns.
        final updated = await _client
            .from('answer_reactions')
            .update(values)
            .eq('answer_id', answerId)
            .eq('user_id', userId)
            .select('answer_id');
        if (updated.isEmpty) {
          await _client.from('answer_reactions').insert({
            'answer_id': answerId,
            'user_id': userId,
            ...values,
          });
        }
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
