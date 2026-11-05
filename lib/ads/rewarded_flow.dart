import 'package:flutter/widgets.dart';

import '../core/app_prefs.dart';
import '../widgets/info_dialog.dart';
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
