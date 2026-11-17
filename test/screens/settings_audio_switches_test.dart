import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/audio_service.dart';
import 'package:rainbow_pour/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
    AudioService.instance.setSound(true);
    AudioService.instance.setMusic(true);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  bool value(WidgetTester tester, int index) =>
      tester.widget<Switch>(find.byType(Switch).at(index)).value;

  testWidgets('the Sound switch flips once, saves, and tells the service', (
    tester,
  ) async {
    await open(tester);
    expect(value(tester, 0), isTrue);
    await tester.tap(find.byType(Switch).at(0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value(tester, 0), isFalse, reason: 'must flip exactly once');
    expect(await AppPrefs.flag('sound'), isFalse);
    expect(AudioService.instance.soundOn, isFalse);

    await tester.tap(find.byType(Switch).at(0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value(tester, 0), isTrue);
    expect(await AppPrefs.flag('sound'), isTrue);
    expect(AudioService.instance.soundOn, isTrue);
  });

  testWidgets('the Music switch flips once, saves, and tells the service', (
    tester,
  ) async {
    await open(tester);
    expect(value(tester, 1), isTrue);
    await tester.tap(find.byType(Switch).at(1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value(tester, 1), isFalse, reason: 'must flip exactly once');
    expect(await AppPrefs.flag('music'), isFalse);
    expect(AudioService.instance.musicOn, isFalse);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value(tester, 1), isTrue);
    expect(await AppPrefs.flag('music'), isTrue);
    expect(AudioService.instance.musicOn, isTrue);
  });

  testWidgets('tapping the row (not the switch) also flips it once', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Music'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value(tester, 1), isFalse);
    expect(AudioService.instance.musicOn, isFalse);
    await tester.tap(find.text('Sound'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value(tester, 0), isFalse);
    expect(AudioService.instance.soundOn, isFalse);
  });

  testWidgets('saved off switches show as off when Settings opens', (
    tester,
  ) async {
    await AppPrefs.setFlag('sound', false);
    await AppPrefs.setFlag('music', false);
    AppPrefs.resetForTest();
    await open(tester);
    expect(value(tester, 0), isFalse);
    expect(value(tester, 1), isFalse);
  });
}
