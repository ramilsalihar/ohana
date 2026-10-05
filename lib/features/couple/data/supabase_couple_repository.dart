import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/couple_repository.dart';
import '../domain/invite.dart';

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

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw CoupleFailure(CoupleFailureReason.fromServerMessage(e.message));
    }
  }
}
