import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/daily_reward.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    AppPrefs.resetForTest();
  });

  test('old separate preference keys are migrated on first use', () async {
    SharedPreferences.setMockInitialValues({
      'consent_done': true,
      'gems': 140,
      'level': 12,
      'nickname': 'Sara',
      'avatar': 5,
      'opt_music': false,
      'owned': ['skin:tube', 'bg:1'],
    });
    expect(await AppPrefs.gems(), 140);
    expect(await AppPrefs.level(), 12);
    expect(await AppPrefs.nickname(), 'Sara');
    expect(await AppPrefs.avatar(), 5);
    expect(await AppPrefs.isConsentDone(), isTrue);
    expect(await AppPrefs.flag('music'), isFalse);
    expect(await AppPrefs.owned(), {'skin:tube', 'bg:1'});

    // and the new document was written
    final prefs = await SharedPreferences.getInstance();
    final saved = SaveData.tryDecode(prefs.getString(AppPrefs.saveKey));
    expect(saved, isNotNull);
    expect(saved!.gems, 140);
  });

  test('changes are stored and survive a fresh start', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AppPrefs.gems(), 0);
    expect(await AppPrefs.addGems(30), 30);
    await AppPrefs.setLevel(7);
    await AppPrefs.setSkin(2);
    await AppPrefs.setBgMode(1);
    await AppPrefs.addOwned('skin:potion');
    await AppPrefs.setFlag('sound', false);
    await AppPrefs.setFlag('tutorial', true);
    await AppPrefs.saveProfile('Mina', 3);

    AppPrefs.resetForTest(); // like closing and reopening the app
    expect(await AppPrefs.gems(), 30);
    expect(await AppPrefs.level(), 7);
    expect(await AppPrefs.skin(), 2);
    expect(await AppPrefs.bgMode(), 1);
    expect(await AppPrefs.owned(), {'skin:potion'});
    expect(await AppPrefs.flag('sound'), isFalse);
    expect(await AppPrefs.flag('tutorial', def: false), isTrue);
    expect(await AppPrefs.nickname(), 'Mina');
    expect(await AppPrefs.isProfileDone(), isTrue);
  });

  test('a win is stored and read back', () async {
    SharedPreferences.setMockInitialValues({});
    expect(
      await AppPrefs.recordWin(level: 1, stars: 3, moves: 9, maxLevel: 300),
      isTrue,
    );
    await AppPrefs.recordWin(level: 2, stars: 1, moves: 15, maxLevel: 300);
    AppPrefs.resetForTest();
    expect(await AppPrefs.stars(), {1: 3, 2: 1});
    expect(await AppPrefs.level(), 3);
    final totals = await AppPrefs.totals();
    expect(totals.completed, 2);
    expect(totals.moves, 24);
  });

  test('gems never go below zero', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.addGems(50);
    expect(await AppPrefs.spendGems(80), isFalse);
    expect(await AppPrefs.gems(), 50);
    expect(await AppPrefs.spendGems(50), isTrue);
    expect(await AppPrefs.gems(), 0);
  });

  test('the welcome gift is paid once', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.claimWelcome(100);
    await AppPrefs.claimWelcome(100);
    expect(await AppPrefs.gems(), 100);
    expect(await AppPrefs.isWelcomeClaimed(), isTrue);
  });

  test('the ad counter counts up and is read back', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AppPrefs.adsToday(), 0);
    expect(await AppPrefs.addAdToday(), 1);
    expect(await AppPrefs.addAdToday(), 2);
    expect(await AppPrefs.adsToday(), 2);
  });

  test('an old counter from another day does not count today', () async {
    SharedPreferences.setMockInitialValues({
      'ads_day': '2001-1-1',
      'ads_count': 3,
    });
    expect(await AppPrefs.adsToday(), 0);
    expect(await AppPrefs.addAdToday(), 1);
  });

  test('a damaged save is replaced by a fresh migration', () async {
    SharedPreferences.setMockInitialValues({
      AppPrefs.saveKey: '{broken',
      'gems': 9,
    });
    expect(await AppPrefs.gems(), 9);
  });

  test('the unfinished level is saved and cleared', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AppPrefs.inProgress(), isNull);
    await AppPrefs.setInProgress(
      InProgress(
        mode: 'level',
        level: 4,
        capacity: 4,
        bottles: [
          [0, 1],
          [],
        ],
        moves: 2,
        history: [
          [0, 1, 1],
        ],
      ),
    );
    AppPrefs.resetForTest();
    final back = await AppPrefs.inProgress();
    expect(back!.level, 4);
    expect(back.bottles, [
      [0, 1],
      [],
    ]);
    await AppPrefs.setInProgress(null);
    AppPrefs.resetForTest();
    expect(await AppPrefs.inProgress(), isNull);
  });

  test('claimDaily adds the gems once and the streak round-trips', () async {
    SharedPreferences.setMockInitialValues({});
    final first = DateTime(2026, 5, 2, 9);
    final later = DateTime(2026, 5, 2, 21);
    expect((await AppPrefs.claimDaily(first)).gems, 20);
    expect((await AppPrefs.claimDaily(later)).gems, 0);
    expect(await AppPrefs.gems(), 20);
    expect((await AppPrefs.claimDaily(DateTime(2026, 5, 3, 8))).gems, 30);
    expect(await AppPrefs.gems(), 50);

    AppPrefs.resetForTest();
    expect(await AppPrefs.gems(), 50);
    final saved = await AppPrefs.daily();
    expect(saved.streakDay, 2);
    expect(saved.streakCount, 2);
    expect(saved.lastClaimDay, '2026-5-3');
    expect(saved.bestStreak, 2);

    saved.streakCount = 99;
    expect((await AppPrefs.daily()).streakCount, 2);

    final prefs = await SharedPreferences.getInstance();
    final decoded = SaveData.tryDecode(prefs.getString(AppPrefs.saveKey))!;
    expect(decoded.daily.streakCount, 2);
    expect(decoded.gems, 50);
  });

  test('an old save without streakCount loads as zero', () async {
    SharedPreferences.setMockInitialValues({
      AppPrefs.saveKey:
          '{"version":1,"gems":5,"daily":{"lastClaimDay":"2026-1-2","streakDay":4,"bestStreak":4}}',
    });
    final saved = await AppPrefs.daily();
    expect(saved.streakCount, 0);
    expect(saved.streakDay, 4);
    expect(saved.bestStreak, 4);
    expect(await AppPrefs.gems(), 5);
  });

  test('touchClock moves forward and a rewind does not stick', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 8, 1, 12);
    expect(await AppPrefs.touchClock(now), isTrue);
    AppPrefs.resetForTest();
    expect((await AppPrefs.daily()).lastSeenMs, now.millisecondsSinceEpoch);

    final behind = now.subtract(const Duration(minutes: 3));
    expect(await AppPrefs.touchClock(behind), isFalse);
    AppPrefs.resetForTest();
    expect((await AppPrefs.daily()).lastSeenMs, now.millisecondsSinceEpoch);

    final ahead = now.add(const Duration(minutes: 10));
    expect(await AppPrefs.touchClock(ahead), isTrue);
    expect((await AppPrefs.daily()).lastSeenMs, ahead.millisecondsSinceEpoch);
  });

  test('claimDaily adds no gems when the clock went back', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 8, 2, 12);
    expect(await AppPrefs.touchClock(now), isTrue);
    final claim = await AppPrefs.claimDaily(
      now.subtract(const Duration(days: 1)),
    );
    expect(claim.gems, 0);
    expect(claim.clockBlocked, isTrue);
    expect(await AppPrefs.gems(), 0);
    AppPrefs.resetForTest();
    final saved = await AppPrefs.daily();
    expect(saved.lastSeenMs, now.millisecondsSinceEpoch);
    expect(saved.streakDay, 0);
    expect(saved.lastClaimDay, isNull);
  });

  test('completeChallenge adds the gems in the same save', () async {
    SharedPreferences.setMockInitialValues({});
    final day = DateTime(2026, 6, 15, 9);
    final result = await AppPrefs.completeChallenge(day, day);
    expect(result.gems, 30);
    expect(result.streak, 1);
    expect(await AppPrefs.gems(), 30);

    AppPrefs.resetForTest();
    final saved = await AppPrefs.daily();
    expect(saved.challengeDone, {dayKey(day)});
    expect(saved.challengeStreak, 1);
    expect(saved.weeklyBonusWeek, isNull);
    expect(await AppPrefs.gems(), 30);

    final again = await AppPrefs.completeChallenge(
      day,
      DateTime(2026, 6, 15, 21),
    );
    expect(again.alreadyDone, isTrue);
    expect(again.gems, 0);
    expect(await AppPrefs.gems(), 30);

    final prefs = await SharedPreferences.getInstance();
    final decoded = SaveData.tryDecode(prefs.getString(AppPrefs.saveKey))!;
    expect(decoded.daily.weeklyBonusWeek, isNull);
    expect(decoded.gems, 30);
    expect(decoded.daily.challengeDone, {dayKey(day)});
  });

  test('an old save without weeklyBonusWeek loads', () async {
    SharedPreferences.setMockInitialValues({
      AppPrefs.saveKey:
          '{"version":1,"gems":4,"daily":{"challengeStreak":2,"challengeDone":["2026-6-14"]}}',
    });
    final saved = await AppPrefs.daily();
    expect(saved.weeklyBonusWeek, isNull);
    expect(saved.rewardDoubledDay, isNull);
    expect(saved.challengeStreak, 2);
    expect(saved.challengeDone, {'2026-6-14'});
    expect(await AppPrefs.gems(), 4);
  });

  test('watchedGemAd pays 10 gems three times, then the next day', () async {
    SharedPreferences.setMockInitialValues({});
    for (var i = 0; i < 3; i++) {
      expect(await AppPrefs.watchedGemAd(), isTrue);
    }
    expect(await AppPrefs.watchedGemAd(), isFalse);
    expect(await AppPrefs.adsToday(), 3);
    expect(await AppPrefs.gems(), 30);

    final prefs = await SharedPreferences.getInstance();
    final saved = SaveData.tryDecode(prefs.getString(AppPrefs.saveKey))!;
    saved.adsDay = '1999-1-1';
    await prefs.setString(AppPrefs.saveKey, saved.encode());
    AppPrefs.resetForTest();

    expect(await AppPrefs.adsToday(), 0);
    expect(await AppPrefs.watchedGemAd(), isTrue);
    expect(await AppPrefs.adsToday(), 1);
    expect(await AppPrefs.gems(), 40);
  });

  test('doubleDailyReward pays once and survives a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 6, 15, 10);
    expect(await AppPrefs.doubleDailyReward(now), 0);

    expect((await AppPrefs.claimDaily(now)).gems, 20);
    expect(await AppPrefs.doubleDailyReward(now), 20);
    expect(await AppPrefs.gems(), 40);
    expect(await AppPrefs.doubleDailyReward(now), 0);
    expect(await AppPrefs.gems(), 40);

    AppPrefs.resetForTest();
    final saved = await AppPrefs.daily();
    expect(saved.rewardDoubledDay, dayKey(now));
    expect(await AppPrefs.gems(), 40);
    expect(await AppPrefs.doubleDailyReward(now), 0);
  });
}
