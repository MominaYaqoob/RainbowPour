import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// What [AnalyticsService] needs from Firebase. Tests pass a fake.
abstract class AnalyticsBackend {
  Future<void> init();
  Future<void> setCollectionEnabled(bool on);
  Future<void> logEvent(String name, Map<String, Object> params);
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal});
}

/// Game events for Firebase Analytics, and crash reports for Crashlytics.
///
/// * Nothing is collected until [setConsent] says yes (the manifest keeps
///   collection off at start). With no consent, or before [init], every call
///   is a silent no-op, so tests and the web build stay quiet.
/// * A Firebase error never reaches the game.
/// * Event names follow Firebase's recommended ones where one exists
///   (`level_start`, `level_end`, `spend_virtual_currency`,
///   `earn_virtual_currency`), so the standard reports work.
class AnalyticsService {
  AnalyticsService({AnalyticsBackend? backend, bool? supported})
    : _injected = backend,
      _supported = supported ?? _androidOnly;

  static final AnalyticsService instance = AnalyticsService();

  static bool get _androidOnly =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final AnalyticsBackend? _injected;
  final bool _supported;
  AnalyticsBackend? _owned;
  AnalyticsBackend get _backend => _injected ?? (_owned ??= _FirebaseBackend());

  bool _ready = false;
  bool _enabled = false;
  bool _wantedBeforeReady = false;

  /// True when events are being sent.
  bool get collecting => _ready && _enabled;

  /// Starts Firebase. Call once at launch; safe to call again.
  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      await _backend.init();
      _ready = true;
      // consent may have arrived while Firebase was still starting
      if (_wantedBeforeReady) await _apply(true);
    } catch (error) {
      _log(error);
    }
  }

  /// The player's consent (UMP) allows analytics and crash reports, or not.
  Future<void> setConsent(bool allowed) async {
    if (!_supported) return;
    if (!_ready) {
      _wantedBeforeReady = allowed;
      return;
    }
    await _apply(allowed);
  }

  Future<void> _apply(bool allowed) async {
    _enabled = allowed;
    try {
      await _backend.setCollectionEnabled(allowed);
    } catch (error) {
      _log(error);
    }
  }

  /// Sends one event. Dropped (not queued) while collection is off.
  void log(String name, [Map<String, Object> params = const {}]) {
    if (!collecting) return;
    unawaited(
      Future<void>.sync(() => _backend.logEvent(name, params)).catchError(_log),
    );
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (!collecting) return;
    try {
      await _backend.recordError(error, stack, fatal: fatal);
    } catch (e) {
      _log(e);
    }
  }

  // ---- levels (where players go, and where they stop)

  void levelStart(int level) => log('level_start', {'level_name': '$level'});

  void levelEnd(int level, {required bool success, int? stars, int? moves}) =>
      log('level_end', {
        'level_name': '$level',
        'success': success ? 1 : 0,
        'level': level,
        'stars': ?stars,
        'moves': ?moves,
      });

  /// The board has no useful move left.
  void levelStuck(int level, {int? moves}) =>
      log('level_stuck', {'level': level, 'moves': ?moves});

  /// The player left a level without finishing it.
  void levelQuit(int level, {required int moves}) =>
      log('level_quit', {'level': level, 'moves': moves});

  // ---- daily challenge

  void challengeStart() => log('challenge_start');

  /// [result] is `win`, `time_up` or `quit`.
  void challengeEnd(String result, {int? secondsLeft}) =>
      log('challenge_end', {'result': result, 'seconds_left': ?secondsLeft});

  // ---- gems (what they buy)

  void gemSpend(String item, int amount) => log('spend_virtual_currency', {
    'virtual_currency_name': 'gems',
    'item_name': item,
    'value': amount,
  });

  void gemEarn(String source, int amount) => log('earn_virtual_currency', {
    'virtual_currency_name': 'gems',
    'source': source,
    'value': amount,
  });

  /// A shop purchase (a bottle skin or a background).
  void shopBuy(String item, int cost) {
    log('shop_buy', {'item': item, 'cost': cost});
    gemSpend(item, cost);
  }

  // ---- ads and daily reward

  /// [result] is `earned`, `closed`, `not_ready` or `error`.
  void rewardedAd(String placement, String result) =>
      log('ad_rewarded', {'placement': placement, 'result': result});

  /// Ad revenue for one shown ad (AdMob's paid event). [valueMicros] is
  /// millionths of [currency]. Firebase uses the name `ad_impression` for ROAS.
  void adImpression({
    required String format,
    required String unit,
    required double valueMicros,
    required String currency,
  }) => log('ad_impression', {
    'value': valueMicros / 1000000,
    'currency': currency,
    'ad_format': format,
    'ad_unit_name': unit,
    'ad_platform': 'AdMob',
  });

  void interstitialShown(int level) => log('ad_interstitial', {'level': level});

  void dailyRewardClaim(int gems) => log('daily_reward_claim', {'gems': gems});

  void _log(Object error, [StackTrace? stack]) {
    if (kDebugMode) debugPrint('Analytics: $error');
  }
}

/// The real Firebase. Crash reports are sent from release builds only.
class _FirebaseBackend implements AnalyticsBackend {
  @override
  Future<void> init() async {
    await Firebase.initializeApp();
  }

  @override
  Future<void> setCollectionEnabled(bool on) async {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(on);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      on && !kDebugMode,
    );
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> params) =>
      FirebaseAnalytics.instance.logEvent(name: name, parameters: params);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (kDebugMode) return;
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }
}
