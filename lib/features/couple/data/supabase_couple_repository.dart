import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/couple_repository.dart';
import '../domain/invite.dart';
import '../domain/invite_code.dart';

class SupabaseCoupleRepository implements CoupleRepository {
  SupabaseCoupleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> createCouple({required String timezone}) => _guard(() async {
    final id = await _client.rpc<Object?>(
      'create_couple',
      params: {'couple_timezone': timezone},
    );
    return id! as String;
  });

  @override
  Future<Invite> createInvite() => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>('create_invite');
    final row = rows.single as Map<String, dynamic>;
    return Invite(
      code: row['code'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  });

  @override
  Future<String> joinCouple(String code, {bool leaveEmptySpace = false}) =>
      _guard(() async {
        final id = await _client.rpc<Object?>(
          'join_couple',
          params: {
            'invite_code': normalizeInviteCode(code),
            'leave_empty_space': leaveEmptySpace,
          },
        );
        return id! as String;
      });

  @override
  Future<CoupleSpace?> getMyCouple() => _guard(() async {
    // Row Level Security only returns the caller's own couple.
    final row = await _client
        .from('couples')
        .select('id, together_since')
        .maybeSingle();
    if (row == null) return null;
    final since = row['together_since'] as String?;
    return CoupleSpace(
      id: row['id'] as String,
      togetherSince: since == null ? null : DateTime.parse(since),
    );
  });

  @override
  Future<void> setTogetherSince(DateTime date) => _guard(() async {
    final couple = await getMyCouple();
    if (couple == null) {
      throw const CoupleFailure(CoupleFailureReason.notInCouple);
    }
    await _client
        .from('couples')
        .update({'together_since': _dateOnly(date)})
        .eq('id', couple.id);
  });

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw CoupleFailure(CoupleFailureReason.fromServerMessage(e.message));
    }
  }
}
