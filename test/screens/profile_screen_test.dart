import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:rainbow_pour/game/difficulty.dart';
import 'package:rainbow_pour/screens/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  testWidgets('an empty save shows zero counters', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(valueFor(tester, 'Levels'), '0');
    expect(valueFor(tester, 'Stars'), '0');
    expect(valueFor(tester, 'Best streak'), '0');
    expect(find.text('24'), findsNothing);
    expect(find.text('63'), findsNothing);
  });

  testWidgets(
    'saved wins show the real totals, including 1 and 2 star levels',
    (tester) async {
      await seedProgress();
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await until(tester, find.text('15'));

      expect(valueFor(tester, 'Levels'), '7');
      expect(valueFor(tester, 'Stars'), '15');
      expect(valueFor(tester, 'Best streak'), '4');
      expect(find.text('24'), findsNothing);
      expect(find.text('63'), findsNothing);
    },
  );
}

/// Levels 1..7. Stars 3,2,1,3,2,3,1 (sum 15, three perfect). Moves sum to 12,345.
Future<void> seedProgress() async {
  final max = DifficultyCurve.maxLevel;
  const stars = {1: 3, 2: 2, 3: 1, 4: 3, 5: 2, 6: 3, 7: 1};
  const moves = {1: 10, 2: 20, 3: 30, 4: 40, 5: 50, 6: 60, 7: 12135};
  for (final level in stars.keys) {
    await AppPrefs.recordWin(
      level: level,
      stars: stars[level]!,
      moves: moves[level]!,
      maxLevel: max,
    );
  }
  final prefs = await SharedPreferences.getInstance();
  final saved = SaveData.tryDecode(prefs.getString(AppPrefs.saveKey));
  expect(saved, isNotNull);
  saved!.daily.bestStreak = 4;
  await prefs.setString(AppPrefs.saveKey, saved.encode());
  AppPrefs.resetForTest();
}

Future<void> until(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (ready.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for $ready');
}

String valueFor(WidgetTester tester, String label) {
  final column = find
      .ancestor(of: find.text(label), matching: find.byType(Column))
      .first;
  final texts = tester.widgetList<Text>(
    find.descendant(of: column, matching: find.byType(Text)),
  );
  for (final text in texts) {
    if (text.data != null && text.data != label) return text.data!;
  }
  fail('no value next to $label');
}
