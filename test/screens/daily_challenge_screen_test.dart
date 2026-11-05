import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_colors.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/daily_reward.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:rainbow_pour/screens/challenge/daily_challenge_screen.dart';
import 'package:rainbow_pour/screens/game/game_screen.dart';
import 'package:rainbow_pour/widgets/water_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  testWidgets('a fresh save can play today', (tester) async {
    final today = DateTime(2026, 6, 18, 10);
    await tester.pumpWidget(
      MaterialApp(home: DailyChallengeScreen(clock: () => today)),
    );
    await until(tester, find.text('Play'));
    expect(find.text('0-day streak'), findsOneWidget);
    expect(find.text('0 of 7 days this week'), findsOneWidget);
    expect(find.text('30'), findsWidgets);
    expect(find.text('Weekly bonus: 40 gems'), findsOneWidget);
    expect(find.text('50'), findsNothing);
    expect(find.textContaining('150'), findsNothing);
    expect(playButton(tester).dim, isFalse);
    expect(
      tester
          .widgetList<Text>(find.text('18'))
          .where((text) => text.style?.color == AppColors.gold),
      isNotEmpty,
    );
    expect(find.byIcon(Icons.close_rounded), findsWidgets);
  });

  testWidgets('three finished days show the streak and the week bar', (
    tester,
  ) async {
    final today = DateTime(2026, 6, 18, 10);
    final data = SaveData();
    for (final day in [15, 16, 17]) {
      data.daily.challengeDone.add(dayKey(DateTime(2026, 6, day)));
    }
    data.daily.challengeStreak = 3;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefs.saveKey, data.encode());
    AppPrefs.resetForTest();

    await tester.pumpWidget(
      MaterialApp(home: DailyChallengeScreen(clock: () => today)),
    );
    await until(tester, find.text('3-day streak'));
    expect(find.text('3 of 7 days this week'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('today done disables play', (tester) async {
    final today = DateTime(2026, 6, 18, 10);
    final data = SaveData();
    data.daily.challengeDone.add(dayKey(today));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefs.saveKey, data.encode());
    AppPrefs.resetForTest();

    await tester.pumpWidget(
      MaterialApp(home: DailyChallengeScreen(clock: () => today)),
    );
    await until(tester, find.text('Done for today'));
    expect(playButton(tester).dim, isTrue);
    await tester.tap(find.text('Done for today'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('a finished week shows 7 of 7', (tester) async {
    final today = DateTime(2026, 6, 21, 10);
    final data = SaveData();
    for (var day = 15; day <= 21; day++) {
      data.daily.challengeDone.add(dayKey(DateTime(2026, 6, day)));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefs.saveKey, data.encode());
    AppPrefs.resetForTest();

    await tester.pumpWidget(
      MaterialApp(home: DailyChallengeScreen(clock: () => today)),
    );
    await until(tester, find.text('7 of 7 days this week'));
    expect(find.text('7-day streak'), findsOneWidget);
  });

  testWidgets('a backwards clock shows the dialog instead of playing', (
    tester,
  ) async {
    final today = DateTime(2026, 6, 18, 10);
    final data = SaveData();
    data.daily.lastSeenMs = today
        .add(const Duration(hours: 3))
        .millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefs.saveKey, data.encode());
    AppPrefs.resetForTest();

    await tester.pumpWidget(
      MaterialApp(home: DailyChallengeScreen(clock: () => today)),
    );
    await until(tester, find.text('Play'));
    expect(playButton(tester).dim, isTrue);
    await tester.tap(find.text('Play'));
    await until(tester, find.text('Check Your Clock'));
    expect(find.byType(GameScreen), findsNothing);
  });
}

WaterButton playButton(WidgetTester tester) {
  return tester.widget<WaterButton>(
    find.ancestor(
      of: find.textContaining(RegExp('Play|Done for today')),
      matching: find.byType(WaterButton),
    ),
  );
}

Future<void> until(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (ready.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for $ready');
}
