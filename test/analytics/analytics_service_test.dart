import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/analytics/analytics_service.dart';

class FakeBackend implements AnalyticsBackend {
  bool failInit = false;
  bool failLog = false;
  int inits = 0;
  final List<bool> collection = [];
  final List<(String, Map<String, Object>)> events = [];
  final List<(Object, bool)> errors = [];

  @override
  Future<void> init() async {
    inits++;
    if (failInit) throw StateError('no firebase');
  }

  @override
  Future<void> setCollectionEnabled(bool on) async => collection.add(on);

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    if (failLog) throw StateError('log failed');
    events.add((name, params));
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async => errors.add((error, fatal));
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

Future<AnalyticsService> started(
  FakeBackend fake, {
  bool consent = true,
}) async {
  final service = AnalyticsService(backend: fake, supported: true);
  await service.init();
  if (consent) await service.setConsent(true);
  return service;
}

void main() {
  test(
    'ad_impression carries value in currency units and the ad format',
    () async {
      final fake = FakeBackend();
      final service = await started(fake);
      service.adImpression(
        format: 'rewarded',
        unit: 'ca-app-pub-x/1',
        valueMicros: 2500000,
        currency: 'USD',
      );
      await settle();
      expect(fake.events.single.$1, 'ad_impression');
      expect(fake.events.single.$2, {
        'value': 2.5,
        'currency': 'USD',
        'ad_format': 'rewarded',
        'ad_unit_name': 'ca-app-pub-x/1',
        'ad_platform': 'AdMob',
      });
    },
  );

  test('nothing is sent before init or before consent', () async {
    final fake = FakeBackend();
    final service = AnalyticsService(backend: fake, supported: true);
    service.levelStart(3);
    await settle();
    expect(fake.events, isEmpty);

    await service.init();
    service.levelStart(3);
    await settle();
    expect(fake.events, isEmpty, reason: 'no consent yet');
    expect(service.collecting, isFalse);

    await service.setConsent(true);
    service.levelStart(3);
    await settle();
    expect(fake.events.length, 1);
    expect(fake.collection, [true]);
  });

  test('consent given while Firebase starts is applied after init', () async {
    final fake = FakeBackend();
    final service = AnalyticsService(backend: fake, supported: true);
    await service.setConsent(true);
    expect(fake.collection, isEmpty);
    await service.init();
    expect(fake.collection, [true]);
    service.levelStart(1);
    await settle();
    expect(fake.events.length, 1);
  });

  test('withdrawing consent stops events and tells Firebase', () async {
    final fake = FakeBackend();
    final service = await started(fake);
    service.levelStart(1);
    await service.setConsent(false);
    service.levelStart(2);
    await settle();
    expect(fake.events.length, 1);
    expect(fake.collection, [true, false]);
  });

  test('unsupported platforms (web, desktop) do nothing', () async {
    final fake = FakeBackend();
    final service = AnalyticsService(backend: fake, supported: false);
    await service.init();
    await service.setConsent(true);
    service.levelStart(1);
    await settle();
    expect(fake.inits, 0);
    expect(fake.events, isEmpty);
  });

  test('a Firebase failure never reaches the game', () async {
    final broken = FakeBackend()..failInit = true;
    final service = AnalyticsService(backend: broken, supported: true);
    await service.init();
    await service.setConsent(true);
    service.levelStart(1);
    await settle();
    expect(broken.events, isEmpty);

    final fake = FakeBackend()..failLog = true;
    final ok = await started(fake);
    ok.levelStart(1);
    await ok.recordError(StateError('x'), null);
    await settle();
  });

  test('level events use Firebase names and the right parameters', () async {
    final fake = FakeBackend();
    final s = await started(fake);
    s.levelStart(12);
    s.levelEnd(12, success: true, stars: 3, moves: 20);
    s.levelEnd(13, success: false);
    s.levelStuck(14, moves: 9);
    s.levelQuit(15, moves: 4);
    await settle();
    expect(fake.events.map((e) => e.$1), [
      'level_start',
      'level_end',
      'level_end',
      'level_stuck',
      'level_quit',
    ]);
    expect(fake.events[0].$2, {'level_name': '12'});
    expect(fake.events[1].$2, {
      'level_name': '12',
      'success': 1,
      'level': 12,
      'stars': 3,
      'moves': 20,
    });
    expect(fake.events[2].$2, {'level_name': '13', 'success': 0, 'level': 13});
    expect(fake.events[3].$2, {'level': 14, 'moves': 9});
  });

  test(
    'gems and shop events say what was bought and what was earned',
    () async {
      final fake = FakeBackend();
      final s = await started(fake);
      s.gemSpend('hint', 40);
      s.gemEarn('level_win', 20);
      s.shopBuy('skin:tube', 700);
      await settle();
      expect(fake.events[0].$1, 'spend_virtual_currency');
      expect(fake.events[0].$2, {
        'virtual_currency_name': 'gems',
        'item_name': 'hint',
        'value': 40,
      });
      expect(fake.events[1].$1, 'earn_virtual_currency');
      expect(fake.events[1].$2['source'], 'level_win');
      expect(fake.events[2].$1, 'shop_buy');
      expect(fake.events[3].$1, 'spend_virtual_currency');
      expect(fake.events[3].$2['item_name'], 'skin:tube');
    },
  );

  test('challenge, ad and daily reward events', () async {
    final fake = FakeBackend();
    final s = await started(fake);
    s.challengeStart();
    s.challengeEnd('win', secondsLeft: 61);
    s.challengeEnd('time_up', secondsLeft: 0);
    s.rewardedAd('shop_gems', 'earned');
    s.interstitialShown(7);
    s.dailyRewardClaim(30);
    await settle();
    expect(fake.events.map((e) => e.$1), [
      'challenge_start',
      'challenge_end',
      'challenge_end',
      'ad_rewarded',
      'ad_interstitial',
      'daily_reward_claim',
    ]);
    expect(fake.events[1].$2, {'result': 'win', 'seconds_left': 61});
    expect(fake.events[3].$2, {'placement': 'shop_gems', 'result': 'earned'});
  });

  test('event names and parameter names fit Firebase limits', () async {
    final fake = FakeBackend();
    final s = await started(fake);
    s.levelStart(1);
    s.levelEnd(1, success: true, stars: 1, moves: 1);
    s.levelStuck(1, moves: 1);
    s.levelQuit(1, moves: 1);
    s.challengeStart();
    s.challengeEnd('quit', secondsLeft: 1);
    s.gemSpend('hint', 1);
    s.gemEarn('x', 1);
    s.shopBuy('a', 1);
    s.rewardedAd('p', 'earned');
    s.interstitialShown(1);
    s.dailyRewardClaim(1);
    await settle();
    final pattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');
    for (final (name, params) in fake.events) {
      expect(name.length <= 40 && pattern.hasMatch(name), isTrue, reason: name);
      expect(params.length <= 25, isTrue);
      for (final entry in params.entries) {
        expect(
          entry.key.length <= 40 && pattern.hasMatch(entry.key),
          isTrue,
          reason: entry.key,
        );
        expect(entry.value is String || entry.value is num, isTrue);
      }
    }
  });

  test('crash reports are sent only with consent', () async {
    final fake = FakeBackend();
    final service = await started(fake, consent: false);
    await service.recordError(StateError('a'), null, fatal: true);
    expect(fake.errors, isEmpty);
    await service.setConsent(true);
    await service.recordError(StateError('b'), null, fatal: true);
    expect(fake.errors.length, 1);
    expect(fake.errors.single.$2, isTrue);
  });
}
