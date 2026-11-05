/// Decides when a full-screen interstitial may appear. Pure Dart, in memory.
///
/// Rules: never in levels 1 to 3, only after every third completed level,
/// at least [minGap] after the previous interstitial, and not right after a
/// rewarded ad. The first one of a session can only come after three levels
/// completed in that session, so never at launch. The caller asks only at a
/// quiet moment (after a win, when the player moves on), never during play,
/// after a failed level or in the daily challenge.
class InterstitialGate {
  InterstitialGate({Duration Function()? clock}) {
    if (clock != null) {
      _now = clock;
    } else {
      final watch = Stopwatch()..start();
      _now = () => watch.elapsed;
    }
  }

  /// First level that may be followed by an interstitial.
  static const firstLevel = 4;

  /// Completed levels between two interstitials.
  static const levelsPerAd = 3;

  /// Least time between two interstitials.
  static const minGap = Duration(seconds: 90);

  /// Quiet time after a rewarded ad.
  static const afterRewardedGap = Duration(seconds: 60);

  late final Duration Function() _now;
  int _completed = 0;
  Duration? _lastShown;
  Duration? _lastRewarded;

  /// Count one campaign level the player has just won.
  void levelCompleted() => _completed++;

  /// A rewarded ad has just been shown.
  void rewardedShown() => _lastRewarded = _now();

  /// True if an interstitial may be shown now, for the campaign [level] the
  /// player has just completed.
  bool shouldShow({required int level}) {
    if (level < firstLevel) return false;
    if (_completed < levelsPerAd) return false;
    final now = _now();
    final shown = _lastShown;
    if (shown != null && now - shown < minGap) return false;
    final rewarded = _lastRewarded;
    if (rewarded != null && now - rewarded < afterRewardedGap) return false;
    return true;
  }

  /// An interstitial was shown: start the next gap and count again.
  void markShown() {
    _lastShown = _now();
    _completed = 0;
  }
}
