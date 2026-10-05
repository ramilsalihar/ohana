import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/activity/domain/partner_activity.dart';

void main() {
  test('maps server types, splitting answers into today and past', () {
    PartnerActivityKind? map(String type, {bool today = false}) =>
        PartnerActivityKind.fromServer(type, isTodaysQuestion: today);

    expect(map('answered', today: true), PartnerActivityKind.answeredToday);
    expect(map('answered'), PartnerActivityKind.answeredPast);
    expect(map('reacted'), PartnerActivityKind.reacted);
    expect(map('sent_note'), PartnerActivityKind.sentNote);
    expect(map('completed_checkin'), PartnerActivityKind.completedCheckin);
  });

  test('unknown types are skipped, including any absence-style signal', () {
    for (final type in ['last_seen', 'opened_app', 'read', '']) {
      expect(
        PartnerActivityKind.fromServer(type, isTodaysQuestion: false),
        isNull,
      );
    }
  });

  test('messages use the partner name, or a fallback', () {
    const named = PartnerActivity(
      id: '1',
      kind: PartnerActivityKind.answeredToday,
      actorName: 'Sam',
    );
    const unnamed = PartnerActivity(id: '2', kind: PartnerActivityKind.reacted);

    expect(named.message, "Sam answered today's question");
    expect(unnamed.message, 'Your partner reacted to your answer');
  });

  test('every message is positive: no absence or comparison wording', () {
    for (final kind in PartnerActivityKind.values) {
      final message = PartnerActivity(
        id: 'x',
        kind: kind,
        actorName: 'Sam',
      ).message.toLowerCase();
      // Whole-word match, so "note" is not mistaken for "not".
      final words = message.split(RegExp(r"[^a-z']+"));
      for (final word in ['not', 'never', 'ago', 'since', 'yet', 'than']) {
        expect(words, isNot(contains(word)), reason: '$kind: $message');
      }
      expect(message, isNot(contains("n't")), reason: '$kind: $message');
      expect(message, isNot(contains('last seen')), reason: '$kind: $message');
    }
  });
}
