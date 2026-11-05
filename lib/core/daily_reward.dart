import 'save_data.dart';

/// Gems for reward days 1 through 7.
const dailyRewardAmounts = [20, 30, 40, 50, 60, 80, 150];

/// How far [DateTime] may sit behind [DailyState.lastSeenMs] before a claim
/// is refused. Two minutes covers a small network time correction.
const clockToleranceMs = 2 * 60 * 1000;

/// What the daily reward screen should show for [now].
class DailyStatus {
  const DailyStatus({
    required this.claimedToday,
    required this.nextRewardDay,
    required this.displayStreakCount,
  });

  final bool claimedToday;

  /// The day that can be claimed, or, if today is already claimed, the day
  /// that opens tomorrow. Always 1..7.
  final int nextRewardDay;

  /// Consecutive days to show. 0 when the last claim is older than yesterday.
  final int displayStreakCount;

  bool get canClaim => !claimedToday;
}

/// Result of [claimDaily]. [gems] is 0 when today was already claimed or the
/// clock went backwards. [clockBlocked] is set only for the clock case.
class DailyClaim {
  const DailyClaim(this.gems, {this.clockBlocked = false});

  final int gems;
  final bool clockBlocked;
}

/// True when [now] is more than [clockToleranceMs] behind [lastSeenMs].
///
/// A fresh install (`lastSeenMs == 0`) is never blocked.
///
/// Known trade-off: [lastSeenMs] only moves forward. If the phone clock jumps
/// far ahead and the app records that time, setting it back to the real time
/// stays blocked until real time catches up.
bool clockWentBack(int lastSeenMs, DateTime now) {
  if (lastSeenMs == 0) return false;
  return now.millisecondsSinceEpoch < lastSeenMs - clockToleranceMs;
}

/// The one clock rule for a claim and for [lastSeenMs] at launch.
///
/// Returns false and leaves [s] unchanged when [clockWentBack] is true.
/// Otherwise moves [DailyState.lastSeenMs] forward to [now] when [now] is
/// later. It never moves backward.
bool recordClock(DailyState s, DateTime now) {
  if (clockWentBack(s.lastSeenMs, now)) return false;
  final nowMs = now.millisecondsSinceEpoch;
  if (nowMs > s.lastSeenMs) s.lastSeenMs = nowMs;
  return true;
}

/// Local calendar day, same shape as [AppPrefs]'s ad-day key: `yyyy-m-d`.
String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// How many calendar days [now] is after [lastKey]. Null when there is no
/// usable last claim. Negative when [now] is an earlier calendar day.
///
/// Year, month and day are compared as UTC dates, so a 23-hour DST day and a
/// claim just before midnight still count as the next day.
int? calendarDaysAfter(String? lastKey, DateTime now) {
  final last = _parseDay(lastKey);
  if (last == null) return null;
  final today = DateTime.utc(now.year, now.month, now.day);
  return today.difference(last).inDays;
}

DateTime? _parseDay(String? key) {
  if (key == null || key.isEmpty) return null;
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

int _dayAfter(int streakDay) =>
    streakDay >= 7 || streakDay < 1 ? 1 : streakDay + 1;

/// Read-only view. Does not change [s].
DailyStatus dailyStatus(DailyState s, DateTime now) {
  final gap = calendarDaysAfter(s.lastClaimDay, now);
  final claimedToday = gap == 0;
  final alive = gap == 0 || gap == 1;
  // Yesterday continues the cycle. A missed day, or no claim yet, opens day 1.
  // After today's claim, nextRewardDay is the day that opens tomorrow.
  final nextRewardDay = alive ? _dayAfter(s.streakDay) : 1;
  final shown = !alive ? 0 : (s.streakCount > 0 ? s.streakCount : s.streakDay);
  return DailyStatus(
    claimedToday: claimedToday,
    nextRewardDay: nextRewardDay,
    displayStreakCount: shown < 0 ? 0 : shown,
  );
}

/// Applies today's claim to [s] when it is still open. Returns the gems to
/// add. The caller adds those gems; this function only touches [s].
///
/// A backwards clock returns 0 gems and [DailyClaim.clockBlocked], and does
/// not change the streak or [DailyState.lastSeenMs]. A real claim moves
/// [DailyState.lastSeenMs] forward (see [recordClock]).
DailyClaim claimDaily(DailyState s, DateTime now) {
  if (!recordClock(s, now)) return const DailyClaim(0, clockBlocked: true);
  final gap = calendarDaysAfter(s.lastClaimDay, now);
  if (gap != null && gap <= 0) return const DailyClaim(0);
  final continued = gap == 1 && s.streakDay >= 1;
  if (continued) {
    final soFar = s.streakCount > 0 ? s.streakCount : s.streakDay;
    s.streakDay = _dayAfter(s.streakDay);
    s.streakCount = soFar + 1;
  } else {
    s.streakDay = 1;
    s.streakCount = 1;
  }
  if (s.streakCount > s.bestStreak) s.bestStreak = s.streakCount;
  s.lastClaimDay = dayKey(now);
  return DailyClaim(dailyRewardAmounts[s.streakDay - 1]);
}
