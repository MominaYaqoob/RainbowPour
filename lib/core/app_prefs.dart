import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_challenge.dart' as challenge;
import 'daily_reward.dart' as reward;
import 'save_data.dart';

/// Local storage for the player's progress and settings.
///
/// Everything lives in one [SaveData] document stored as JSON under
/// [saveKey]. The first time it is missing, the values older builds kept in
/// separate preference keys are migrated into it. The methods keep the names
/// the screens already use.
abstract final class AppPrefs {
  static const saveKey = 'save_v1';

  static SaveData? _data;
  static Future<SaveData>? _loading;

  static Future<SaveData> _load() => _data != null
      ? Future.value(_data)
      : (_loading ??= _read().then((d) => _data = d));

  static Future<SaveData> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = SaveData.tryDecode(prefs.getString(saveKey));
    if (saved != null) return saved;
    final old = <String, Object?>{
      for (final key in prefs.getKeys()) key: prefs.get(key),
    };
    final migrated = SaveData.fromLegacy(old);
    await prefs.setString(saveKey, migrated.encode());
    return migrated;
  }

  /// Runs [change] on the save and stores the result.
  static Future<T> _update<T>(T Function(SaveData d) change) async {
    final data = await _load();
    final result = change(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(saveKey, data.encode());
    return result;
  }

  /// Forgets the loaded copy so the next call reads storage again (tests).
  @visibleForTesting
  static void resetForTest() {
    _data = null;
    _loading = null;
  }

  // ---- settings and flags

  /// Settings switches and small flags: `sound`, `music`, `vibration`
  /// (on by default), `colorblind` and `tutorial` (off by default).
  static Future<bool> flag(String key, {bool def = true}) async {
    final d = await _load();
    return switch (key) {
      'sound' => d.sound,
      'music' => d.music,
      'vibration' => d.vibration,
      'colorblind' => d.colorblind,
      'tutorial' => d.tutorialDone,
      _ => def,
    };
  }

  static Future<void> setFlag(String key, bool v) => _update((d) {
    switch (key) {
      case 'sound':
        d.sound = v;
      case 'music':
        d.music = v;
      case 'vibration':
        d.vibration = v;
      case 'colorblind':
        d.colorblind = v;
      case 'tutorial':
        d.tutorialDone = v;
    }
  });

  // ---- first launch

  static Future<bool> isConsentDone() async => (await _load()).consentDone;
  static Future<void> setConsentDone() => _update((d) => d.consentDone = true);

  static Future<bool> isOnboardingDone() async =>
      (await _load()).onboardingDone;
  static Future<void> setOnboardingDone() =>
      _update((d) => d.onboardingDone = true);

  static Future<bool> isWelcomeClaimed() async =>
      (await _load()).welcomeClaimed;

  /// Adds the welcome gift to the gem balance, once.
  static Future<void> claimWelcome(int gems) => _update((d) {
    if (d.welcomeClaimed) return;
    d.gems += gems;
    d.welcomeClaimed = true;
  });

  // ---- shop

  static Future<int> skin() async => (await _load()).skin;
  static Future<void> setSkin(int i) => _update((d) => d.skin = i);

  static Future<int> bgMode() async => (await _load()).bgMode;
  static Future<void> setBgMode(int i) => _update((d) => d.bgMode = i);

  /// Shop items the player has bought, e.g. `skin:tube` or `bg:2`.
  static Future<Set<String>> owned() async => {...(await _load()).owned};

  static Future<void> addOwned(String id) => _update((d) => d.owned.add(id));

  // ---- progress

  /// The furthest level the player can open.
  static Future<int> level() async => (await _load()).level;
  static Future<void> setLevel(int v) => _update((d) => d.level = v);

  /// Stores a win: best stars, completed count, total moves, next level open.
  /// Returns true when the stars are a new best for the level.
  static Future<bool> recordWin({
    required int level,
    required int stars,
    required int moves,
    required int maxLevel,
  }) => _update(
    (d) => d.recordWin(
      level: level,
      stars: stars,
      moves: moves,
      maxLevel: maxLevel,
    ),
  );

  /// Best stars per level (1 to 3); a level that was never won is missing.
  static Future<Map<int, int>> stars() async => {...(await _load()).stars};

  /// Levels won and moves made in all of them.
  static Future<({int completed, int moves})> totals() async {
    final d = await _load();
    return (completed: d.levelsCompleted, moves: d.totalMoves);
  }

  /// Longest daily streak stored in the save. Read only.
  static Future<int> bestStreak() async => (await _load()).daily.bestStreak;

  /// A copy of the daily record. Changing the copy does not change the save.
  static Future<DailyState> daily() async {
    final src = (await _load()).daily;
    return DailyState.fromJson(src.toJson());
  }

  /// Records [now] when the clock is fine, and returns true.
  /// Returns false and writes nothing when the clock went backwards.
  /// Uses [reward.recordClock], the same rule as [claimDaily].
  static Future<bool> touchClock(DateTime now) =>
      _update((d) => reward.recordClock(d.daily, now));

  /// Claims today's reward when it is still open. Gems and the streak are
  /// written in the same save. [DailyClaim.gems] is 0 when today was already
  /// claimed or the clock went backwards ([DailyClaim.clockBlocked]).
  /// [now] is the clock the caller trusts.
  static Future<reward.DailyClaim> claimDaily(DateTime now) => _update((d) {
    final result = reward.claimDaily(d.daily, now);
    d.gems += result.gems;
    return result;
  });

  /// Finishes [boardDay] if it is still [now]'s local day. Gems and the
  /// challenge record are written in the same save.
  static Future<challenge.ChallengeResult> completeChallenge(
    DateTime boardDay,
    DateTime now,
  ) => _update((d) {
    final result = challenge.completeChallenge(d.daily, boardDay, now);
    d.gems += result.gems;
    return result;
  });

  // ---- gems

  static Future<int> gems() async => (await _load()).gems;

  /// Adds gems and returns the new total.
  static Future<int> addGems(int n) => _update((d) => d.gems += n);

  /// Takes [n] gems if there are enough. Returns false (and changes nothing)
  /// when the player cannot afford it.
  static Future<bool> spendGems(int n) => _update((d) {
    if (d.gems < n) return false;
    d.gems -= n;
    return true;
  });

  // ---- rewarded ads

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  /// Gem ads watched today. Starts again from 0 on a new day.
  static Future<int> adsToday() async {
    final d = await _load();
    return d.adsDay == _today() ? d.adsCount : 0;
  }

  /// Gems from one watched gem ad, and how many of those ads fit in a day.
  static const gemAdReward = 10;
  static const gemAdDailyCap = 3;

  /// Pays [gemAdReward] and counts the ad, in one save. False at the daily cap.
  static Future<bool> watchedGemAd() => _update((d) {
    final today = _today();
    if (d.adsDay != today) {
      d.adsDay = today;
      d.adsCount = 0;
    }
    if (d.adsCount >= gemAdDailyCap) return false;
    d.adsCount++;
    d.gems += gemAdReward;
    return true;
  });

  /// Adds today's claimed daily reward a second time. 0 if it was not claimed
  /// today, or an ad already doubled it.
  static Future<int> doubleDailyReward(DateTime now) => _update((d) {
    final key = reward.dayKey(now);
    final daily = d.daily;
    if (daily.lastClaimDay != key || daily.rewardDoubledDay == key) return 0;
    if (daily.streakDay < 1 ||
        daily.streakDay > reward.dailyRewardAmounts.length) {
      return 0;
    }
    final amount = reward.dailyRewardAmounts[daily.streakDay - 1];
    daily.rewardDoubledDay = key;
    d.gems += amount;
    return amount;
  });

  /// Counts one more watched ad and returns today's total.
  static Future<int> addAdToday() => _update((d) {
    final today = _today();
    if (d.adsDay != today) {
      d.adsDay = today;
      d.adsCount = 0;
    }
    return ++d.adsCount;
  });

  // ---- profile

  static Future<bool> isProfileDone() async => (await _load()).profileDone;

  static Future<void> saveProfile(String nickname, int avatar) => _update((d) {
    d.nickname = nickname;
    d.avatar = avatar;
    d.profileDone = true;
  });

  static Future<String?> nickname() async => (await _load()).nickname;
  static Future<int> avatar() async => (await _load()).avatar;

  // ---- the level being played

  /// The unfinished level saved after the last move, or null.
  static Future<InProgress?> inProgress() async => (await _load()).inProgress;

  /// Saves the unfinished level, or clears it with null.
  static Future<void> setInProgress(InProgress? progress) =>
      _update((d) => d.inProgress = progress);
}
