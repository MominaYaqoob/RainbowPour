/// The AdMob and UMP calls [AdService] needs. Tests pass a fake.
abstract class AdsGateway {
  /// Age rating for every later ad request. Does not load an ad.
  Future<void> applyRequestConfiguration();

  Future<void> requestConsentInfoUpdate();

  Future<void> loadAndShowConsentFormIfRequired();

  Future<bool> readCanRequestAds();

  Future<bool> get privacyOptionsRequired;

  Future<void> showPrivacyOptions();

  Future<void> initializeMobileAds();

  /// Loads one rewarded ad. Completes when it is ready, or throws.
  Future<void> loadRewarded(String adUnitId);

  /// Shows the ad from [loadRewarded]. True only if the user-earned callback
  /// ran. False means the ad closed with no reward. Throws if it cannot show.
  Future<bool> showLoadedRewarded();

  /// Loads one interstitial ad. Completes when it is ready, or throws.
  Future<void> loadInterstitial(String adUnitId);

  /// Shows the ad from [loadInterstitial]. Completes when it is closed.
  /// Throws if it cannot show.
  Future<void> showLoadedInterstitial();
}
