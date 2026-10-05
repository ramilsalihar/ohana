import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/partner_activity.dart';

class SupabaseActivityRepository implements ActivityRepository {
  SupabaseActivityRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PartnerActivity>> getPartnerActivity() async {
    final rows = await _client.rpc<List<dynamic>>('get_partner_activity');
    final items = <PartnerActivity>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final kind = PartnerActivityKind.fromServer(
        row['type'] as String,
        isTodaysQuestion: row['is_todays_question'] as bool? ?? false,
      );
      if (kind == null) continue;
      items.add(
        PartnerActivity(
          id: row['id'] as String,
          kind: kind,
          actorName: row['actor_name'] as String?,
        ),
      );
    }
    return items;
  }
}
