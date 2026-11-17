import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'app_prefs.dart';
import 'daily_reward.dart';

/// First level whose win may be followed by a review request.
const reviewMinLevel = 5;

/// Days between two automatic review requests.
const reviewGapDays = 30;

/// May the in-app review be requested now? Pure: [now] is passed in.
///
/// Only after a win of [reviewMinLevel] or later, at most once per
/// [reviewGapDays], and never when the phone clock looks wrong. The caller
/// asks only at a quiet moment (a win, never a failed level or the daily
/// challenge).
bool reviewAllowed({
  required int levelWon,
  required String? lastAskedDay,
  required int lastSeenMs,
  required DateTime now,
}) {
  if (levelWon < reviewMinLevel) return false;
  if (clockWentBack(lastSeenMs, now)) return false;
  final gap = calendarDaysAfter(lastAskedDay, now);
  if (gap == null) return true; // never asked
  return gap >= reviewGapDays;
}

/// What [ReviewPrompt] needs from the review plugin. Tests pass a fake.
abstract class ReviewGateway {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing();
}

class _PluginReviewGateway implements ReviewGateway {
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing() => InAppReview.instance.openStoreListing();
}

/// Asks the player to rate the game: once in a while by itself, or when the
/// player taps "Rate Rainbow Pour". No error ever reaches the game, and no
/// personal data is sent anywhere.
abstract final class ReviewPrompt {
  /// Replaced by tests.
  static ReviewGateway gateway = _PluginReviewGateway();

  /// Requests the review if [reviewAllowed] says yes. Returns true when a
  /// request was made (the day is then remembered).
  static Future<bool> maybeAsk({
    required int levelWon,
    DateTime? now,
    bool supported = !kIsWeb,
  }) async {
    if (!supported) return false;
    final time = now ?? DateTime.now();
    try {
      final allowed = reviewAllowed(
        levelWon: levelWon,
        lastAskedDay: await AppPrefs.reviewAskedDay(),
        lastSeenMs: await AppPrefs.lastSeenMs(),
        now: time,
      );
      if (!allowed) return false;
      if (!await gateway.isAvailable()) return false;
      await AppPrefs.markReviewAsked(time);
      await gateway.requestReview();
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Review: $error');
      return false;
    }
  }

  /// The player chose to rate (Settings, 4 or 5 stars). Ignores the 30-day
  /// rule. Falls back to the store page when the in-app sheet is not
  /// available. Returns true when something was shown.
  static Future<bool> rateNow({DateTime? now, bool supported = !kIsWeb}) async {
    if (!supported) return false;
    try {
      await AppPrefs.markReviewAsked(now ?? DateTime.now());
      if (await gateway.isAvailable()) {
        await gateway.requestReview();
      } else {
        await gateway.openStoreListing();
      }
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Review: $error');
      return false;
    }
  }
}
