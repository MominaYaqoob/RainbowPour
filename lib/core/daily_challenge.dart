import 'daily_reward.dart';
import 'save_data.dart';

/// Countdown length for one daily challenge.
const challengeSeconds = 300;

/// Gems for finishing today's board.
const challengeRewardGems = 30;

/// Gems once, when all seven days Monday..Sunday of a week are done.
const weeklyBonusGems = 40;

/// Completed days older than this are dropped on the next save.
const challengeHistoryDays = 400;

/// What [completeChallenge] did to the save.
class ChallengeResult {
  const ChallengeResult({
    required this.gems,
    required this.streak,
    this.weeklyBonus = false,
    this.alreadyDone = false,
    this.clockBlocked = false,
    this.wrongDay = false,
  });

  final int gems;
  final int streak;
  final bool weeklyBonus;
  final bool alreadyDone;
  final bool clockBlocked;
  final bool wrongDay;
}

/// Consecutive completed days ending [today], or ending yesterday when today
/// is still open. 0 when neither today nor yesterday is done.
int challengeStreakOf(Set<String> done, DateTime today) {
  final end = done.contains(dayKey(today)) ? today : _shift(today, -1);
  if (!done.contains(dayKey(end))) return 0;
  var count = 0;
  var cursor = end;
  while (done.contains(dayKey(cursor))) {
    count++;
    cursor = _shift(cursor, -1);
  }
  return count;
}

/// Monday..Sunday of the week that contains [day], as local dates.
List<DateTime> weekDays(DateTime day) {
  final utc = DateTime.utc(day.year, day.month, day.day);
  final monday = utc.subtract(Duration(days: utc.weekday - 1));
  return [for (var i = 0; i < 7; i++) _shift(monday, i)];
}

/// [dayKey] of the Monday of [day]'s week.
String weekKey(DateTime day) => dayKey(weekDays(day).first);

/// Records [boardDay] when it is still [now]'s local day.
///
/// The caller adds [ChallengeResult.gems]. A backwards clock changes nothing.
/// Finishing after midnight ([wrongDay]) or a second time ([alreadyDone])
/// pays nothing. The weekly bonus is stored in [DailyState.weeklyBonusWeek]
/// so the same week cannot pay it twice.
ChallengeResult completeChallenge(
  DailyState s,
  DateTime boardDay,
  DateTime now,
) {
  if (!recordClock(s, now)) {
    return ChallengeResult(
      gems: 0,
      streak: s.challengeStreak,
      clockBlocked: true,
    );
  }
  _prune(s, now);
  if (dayKey(boardDay) != dayKey(now)) {
    return ChallengeResult(gems: 0, streak: s.challengeStreak, wrongDay: true);
  }
  final key = dayKey(now);
  if (s.challengeDone.contains(key)) {
    return ChallengeResult(
      gems: 0,
      streak: challengeStreakOf(s.challengeDone, now),
      alreadyDone: true,
    );
  }
  s.challengeDone.add(key);
  s.challengeStreak = challengeStreakOf(s.challengeDone, now);
  var gems = challengeRewardGems;
  var bonus = false;
  final week = weekKey(now);
  final finished = weekDays(
    now,
  ).every((date) => s.challengeDone.contains(dayKey(date)));
  if (finished && s.weeklyBonusWeek != week) {
    gems += weeklyBonusGems;
    s.weeklyBonusWeek = week;
    bonus = true;
  }
  return ChallengeResult(
    gems: gems,
    streak: s.challengeStreak,
    weeklyBonus: bonus,
  );
}

void _prune(DailyState s, DateTime now) {
  s.challengeDone.removeWhere((key) {
    final gap = calendarDaysAfter(key, now);
    return gap != null && gap > challengeHistoryDays;
  });
}

/// Calendar shift. UTC dates, so a DST day still moves one date.
DateTime _shift(DateTime day, int days) {
  final utc = DateTime.utc(day.year, day.month, day.day);
  final next = utc.add(Duration(days: days));
  return DateTime(next.year, next.month, next.day);
}
