import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_colors.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:rainbow_pour/game/difficulty.dart';
import 'package:rainbow_pour/screens/profile/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  testWidgets('an empty save shows zeros, an empty bar and a message', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StatsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final cap = DifficultyCurve.maxLevel * 3;
    expect(starTotal(tester), '0');
    expect(find.text(' / $cap'), findsOneWidget);
    expect(barFill(tester), 0);
    expect(valueFor(tester, 'Levels done'), '0');
    expect(valueFor(tester, 'Best streak'), '0');
    expect(valueFor(tester, 'Total moves'), '0');
    expect(valueFor(tester, '3-star levels'), '0');
    expect(find.text('Play your first level!'), findsOneWidget);
    expect(find.text('Level 1'), findsNothing);
    expect(find.text('Gems earned'), findsNothing);
    expect(find.text('RECENT LEVELS'), findsNothing);
    expect(find.text('LATEST LEVELS'), findsOneWidget);
  });

  testWidgets('mixed stars match the totals and the five latest levels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await seedProgress();
    await tester.pumpWidget(const MaterialApp(home: StatsScreen()));
    await until(tester, find.text('12,345'));

    final cap = DifficultyCurve.maxLevel * 3;
    expect(starTotal(tester), '15');
    expect(find.text(' / $cap'), findsOneWidget);
    expect(barFill(tester), closeTo(15 / cap, 0.000001));
    expect(valueFor(tester, 'Levels done'), '7');
    expect(valueFor(tester, 'Best streak'), '4');
    expect(valueFor(tester, 'Total moves'), '12,345');
    // 1-star and 2-star wins stay out of the perfect count: only 1, 4 and 6.
    expect(valueFor(tester, '3-star levels'), '3');

    expect(
      tester
          .widgetList<Text>(find.textContaining(RegExp(r'^Level \d+$')))
          .map((text) => text.data)
          .toList(),
      ['Level 7', 'Level 6', 'Level 5', 'Level 4', 'Level 3'],
    );
    expectRowStars(tester, 7, 1);
    expectRowStars(tester, 6, 3);
    expectRowStars(tester, 5, 2);
    expectRowStars(tester, 4, 3);
    expectRowStars(tester, 3, 1);
    expect(find.text('Level 2'), findsNothing);
    expect(find.text('Level 1'), findsNothing);
    expect(find.text('Play your first level!'), findsNothing);
    expect(find.text('BEST'), findsNothing);
    expect(find.text('Gems earned'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'\d+ moves').hasMatch(widget.data!),
      ),
      findsNothing,
    );
  });
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

String starTotal(WidgetTester tester) => valueFor(tester, 'TOTAL STARS');

double? barFill(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor;

void expectRowStars(WidgetTester tester, int level, int stars) {
  final row = find
      .ancestor(of: find.text('Level $level'), matching: find.byType(Row))
      .first;
  final icons = tester
      .widgetList<Icon>(
        find.descendant(of: row, matching: find.byIcon(Icons.star_rounded)),
      )
      .toList();
  expect(icons, hasLength(3));
  for (var i = 0; i < 3; i++) {
    expect(
      icons[i].color,
      i < stars ? AppColors.gold : Colors.white.withValues(alpha: 0.2),
    );
  }
}
