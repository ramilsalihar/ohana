/// Together counter and milestones (PRD F6), computed from the couple's
/// "together since" date. All dates are calendar dates; time of day is ignored.
class TogetherCounter {
  TogetherCounter({required DateTime since, required DateTime today})
    : since = _dateOnly(since),
      today = _dateOnly(today);

  final DateTime since;
  final DateTime today;

  /// False when "together since" is in the future (e.g. a device clock that
  /// is behind); there is nothing meaningful to count then.
  bool get hasStarted => !today.isBefore(since);

  /// 1 on the first day together, 2 the day after, and so on.
  int get dayNumber => _daysBetween(since, today) + 1;

  /// The nearest milestone on or after today: every 100th day, or a yearly
  /// anniversary, whichever comes first.
  Milestone get nextMilestone {
    final hundred = _nextHundredDays();
    final anniversary = _nextAnniversary();
    // On a tie the anniversary is the more meaningful one to show.
    return anniversary.daysUntil <= hundred.daysUntil ? anniversary : hundred;
  }

  Milestone _nextHundredDays() {
    final current = dayNumber;
    final target = current % 100 == 0 ? current : (current ~/ 100 + 1) * 100;
    return Milestone(
      kind: MilestoneKind.hundredDays,
      value: target,
      daysUntil: target - current,
    );
  }

  Milestone _nextAnniversary() {
    // Year 0 is the start date itself, which is not an anniversary.
    var years = today.year - since.year;
    if (years < 1) years = 1;
    var date = _anniversaryIn(since.year + years);
    if (date.isBefore(today)) {
      years++;
      date = _anniversaryIn(since.year + years);
    }
    return Milestone(
      kind: MilestoneKind.anniversary,
      value: years,
      daysUntil: _daysBetween(today, date),
    );
  }

  /// The anniversary date in [year]. A 29 February start is celebrated on
  /// 28 February in years without a leap day.
  DateTime _anniversaryIn(int year) {
    final lastDayOfMonth = DateTime(year, since.month + 1, 0).day;
    final day = since.day > lastDayOfMonth ? lastDayOfMonth : since.day;
    return DateTime(year, since.month, day);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar days from [from] to [to]. Compared in UTC so daylight-saving
  /// changes (23- or 25-hour days) cannot shift the count.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

enum MilestoneKind { hundredDays, anniversary }

class Milestone {
  const Milestone({
    required this.kind,
    required this.value,
    required this.daysUntil,
  });

  final MilestoneKind kind;

  /// The day number for [MilestoneKind.hundredDays] (100, 200, …) or the
  /// number of years for [MilestoneKind.anniversary].
  final int value;

  /// 0 when the milestone is today.
  final int daysUntil;

  bool get isToday => daysUntil == 0;
}
