import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/game/level_repository.dart';
import 'package:rainbow_pour/screens/game/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  testWidgets('the countdown reaches time up and retry restores it', (
    tester,
  ) async {
    var ms = 0;
    final day = DateTime(2026, 6, 18);
    // The widget test zone does not finish an isolate the widget starts, so
    // the board is built first and then served from the cache.
    await tester.runAsync(() => LevelRepository.getChallenge(day));
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen.challenge(
          day: day,
          challengeSeconds: 2,
          elapsed: () => Duration(milliseconds: ms),
        ),
      ),
    );
    // The playable board, and the countdown, wait out the loading pause.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('0:02'), findsOneWidget);
    expect(find.text("Time's up"), findsNothing);

    ms = 2000;
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text("Time's up"), findsWidgets);

    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('0:02'), findsOneWidget);
    expect(find.text("Time's up"), findsNothing);
  });
}
