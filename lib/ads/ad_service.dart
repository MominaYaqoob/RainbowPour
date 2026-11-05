import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_config.dart';
import 'ads_gateway.dart';
import 'gateway_loader.dart';
import 'interstitial_gate.dart';

/// What happened when the player was offered a rewarded ad.
enum RewardedResult { rewarded, notReady, dismissed, error }

/// UMP consent, then one Mobile Ads start, then one preloaded rewarded ad.
///
/// Safe to call many times: calls that overlap share one future, and the SDK
/// starts at most once. Web and every platform other than Android do nothing.
class AdService {
  AdService({
    AdsGateway? gateway,
    bool? supported,
    Duration? readyWait,
    InterstitialGate? gate,
  }) : _injected = gateway,
       _supported = supported ?? _androidOnly,
       _readyWait = readyWait ?? rewardedReadyWait,
       gate = gate ?? InterstitialGate();

  static final AdService instance = AdService();

  /// How long the consent screen waits for UMP before it moves on.
  static const consentInitializeTimeout = Duration(seconds: 30);

  /// How long a tap waits for a rewarded ad that is still loading.
  static const rewardedReadyWait = Duration(seconds: 1);

  static bool get _androidOnly =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final AdsGateway? _injected;

  /// Rules for when an interstitial may appear.
  final InterstitialGate gate;

  /// True once ads may be requested (consent done). Banner and native widgets
  /// listen to this so they load as soon as it turns on.
  final ValueNotifier<bool> adsReady = ValueNotifier(false);
  final bool _supported;
  final Duration _readyWait;

  AdsGateway? _owned;
  Future<void>? _inFlight;
  Future<void>? _loading;
  bool _sdkStarted = false;
  bool _canRequestAds = false;
  bool _rewardedReady = false;
  bool _showingRewarded = false;
  bool _interstitialReady = false;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;

  bool get canRequestAds => _supported && _canRequestAds;

  AdsGateway get _gateway => _injected ?? (_owned ??= loadAdsGateway());

  /// Runs UMP, then [MobileAds.initialize] only when ads may be requested.
  Future<void> initialize() {
    final current = _inFlight;
    if (current != null) return current;
    final run = _initialize();
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  Future<void> _initialize() async {
    if (!_supported) return;
    try {
      final gateway = _gateway;
      await gateway.requestConsentInfoUpdate();
      await gateway.loadAndShowConsentFormIfRequired();
      final allowed = await gateway.readCanRequestAds();
      _canRequestAds = allowed;
      if (!allowed || _sdkStarted) return;
      await gateway.applyRequestConfiguration();
      await gateway.initializeMobileAds();
      _sdkStarted = true;
      adsReady.value = true;
      _preloadRewarded();
      _preloadInterstitial();
    } catch (error, stack) {
      _log(error, stack);
    }
  }

  Future<bool> get privacyOptionsRequired async {
    if (!_supported) return false;
    try {
      return await _gateway.privacyOptionsRequired;
    } catch (error, stack) {
      _log(error, stack);
      return false;
    }
  }

  /// Shows the preloaded rewarded ad. A reward is reported only when the
  /// user-earned callback runs. Closing early is [RewardedResult.dismissed].
  Future<RewardedResult> showRewarded() async {
    if (!_supported || !_canRequestAds || _showingRewarded) {
      return RewardedResult.notReady;
    }
    if (!_rewardedReady) {
      _preloadRewarded();
      final pending = _loading;
      if (pending != null) {
        try {
          await pending.timeout(_readyWait);
        } on TimeoutException {
          // The load keeps going. This tap does not wait any longer.
        }
      }
    }
    if (!_rewardedReady || _showingRewarded) return RewardedResult.notReady;
    _showingRewarded = true;
    _rewardedReady = false;
    try {
      final earned = await _gateway.showLoadedRewarded();
      gate.rewardedShown();
      return earned ? RewardedResult.rewarded : RewardedResult.dismissed;
    } catch (error, stack) {
      _log(error, stack);
      return RewardedResult.error;
    } finally {
      _showingRewarded = false;
      _preloadRewarded();
    }
  }

  void _preloadRewarded() {
    if (!_supported || !_canRequestAds || _rewardedReady || _loading != null) {
      return;
    }
    final run = _loadRewarded();
    _loading = run;
    run.whenComplete(() {
      if (identical(_loading, run)) _loading = null;
    });
  }

  Future<void> _loadRewarded() async {
    try {
      await _gateway.loadRewarded(AdConfig.rewardedId);
      if (!_showingRewarded) _rewardedReady = true;
    } catch (error, stack) {
      _rewardedReady = false;
      _log(error, stack);
    }
  }

  /// Counts a campaign level the player just won (for the interstitial rule).
  void onLevelCompleted() => gate.levelCompleted();

  /// Shows an interstitial if the gate allows it and one is ready; completes
  /// when it is closed. Returns at once (no delay) when there is nothing to
  /// show or it fails. Call it only when the player moves on after a win.
  Future<void> maybeShowInterstitial({required int level}) async {
    if (!_supported || !_canRequestAds || _showingInterstitial) return;
    if (_showingRewarded || !gate.shouldShow(level: level)) return;
    if (!_interstitialReady) {
      _preloadInterstitial();
      return;
    }
    _showingInterstitial = true;
    _interstitialReady = false;
    try {
      gate.markShown();
      await _gateway.showLoadedInterstitial();
    } catch (error, stack) {
      _log(error, stack);
    } finally {
      _showingInterstitial = false;
      _preloadInterstitial();
    }
  }

  void _preloadInterstitial() {
    if (!_supported ||
        !_canRequestAds ||
        _interstitialReady ||
        _loadingInterstitial) {
      return;
    }
    _loadingInterstitial = true;
    _gateway
        .loadInterstitial(AdConfig.interstitialId)
        .then((_) => _interstitialReady = true)
        .catchError((Object error, StackTrace stack) {
          _interstitialReady = false;
          _log(error, stack);
          return false;
        })
        .whenComplete(() => _loadingInterstitial = false);
  }

  Future<void> showPrivacyOptions() async {
    if (!_supported) return;
    try {
      await _gateway.showPrivacyOptions();
    } catch (error, stack) {
      _log(error, stack);
    }
  }

  void _log(Object error, StackTrace stack) {
    if (kDebugMode) debugPrint('AdService: $error\n$stack');
  }
}
