import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/daily_reward.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 18, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  test('setGems sets the balance and never goes below zero', () async {
    await AppPrefsQa.setGems(250);
    expect(await AppPrefs.gems(), 250);
    await AppPrefsQa.setGems(-5);
    expect(await AppPrefs.gems(), 0);
  });

  test('jumpToLevel opens that level and keeps the stars of others', () async {
    await AppPrefs.recordWin(level: 1, stars: 3, moves: 5, maxLevel: 300);
    await AppPrefsQa.jumpToLevel(105, maxLevel: 300);
    expect(await AppPrefs.level(), 105);
    expect((await AppPrefs.stars())[1], 3);
    expect((await AppPrefs.stars()).containsKey(105), isFalse);
    await AppPrefsQa.jumpToLevel(999, maxLevel: 300);
    expect(await AppPrefs.level(), 300);
    await AppPrefsQa.jumpToLevel(-4, maxLevel: 300);
    expect(await AppPrefs.level(), 1);
  });

  test('unlockAll and resetProgress', () async {
    await AppPrefsQa.unlockAll(maxLevel: 300);
    expect(await AppPrefs.level(), 300);
    await AppPrefs.recordWin(level: 2, stars: 2, moves: 9, maxLevel: 300);
    await AppPrefsQa.resetProgress();
    expect(await AppPrefs.level(), 1);
    expect(await AppPrefs.stars(), isEmpty);
    final totals = await AppPrefs.totals();
    expect(totals.completed, 0);
    expect(totals.moves, 0);
  });

  test('the fake clock blocks a claim and can be fixed again', () async {
    await AppPrefsQa.shiftClockAhead(now);
    var claim = await AppPrefs.claimDaily(now);
    expect(claim.clockBlocked, isTrue);
    expect(claim.gems, 0);
    await AppPrefsQa.resetClock(now);
    claim = await AppPrefs.claimDaily(now);
    expect(claim.clockBlocked, isFalse);
    expect(claim.gems, dailyRewardAmounts.first);
  });

  test('dailyClaimableDay3 gives the day 3 reward', () async {
    await AppPrefsQa.dailyClaimableDay3(now);
    final claim = await AppPrefs.claimDaily(now);
    expect(claim.gems, dailyRewardAmounts[2]);
    expect((await AppPrefs.daily()).streakCount, 3);
  });

  test('daily reward and challenge resets', () async {
    await AppPrefs.claimDaily(now);
    await AppPrefs.completeChallenge(DateTime(2026, 11, 18), now);
    await AppPrefsQa.resetDailyReward();
    await AppPrefsQa.resetChallenge();
    final d = await AppPrefs.daily();
    expect(d.lastClaimDay, isNull);
    expect(d.streakDay, 0);
    expect(d.streakCount, 0);
    expect(d.challengeDone, isEmpty);
    expect(d.challengeStreak, 0);
  });

  test('ad counter and review record resets', () async {
    await AppPrefs.watchedGemAd();
    await AppPrefs.markReviewAsked(now);
    expect(await AppPrefs.adsToday(), 1);
    await AppPrefsQa.resetAdCounters();
    await AppPrefsQa.resetReviewRecord();
    expect(await AppPrefs.adsToday(), 0);
    expect(await AppPrefs.reviewAskedDay(), isNull);
  });

  test('clearAll starts a brand new player', () async {
    await AppPrefsQa.setGems(999);
    await AppPrefsQa.jumpToLevel(50, maxLevel: 300);
    await AppPrefsQa.clearAll();
    expect(await AppPrefs.gems(), 0);
    expect(await AppPrefs.level(), 1);
  });
}
