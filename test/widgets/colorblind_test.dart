import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/app_colors.dart';
import 'package:rainbow_pour/core/app_prefs.dart';
import 'package:rainbow_pour/core/colorblind.dart';
import 'package:rainbow_pour/widgets/cone_bottle.dart';
import 'package:rainbow_pour/widgets/liquid_symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CIE76 distance between two colours in Lab (D65).
double deltaE(Color a, Color b) {
  final la = _lab(a);
  final lb = _lab(b);
  return math.sqrt(
    math.pow(la[0] - lb[0], 2) +
        math.pow(la[1] - lb[1], 2) +
        math.pow(la[2] - lb[2], 2),
  );
}

List<double> _lab(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = lin(c.r);
  final g = lin(c.g);
  final b = lin(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

Future<List<int>> render(
  WidgetTester tester, {
  required Widget bottle,
  required GlobalKey key,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: RepaintBoundary(key: key, child: bottle),
        ),
      ),
    ),
  );
  late List<int> bytes;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    bytes = data!.buffer.asUint8List().toList();
  });
  return bytes;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPrefs.resetForTest();
    ColorblindMode.set(false);
  });

  test('the symbol table has 20 distinct symbols, one per palette colour', () {
    expect(LiquidSymbols.count, AppColors.liquid.length);
    expect(LiquidSymbols.names.length, 20);
    expect(LiquidSymbols.names.toSet().length, 20);
    for (var i = 0; i < 20; i++) {
      final bounds = LiquidSymbols.pathFor(i).getBounds();
      expect(bounds.width, greaterThan(0.5), reason: LiquidSymbols.names[i]);
      expect(bounds.height, greaterThan(0.5), reason: LiquidSymbols.names[i]);
      expect(bounds.left, greaterThanOrEqualTo(-1.01));
      expect(bounds.right, lessThanOrEqualTo(1.01));
      expect(bounds.top, greaterThanOrEqualTo(-1.01));
      expect(bounds.bottom, lessThanOrEqualTo(1.01));
    }
  });

  test('close colours get different symbols', () {
    String name(int id) => LiquidSymbols.names[id];
    final groups = [
      [12, 8, 19], // cream, lime, mint
      [13, 9, 0], // maroon, brown, red
      [16, 4], // sky, cyan
    ];
    for (final g in groups) {
      expect(g.map(name).toSet().length, g.length);
    }
  });

  test('palette distance report (CIE76, below 12 is listed)', () {
    var pairs = 0;
    final all = <(double, String)>[];
    for (var i = 0; i < 20; i++) {
      expect(deltaE(AppColors.liquid[i], AppColors.liquid[i]), 0);
      for (var j = i + 1; j < 20; j++) {
        pairs++;
        final d = deltaE(AppColors.liquid[i], AppColors.liquid[j]);
        all.add((d, '${LiquidSymbols.names[i]} ~ ${LiquidSymbols.names[j]}'));
      }
    }
    expect(pairs, 190);
    all.sort((a, b) => a.$1.compareTo(b.$1));
    final below = all.where((e) => e.$1 < 12).length;
    // ignore: avoid_print
    print('Colour pairs under dE76 12: $below. Five closest:');
    for (final e in all.take(5)) {
      // ignore: avoid_print
      print('  ${e.$2}: ${e.$1.toStringAsFixed(1)}');
    }
  });

  test('the switch notifier follows the saved flag and the setter', () async {
    await AppPrefs.setFlag('colorblind', true);
    await ColorblindMode.load();
    expect(ColorblindMode.enabled.value, isTrue);
    ColorblindMode.set(false);
    expect(ColorblindMode.enabled.value, isFalse);
  });

  testWidgets('ConeBottle builds with symbols on and off for every size', (
    tester,
  ) async {
    for (final cap in [4, 5]) {
      for (final width in [24.0, 56.0]) {
        for (final on in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: ConeBottle(
                  layers: List<int>.generate(cap, (i) => i * 4 % 20),
                  capacity: cap,
                  width: width,
                  symbols: on,
                  extraColor: 7,
                  extraProgress: 0.8,
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(ConeBottle), findsOneWidget);
        }
      }
    }
  });

  testWidgets('mode off draws exactly the same pixels; mode on adds symbols', (
    tester,
  ) async {
    final key = GlobalKey();
    const layers = [0, 4, 8, 12];
    final base = await render(
      tester,
      key: key,
      bottle: const ConeBottle(layers: layers, width: 56, symbols: false),
    );
    final byDefault = await render(
      tester,
      key: key,
      bottle: const ConeBottle(layers: layers, width: 56),
    );
    expect(byDefault, base, reason: 'switch off must look identical');

    final withSymbols = await render(
      tester,
      key: key,
      bottle: const ConeBottle(layers: layers, width: 56, symbols: true),
    );
    expect(withSymbols, isNot(base));
  });

  testWidgets('the Settings switch reaches a bottle that follows it', (
    tester,
  ) async {
    final key = GlobalKey();
    const bottle = ConeBottle(layers: [3, 9], width: 56);
    final off = await render(tester, key: key, bottle: bottle);
    ColorblindMode.set(true);
    final on = await render(tester, key: key, bottle: bottle);
    ColorblindMode.set(false);
    expect(on, isNot(off));
  });
}
