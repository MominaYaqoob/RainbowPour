import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/screens/settings/qa_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  Future<void> show(WidgetTester tester, {bool? enabled}) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QaSection(
              enabled: enabled,
              clock: () => DateTime(2026, 11, 18, 12),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a release build (enabled false) builds nothing', (tester) async {
    await show(tester, enabled: false);
    expect(find.byKey(const ValueKey('qa-section')), findsNothing);
    expect(find.text('QA (DEBUG ONLY)'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a debug build shows the QA rows', (tester) async {
    await show(tester);
    expect(find.text('QA (DEBUG ONLY)'), findsOneWidget);
    expect(find.text('Gems +500'), findsOneWidget);
    expect(find.text('Level failed popup'), findsOneWidget);
    expect(find.text('Clear the whole save'), findsOneWidget);
  });

  testWidgets('Gems +500 adds gems and Gems = 0 empties them', (tester) async {
    await show(tester);
    await tester.tap(find.text('Gems +500'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(await AppPrefs.gems(), 500);
    await tester.tap(find.text('Gems = 0'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(await AppPrefs.gems(), 0);
  });

  testWidgets('Jump to level writes the typed level', (tester) async {
    await show(tester);
    await tester.enterText(find.byType(TextField), '105');
    await tester.tap(find.text('Go'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(await AppPrefs.level(), 105);
  });

  testWidgets('popup rows open their dialogs', (tester) async {
    await show(tester);
    await tester.tap(find.text('Level failed popup'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // the test font is wider than the real one: ignore a text overflow
    tester.takeException();
    expect(find.text('No Moves Left'), findsWidgets);
  });

  testWidgets('the fake clock row blocks the daily claim', (tester) async {
    await show(tester);
    await tester.tap(find.text('Fake clock one day ahead (blocks claims)'));
    await tester.pump(const Duration(milliseconds: 200));
    final claim = await AppPrefs.claimDaily(DateTime(2026, 11, 18, 12));
    expect(claim.clockBlocked, isTrue);
  });
}
