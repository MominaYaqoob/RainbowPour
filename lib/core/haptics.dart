import 'package:flutter/services.dart';

import 'app_prefs.dart';

/// Short vibrations, only when the Vibration switch in Settings is on.
abstract final class Haptics {
  static bool _on = true;

  static Future<void> load() async => _on = await AppPrefs.flag('vibration');

  static void enable(bool v) => _on = v;

  static void tap() {
    if (_on) HapticFeedback.selectionClick();
  }

  static void light() {
    if (_on) HapticFeedback.lightImpact();
  }

  static void success() {
    if (_on) HapticFeedback.mediumImpact();
  }

  static void fail() {
    if (_on) HapticFeedback.heavyImpact();
  }
}
