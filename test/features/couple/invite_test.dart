import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/couple/domain/couple_repository.dart';
import 'package:ohana/features/couple/domain/invite.dart';

void main() {
  final now = DateTime.utc(2026, 10, 5, 12);

  Invite expiringIn(Duration d) =>
      Invite(code: 'ABC234', expiresAt: now.add(d));

  group('Invite', () {
    test('daysLeft rounds up to whole days', () {
      expect(expiringIn(const Duration(days: 7)).daysLeft(now), 7);
      expect(expiringIn(const Duration(days: 6, hours: 1)).daysLeft(now), 7);
      expect(expiringIn(const Duration(minutes: 5)).daysLeft(now), 1);
    });

    test('is expired at and after the expiry time', () {
      expect(expiringIn(const Duration(seconds: 1)).isExpired(now), isFalse);
      expect(expiringIn(Duration.zero).isExpired(now), isTrue);
      expect(expiringIn(const Duration(days: -1)).isExpired(now), isTrue);
      expect(expiringIn(const Duration(days: -1)).daysLeft(now), 0);
    });
  });

  group('CoupleFailureReason.fromServerMessage', () {
    test('maps the names raised by the SQL functions', () {
      const expected = {
        'not_authenticated': CoupleFailureReason.notAuthenticated,
        'already_in_couple': CoupleFailureReason.alreadyInCouple,
        'not_in_couple': CoupleFailureReason.notInCouple,
        'couple_full': CoupleFailureReason.coupleFull,
        'invalid_timezone': CoupleFailureReason.invalidTimezone,
      };
      expected.forEach((message, reason) {
        expect(CoupleFailureReason.fromServerMessage(message), reason);
      });
    });

    test('anything else is unknown and never shown raw', () {
      const failure = CoupleFailure(CoupleFailureReason.unknown);
      expect(
        CoupleFailureReason.fromServerMessage('relation "x" does not exist'),
        CoupleFailureReason.unknown,
      );
      expect(failure.message, 'Something went wrong. Please try again.');
    });
  });
}
