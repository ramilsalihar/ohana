import 'invite.dart';

/// Couple space operations. Implemented by Supabase in production and by
/// fakes in tests.
abstract interface class CoupleRepository {
  /// Creates a couple space with the current user as its first member and
  /// returns its id. [timezone] is an IANA name such as `Europe/Berlin`.
  Future<String> createCouple({required String timezone});

  /// Returns the couple's current invite, creating one if none is valid.
  Future<Invite> createInvite();
}

enum CoupleFailureReason {
  notAuthenticated,
  alreadyInCouple,
  notInCouple,
  coupleFull,
  invalidTimezone,
  unknown;

  /// Maps the stable error names raised by the pairing SQL functions.
  static CoupleFailureReason fromServerMessage(String message) =>
      switch (message.trim()) {
        'not_authenticated' => notAuthenticated,
        'already_in_couple' => alreadyInCouple,
        'not_in_couple' => notInCouple,
        'couple_full' => coupleFull,
        'invalid_timezone' => invalidTimezone,
        _ => unknown,
      };
}

class CoupleFailure implements Exception {
  const CoupleFailure(this.reason);

  final CoupleFailureReason reason;

  /// Text that is safe to show to the user.
  String get message => switch (reason) {
    CoupleFailureReason.notAuthenticated => 'Please sign in again.',
    CoupleFailureReason.alreadyInCouple => 'You are already in a couple space.',
    CoupleFailureReason.notInCouple => 'Create your couple space first.',
    CoupleFailureReason.coupleFull => 'Your partner has already joined.',
    CoupleFailureReason.invalidTimezone ||
    CoupleFailureReason.unknown => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'CoupleFailure: ${reason.name}';
}
