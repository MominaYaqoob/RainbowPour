import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePlayer implements SoundPlayer {
  final List<String> sfx = [];
  final List<String> log = [];
  bool throwOnPlay = false;

  @override
  Future<void> playSfx(String asset) async {
    if (throwOnPlay) throw StateError('engine blocked');
    sfx.add(asset);
  }

  @override
  Future<void> startMusic(String asset, double volume) async {
    if (throwOnPlay) throw StateError('engine blocked');
    log.add('start');
  }

  @override
  Future<void> pauseMusic() async => log.add('pause');

  @override
  Future<void> resumeMusic() async => log.add('resume');

  @override
  Future<void> stopMusic() async => log.add('stop');
}

Future<AudioService> make(
  FakePlayer player, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({});
  AppPrefs.resetForTest();
  for (final e in prefs.entries) {
    await AppPrefs.setFlag(e.key, e.value as bool);
  }
  final service = AudioService(player: player);
  await service.load(observeLifecycle: false);
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nothing plays before load', () async {
    final player = FakePlayer();
    final service = AudioService(player: player);
    service.play(Sfx.tap);
    service.startMusic();
    await Future<void>.delayed(Duration.zero);
    expect(player.sfx, isEmpty);
    expect(player.log, isEmpty);
  });

  test('sound on plays the matching file, sound off is silent', () async {
    final player = FakePlayer();
    final service = await make(player);
    service.play(Sfx.pour);
    service.play(Sfx.win);
    await Future<void>.delayed(Duration.zero);
    expect(player.sfx, [AudioAssets.pour, AudioAssets.win]);

    service.setSound(false);
    service.play(Sfx.tap);
    await Future<void>.delayed(Duration.zero);
    expect(player.sfx.length, 2);

    service.setSound(true);
    service.play(Sfx.tap);
    await Future<void>.delayed(Duration.zero);
    expect(player.sfx.last, AudioAssets.tap);
  });

  test('saved switches are read at load', () async {
    final player = FakePlayer();
    final service = await make(player, prefs: {'sound': false, 'music': false});
    expect(service.soundOn, isFalse);
    expect(service.musicOn, isFalse);
    service.play(Sfx.tap);
    service.startMusic();
    await Future<void>.delayed(Duration.zero);
    expect(player.sfx, isEmpty);
    expect(player.log, isEmpty);
  });

  test('music off is never started; turning it on starts it at once', () async {
    final player = FakePlayer();
    final service = await make(player, prefs: {'music': false});
    service.startMusic();
    await Future<void>.delayed(Duration.zero);
    expect(player.log, isEmpty);

    service.setMusic(true);
    await Future<void>.delayed(Duration.zero);
    expect(player.log, ['start']);

    service.setMusic(false);
    await Future<void>.delayed(Duration.zero);
    expect(player.log, ['start', 'stop']);
  });

  test('starting music twice starts the player once', () async {
    final player = FakePlayer();
    final service = await make(player);
    service.startMusic();
    service.startMusic();
    await Future<void>.delayed(Duration.zero);
    expect(player.log, ['start']);
  });

  test('the background pauses music and the return resumes it', () async {
    final player = FakePlayer();
    final service = await make(player);
    service.startMusic();
    await Future<void>.delayed(Duration.zero);

    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(player.log, ['start', 'pause']);

    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(player.log, ['start', 'pause', 'resume']);
  });

  test('lifecycle changes do nothing when music is off', () async {
    final player = FakePlayer();
    final service = await make(player, prefs: {'music': false});
    service.startMusic();
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(player.log, isEmpty);
  });

  test('music is not started while the app is in the background', () async {
    final player = FakePlayer();
    final service = await make(player);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    service.startMusic();
    await Future<void>.delayed(Duration.zero);
    expect(player.log, isEmpty);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(player.log, ['start']);
  });

  test('a player that throws never throws out of the service', () async {
    final player = FakePlayer()..throwOnPlay = true;
    final service = await make(player);
    service.play(Sfx.tap);
    service.startMusic();
    await Future<void>.delayed(Duration.zero);
    expect(player.sfx, isEmpty);
  });

  test('every audio asset exists on disk and is listed in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/audio/'));
    for (final asset in AudioAssets.all) {
      final file = File('assets/$asset');
      expect(file.existsSync(), isTrue, reason: '$asset is missing');
      expect(file.lengthSync(), greaterThan(44), reason: '$asset is empty');
    }
    for (final sfx in Sfx.values) {
      expect(AudioAssets.all, contains(AudioAssets.of(sfx)));
    }
  });
}
