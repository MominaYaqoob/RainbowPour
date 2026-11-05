import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/ads/ad_service.dart';
import 'package:rainbow_pour/ads/ads_gateway.dart';
import 'package:rainbow_pour/ads/interstitial_gate.dart';

void main() {
  late Duration now;
  late InterstitialGate gate;

  setUp(() {
    now = const Duration(minutes: 10);
    gate = InterstitialGate(clock: () => now);
  });

  void win(int times) {
    for (var i = 0; i < times; i++) {
      gate.levelCompleted();
    }
  }

  test('levels 1 to 3 never allow an interstitial', () {
    win(5);
    for (final level in [1, 2, 3]) {
      expect(gate.shouldShow(level: level), isFalse);
    }
    expect(gate.shouldShow(level: 4), isTrue);
  });

  test('nothing at launch: three completed levels are needed first', () {
    expect(gate.shouldShow(level: 10), isFalse);
    win(2);
    expect(gate.shouldShow(level: 10), isFalse);
    win(1);
    expect(gate.shouldShow(level: 10), isTrue);
  });

  test('once per three completed levels', () {
    win(3);
    expect(gate.shouldShow(level: 6), isTrue);
    gate.markShown();
    now += const Duration(minutes: 5);
    win(2);
    expect(gate.shouldShow(level: 8), isFalse);
    win(1);
    expect(gate.shouldShow(level: 9), isTrue);
  });

  test('89 seconds is blocked and 90 seconds is allowed', () {
    win(3);
    gate.markShown();
    win(3);
    now += const Duration(seconds: 89);
    expect(gate.shouldShow(level: 9), isFalse);
    now += const Duration(seconds: 1);
    expect(gate.shouldShow(level: 9), isTrue);
  });

  test('blocked for a minute after a rewarded ad', () {
    win(3);
    gate.rewardedShown();
    now += const Duration(seconds: 59);
    expect(gate.shouldShow(level: 6), isFalse);
    now += const Duration(seconds: 1);
    expect(gate.shouldShow(level: 6), isTrue);
  });

  test('the service shows an interstitial only when the gate allows', () async {
    final fake = _InterstitialGateway();
    final clock = Duration(minutes: 10);
    final ads = AdService(
      gateway: fake,
      supported: true,
      gate: InterstitialGate(clock: () => clock),
    );
    await ads.initialize();
    await Future<void>.delayed(Duration.zero);
    expect(fake.loads, 1);

    // gate closed: no show
    await ads.maybeShowInterstitial(level: 6);
    expect(fake.shows, 0);

    for (var i = 0; i < 3; i++) {
      ads.onLevelCompleted();
    }
    await ads.maybeShowInterstitial(level: 6);
    expect(fake.shows, 1);
    // counted again from zero and loading the next one
    await Future<void>.delayed(Duration.zero);
    expect(fake.loads, 2);
    await ads.maybeShowInterstitial(level: 7);
    expect(fake.shows, 1);
  });

  test('a failed show never throws and never delays', () async {
    final fake = _InterstitialGateway()..failShow = true;
    final ads = AdService(
      gateway: fake,
      supported: true,
      gate: InterstitialGate(clock: () => const Duration(minutes: 10)),
    );
    await ads.initialize();
    await Future<void>.delayed(Duration.zero);
    for (var i = 0; i < 3; i++) {
      ads.onLevelCompleted();
    }
    await ads.maybeShowInterstitial(level: 6);
    expect(fake.shows, 1);
  });

  test('unsupported platforms do nothing', () async {
    final fake = _InterstitialGateway();
    final ads = AdService(gateway: fake, supported: false);
    for (var i = 0; i < 3; i++) {
      ads.onLevelCompleted();
    }
    await ads.maybeShowInterstitial(level: 6);
    expect(fake.loads, 0);
    expect(fake.shows, 0);
    expect(ads.adsReady.value, isFalse);
  });
}

class _InterstitialGateway implements AdsGateway {
  int loads = 0;
  int shows = 0;
  bool failShow = false;

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
  Future<void> loadRewarded(String adUnitId) async {}

  @override
  Future<bool> showLoadedRewarded() async => true;

  @override
  Future<void> loadInterstitial(String adUnitId) async {
    loads++;
  }

  @override
  Future<void> showLoadedInterstitial() async {
    shows++;
    if (failShow) throw StateError('show failed');
  }
}
