/// Something positive the partner did recently (PRD F4).
///
/// There is deliberately no timestamp and no "absence" kind: the strip shows
/// effort, never when someone was last around or what they have not done.
enum PartnerActivityKind {
  answeredToday,
  answeredPast,
  reacted,
  sentNote,
  completedCheckin;

  /// Maps the server's activity type; null for types this version does not
  /// know, which are skipped rather than shown wrongly.
  static PartnerActivityKind? fromServer(
    String type, {
    required bool isTodaysQuestion,
  }) => switch (type) {
    'answered' => isTodaysQuestion ? answeredToday : answeredPast,
    'reacted' => reacted,
    'sent_note' => sentNote,
    'completed_checkin' => completedCheckin,
    _ => null,
  };
}

class PartnerActivity {
  const PartnerActivity({required this.id, required this.kind, this.actorName});

  final String id;
  final PartnerActivityKind kind;
  final String? actorName;

  /// One warm line, e.g. "Sam answered today's question".
  String get message {
    final name = actorName ?? 'Your partner';
    return switch (kind) {
      PartnerActivityKind.answeredToday => "$name answered today's question",
      PartnerActivityKind.answeredPast => '$name answered a past question',
      PartnerActivityKind.reacted => '$name reacted to your answer',
      PartnerActivityKind.sentNote => '$name sent you a note',
      PartnerActivityKind.completedCheckin => '$name completed the check-in',
    };
  }
}

/// Implemented by Supabase in production and by fakes in tests.
abstract interface class ActivityRepository {
  /// The partner's positive actions from the last 48 hours, newest first.
  Future<List<PartnerActivity>> getPartnerActivity();
}
