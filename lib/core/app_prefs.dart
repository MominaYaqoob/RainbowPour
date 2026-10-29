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

  static Future<int> level() async => (await _p).getInt(_level) ?? 1;

  static Future<int> gems() async => (await _p).getInt(_gems) ?? 0;

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
