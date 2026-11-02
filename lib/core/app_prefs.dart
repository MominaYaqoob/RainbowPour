import 'package:shared_preferences/shared_preferences.dart';

/// Small wrapper around local storage: first-launch flags and the player's
/// basic profile.
abstract final class AppPrefs {
  static const _consentDone = 'consent_done';
  static const _onboardingDone = 'onboarding_done';
  static const _welcomeClaimed = 'welcome_claimed';
  static const _profileDone = 'profile_done';
  static const _nickname = 'nickname';
  static const _avatar = 'avatar';
  static const _gems = 'gems';
  static const _level = 'level';
  static const _skin = 'bottle_skin';
  static const _bgMode = 'bg_mode';

  /// Settings switches: sound, music, vibration are on by default,
  /// colorblind mode is off.
  static Future<bool> flag(String key, {bool def = true}) async =>
      (await _p).getBool('opt_$key') ?? def;
  static Future<void> setFlag(String key, bool v) async =>
      (await _p).setBool('opt_$key', v);

  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<bool> isConsentDone() async =>
      (await _p).getBool(_consentDone) ?? false;
  static Future<void> setConsentDone() async =>
      (await _p).setBool(_consentDone, true);

  static Future<bool> isOnboardingDone() async =>
      (await _p).getBool(_onboardingDone) ?? false;
  static Future<void> setOnboardingDone() async =>
      (await _p).setBool(_onboardingDone, true);

  static Future<bool> isWelcomeClaimed() async =>
      (await _p).getBool(_welcomeClaimed) ?? false;

  /// Adds the welcome gift to the gem balance, once.
  static Future<void> claimWelcome(int gems) async {
    final p = await _p;
    if (p.getBool(_welcomeClaimed) ?? false) return;
    await p.setInt(_gems, (p.getInt(_gems) ?? 0) + gems);
    await p.setBool(_welcomeClaimed, true);
  }

  static Future<int> skin() async => (await _p).getInt(_skin) ?? 0;
  static Future<void> setSkin(int i) async => (await _p).setInt(_skin, i);

  static Future<int> bgMode() async => (await _p).getInt(_bgMode) ?? -1;
  static Future<void> setBgMode(int i) async => (await _p).setInt(_bgMode, i);

  static Future<int> level() async => (await _p).getInt(_level) ?? 1;
  static Future<void> setLevel(int v) async =>
      (await _p).setInt(_level, v);

  static Future<int> gems() async => (await _p).getInt(_gems) ?? 0;

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  /// Gem ads watched today. Starts again from 0 on a new day.
  static Future<int> adsToday() async {
    final p = await _p;
    if (p.getString('ads_day') != _today()) return 0;
    return p.getInt('ads_count') ?? 0;
  }

  /// Counts one more watched ad and returns today's total.
  static Future<int> addAdToday() async {
    final p = await _p;
    final n = await adsToday() + 1;
    await p.setString('ads_day', _today());
    await p.setInt('ads_count', n);
    return n;
  }

  /// Shop items the player has bought, e.g. `skin:tube` or `bg:2`.
  static Future<Set<String>> owned() async =>
      ((await _p).getStringList('owned') ?? const <String>[]).toSet();

  static Future<void> addOwned(String id) async {
    final s = await owned()
      ..add(id);
    await (await _p).setStringList('owned', s.toList());
  }

  /// Adds gems and returns the new total.
  static Future<int> addGems(int n) async {
    final p = await _p;
    final total = (p.getInt(_gems) ?? 0) + n;
    await p.setInt(_gems, total);
    return total;
  }

  /// Takes [n] gems if there are enough. Returns false (and changes nothing)
  /// when the player cannot afford it.
  static Future<bool> spendGems(int n) async {
    final p = await _p;
    final have = p.getInt(_gems) ?? 0;
    if (have < n) return false;
    await p.setInt(_gems, have - n);
    return true;
  }

  static Future<bool> isProfileDone() async =>
      (await _p).getBool(_profileDone) ?? false;

  static Future<void> saveProfile(String nickname, int avatar) async {
    final p = await _p;
    await p.setString(_nickname, nickname);
    await p.setInt(_avatar, avatar);
    await p.setBool(_profileDone, true);
  }

  static Future<String?> nickname() async => (await _p).getString(_nickname);
  static Future<int> avatar() async => (await _p).getInt(_avatar) ?? 0;
}
