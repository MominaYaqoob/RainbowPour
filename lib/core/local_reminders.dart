import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'app_prefs.dart';
import 'daily_reward.dart';
import 'save_data.dart';

/// One reminder the phone will show by itself.
class Reminder {
  const Reminder(this.id, this.when, this.body);

  final int id;
  final DateTime when;
  final String body;

  @override
  String toString() => 'Reminder($id, $when, $body)';
}

/// Hour of the day (local time) the reminder appears.
const reminderHour = 10;

/// How many days ahead are scheduled. The list is built again every time the
/// player comes back to Home, so a player who stops playing gets at most this
/// many reminders and then silence.
const reminderDays = 7;

const _bothOpen =
    'Your daily reward and daily challenge are ready. Collect your gems!';
const _rewardOpen = 'Your daily reward is waiting. Come and collect your gems!';
const _challengeOpen = "Today's challenge is ready. Finish it for 30 gems!";

/// Which reminders to schedule, as a pure function of the save and the clock.
///
/// * Today (if [reminderHour] is still ahead): only for what is still open.
///   Nothing when the reward is claimed and the challenge is done.
/// * The next days: always, because nothing can be claimed ahead of time.
List<Reminder> planReminders(DailyState s, DateTime now) {
  final out = <Reminder>[];
  for (var i = 0; i < reminderDays; i++) {
    final when = DateTime(now.year, now.month, now.day + i, reminderHour);
    if (!when.isAfter(now)) continue;
    String body;
    if (i == 0) {
      final rewardOpen = dailyStatus(s, now).canClaim;
      final challengeOpen = !s.challengeDone.contains(dayKey(now));
      if (!rewardOpen && !challengeOpen) continue;
      body = rewardOpen && challengeOpen
          ? _bothOpen
          : (rewardOpen ? _rewardOpen : _challengeOpen);
    } else {
      body = const [_bothOpen, _rewardOpen, _challengeOpen][i % 3];
    }
    out.add(Reminder(i, when, body));
  }
  return out;
}

/// What [LocalReminders] needs from the phone. Tests pass a fake.
abstract class ReminderBackend {
  /// Cancels every reminder, then schedules [reminders].
  Future<void> replaceAll(List<Reminder> reminders);
}

/// "Daily reward / challenge" reminders that the game schedules on the phone
/// itself (no server, no internet).
///
/// Follows the Notifications switch in Settings, and the permission the
/// player gave. [refresh] is cheap: call it whenever Home shows.
class LocalReminders {
  LocalReminders({ReminderBackend? backend, bool? supported})
    : _injected = backend,
      _supported = supported ?? _androidOnly;

  static final LocalReminders instance = LocalReminders();

  static bool get _androidOnly =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final ReminderBackend? _injected;
  final bool _supported;
  ReminderBackend? _owned;
  ReminderBackend get _backend => _injected ?? (_owned ??= _PluginBackend());

  /// Schedules the next days again from the current save (or cancels all when
  /// the Notifications switch is off). Never throws.
  Future<void> refresh({DateTime? now}) async {
    if (!_supported) return;
    try {
      final on = await AppPrefs.flag('notifications');
      if (!on) {
        await _backend.replaceAll(const []);
        return;
      }
      final state = await AppPrefs.daily();
      await _backend.replaceAll(planReminders(state, now ?? DateTime.now()));
    } catch (error) {
      if (kDebugMode) debugPrint('Reminders: $error');
    }
  }
}

class _PluginBackend implements ReminderBackend {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    _ready = true;
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminders',
        'Daily reminders',
        channelDescription: 'Daily reward and daily challenge reminders',
        icon: 'ic_notification',
        color: Color(0xFFFFC107),
      ),
    );
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        r.id,
        'Rainbow Pour',
        r.body,
        // An exact moment in time, so no time zone database is needed.
        tz.TZDateTime.from(r.when, tz.UTC),
        details,
        // Inexact: no special "exact alarm" permission, a few minutes late
        // at most.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
