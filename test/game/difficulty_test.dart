import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/difficulty.dart';

void main() {
  test('spec table for the sample levels', () {
    expect(_spec(1), (colors: 3, capacity: 4, bottles: 5, background: 0));
    expect(_spec(4), (colors: 3, capacity: 4, bottles: 5, background: 0));
    expect(_spec(5), (colors: 4, capacity: 4, bottles: 6, background: 0));
    expect(_spec(10), (colors: 5, capacity: 4, bottles: 7, background: 0));
    expect(_spec(11), (colors: 5, capacity: 4, bottles: 7, background: 0));
    expect(_spec(32), (colors: 6, capacity: 5, bottles: 8, background: 1));
    expect(_spec(60), (colors: 6, capacity: 5, bottles: 8, background: 2));
    expect(_spec(102), (colors: 9, capacity: 4, bottles: 11, background: 5));
    expect(_spec(200), (colors: 9, capacity: 5, bottles: 11, background: 3));
    expect(_spec(305), (colors: 11, capacity: 6, bottles: 13, background: 3));
    expect(_spec(500), (colors: 10, capacity: 5, bottles: 12, background: 0));
  });

  test('par floor grows from two colours to three', () {
    expect(DifficultyCurve.parFloor(1), 6);
    expect(DifficultyCurve.parFloor(500), 30);
    expect(
      DifficultyCurve.parFloor(400),
      greaterThan(DifficultyCurve.parFloor(10)),
    );
  });

  test('every level stays inside the bottle and colour limits', () {
    for (var level = 1; level <= 500; level++) {
      final spec = DifficultyCurve.specFor(level);
      expect(spec.level, level);
      expect(spec.colors, inInclusiveRange(3, 12));
      expect(spec.bottles, spec.colors + 2);
      expect(spec.bottles, lessThanOrEqualTo(14));
      expect(spec.capacity, inInclusiveRange(4, 6));
      expect(spec.backgroundIndex, ((level - 1) ~/ 20) % 6);
      if (level <= 30) expect(spec.capacity, 4);
      if (level > 10 && level % 10 == 0) {
        final plain = level == 500 ? 12 : spec.colors;
        expect(spec.colors, lessThanOrEqualTo(plain));
      }
    }
  });
}

({int colors, int capacity, int bottles, int background}) _spec(int level) {
  final spec = DifficultyCurve.specFor(level);
  return (
    colors: spec.colors,
    capacity: spec.capacity,
    bottles: spec.bottles,
    background: spec.backgroundIndex,
  );
}
