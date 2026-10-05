import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/daily_question/domain/streak.dart';
import 'package:ohana/features/daily_question/presentation/streak_badge.dart';

// October 2026: the 5th is a Monday.
DateTime oct(int day) => DateTime(2026, 10, day);
DateTime sep(int day) => DateTime(2026, 9, day);

int streak(DateTime today, List<DateTime> completed) =>
    Streak.compute(today: today, completedDates: completed).days;

void main() {
  test('calendar assumption: 5 October 2026 is a Monday', () {
    expect(oct(5).weekday, DateTime.monday);
  });

  group('counting', () {
    test('no completed days: no streak, no history', () {
      final s = Streak.compute(today: oct(8), completedDates: const []);
      expect(s.days, 0);
      expect(s.hasHistory, isFalse);
    });

    test('consecutive days up to and including today', () {
      expect(streak(oct(8), [oct(6), oct(7), oct(8)]), 3);
    });

    test('today still in progress does not break the streak', () {
      expect(streak(oct(8), [oct(5), oct(6), oct(7)]), 3);
    });

    test('order and duplicates in the input do not matter', () {
      expect(streak(oct(8), [oct(8), oct(6), oct(7), oct(7)]), 3);
    });

    test('time of day is ignored', () {
      expect(
        Streak.compute(
          today: DateTime(2026, 10, 8, 23, 59),
          completedDates: [DateTime(2026, 10, 7, 0, 1), oct(8)],
        ).days,
        2,
      );
    });

    test('a late answer that completes a past day joins the run', () {
      // Without the 6th the run from the 8th would need a freeze; with it
      // the days are simply consecutive.
      expect(streak(oct(8), [oct(5), oct(6), oct(7), oct(8)]), 4);
    });
  });

  group('freeze days', () {
    test('one missed day is covered and adds nothing to the count', () {
      // Missed Wed 7th.
      expect(streak(oct(9), [oct(5), oct(6), oct(8), oct(9)]), 4);
    });

    test('two missed days in one week are covered', () {
      // Week of Mon 5th: missed Tue 6th and Thu 8th.
      expect(streak(oct(10), [oct(5), oct(7), oct(9), oct(10)]), 4);
    });

    test('a third missed day in the same week ends the streak', () {
      // Missed Tue 6th, Thu 8th, Sat 10th; today Sun 11th complete.
      // Walking back: 11 ✓, 10 freeze, 9 ✓, 8 freeze, 7 ✓, 6 → no freeze left.
      expect(streak(oct(11), [oct(5), oct(7), oct(9), oct(11)]), 3);
    });

    test('each week gets its own two freeze days', () {
      // Week 1 (Sep 28–Oct 4): missed Sat 3rd, Sun 4th.
      // Week 2 (Oct 5–11): missed Mon 5th, Tue 6th.
      // Four missed days in a row, but only two per week.
      expect(streak(oct(8), [sep(30), oct(1), oct(2), oct(7), oct(8)]), 5);
    });

    test('three missed days in a row within one week break it', () {
      // Missed Tue 6th, Wed 7th, Thu 8th.
      expect(streak(oct(10), [oct(5), oct(9), oct(10)]), 2);
    });

    test('yesterday missed, today in progress: freeze keeps it alive', () {
      expect(streak(oct(8), [oct(5), oct(6)]), 2);
    });

    test('freezes cannot keep a long-dead streak alive', () {
      final s = Streak.compute(
        today: oct(31),
        completedDates: [oct(5), oct(6)],
      );
      expect(s.days, 0);
      expect(s.hasHistory, isTrue);
    });

    test('days before the first completed day are not counted as misses', () {
      // Nothing before the 7th: the walk stops there instead of spending
      // freezes on days before the couple had any history.
      expect(streak(oct(8), [oct(7), oct(8)]), 2);
    });
  });

  group('across calendar boundaries', () {
    test('month and year boundaries', () {
      expect(
        streak(DateTime(2027, 1, 2), [
          DateTime(2026, 12, 30),
          DateTime(2026, 12, 31),
          DateTime(2027, 1, 1),
          DateTime(2027, 1, 2),
        ]),
        4,
      );
    });

    test('daylight-saving change does not skip or double a day', () {
      // US clocks change on 8 March 2026 and 1 November 2026.
      expect(
        streak(DateTime(2026, 3, 9), [
          DateTime(2026, 3, 7),
          DateTime(2026, 3, 8),
          DateTime(2026, 3, 9),
        ]),
        3,
      );
      expect(
        streak(DateTime(2026, 11, 2), [
          DateTime(2026, 10, 31),
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 2),
        ]),
        3,
      );
    });

    test('weeks run Monday to Sunday, including before 1970', () {
      // Mon 5th, Tue 6th and Wed 7th missed, all in the week of the 5th:
      // two are frozen, the third ends the run before it can reach Fri 2nd.
      // (If Monday belonged to the previous week this would be 3.)
      expect(streak(oct(9), [oct(2), oct(8), oct(9)]), 2);
      expect(
        streak(DateTime(1969, 12, 31), [
          DateTime(1969, 12, 29),
          DateTime(1969, 12, 30),
          DateTime(1969, 12, 31),
        ]),
        3,
      );
    });
  });

  group('copy', () {
    test('counts and pluralises', () {
      expect(
        StreakBadge.label(const Streak(days: 1, hasHistory: true)),
        '1 day in a row together',
      );
      expect(
        StreakBadge.label(const Streak(days: 12, hasHistory: true)),
        '12 days in a row together',
      );
      expect(
        StreakBadge.label(const Streak(days: 1200, hasHistory: true)),
        '1,200 days in a row together',
      );
    });

    test('a broken streak invites, without blame', () {
      final broken = StreakBadge.label(const Streak(days: 0, hasHistory: true));
      final fresh = StreakBadge.label(const Streak(days: 0, hasHistory: false));
      expect(broken, 'Start a new streak together');
      expect(fresh, 'Answer together to start a streak');
      for (final text in [broken, fresh]) {
        for (final blame in ['missed', 'lost', 'broke', 'you ', 'partner']) {
          expect(text.toLowerCase(), isNot(contains(blame)));
        }
      }
    });
  });
}
