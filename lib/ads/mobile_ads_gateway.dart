import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_gateway.dart';

/// Android (and other IO) builds. Web uses [mobile_ads_gateway_stub.dart].
AdsGateway createMobileAdsGateway() => PluginAdsGateway();

/// Google UMP plus Mobile Ads. Errors from the plugin propagate to [AdService].
class PluginAdsGateway implements AdsGateway {
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;

  @override
  Future<void> applyRequestConfiguration() {
    return MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        // Teen rating. Not child-directed and not a teen-treatment flag, so
        // personalised ads stay whatever UMP decided.
        maxAdContentRating: MaxAdContentRating.t,
        ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
      ),
    );
  }

  ConsentRequestParameters _params() {
    return ConsentRequestParameters(
      // The game is 13+. This is not an ads-personalisation override.
      tagForUnderAgeOfConsent: false,
      consentDebugSettings: _debugSettings(),
    );
  }

  /// Debug builds only. Both values stay empty so the real region is used.
  /// To force the EEA form on one phone, uncomment the block and put that
  /// phone's hashed device id in the list.
  ConsentDebugSettings? _debugSettings() {
    if (!kDebugMode) return null;
    // return ConsentDebugSettings(
    //   debugGeography: DebugGeography.debugGeographyEea,
    //   testIdentifiers: <String>['YOUR-TEST-DEVICE-HASHED-ID'],
    // );
    return null;
  }

  @override
  Future<void> requestConsentInfoUpdate() {
    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        _params(),
        () {
          if (!done.isCompleted) done.complete();
        },
        (FormError error) {
          if (!done.isCompleted) {
            done.completeError(
              StateError('UMP update ${error.errorCode}: ${error.message}'),
            );
          }
        },
      );
    } catch (error, stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    }
    return done.future;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() {
    final done = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (done.isCompleted) return;
      if (error != null) {
        done.completeError(
          StateError('UMP form ${error.errorCode}: ${error.message}'),
        );
      } else {
        done.complete();
      }
    }).catchError((Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }

  @override
  Future<bool> readCanRequestAds() =>
      ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> get privacyOptionsRequired async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<void> showPrivacyOptions() {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (done.isCompleted) return;
      if (error != null) {
        done.completeError(
          StateError('UMP privacy ${error.errorCode}: ${error.message}'),
        );
      } else {
        done.complete();
      }
    }).catchError((Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }

  @override
  Future<void> initializeMobileAds() {
    return MobileAds.instance.initialize();
  }

  @override
  Future<void> loadRewarded(String adUnitId) {
    final done = Completer<void>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded?.dispose();
          _rewarded = ad;
          if (!done.isCompleted) done.complete();
        },
        onAdFailedToLoad: (error) {
          if (!done.isCompleted) {
            done.completeError(
              StateError('rewarded load ${error.code}: ${error.message}'),
            );
          }
        },
      ),
    ).catchError((Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }

  @override
  Future<bool> showLoadedRewarded() {
    final ad = _rewarded;
    if (ad == null) throw StateError('rewarded ad is not loaded');
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        if (!done.isCompleted) {
          done.completeError(
            StateError('rewarded show ${error.code}: ${error.message}'),
          );
        }
      },
    );
    // Earned becomes true only inside this callback. A closed ad is not one.
    ad
        .show(
          onUserEarnedReward: (shown, reward) {
            earned = true;
          },
        )
        .catchError((Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        });
    return done.future;
  }

  @override
  Future<void> loadInterstitial(String adUnitId) {
    final done = Completer<void>();
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial?.dispose();
          _interstitial = ad;
          if (!done.isCompleted) done.complete();
        },
        onAdFailedToLoad: (error) {
          if (!done.isCompleted) {
            done.completeError(
              StateError('interstitial load ${error.code}: ${error.message}'),
            );
          }
        },
      ),
    ).catchError((Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }

  @override
  Future<void> showLoadedInterstitial() {
    final ad = _interstitial;
    if (ad == null) throw StateError('interstitial ad is not loaded');
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        if (!done.isCompleted) {
          done.completeError(
            StateError('interstitial show ${error.code}: ${error.message}'),
          );
        }
      },
    );
    ad.show().catchError((Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }
}
