part of 'app_prefs.dart';

/// Save-file shortcuts for the debug-only QA menu (Settings, debug builds).
///
/// Nothing in the game uses these. Only the QA menu calls them, and that menu
/// is wrapped in `kDebugMode`, so release builds drop all of this code.
extension AppPrefsQa on AppPrefs {
  /// Sets the gem balance to exactly [n] (never below 0).
  static Future<void> setGems(int n) => AppPrefs._update((d) {
    d.gems = n < 0 ? 0 : n;
  });

  /// Makes [level] the furthest open level and drops any unfinished board, so
  /// "Play" starts that level. Stars of earlier levels are left alone, so a
  /// level never won still pays its first-win gems.
  static Future<void> jumpToLevel(int level, {required int maxLevel}) =>
      AppPrefs._update((d) {
        d.level = level.clamp(1, maxLevel);
        d.inProgress = null;
      });

  /// Opens every level (the furthest open level becomes [maxLevel]).
  static Future<void> unlockAll({required int maxLevel}) =>
      AppPrefs._update((d) {
        d.level = maxLevel;
        d.inProgress = null;
      });

  /// Back to a new player's progress: level 1, no stars, no counters.
  static Future<void> resetProgress() => AppPrefs._update((d) {
    d.level = 1;
    d.stars.clear();
    d.levelsCompleted = 0;
    d.totalMoves = 0;
    d.inProgress = null;
  });

  /// Pretends the phone clock was one day ahead earlier, so the daily clock
  /// check blocks claims ("Check Your Clock"). Undo it with [resetClock].
  static Future<void> shiftClockAhead(DateTime now) => AppPrefs._update((d) {
    d.daily.lastSeenMs = now
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;
  });

  /// Sets the last seen time to [now] (clears the fake clock trouble).
  static Future<void> resetClock(DateTime now) => AppPrefs._update((d) {
    d.daily.lastSeenMs = now.millisecondsSinceEpoch;
  });

  /// Makes the daily reward claimable again as day 3 of a running streak:
  /// the last claim is yesterday.
  static Future<void> dailyClaimableDay3(DateTime now) => AppPrefs._update((d) {
    final yesterday = now.subtract(const Duration(days: 1));
    d.daily.lastClaimDay = reward.dayKey(yesterday);
    d.daily.streakDay = 2;
    d.daily.streakCount = 2;
    d.daily.rewardDoubledDay = null;
  });

  /// Forgets all daily reward claims and streaks.
  static Future<void> resetDailyReward() => AppPrefs._update((d) {
    d.daily.lastClaimDay = null;
    d.daily.streakDay = 0;
    d.daily.streakCount = 0;
    d.daily.bestStreak = 0;
    d.daily.rewardDoubledDay = null;
  });

  /// Forgets all daily challenge results.
  static Future<void> resetChallenge() => AppPrefs._update((d) {
    d.daily.challengeDone.clear();
    d.daily.challengeStreak = 0;
    d.daily.weeklyBonusWeek = null;
  });

  /// Zeroes today's gem-ad counter.
  static Future<void> resetAdCounters() => AppPrefs._update((d) {
    d.adsDay = null;
    d.adsCount = 0;
  });

  /// Lets the in-app review be asked again.
  static Future<void> resetReviewRecord() =>
      AppPrefs._update((d) => d.reviewAskedDay = null);

  /// Wipes the whole save (the next read starts a brand new player).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppPrefs.saveKey);
    AppPrefs.resetForTest();
  }
}
