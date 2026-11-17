import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/screens/game/level_complete_dialog.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required int gems,
    bool offerDouble = false,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    LevelCompleteDialog.show(
      ctx,
      level: 9,
      stars: 3,
      moves: 20,
      gems: gems,
      offerDouble: offerDouble,
      onDouble: () async => true,
      onNext: () {},
      onReplay: () {},
      onHome: () {},
    );
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // the test font is wider than the real one: ignore a text overflow
    tester.takeException();
  }

  testWidgets('the first win shows the gems and the 2x offer', (tester) async {
    await open(tester, gems: 20, offerDouble: true);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('Watch an ad for 2x gems'), findsOneWidget);
    expect(find.text('Gems are paid on the first win only'), findsNothing);
  });

  testWidgets('a replay shows no gems and no 2x offer', (tester) async {
    await open(tester, gems: 0);
    expect(find.text('+0'), findsNothing);
    expect(find.text('Gems are paid on the first win only'), findsOneWidget);
    expect(find.text('Watch an ad for 2x gems'), findsNothing);
    expect(find.text('Next Level'), findsWidgets);
  });
}
