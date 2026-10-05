/// A code the partner uses to join the couple space. Valid for 7 days and
/// usable once.
class Invite {
  const Invite({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  /// Whole days until expiry, rounded up; 0 once expired.
  int daysLeft(DateTime now) {
    final remaining = expiresAt.difference(now);
    if (remaining <= Duration.zero) return 0;
    return (remaining.inSeconds / Duration.secondsPerDay).ceil();
  }
}
