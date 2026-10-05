import 'invite.dart';

/// Couple space operations. Implemented by Supabase in production and by
/// fakes in tests.
abstract interface class CoupleRepository {
  /// Creates a couple space with the current user as its first member and
  /// returns its id. [timezone] is an IANA name such as `Europe/Berlin`.
  Future<String> createCouple({required String timezone});

  /// Returns the couple's current invite, creating one if none is valid.
  Future<Invite> createInvite();

  /// Joins the couple that issued [code] and returns its id.
  ///
  /// If the caller has created their own space and is alone in it, this fails
  /// with [CoupleFailureReason.hasEmptySpace] unless [leaveEmptySpace] is
  /// true, in which case that empty space is deleted first.
  Future<String> joinCouple(String code, {bool leaveEmptySpace = false});
}

enum CoupleFailureReason {
  notAuthenticated,
  alreadyInCouple,
  notInCouple,
  coupleFull,
  invalidTimezone,
  invalidInvite,
  inviteUsed,
  inviteExpired,
  ownInvite,
  hasEmptySpace,
  unknown;

  /// Maps the stable error names raised by the pairing SQL functions.
  static CoupleFailureReason fromServerMessage(String message) =>
      switch (message.trim()) {
        'not_authenticated' => notAuthenticated,
        'already_in_couple' => alreadyInCouple,
        'not_in_couple' => notInCouple,
        'couple_full' => coupleFull,
        'invalid_timezone' => invalidTimezone,
        'invalid_invite' => invalidInvite,
        'invite_used' => inviteUsed,
        'invite_expired' => inviteExpired,
        'own_invite' => ownInvite,
        'has_empty_space' => hasEmptySpace,
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
    CoupleFailureReason.coupleFull => 'This space already has two people.',
    CoupleFailureReason.invalidInvite =>
      'That code does not match an invite. Check it and try again.',
    CoupleFailureReason.inviteUsed =>
      'That code has already been used. Ask your partner for a new one.',
    CoupleFailureReason.inviteExpired =>
      'That code has expired. Ask your partner for a new one.',
    CoupleFailureReason.ownInvite =>
      'That is your own code. Share it with your partner.',
    CoupleFailureReason.hasEmptySpace =>
      'You already created a space of your own.',
    CoupleFailureReason.invalidTimezone ||
    CoupleFailureReason.unknown => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'CoupleFailure: ${reason.name}';
}
