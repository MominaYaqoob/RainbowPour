import 'package:flutter/foundation.dart';

import 'app_prefs.dart';

/// The Colorblind mode switch: symbols drawn on the liquid. A notifier (like
/// the bottle skin) so a change in Settings reaches every bottle at once.
abstract final class ColorblindMode {
  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  static Future<void> load() async {
    enabled.value = await AppPrefs.flag('colorblind', def: false);
  }

  /// Applies the switch now; [AppPrefs] keeps the saved value.
  static void set(bool on) => enabled.value = on;
}
