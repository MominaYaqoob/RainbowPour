import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/difficulty.dart';

void main() {
  test('the first levels follow the planned bottle counts', () {
    expect(DifficultyCurve.specFor(1).bottles, 3);
    expect(DifficultyCurve.specFor(1).colors, 2);
    expect(DifficultyCurve.specFor(1).isTutorial, isTrue);
    expect(DifficultyCurve.specFor(2).bottles, 4);
    expect(DifficultyCurve.specFor(3).bottles, 6);
    expect(DifficultyCurve.specFor(4).bottles, 7);
    expect(DifficultyCurve.specFor(5).bottles, 8);
    expect(DifficultyCurve.specFor(2).isTutorial, isFalse);
  });

  test('bottles and colours grow to the maximum by level 100', () {
    var best = 0;
    for (var level = 6; level <= 100; level++) {
      final spec = DifficultyCurve.specFor(level);
      if (spec.bottles > best) best = spec.bottles;
    }
    expect(best, DifficultyCurve.maxBottles);
    // a regular level (not a breather) late on is at the maximum
    expect(DifficultyCurve.specFor(101).bottles, 25);
    expect(DifficultyCurve.specFor(101).colors, DifficultyCurve.maxColors);
    expect(
      DifficultyCurve.specFor(60).bottles,
      greaterThan(DifficultyCurve.specFor(12).bottles),
    );
  });

  test('par floor grows with the level', () {
    expect(DifficultyCurve.parFloor(1), 3);
    expect(
      DifficultyCurve.parFloor(250),
      greaterThan(DifficultyCurve.parFloor(10)),
    );
  });

  test('every level stays inside the bottle and colour limits', () {
    for (var level = 1; level <= DifficultyCurve.maxLevel; level++) {
      final spec = DifficultyCurve.specFor(level);
      expect(spec.level, level);
      expect(spec.colors, inInclusiveRange(2, DifficultyCurve.maxColors));
      expect(spec.bottles, greaterThan(spec.fullBottles));
      expect(spec.duplicates, inInclusiveRange(0, spec.colors));
      expect(spec.bottles, lessThanOrEqualTo(DifficultyCurve.maxBottles));
      expect(spec.empties, inInclusiveRange(1, 2));
      expect(spec.bottles - spec.fullBottles, spec.empties);
      expect(spec.capacity, inInclusiveRange(4, 6));
      expect(spec.backgroundIndex, ((level - 1) ~/ 20) % 6);
      if (level <= 30) expect(spec.capacity, 4);
    }
  });

  test('every fifth level after the fifth is a breather', () {
    final normal = DifficultyCurve.specFor(14);
    final easy = DifficultyCurve.specFor(15);
    expect(easy.colors, lessThan(DifficultyCurve.specFor(16).colors));
    expect(easy.bottles, lessThan(normal.bottles));
  });
}
