import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/home/domain/together_counter.dart';

TogetherCounter counter(DateTime since, DateTime today) =>
    TogetherCounter(since: since, today: today);

void main() {
  group('dayNumber', () {
    test('the first day together is day 1', () {
      final c = counter(DateTime(2024, 3, 10), DateTime(2024, 3, 10));
      expect(c.dayNumber, 1);
      expect(c.hasStarted, isTrue);
    });

    test('counts calendar days, ignoring time of day', () {
      final c = counter(
        DateTime(2024, 3, 10, 23, 59),
        DateTime(2024, 3, 11, 0, 1),
      );
      expect(c.dayNumber, 2);
    });

    test('matches the PRD example scale', () {
      // 1,246 days after the start is day 1,247.
      final since = DateTime(2023, 5, 14);
      final today = DateTime.utc(2023, 5, 14).add(const Duration(days: 1246));
      expect(
        counter(since, DateTime(today.year, today.month, today.day)).dayNumber,
        1247,
      );
    });

    test('is not shifted by daylight-saving changes', () {
      // Spans the US spring-forward and fall-back dates in 2025.
      expect(counter(DateTime(2025, 3, 8), DateTime(2025, 3, 10)).dayNumber, 3);
      expect(
        counter(DateTime(2025, 11, 1), DateTime(2025, 11, 3)).dayNumber,
        3,
      );
      expect(
        counter(DateTime(2025, 1, 1), DateTime(2026, 1, 1)).dayNumber,
        366,
      );
    });

    test('a future start date has not started', () {
      final c = counter(DateTime(2026, 1, 2), DateTime(2026, 1, 1));
      expect(c.hasStarted, isFalse);
    });
  });

  group('nextMilestone', () {
    test('early on, the next milestone is day 100', () {
      final m = counter(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 1),
      ).nextMilestone;
      expect(m.kind, MilestoneKind.hundredDays);
      expect(m.value, 100);
      expect(m.daysUntil, 99);
    });

    test('day 100 itself is shown as today', () {
      // 2026-01-01 + 99 days = 2026-04-10.
      final m = counter(
        DateTime(2026, 1, 1),
        DateTime(2026, 4, 10),
      ).nextMilestone;
      expect(m.kind, MilestoneKind.hundredDays);
      expect(m.value, 100);
      expect(m.isToday, isTrue);
    });

    test('the day after day 100, the target is day 200', () {
      final m = counter(
        DateTime(2026, 1, 1),
        DateTime(2026, 4, 11),
      ).nextMilestone;
      expect(m.value, 200);
      expect(m.daysUntil, 99);
    });

    test('the anniversary wins when it comes before the next 100th day', () {
      // Day 301 falls on 2026-10-28; day 400 is 99 days away, the first
      // anniversary (2027-01-01) is 65 days away.
      final m = counter(
        DateTime(2026, 1, 1),
        DateTime(2026, 10, 28),
      ).nextMilestone;
      expect(m.kind, MilestoneKind.anniversary);
      expect(m.value, 1);
      expect(m.daysUntil, 65);
    });

    test('the anniversary day is shown as today with the right year count', () {
      final m = counter(
        DateTime(2023, 5, 14),
        DateTime(2026, 5, 14),
      ).nextMilestone;
      expect(m.kind, MilestoneKind.anniversary);
      expect(m.value, 3);
      expect(m.isToday, isTrue);
    });

    test('after this year\'s anniversary, it counts toward next year\'s', () {
      final c = counter(DateTime(2023, 5, 14), DateTime(2026, 5, 15));
      final m = c.nextMilestone;
      // Day 1,098 → day 1,100 is 2 days away, sooner than the anniversary.
      expect(c.dayNumber, 1098);
      expect(m.kind, MilestoneKind.hundredDays);
      expect(m.value, 1100);
      expect(m.daysUntil, 2);
    });

    test('before the anniversary in the same calendar year', () {
      final m = counter(
        DateTime(2023, 12, 20),
        DateTime(2025, 12, 1),
      ).nextMilestone;
      expect(m.kind, MilestoneKind.anniversary);
      expect(m.value, 2);
      expect(m.daysUntil, 19);
    });

    test('29 February is celebrated on 28 February in non-leap years', () {
      final nonLeap = counter(
        DateTime(2024, 2, 29),
        DateTime(2025, 2, 28),
      ).nextMilestone;
      expect(nonLeap.kind, MilestoneKind.anniversary);
      expect(nonLeap.value, 1);
      expect(nonLeap.isToday, isTrue);

      final leap = counter(
        DateTime(2024, 2, 29),
        DateTime(2028, 2, 28),
      ).nextMilestone;
      expect(leap.kind, MilestoneKind.anniversary);
      expect(leap.value, 4);
      expect(leap.daysUntil, 1);
    });
  });
}
