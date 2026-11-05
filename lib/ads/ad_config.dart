/// Every AdMob id used by the app. Nowhere else may hard-code an id.
///
/// [useTestIds] stays true until the owner supplies real ids. The Android
/// manifest `APPLICATION_ID` must be the same app id, because the SDK reads
/// it before Dart starts. Replace that value at the same time.
class AdConfig {
  const AdConfig._();

  static const useTestIds = true;

  static const testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testBannerId = 'ca-app-pub-3940256099942544/9214589741';
  static const testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const testNativeId = 'ca-app-pub-3940256099942544/2247696110';

  /// Real ids from the owner's AdMob account. Empty until release.
  static const realAppId = '';
  static const realBannerId = '';
  static const realInterstitialId = '';
  static const realRewardedId = '';
  static const realNativeId = '';

  static String get appId => resolve(testId: testAppId, realId: realAppId);

  static String get bannerId =>
      resolve(testId: testBannerId, realId: realBannerId);

  static String get interstitialId =>
      resolve(testId: testInterstitialId, realId: realInterstitialId);

  static String get rewardedId =>
      resolve(testId: testRewardedId, realId: realRewardedId);

  static String get nativeId =>
      resolve(testId: testNativeId, realId: realNativeId);

  /// Picks the test or the real id. An empty real id never falls back to a
  /// test id: debug builds fail the assert, and release builds throw.
  static String resolve({
    required String testId,
    required String realId,
    bool? useTestIds,
  }) {
    if (useTestIds ?? AdConfig.useTestIds) return testId;
    if (realId.isEmpty) {
      const message =
          'AdConfig: real ad id is empty and useTestIds is false. '
          'Refusing to use a test id.';
      assert(false, message);
      throw StateError(message);
    }
    return realId;
  }
}
