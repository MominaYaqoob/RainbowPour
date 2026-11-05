import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/daily_challenge.dart';
import 'package:rainbow_pour/core/daily_reward.dart';
import 'package:rainbow_pour/core/save_data.dart';

void main() {
  test('a day pays once and a second finish pays nothing', () {
    final s = DailyState();
    final day = DateTime(2026, 6, 15, 9);
    final first = completeChallenge(s, day, day);
    expect(first.gems, challengeRewardGems);
    expect(first.streak, 1);
    expect(first.alreadyDone, isFalse);
    expect(s.challengeDone, {dayKey(day)});

    final again = completeChallenge(s, day, DateTime(2026, 6, 15, 23));
    expect(again.gems, 0);
    expect(again.alreadyDone, isTrue);
    expect(s.challengeStreak, 1);
  });

  test('the streak crosses month and year boundaries and breaks on a gap', () {
    final s = DailyState();
    completeChallenge(s, DateTime(2026, 1, 31, 10), DateTime(2026, 1, 31, 10));
    final next = completeChallenge(
      s,
      DateTime(2026, 2, 1, 8),
      DateTime(2026, 2, 1, 8),
    );
    expect(next.streak, 2);

    final year = DailyState();
    completeChallenge(
      year,
      DateTime(2025, 12, 31, 22),
      DateTime(2025, 12, 31, 22),
    );
    expect(
      completeChallenge(
        year,
        DateTime(2026, 1, 1, 1),
        DateTime(2026, 1, 1, 1),
      ).streak,
      2,
    );

    final leap = DailyState();
    completeChallenge(leap, DateTime(2024, 2, 28), DateTime(2024, 2, 28));
    completeChallenge(leap, DateTime(2024, 2, 29), DateTime(2024, 2, 29));
    expect(
      completeChallenge(
        leap,
        DateTime(2024, 3, 1),
        DateTime(2024, 3, 1),
      ).streak,
      3,
    );

    final broken = DailyState();
    completeChallenge(broken, DateTime(2026, 5, 1), DateTime(2026, 5, 1));
    completeChallenge(broken, DateTime(2026, 5, 2), DateTime(2026, 5, 2));
    expect(challengeStreakOf(broken.challengeDone, DateTime(2026, 5, 4)), 0);
    expect(
      completeChallenge(
        broken,
        DateTime(2026, 5, 4),
        DateTime(2026, 5, 4),
      ).streak,
      1,
    );
  });

  test('an open today keeps the streak that ended yesterday', () {
    final s = DailyState();
    completeChallenge(s, DateTime(2026, 4, 9), DateTime(2026, 4, 9));
    completeChallenge(s, DateTime(2026, 4, 10), DateTime(2026, 4, 10));
    expect(challengeStreakOf(s.challengeDone, DateTime(2026, 4, 11, 7)), 2);
    expect(s.challengeDone.contains(dayKey(DateTime(2026, 4, 11))), isFalse);
  });

  test('the weekly bonus is paid once per finished Monday to Sunday', () {
    final s = DailyState();
    final monday = DateTime(2026, 6, 15);
    expect(monday.weekday, DateTime.monday);
    for (var i = 0; i < 6; i++) {
      final day = DateTime(2026, 6, 15 + i);
      final result = completeChallenge(s, day, day);
      expect(result.weeklyBonus, isFalse);
      expect(result.gems, challengeRewardGems);
    }
    expect(s.weeklyBonusWeek, isNull);
    final sunday = DateTime(2026, 6, 21, 18);
    expect(sunday.weekday, DateTime.sunday);
    expect(weekKey(sunday), dayKey(monday));
    expect(weekDays(sunday).length, 7);
    expect(weekDays(sunday).first.day, 15);
    expect(weekDays(sunday).last.day, 21);

    final seventh = completeChallenge(s, sunday, sunday);
    expect(seventh.weeklyBonus, isTrue);
    expect(seventh.gems, challengeRewardGems + weeklyBonusGems);
    expect(seventh.streak, 7);
    expect(s.weeklyBonusWeek, dayKey(monday));

    final repeat = completeChallenge(s, sunday, DateTime(2026, 6, 21, 22));
    expect(repeat.alreadyDone, isTrue);
    expect(repeat.gems, 0);
    expect(s.weeklyBonusWeek, dayKey(monday));

    final nextMonday = DateTime(2026, 6, 22);
    expect(weekKey(nextMonday), isNot(weekKey(sunday)));
    for (var i = 0; i < 6; i++) {
      final day = DateTime(2026, 6, 22 + i);
      expect(completeChallenge(s, day, day).weeklyBonus, isFalse);
    }
    final nextSunday = DateTime(2026, 6, 28);
    final again = completeChallenge(s, nextSunday, nextSunday);
    expect(again.weeklyBonus, isTrue);
    expect(s.weeklyBonusWeek, weekKey(nextMonday));
  });

  test('a finish after midnight and a backwards clock pay nothing', () {
    final late = DailyState()..challengeStreak = 4;
    final missed = completeChallenge(
      late,
      DateTime(2026, 7, 1, 23),
      DateTime(2026, 7, 2, 0, 10),
    );
    expect(missed.wrongDay, isTrue);
    expect(missed.gems, 0);
    expect(late.challengeDone, isEmpty);
    expect(late.challengeStreak, 4);

    final seen = DateTime(2026, 7, 4, 15);
    final blocked = DailyState()
      ..challengeStreak = 2
      ..challengeDone = {'2026-7-3'}
      ..lastSeenMs = seen.millisecondsSinceEpoch
      ..weeklyBonusWeek = '2026-6-29';
    final claim = completeChallenge(
      blocked,
      seen.subtract(const Duration(minutes: 3)),
      seen.subtract(const Duration(minutes: 3)),
    );
    expect(claim.clockBlocked, isTrue);
    expect(claim.gems, 0);
    expect(blocked.challengeStreak, 2);
    expect(blocked.challengeDone, {'2026-7-3'});
    expect(blocked.lastSeenMs, seen.millisecondsSinceEpoch);
    expect(blocked.weeklyBonusWeek, '2026-6-29');
  });
}
