import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/ads/ad_config.dart';

void main() {
  test('test mode returns the five Google sample ids', () {
    expect(AdConfig.useTestIds, isTrue);
    final ids = {
      'app': AdConfig.appId,
      'banner': AdConfig.bannerId,
      'interstitial': AdConfig.interstitialId,
      'rewarded': AdConfig.rewardedId,
      'native': AdConfig.nativeId,
    };
    expect(ids['app'], AdConfig.testAppId);
    expect(ids['banner'], AdConfig.testBannerId);
    expect(ids['interstitial'], AdConfig.testInterstitialId);
    expect(ids['rewarded'], AdConfig.testRewardedId);
    expect(ids['native'], AdConfig.testNativeId);
    final shape = RegExp(r'^ca-app-pub-\d+[~/]\d+$');
    for (final id in ids.values) {
      expect(id, isNotEmpty);
      expect(id, matches(shape));
    }
    expect(AdConfig.appId, contains('~'));
    expect(AdConfig.bannerId, contains('/'));
  });

  test('an empty real id never falls back to the test id', () {
    expect(
      () => AdConfig.resolve(
        useTestIds: false,
        testId: AdConfig.testBannerId,
        realId: '',
      ),
      throwsA(anyOf(isA<AssertionError>(), isA<StateError>())),
    );
    expect(
      AdConfig.resolve(
        useTestIds: false,
        testId: AdConfig.testBannerId,
        realId: 'ca-app-pub-1/2',
      ),
      'ca-app-pub-1/2',
    );
  });

  test('no other dart file hard-codes an ad id', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.endsWith('lib/ads/ad_config.dart')) continue;
      if (entity.readAsStringSync().contains('ca-app-pub-')) hits.add(path);
    }
    expect(hits, isEmpty);
  });
}
