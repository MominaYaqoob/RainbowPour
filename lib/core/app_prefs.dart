import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
