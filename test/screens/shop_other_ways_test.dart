import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/screens/challenge/daily_challenge_screen.dart';
import 'package:rainbow_pour/screens/daily/daily_reward_screen.dart';
import 'package:rainbow_pour/screens/levels/level_map_screen.dart';
import 'package:rainbow_pour/screens/shop/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  Future<void> openShop(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pump(const Duration(milliseconds: 1600));
    final target = find.text('Daily challenge');
    await tester.dragUntilVisible(
      target,
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('the Other ways rows open their screens', (tester) async {
    await openShop(tester);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));

    await tester.tap(find.text('Daily reward'));
    await pumpRoute(tester);
    expect(find.byType(DailyRewardScreen), findsOneWidget);
  });

  testWidgets('Complete levels opens the level map', (tester) async {
    await openShop(tester);
    await tester.tap(find.text('Complete levels'));
    await pumpRoute(tester);
    expect(find.byType(LevelMapScreen), findsOneWidget);
  });

  testWidgets('Daily challenge opens the challenge screen', (tester) async {
    await openShop(tester);
    await tester.tap(find.text('Daily challenge'));
    await pumpRoute(tester);
    expect(find.byType(DailyChallengeScreen), findsOneWidget);
  });
}

/// A pushed route needs a few frames to appear; screens with endless
/// animations never settle, so pump a fixed number of short frames.
Future<void> pumpRoute(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
