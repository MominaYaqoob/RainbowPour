import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
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
}
