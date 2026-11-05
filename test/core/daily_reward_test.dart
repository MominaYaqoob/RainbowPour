import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/daily_reward.dart';
import 'package:rainbow_pour/core/save_data.dart';

void main() {
  test('the first claim is day 1 for 20 gems', () {
    final s = DailyState();
    final claim = claimDaily(s, DateTime(2026, 4, 1, 12));
    expect(claim.gems, 20);
    expect(s.streakDay, 1);
    expect(s.streakCount, 1);
    expect(s.bestStreak, 1);
    expect(s.lastClaimDay, '2026-4-1');
    final status = dailyStatus(s, DateTime(2026, 4, 1, 18));
    expect(status.claimedToday, isTrue);
    expect(status.canClaim, isFalse);
    expect(status.nextRewardDay, 2);
    expect(status.displayStreakCount, 1);
  });

  test('a second claim on the same day adds nothing', () {
    final s = DailyState();
    claimDaily(s, DateTime(2026, 7, 4, 8));
    final again = claimDaily(s, DateTime(2026, 7, 4, 23, 59));
    expect(again.gems, 0);
    expect(s.streakDay, 1);
    expect(s.streakCount, 1);
    expect(s.bestStreak, 1);
    expect(s.lastClaimDay, '2026-7-4');
  });

  test('the next calendar day opens reward day 2', () {
    final s = DailyState()
      ..lastClaimDay = '2026-4-1'
      ..streakDay = 1
      ..streakCount = 1
      ..bestStreak = 1;
    final before = dailyStatus(s, DateTime(2026, 4, 2, 0, 10));
    expect(before.claimedToday, isFalse);
    expect(before.canClaim, isTrue);
    expect(before.nextRewardDay, 2);
    expect(before.displayStreakCount, 1);
    final claim = claimDaily(s, DateTime(2026, 4, 2, 0, 10));
    expect(claim.gems, 30);
    expect(s.streakDay, 2);
    expect(s.streakCount, 2);
  });

  test('a gap of 2 days restarts at day 1', () {
    final s = DailyState();
    claimDaily(s, DateTime(2026, 1, 1, 10));
    claimDaily(s, DateTime(2026, 1, 2, 10));
    final claim = claimDaily(s, DateTime(2026, 1, 4, 10));
    expect(claim.gems, 20);
    expect(s.streakDay, 1);
    expect(s.streakCount, 1);
    expect(s.bestStreak, 2);
    expect(dailyStatus(s, DateTime(2026, 1, 6, 10)).displayStreakCount, 0);
  });

  test('day 7 wraps, and the streak count keeps growing', () {
    final s = DailyState();
    var day = DateTime(2026, 4, 1);
    final gems = <int>[];
    for (var i = 0; i < 9; i++) {
      gems.add(claimDaily(s, day).gems);
      day = DateTime(day.year, day.month, day.day + 1);
    }
    expect(gems, [20, 30, 40, 50, 60, 80, 150, 20, 30]);
    expect(s.streakCount, 9);
    expect(s.bestStreak, 9);
    expect(s.streakDay, 2);
    expect(dailyStatus(s, DateTime(2026, 4, 9, 12)).displayStreakCount, 9);
  });

  test('bestStreak survives a broken streak', () {
    final s = DailyState();
    var day = DateTime(2026, 5, 1);
    for (var i = 0; i < 4; i++) {
      claimDaily(s, day);
      day = DateTime(day.year, day.month, day.day + 1);
    }
    expect(s.bestStreak, 4);
    // Last claim is May 4. May 6 is two calendar days later, so May 5 was missed.
    final claim = claimDaily(s, DateTime(2026, 5, 6, 9));
    expect(claim.gems, 20);
    expect(s.streakCount, 1);
    expect(s.streakDay, 1);
    expect(s.bestStreak, 4);
  });

  test('month, year and leap-day boundaries are the next reward day', () {
    final january = DailyState();
    claimDaily(january, DateTime(2026, 1, 31, 23, 30));
    expect(claimDaily(january, DateTime(2026, 2, 1, 0, 30)).gems, 30);

    final year = DailyState();
    claimDaily(year, DateTime(2025, 12, 31, 22));
    expect(claimDaily(year, DateTime(2026, 1, 1, 1)).gems, 30);
    expect(year.streakCount, 2);

    final leap = DailyState();
    claimDaily(leap, DateTime(2024, 2, 29, 12));
    expect(claimDaily(leap, DateTime(2024, 3, 1, 12)).gems, 30);
    expect(leap.lastClaimDay, '2024-3-1');
  });

  test('a DST change still counts as the next calendar day', () {
    // 2026-03-08 is the US spring-forward. Two hours later is the next date,
    // even where a local clock only moved 23 hours.
    final s = DailyState();
    expect(claimDaily(s, DateTime(2026, 3, 8, 23)).gems, 20);
    expect(claimDaily(s, DateTime(2026, 3, 9, 1)).gems, 30);
    expect(s.streakDay, 2);
    expect(s.streakCount, 2);
  });

  test('a fresh save and a small rewind are not blocked', () {
    final seen = DateTime(2026, 6, 10, 15);
    final ms = seen.millisecondsSinceEpoch;
    expect(clockWentBack(0, seen), isFalse);
    expect(clockWentBack(ms, seen), isFalse);
    expect(
      clockWentBack(ms, seen.subtract(const Duration(minutes: 1))),
      isFalse,
    );
    expect(
      clockWentBack(ms, seen.subtract(const Duration(minutes: 3))),
      isTrue,
    );
    expect(clockWentBack(ms, seen.subtract(const Duration(days: 1))), isTrue);

    final fresh = DailyState();
    final claim = claimDaily(fresh, seen);
    expect(claim.clockBlocked, isFalse);
    expect(claim.gems, 20);
    expect(fresh.lastSeenMs, ms);
  });

  test('a blocked claim changes nothing', () {
    final seen = DateTime(2026, 6, 10, 15);
    final s = DailyState()
      ..lastClaimDay = '2026-6-9'
      ..streakDay = 3
      ..streakCount = 3
      ..bestStreak = 3
      ..lastSeenMs = seen.millisecondsSinceEpoch;
    final claim = claimDaily(s, seen.subtract(const Duration(minutes: 3)));
    expect(claim.gems, 0);
    expect(claim.clockBlocked, isTrue);
    expect(s.streakDay, 3);
    expect(s.streakCount, 3);
    expect(s.lastClaimDay, '2026-6-9');
    expect(s.lastSeenMs, seen.millisecondsSinceEpoch);

    final dayBehind = claimDaily(s, seen.subtract(const Duration(days: 1)));
    expect(dayBehind.gems, 0);
    expect(dayBehind.clockBlocked, isTrue);
    expect(s.streakDay, 3);
    expect(s.lastSeenMs, seen.millisecondsSinceEpoch);
  });

  test('lastSeenMs moves forward and never backward', () {
    final s = DailyState();
    final first = DateTime(2026, 6, 10, 15);
    expect(claimDaily(s, first).gems, 20);
    expect(s.lastSeenMs, first.millisecondsSinceEpoch);

    final within = first.subtract(const Duration(minutes: 1));
    expect(claimDaily(s, within).clockBlocked, isFalse);
    expect(s.lastSeenMs, first.millisecondsSinceEpoch);

    final later = first.add(const Duration(hours: 2));
    claimDaily(s, later);
    expect(s.lastSeenMs, later.millisecondsSinceEpoch);
    expect(s.streakDay, 1);
    expect(s.lastClaimDay, '2026-6-10');
  });
}
