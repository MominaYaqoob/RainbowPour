import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/screens/shop/shop_screen.dart';
import 'package:rainbow_pour/widgets/gem_pill.dart';
import 'package:rainbow_pour/widgets/page_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
  });

  testWidgets('the gem pill on an inner screen opens the Shop', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PageShell(title: 'Levels', child: SizedBox.expand()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ShopScreen), findsNothing);

    await tester.tap(find.byType(GemPill));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ShopScreen), findsOneWidget);
    // no "coming soon" message any more
    expect(find.textContaining('coming soon'), findsNothing);
  });

  testWidgets('the Shop itself does not open another Shop', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.tap(find.byType(GemPill));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ShopScreen), findsOneWidget);
  });
}
