import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/daily_reward.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:rainbow_pour/screens/daily/daily_reward_screen.dart';
import 'package:rainbow_pour/widgets/water_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  testWidgets('a fresh save claims day 1 once', (tester) async {
    final now = DateTime(2026, 6, 15, 10);
    await tester.pumpWidget(
      MaterialApp(home: DailyRewardScreen(clock: () => now)),
    );
    await until(tester, find.text('Claim +20'));
    expect(find.text('Start your streak!'), findsOneWidget);
    expect(find.text('Check Your Clock'), findsNothing);

    await tester.tap(find.text('Claim +20'));
    await until(tester, find.text('Claimed'));
    expect(find.text('Claim +20'), findsNothing);
    expect(find.text('Come back tomorrow'), findsOneWidget);
    expect(await AppPrefs.gems(), 20);

    await tester.tap(find.text('Claimed'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(await AppPrefs.gems(), 20);
  });

  testWidgets('yesterday streak day 2 offers 40 gems', (tester) async {
    final now = DateTime(2026, 6, 15, 10);
    final yesterday = DateTime(2026, 6, 14, 21);
    final data = SaveData();
    data.daily
      ..lastClaimDay = dayKey(yesterday)
      ..streakDay = 2
      ..streakCount = 2
      ..bestStreak = 2;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefs.saveKey, data.encode());
    AppPrefs.resetForTest();

    await tester.pumpWidget(
      MaterialApp(home: DailyRewardScreen(clock: () => now)),
    );
    await until(tester, find.text('Claim +40'));
    expect(find.text('2-day streak'), findsOneWidget);
    expect(find.text('Claimed'), findsNothing);
    expect(find.text('Check Your Clock'), findsNothing);
  });

  testWidgets('a future lastSeenMs blocks the claim and shows the dialog', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 15, 10);
    final data = SaveData()
      ..daily.lastSeenMs = now
          .add(const Duration(hours: 3))
          .millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPrefs.saveKey, data.encode());
    AppPrefs.resetForTest();

    await tester.pumpWidget(
      MaterialApp(home: DailyRewardScreen(clock: () => now)),
    );
    await until(tester, find.text('Check Your Clock'));
    expect(claimButton(tester).dim, isTrue);
    expect(find.text('Claimed'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Check Your Clock'), findsNothing);

    await tester.tap(find.text('Claim +20'));
    await until(tester, find.text('Check Your Clock'));
    expect(await AppPrefs.gems(), 0);
  });

  testWidgets('a clock turned back while the screen is open stays unclaimed', (
    tester,
  ) async {
    var now = DateTime(2026, 6, 15, 12);
    await tester.pumpWidget(
      MaterialApp(home: DailyRewardScreen(clock: () => now)),
    );
    await until(tester, find.text('Claim +20'));
    expect(find.text('Check Your Clock'), findsNothing);

    now = now.subtract(const Duration(minutes: 3));
    await tester.tap(find.text('Claim +20'));
    await until(tester, find.text('Check Your Clock'));
    expect(find.text('Claimed'), findsNothing);
    expect(await AppPrefs.gems(), 0);
    expect(claimButton(tester).dim, isTrue);
  });
}

WaterButton claimButton(WidgetTester tester) {
  return tester.widget<WaterButton>(
    find.ancestor(
      of: find.textContaining('Claim'),
      matching: find.byType(WaterButton),
    ),
  );
}

Future<void> until(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (ready.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for $ready');
}
