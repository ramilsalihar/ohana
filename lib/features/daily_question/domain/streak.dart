/// The couple's daily-question streak (PRD F2, "gentle streak").
///
/// Rules:
///  * A day counts when both partners answered it, even if late.
///  * Today never breaks the streak: it is still in progress.
///  * A missed day is covered by a freeze day and the streak carries on (the
///    frozen day itself adds nothing to the count).
///  * There are [freezesPerWeek] freeze days per calendar week (Monday to
///    Sunday), applied automatically. A third missed day in one week ends
///    the streak.
///
/// The input is couple-level only, so nothing here can say who missed.
class Streak {
  const Streak({required this.days, required this.hasHistory});

  /// Days both answered in the current run. 0 when there is no live streak.
  final int days;

  /// Whether the couple has ever completed a day; distinguishes a broken
  /// streak from one that has not started.
  final bool hasHistory;

  static const freezesPerWeek = 2;

  factory Streak.compute({
    required DateTime today,
    required Iterable<DateTime> completedDates,
  }) {
    final completed = {for (final d in completedDates) _dayIndex(d)};
    if (completed.isEmpty) return const Streak(days: 0, hasHistory: false);

    final earliest = completed.reduce((a, b) => a < b ? a : b);
    final todayIndex = _dayIndex(today);
    final freezesUsed = <int, int>{};
    var days = 0;

    // Start from today if it is already complete, otherwise from yesterday.
    var day = completed.contains(todayIndex) ? todayIndex : todayIndex - 1;
    for (; day >= earliest; day--) {
      if (completed.contains(day)) {
        days++;
        continue;
      }
      final week = _weekIndex(day);
      final used = freezesUsed[week] ?? 0;
      if (used >= freezesPerWeek) break;
      freezesUsed[week] = used + 1;
    }
    return Streak(days: days, hasHistory: true);
  }

  /// Days since the epoch for the calendar date of [d]. Built in UTC so
  /// daylight-saving changes cannot shift the day.
  static int _dayIndex(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// Identifies the Monday-to-Sunday week containing day [index].
  /// 1970-01-01 (index 0) was a Thursday, so index 4 is the first Monday.
  static int _weekIndex(int index) => (index - 4) ~/ 7 - (index < 4 ? 1 : 0);
}
