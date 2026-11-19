import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_prefs.dart';

/// What [NotificationService] needs from Firebase Cloud Messaging.
/// Tests pass a fake.
abstract class NotificationBackend {
  /// Turns the FCM token on or off. Off also deletes the token, so the phone
  /// stops receiving messages.
  Future<void> setActive(bool on);

  /// Shows the Android 13+ permission dialog. True when notifications are
  /// allowed afterwards.
  Future<bool> requestPermission();
}

/// Push messages from the Firebase console (no app update needed to send a
/// new one: Firebase Console > Messaging > New campaign).
///
/// * Off until the player has been through the consent screen (the manifest
///   keeps FCM auto-init off).
/// * Off when the player switches Notifications off in Settings.
/// * The permission dialog appears once, after the player has finished a
///   couple of levels, never at launch.
/// * A Firebase error never reaches the game.
class NotificationService {
  NotificationService({NotificationBackend? backend, bool? supported})
    : _injected = backend,
      _supported = supported ?? _androidOnly;

  static final NotificationService instance = NotificationService();

  /// Levels the player must have finished before the permission dialog.
  static const levelsBeforeAsk = 2;

  static bool get _androidOnly =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final NotificationBackend? _injected;
  final bool _supported;
  NotificationBackend? _owned;
  NotificationBackend get _backend => _injected ?? (_owned ??= _FcmBackend());

  bool _consent = false;
  bool _switchOn = true;
  bool _active = false;

  /// True when this phone is registered for messages.
  bool get active => _active;

  /// Reads the saved Settings switch. Call once at launch.
  Future<void> load() async {
    _switchOn = await AppPrefs.flag('notifications');
  }

  /// The player's consent (UMP) allows it, or not.
  Future<void> setConsent(bool allowed) async {
    _consent = allowed;
    await _apply();
  }

  /// The Settings switch. Switching on asks for the permission if needed.
  Future<void> setSwitch(bool on) async {
    _switchOn = on;
    if (on && _supported) {
      await _guard(() async {
        await _backend.requestPermission();
        await AppPrefs.setFlag('notif_asked', true);
      });
    }
    await _apply();
  }

  /// Asks for the permission once, after [levelsBeforeAsk] finished levels.
  /// Returns true when the dialog was shown.
  Future<bool> maybeAskPermission({required int levelsDone}) async {
    if (!_supported || !_consent || !_switchOn) return false;
    if (levelsDone < levelsBeforeAsk) return false;
    if (await AppPrefs.flag('notif_asked', def: false)) return false;
    await AppPrefs.setFlag('notif_asked', true);
    await _guard(_backend.requestPermission);
    return true;
  }

  Future<void> _apply() async {
    if (!_supported) return;
    final want = _consent && _switchOn;
    if (_active == want) return;
    _active = want;
    await _guard(() => _backend.setActive(want));
  }

  Future<void> _guard(Future<void> Function() job) async {
    try {
      await job();
    } catch (error) {
      if (kDebugMode) debugPrint('Notifications: $error');
    }
  }
}

/// The real FCM. Created on first use.
class _FcmBackend implements NotificationBackend {
  Future<void> _firebase() async {
    // Safe to call again: it returns the app that is already running.
    await Firebase.initializeApp();
  }

  @override
  Future<void> setActive(bool on) async {
    await _firebase();
    final fcm = FirebaseMessaging.instance;
    await fcm.setAutoInitEnabled(on);
    // The token calls are marked deprecated in favour of register(), but they
    // are the proven path for Android and the Firebase console campaigns.
    if (on) {
      // ignore: deprecated_member_use
      await fcm.getToken(); // registers this phone
    } else {
      // ignore: deprecated_member_use
      await fcm.deleteToken();
    }
  }

  @override
  Future<bool> requestPermission() async {
    await _firebase();
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
