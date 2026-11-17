import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'app_prefs.dart';

/// The sound effects of the game.
enum Sfx { tap, select, pour, bottleFull, win, fail }

/// Asset paths (relative to the `assets/` folder). The files in
/// `assets/audio/` are silent placeholders until real ones are supplied.
abstract final class AudioAssets {
  static const tap = 'audio/tap.wav';
  static const select = 'audio/select.wav';
  static const pour = 'audio/pour.wav';
  static const bottleFull = 'audio/bottle_full.wav';
  static const win = 'audio/win.wav';
  static const fail = 'audio/fail.wav';
  static const music = 'audio/music_loop.wav';

  static String of(Sfx sfx) => switch (sfx) {
    Sfx.tap => tap,
    Sfx.select => select,
    Sfx.pour => pour,
    Sfx.bottleFull => bottleFull,
    Sfx.win => win,
    Sfx.fail => fail,
  };

  static const all = [tap, select, pour, bottleFull, win, fail, music];
}

/// What [AudioService] needs from a sound engine. Tests pass a fake.
abstract class SoundPlayer {
  Future<void> playSfx(String asset);
  Future<void> startMusic(String asset, double volume);
  Future<void> pauseMusic();
  Future<void> resumeMusic();
  Future<void> stopMusic();
}

/// Sound effects and background music, following the Sound and Music
/// switches in Settings.
///
/// Nothing plays until [load] has run (so widget tests stay silent), and no
/// player error ever reaches the caller: a missing file or a blocked audio
/// engine just means silence.
class AudioService with WidgetsBindingObserver {
  AudioService({SoundPlayer? player}) : _injected = player;

  static final AudioService instance = AudioService();

  /// Music volume: low, so it never drowns the effects.
  static const musicVolume = 0.4;

  final SoundPlayer? _injected;
  SoundPlayer? _owned;
  SoundPlayer get _player => _injected ?? (_owned ??= _PluginPlayer());

  bool _loaded = false;
  bool _sound = true;
  bool _music = true;

  /// The game wants music (Home was shown), whatever the switch says.
  bool _musicWanted = false;
  bool _musicPlaying = false;
  bool _musicPaused = false;
  bool _inBackground = false;

  bool get soundOn => _sound;
  bool get musicOn => _music;

  /// Reads the two switches and starts watching the app lifecycle.
  Future<void> load({bool observeLifecycle = true}) async {
    _sound = await AppPrefs.flag('sound');
    _music = await AppPrefs.flag('music');
    if (!_loaded && observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
    _loaded = true;
    _log('load: sound=$_sound music=$_music');
    _syncMusic();
  }

  /// Sound switch changed in Settings. Applies at once.
  void setSound(bool on) => _sound = on;

  /// Music switch changed in Settings. Starts or stops the music at once.
  void setMusic(bool on) {
    _music = on;
    _syncMusic();
  }

  /// Plays one effect. Fire and forget; silent when Sound is off.
  void play(Sfx sfx) {
    _log('sfx $sfx: loaded=$_loaded sound=$_sound');
    if (!_loaded || !_sound) return;
    _guard(() => _player.playSfx(AudioAssets.of(sfx)));
  }

  /// The game wants background music (called when Home first shows).
  void startMusic() {
    _musicWanted = true;
    _syncMusic();
  }

  void stopMusic() {
    _musicWanted = false;
    _syncMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final away = state != AppLifecycleState.resumed;
    if (away == _inBackground) return;
    _inBackground = away;
    _syncMusic();
  }

  /// Brings the player in line with: wanted, switch on, app in front.
  void _syncMusic() {
    if (!_loaded) return;
    final shouldPlay = _musicWanted && _music && !_inBackground;
    _log(
      'music sync: wanted=$_musicWanted on=$_music '
      'background=$_inBackground playing=$_musicPlaying',
    );
    if (shouldPlay) {
      if (!_musicPlaying) {
        _musicPlaying = true;
        _musicPaused = false;
        _guard(() => _player.startMusic(AudioAssets.music, musicVolume));
      } else if (_musicPaused) {
        _musicPaused = false;
        _guard(() => _player.resumeMusic());
      }
      return;
    }
    if (!_musicPlaying) return;
    if (_musicWanted && _music) {
      // only the app went to the background: keep the position
      if (!_musicPaused) {
        _musicPaused = true;
        _guard(() => _player.pauseMusic());
      }
    } else {
      _musicPlaying = false;
      _musicPaused = false;
      _guard(() => _player.stopMusic());
    }
  }

  int _logged = 0;

  /// A few lines about what the service decides, also in release builds, so
  /// "no sound on the phone" can be diagnosed from the log. Capped.
  void _log(String message) {
    if (_logged >= 40) return;
    _logged++;
    debugPrint('Audio: $message');
  }

  void _guard(Future<void> Function() job) {
    unawaited(
      Future<void>.sync(job).catchError((Object error) {
        // Always logged (also in release): a silent failure here once meant
        // "no sound at all" on phones and was impossible to see.
        debugPrint('Audio error: $error');
      }),
    );
  }
}

/// The real engine (audioplayers): a small pool for overlapping effects and
/// one looping music player. Created on first use.
class _PluginPlayer implements SoundPlayer {
  static const _poolSize = 4;

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _music;
  bool _contextSet = false;

  Future<void> _setContext() async {
    if (_contextSet) return;
    _contextSet = true;
    // Mix with the player's own music app instead of stopping it.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
  }

  @override
  Future<void> playSfx(String asset) async {
    await _setContext();
    if (_pool.isEmpty) {
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
    }
    final p = _pool[_next++ % _poolSize];
    await p.play(AssetSource(asset));
  }

  @override
  Future<void> startMusic(String asset, double volume) async {
    await _setContext();
    final p = _music ??= AudioPlayer();
    await p.setReleaseMode(ReleaseMode.loop);
    await p.setVolume(volume);
    await p.play(AssetSource(asset));
  }

  @override
  Future<void> pauseMusic() async => _music?.pause();

  @override
  Future<void> resumeMusic() async => _music?.resume();

  @override
  Future<void> stopMusic() async => _music?.stop();
}
