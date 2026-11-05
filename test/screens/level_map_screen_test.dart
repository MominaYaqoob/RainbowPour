import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_colors.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/game/difficulty.dart';
import 'package:rainbow_pour/screens/game/game_screen.dart';
import 'package:rainbow_pour/screens/levels/level_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  // The map pulse and the night background repeat forever.
  Future<void> showMap(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LevelMapScreen()));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('levels-loading')).evaluate().isEmpty &&
          find
              .byKey(const ValueKey('level-map-scroll'))
              .evaluate()
              .isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 50));
        return;
      }
    }
    fail('level map did not finish loading');
  }

  ScrollPosition mapPosition(WidgetTester tester) {
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('level-map-scroll')),
      matching: find.byType(Scrollable),
    );
    return tester.state<ScrollableState>(scrollable).position;
  }

  Future<void> scrollToTop(WidgetTester tester) async {
    final position = mapPosition(tester);
    position.jumpTo(position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder node(int level) => find.byKey(ValueKey<int>(level));

  void expectCurrent(int level) {
    expect(
      find.descendant(of: node(level), matching: find.text('PLAY')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: node(level), matching: find.text('$level')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: node(level),
        matching: find.byIcon(Icons.lock_rounded),
      ),
      findsNothing,
    );
  }

  void expectLocked(int level) {
    expect(node(level), findsOneWidget);
    expect(
      find.descendant(
        of: node(level),
        matching: find.byIcon(Icons.lock_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: node(level), matching: find.text('PLAY')),
      findsNothing,
    );
  }

  void expectDone(WidgetTester tester, int level, int stars) {
    expect(
      find.descendant(of: node(level), matching: find.text('$level')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: node(level), matching: find.text('PLAY')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: node(level),
        matching: find.byIcon(Icons.lock_rounded),
      ),
      findsNothing,
    );
    final icons = tester
        .widgetList<Icon>(
          find.descendant(
            of: node(level),
            matching: find.byIcon(Icons.star_rounded),
          ),
        )
        .toList();
    expect(icons, hasLength(3));
    for (var i = 0; i < 3; i++) {
      expect(
        icons[i].color,
        i < stars ? AppColors.gold : Colors.white.withValues(alpha: 0.25),
      );
    }
  }

  testWidgets('fresh save: level 1 is current and level 2 is locked', (
    tester,
  ) async {
    await showMap(tester);
    expectCurrent(1);
    expectLocked(2);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.text('PLAY'), findsOneWidget);
    expect(mapPosition(tester).pixels, 0);
  });

  testWidgets('saved progress shows real stars, current and locked nodes', (
    tester,
  ) async {
    final max = DifficultyCurve.maxLevel;
    await AppPrefs.recordWin(level: 1, stars: 3, moves: 4, maxLevel: max);
    await AppPrefs.recordWin(level: 2, stars: 2, moves: 6, maxLevel: max);
    await AppPrefs.recordWin(level: 3, stars: 1, moves: 8, maxLevel: max);
    await AppPrefs.recordWin(level: 4, stars: 3, moves: 5, maxLevel: max);

    await showMap(tester);

    expectDone(tester, 1, 3);
    expectDone(tester, 2, 2);
    expectDone(tester, 3, 1);
    expectDone(tester, 4, 3);
    expectCurrent(5);
    expectLocked(6);
    expect(find.text('PLAY'), findsOneWidget);
    expect(mapPosition(tester).pixels, (5 - 3) * 96);
  });

  testWidgets('tapping a locked level does not open the game', (tester) async {
    await showMap(tester);
    await tester.tap(node(2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Finish level 1 first'), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('all levels are reachable, including the last one', (
    tester,
  ) async {
    await showMap(tester);
    await scrollToTop(tester);
    expect(node(DifficultyCurve.maxLevel), findsOneWidget);
    expect(mapPosition(tester).pixels, mapPosition(tester).maxScrollExtent);
  });

  testWidgets('coming back from a level reloads stars and the open level', (
    tester,
  ) async {
    await showMap(tester);
    await tester.tap(node(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);

    await AppPrefs.recordWin(
      level: 1,
      stars: 3,
      moves: 4,
      maxLevel: DifficultyCurve.maxLevel,
    );
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    // The game waits before it installs the board. Let that timer finish.
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(GameScreen), findsNothing);
    expectDone(tester, 1, 3);
    expectCurrent(2);
    expect(find.text('PLAY'), findsOneWidget);
  });

  testWidgets('a finished game has no current node', (tester) async {
    final max = DifficultyCurve.maxLevel;
    await AppPrefs.setLevel(max);
    await AppPrefs.recordWin(level: max, stars: 2, moves: 9, maxLevel: max);

    await showMap(tester);
    await scrollToTop(tester);

    expectDone(tester, max, 2);
    expect(find.text('PLAY'), findsNothing);
  });
}
