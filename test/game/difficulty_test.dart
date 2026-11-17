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

  test('bottles and colours grow to the maximum by level 99', () {
    var best = 0;
    for (var level = 6; level <= 99; level++) {
      final spec = DifficultyCurve.specFor(level);
      if (spec.bottles > best) best = spec.bottles;
    }
    expect(best, DifficultyCurve.maxBottles);
    expect(DifficultyCurve.specFor(99).bottles, 25);
    expect(DifficultyCurve.specFor(99).colors, DifficultyCurve.maxColors);
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

  group('the bottle wave from level 100', () {
    test('levels 1 to 99 are exactly what they were', () {
      // spot checks of the old curve (bottles / colours)
      const old = {
        1: (3, 2),
        5: (8, 5),
        10: (10, 6),
        26: (16, 12),
        41: (19, 14),
        61: (21, 17),
        91: (24, 19),
        99: (25, 20),
      };
      for (final e in old.entries) {
        final s = DifficultyCurve.specFor(e.key);
        expect((s.bottles, s.colors), e.value, reason: 'level ${e.key}');
      }
    });

    test('bottles follow the ten level wave and repeat', () {
      for (var level = 100; level <= 300; level++) {
        final i = (level - 100) % 10;
        expect(
          DifficultyCurve.specFor(level).bottles,
          DifficultyCurve.waveBottles[i],
          reason: 'level $level',
        );
      }
      expect(DifficultyCurve.specFor(100).bottles, 19);
      expect(DifficultyCurve.specFor(105).bottles, 25);
      expect(DifficultyCurve.specFor(108).bottles, 20);
      expect(DifficultyCurve.specFor(109).bottles, 15);
      expect(DifficultyCurve.specFor(110).bottles, 19);
    });

    test('the wave stays between 15 and 25 bottles and keeps 2 empties', () {
      for (var level = 100; level <= 300; level++) {
        final s = DifficultyCurve.specFor(level);
        expect(s.bottles, inInclusiveRange(15, 25));
        expect(s.empties, 2);
        // never more than one colour per full bottle, 20 colours at most
        expect(s.colors, lessThanOrEqualTo(s.fullBottles));
        expect(s.colors, lessThanOrEqualTo(DifficultyCurve.maxColors));
        // no colour needs more than two bottles
        expect(s.duplicates, lessThanOrEqualTo(s.colors));
      }
    });

    test('there are many different bottle counts, not one plateau', () {
      final counts = {
        for (var l = 100; l <= 300; l++) DifficultyCurve.specFor(l).bottles,
      };
      expect(counts.length, greaterThanOrEqualTo(8));
    });
  });
}
