import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/save_data.dart';

void main() {
  test('a new save has the defaults', () {
    final s = SaveData();
    expect(s.gems, 0);
    expect(s.level, 1);
    expect(s.sound, isTrue);
    expect(s.colorblind, isFalse);
    expect(s.bgMode, -1);
    expect(s.inProgress, isNull);
    expect(s.stars, isEmpty);
  });

  test('everything survives encode and decode', () {
    final s = SaveData()
      ..consentDone = true
      ..onboardingDone = true
      ..welcomeClaimed = true
      ..profileDone = true
      ..nickname = 'Momina'
      ..avatar = 3
      ..tutorialDone = true
      ..gems = 250
      ..owned = {'skin:tube', 'bg:2'}
      ..skin = 2
      ..bgMode = 1
      ..level = 17
      ..stars = {1: 3, 2: 2, 16: 1}
      ..levelsCompleted = 16
      ..totalMoves = 410
      ..sound = false
      ..music = false
      ..vibration = false
      ..colorblind = true
      ..adsDay = '2026-11-5'
      ..adsCount = 2;
    s.daily
      ..lastClaimDay = '2026-11-4'
      ..streakDay = 3
      ..bestStreak = 5
      ..lastSeenMs = 1793000000000
      ..challengeDone = {'2026-11-3', '2026-11-4'}
      ..challengeStreak = 2;
    s.inProgress = InProgress(
      mode: 'level',
      level: 17,
      capacity: 4,
      bottles: [
        [0, 1, 0],
        [1, 0],
        [],
      ],
      moves: 5,
      history: [
        [0, 2, 1],
        [1, 2, 2],
      ],
      freeUndos: 2,
      bonusUndos: 3,
      extraBottleUsed: true,
    );

    final back = SaveData.tryDecode(s.encode())!;
    expect(back.toJson(), s.toJson());
    expect(back.nickname, 'Momina');
    expect(back.owned, {'skin:tube', 'bg:2'});
    expect(back.stars, {1: 3, 2: 2, 16: 1});
    expect(back.daily.challengeDone, {'2026-11-3', '2026-11-4'});
    expect(back.inProgress!.bottles, [
      [0, 1, 0],
      [1, 0],
      [],
    ]);
    expect(back.inProgress!.history, [
      [0, 2, 1],
      [1, 2, 2],
    ]);
    expect(back.inProgress!.extraBottleUsed, isTrue);
  });

  test('missing or damaged text gives null', () {
    expect(SaveData.tryDecode(null), isNull);
    expect(SaveData.tryDecode(''), isNull);
    expect(SaveData.tryDecode('{not json'), isNull);
    expect(SaveData.tryDecode('[1,2,3]'), isNull);
  });

  test('wrongly typed fields fall back to defaults', () {
    final s = SaveData.tryDecode(
      '{"gems":"lots","level":null,"sound":"yes","stars":{"3":9,"x":2,"4":2},'
      '"owned":[1,"bg:1"],"inProgress":{"mode":"level"}}',
    )!;
    expect(s.gems, 0);
    expect(s.level, 1);
    expect(s.sound, isTrue);
    // star 9 and key "x" are dropped, "4": 2 stays
    expect(s.stars, {4: 2});
    expect(s.owned, {'bg:1'});
    expect(s.inProgress, isNull);
  });

  test('a saved board that cannot be real is dropped', () {
    // five layers in a four-layer bottle
    final tooFull = SaveData.tryDecode(
      '{"inProgress":{"mode":"level","capacity":4,'
      '"bottles":[[0,0,0,0,0]],"moves":0,"history":[]}}',
    )!;
    expect(tooFull.inProgress, isNull);
    // a history entry with the wrong shape
    final badHistory = SaveData.tryDecode(
      '{"inProgress":{"mode":"level","capacity":4,'
      '"bottles":[[0],[]],"moves":1,"history":[[0,1]]}}',
    )!;
    expect(badHistory.inProgress, isNull);
  });

  group('recording a win', () {
    test('the first win stores stars, counts the level and opens the next', () {
      final s = SaveData();
      final best = s.recordWin(level: 1, stars: 2, moves: 8, maxLevel: 300);
      expect(best, isTrue);
      expect(s.stars, {1: 2});
      expect(s.levelsCompleted, 1);
      expect(s.totalMoves, 8);
      expect(s.level, 2);
    });

    test('fewer stars never lower the best, more stars raise it', () {
      final s = SaveData()
        ..recordWin(level: 5, stars: 3, moves: 10, maxLevel: 300);
      expect(
        s.recordWin(level: 5, stars: 1, moves: 20, maxLevel: 300),
        isFalse,
      );
      expect(s.stars[5], 3);
      final t = SaveData()
        ..recordWin(level: 5, stars: 1, moves: 20, maxLevel: 300);
      expect(t.recordWin(level: 5, stars: 3, moves: 11, maxLevel: 300), isTrue);
      expect(t.stars[5], 3);
    });

    test('a level is counted once but every win adds its moves', () {
      final s = SaveData()
        ..recordWin(level: 3, stars: 1, moves: 12, maxLevel: 300)
        ..recordWin(level: 3, stars: 2, moves: 9, maxLevel: 300);
      expect(s.levelsCompleted, 1);
      expect(s.totalMoves, 21);
    });

    test('replaying an old level does not close the open ones', () {
      final s = SaveData()..level = 40;
      s.recordWin(level: 7, stars: 3, moves: 6, maxLevel: 300);
      expect(s.level, 40);
    });

    test('the last level opens nothing new', () {
      final s = SaveData()..level = 300;
      s.recordWin(level: 300, stars: 2, moves: 50, maxLevel: 300);
      expect(s.level, 300);
    });

    test('stars outside 1 to 3 are kept inside the range', () {
      final s = SaveData()
        ..recordWin(level: 2, stars: 9, moves: 5, maxLevel: 300)
        ..recordWin(level: 3, stars: 0, moves: 5, maxLevel: 300);
      expect(s.stars, {2: 3, 3: 1});
    });
  });

  test('old preference values are migrated', () {
    final s = SaveData.fromLegacy({
      'consent_done': true,
      'onboarding_done': true,
      'welcome_claimed': true,
      'profile_done': true,
      'nickname': 'Ali',
      'avatar': 4,
      'gems': 320,
      'level': 21,
      'bottle_skin': 2,
      'bg_mode': 3,
      'owned': ['skin:tube'],
      'opt_sound': false,
      'opt_vibration': false,
      'opt_tutorial': true,
      'ads_day': '2026-11-2',
      'ads_count': 3,
    });
    expect(s.consentDone && s.onboardingDone && s.welcomeClaimed, isTrue);
    expect(s.profileDone, isTrue);
    expect(s.nickname, 'Ali');
    expect(s.avatar, 4);
    expect(s.gems, 320);
    expect(s.level, 21);
    expect(s.skin, 2);
    expect(s.bgMode, 3);
    expect(s.owned, {'skin:tube'});
    expect(s.sound, isFalse);
    expect(s.music, isTrue);
    expect(s.vibration, isFalse);
    expect(s.tutorialDone, isTrue);
    expect(s.adsDay, '2026-11-2');
    expect(s.adsCount, 3);
  });

  test('migrating nothing gives a clean new save', () {
    final s = SaveData.fromLegacy({});
    expect(s.toJson(), SaveData().toJson());
  });
}
