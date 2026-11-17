import 'package:flutter/widgets.dart';

import '../core/app_prefs.dart';
import '../widgets/info_dialog.dart';
import '../analytics/analytics_service.dart';
import 'ad_service.dart';

/// One rewarded-ad tap: busy guard, daily gem cap, and the not-ready dialog.
///
/// [onReward] runs only for [RewardedResult.rewarded]. Closing the ad, a load
/// error and "not ready" grant nothing.
class RewardedFlow {
  const RewardedFlow._();

  static bool _busy = false;

  @visibleForTesting
  static void resetForTest() => _busy = false;

  static Future<RewardedResult> run(
    BuildContext context, {
    AdService? ads,
    bool gemCap = false,
    String placement = 'unknown',
    required Future<void> Function() onReward,
  }) async {
    if (_busy) return RewardedResult.dismissed;
    _busy = true;
    try {
      if (gemCap && await AppPrefs.adsToday() >= AppPrefs.gemAdDailyCap) {
        if (context.mounted) await InfoDialog.dailyLimit(context);
        return RewardedResult.notReady;
      }
      final result = await (ads ?? AdService.instance).showRewarded();
      AnalyticsService.instance.rewardedAd(placement, _label(result));
      // An earned reward is paid even if the player left the screen while the
      // ad was open: [onReward] must check `mounted` itself before touching UI.
      if (result == RewardedResult.rewarded) {
        await onReward();
        return result;
      }
      if (!context.mounted) return result;
      switch (result) {
        case RewardedResult.rewarded:
        case RewardedResult.dismissed:
          break;
        case RewardedResult.notReady:
        case RewardedResult.error:
          await InfoDialog.adNotReady(context);
      }
      return result;
    } finally {
      _busy = false;
    }
  }
}

String _label(RewardedResult r) => switch (r) {
  RewardedResult.rewarded => 'earned',
  RewardedResult.dismissed => 'closed',
  RewardedResult.notReady => 'not_ready',
  RewardedResult.error => 'error',
};
