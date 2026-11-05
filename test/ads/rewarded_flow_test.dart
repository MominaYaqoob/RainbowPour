import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/ads/ad_service.dart';
import 'package:rainbow_pour/ads/ads_gateway.dart';
import 'package:rainbow_pour/ads/rewarded_flow.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:rainbow_pour/game/rewards.dart';
import 'package:rainbow_pour/screens/game/level_complete_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
    RewardedFlow.resetForTest();
  });

  test('a reward is the only result that grants', () async {
    final undos = UndoCredits();
    final bottle = ExtraBottle();
    var gems = 0;
    var doubled = false;

    void apply(RewardedResult result) {
      if (result != RewardedResult.rewarded) return;
      gems += 10;
      if (!doubled) doubled = true;
      undos.grantWatchedAd();
      bottle.take();
    }

    for (final result in [
      RewardedResult.dismissed,
      RewardedResult.notReady,
      RewardedResult.error,
    ]) {
      apply(result);
    }
    expect(gems, 0);
    expect(doubled, isFalse);
    expect(undos.bonus, 0);
    expect(bottle.used, isFalse);

    apply(RewardedResult.rewarded);
    expect(gems, 10);
    expect(doubled, isTrue);
    expect(undos.bonus, 3);
    expect(bottle.used, isTrue);
    expect(bottle.take(), isFalse);
  });

  testWidgets('rewarded grants, and the other results grant nothing', (
    tester,
  ) async {
    Future<void> offer(RewardedResult result, {bool failLoad = false}) async {
      SharedPreferences.setMockInitialValues({});
      AppPrefs.resetForTest();
      RewardedFlow.resetForTest();
      final fake = ScriptedGateway()
        ..outcome = result
        ..failLoad = failLoad;
      final ads = await openAds(fake);
      var grants = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                RewardedFlow.run(
                  context,
                  ads: ads,
                  gemCap: true,
                  onReward: () async {
                    grants++;
                    await AppPrefs.watchedGemAd();
                  },
                );
              },
              child: const Text('Watch'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Watch'));
      await tester.pump();
      if (result == RewardedResult.notReady || result == RewardedResult.error) {
        await until(tester, find.text('Ad Not Ready'));
        await tester.tap(find.text('OK'));
        await tester.pump(const Duration(milliseconds: 400));
      } else {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(grants, result == RewardedResult.rewarded ? 1 : 0);
      expect(await AppPrefs.gems(), result == RewardedResult.rewarded ? 10 : 0);
      expect(fake.shows, failLoad ? 0 : 1);
    }

    await offer(RewardedResult.rewarded);
    await offer(RewardedResult.dismissed);
    await offer(RewardedResult.notReady, failLoad: true);
    await offer(RewardedResult.error);
  });

  testWidgets('the fourth gem ad shows the daily limit and pays nothing', (
    tester,
  ) async {
    final now = DateTime.now();
    final data = SaveData()
      ..adsDay = '${now.year}-${now.month}-${now.day}'
      ..adsCount = 3
      ..gems = 30;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefs.saveKey, data.encode());
    AppPrefs.resetForTest();

    final fake = ScriptedGateway();
    final ads = await openAds(fake);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              RewardedFlow.run(
                context,
                ads: ads,
                gemCap: true,
                onReward: () async {
                  await AppPrefs.watchedGemAd();
                },
              );
            },
            child: const Text('Watch'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Watch'));
    await until(tester, find.text('Daily Limit Reached'));
    expect(fake.shows, 0);
    expect(await AppPrefs.gems(), 30);
    expect(await AppPrefs.adsToday(), 3);
  });

  testWidgets('a second tap while the ad is open does not grant again', (
    tester,
  ) async {
    final fake = ScriptedGateway()..hold = Completer<void>();
    final ads = await openAds(fake);
    var grants = 0;
    late BuildContext buttonContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            buttonContext = context;
            return const Text('ready');
          },
        ),
      ),
    );
    final first = RewardedFlow.run(
      buttonContext,
      ads: ads,
      onReward: () async {
        grants++;
      },
    );
    final second = RewardedFlow.run(
      buttonContext,
      ads: ads,
      onReward: () async {
        grants++;
      },
    );
    fake.hold!.complete();
    await Future.wait([first, second]);
    expect(fake.shows, 1);
    expect(grants, 1);
    expect(fake.loads, 2);
  });

  testWidgets('win 2x can be taken once, and level 1 does not offer it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;
    Widget host(Widget child) => MediaQuery(
      data: const MediaQueryData(
        size: Size(800, 1600),
        textScaler: TextScaler.linear(0.8),
      ),
      child: child,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: host(
          LevelCompleteDialog(
            level: 4,
            stars: 3,
            moves: 12,
            gems: 20,
            offerDouble: true,
            onDouble: () async {
              taps++;
              return true;
            },
            onNext: () {},
            onReplay: () {},
            onHome: () {},
          ),
        ),
      ),
    );
    tester.takeException();
    await tester.tap(find.text('Watch an ad for 2x gems'));
    await tester.pump();
    expect(taps, 1);
    expect(find.text('Doubled'), findsOneWidget);
    await tester.tap(find.text('Doubled'));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: host(
          LevelCompleteDialog(
            level: 1,
            stars: 3,
            moves: 3,
            gems: 20,
            onNext: () {},
            onReplay: () {},
            onHome: () {},
          ),
        ),
      ),
    );
    tester.takeException();
    expect(find.text('Watch an ad for 2x gems'), findsNothing);
  });
}

class ScriptedGateway implements AdsGateway {
  RewardedResult outcome = RewardedResult.rewarded;
  bool failLoad = false;
  int loads = 0;
  int shows = 0;
  Completer<void>? hold;

  @override
  Future<void> applyRequestConfiguration() async {}

  @override
  Future<void> requestConsentInfoUpdate() async {}

  @override
  Future<void> loadAndShowConsentFormIfRequired() async {}

  @override
  Future<bool> readCanRequestAds() async => true;

  @override
  Future<bool> get privacyOptionsRequired async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> initializeMobileAds() async {}

  @override
  Future<void> loadRewarded(String adUnitId) async {
    loads++;
    if (failLoad) throw StateError('load failed');
  }

  @override
  Future<bool> showLoadedRewarded() async {
    shows++;
    final waiting = hold;
    if (waiting != null) await waiting.future;
    if (outcome == RewardedResult.error) throw StateError('show failed');
    return outcome == RewardedResult.rewarded;
  }

  @override
  Future<void> loadInterstitial(String adUnitId) async {}

  @override
  Future<void> showLoadedInterstitial() async {}
}

Future<AdService> openAds(ScriptedGateway fake) async {
  final ads = AdService(
    gateway: fake,
    supported: true,
    readyWait: const Duration(milliseconds: 40),
  );
  await ads.initialize();
  await Future<void>.value();
  return ads;
}

Future<void> until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets);
}
