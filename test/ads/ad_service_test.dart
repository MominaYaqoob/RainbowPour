import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/ads/ad_service.dart';
import 'package:rainbow_pour/ads/ads_gateway.dart';

void main() {
  test('MobileAds stays down until consent allows ads', () async {
    final fake = _FakeGateway();
    final ads = AdService(gateway: fake, supported: true);

    await ads.initialize();
    expect(ads.canRequestAds, isFalse);
    expect(fake.sdkInits, 0);
    expect(fake.configs, 0);

    fake.allowed = true;
    fake.hold = true;
    final first = ads.initialize();
    final second = ads.initialize();
    final third = ads.initialize();
    fake.release();
    await Future.wait([first, second, third]);

    expect(fake.sdkInits, 1);
    expect(fake.configs, 1);
    expect(fake.updates, 2);
    expect(ads.canRequestAds, isTrue);

    await ads.initialize();
    expect(fake.sdkInits, 1);
  });

  test('a failed consent update leaves ads blocked', () async {
    final fake = _FakeGateway()
      ..allowed = true
      ..failUpdate = true;
    final ads = AdService(gateway: fake, supported: true);

    await expectLater(ads.initialize(), completes);
    expect(ads.canRequestAds, isFalse);
    expect(fake.sdkInits, 0);
    expect(fake.forms, 0);
  });

  test('web and non-Android do nothing', () async {
    final fake = _FakeGateway()..allowed = true;
    final ads = AdService(gateway: fake, supported: false);

    await ads.initialize();
    expect(fake.updates, 0);
    expect(fake.forms, 0);
    expect(fake.sdkInits, 0);
    expect(ads.canRequestAds, isFalse);
    expect(await ads.privacyOptionsRequired, isFalse);
    await ads.showPrivacyOptions();
    expect(fake.privacyShows, 0);
  });
}

class _FakeGateway implements AdsGateway {
  bool allowed = false;
  bool failUpdate = false;
  bool hold = false;
  int updates = 0;
  int forms = 0;
  int configs = 0;
  int sdkInits = 0;
  int privacyShows = 0;

  Completer<void>? _paused;

  void release() {
    hold = false;
    final paused = _paused;
    if (paused != null && !paused.isCompleted) paused.complete();
  }

  @override
  Future<void> applyRequestConfiguration() async {
    configs++;
  }

  @override
  Future<void> requestConsentInfoUpdate() async {
    updates++;
    if (hold) {
      final paused = _paused ??= Completer<void>();
      await paused.future;
    }
    if (failUpdate) throw StateError('consent update failed');
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() async {
    forms++;
  }

  @override
  Future<bool> readCanRequestAds() async => allowed;

  @override
  Future<bool> get privacyOptionsRequired async => false;

  @override
  Future<void> showPrivacyOptions() async {
    privacyShows++;
  }

  @override
  Future<void> initializeMobileAds() async {
    sdkInits++;
  }

  @override
  Future<void> loadRewarded(String adUnitId) async {}

  @override
  Future<bool> showLoadedRewarded() async => false;

  @override
  Future<void> loadInterstitial(String adUnitId) async {}

  @override
  Future<void> showLoadedInterstitial() async {}
}
