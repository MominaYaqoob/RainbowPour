import 'dart:math' as math;

/// How big a level is. See BACKEND_THEORY section 4.4.
class LevelSpec {
  const LevelSpec({
    required this.level,
    required this.colors,
    required this.capacity,
    required this.bottles,
    required this.backgroundIndex,
  });

  final int level;
  final int colors;
  final int capacity;
  final int bottles;
  final int backgroundIndex;

  @override
  String toString() =>
      'L$level C$colors K$capacity B$bottles bg$backgroundIndex';
}

/// Level number to colours, capacity, bottle count, and background.
abstract final class DifficultyCurve {
  static LevelSpec specFor(int level) {
    if (level < 1 || level > 500) {
      throw ArgumentError.value(level, 'level', 'expected 1..500');
    }
    final colors = _colors(level);
    final capacity = _capacity(level);
    return LevelSpec(
      level: level,
      colors: colors,
      capacity: capacity,
      bottles: colors + 2,
      backgroundIndex: ((level - 1) ~/ 20) % 6,
    );
  }

  static int _colors(int n) {
    final int colors;
    if (n <= 10) {
      colors = 3 + (n - 1) ~/ 4;
    } else if (n <= 60) {
      colors = _lerp(n, 11, 60, 5, 8);
    } else if (n <= 200) {
      colors = _lerp(n, 61, 200, 8, 11);
    } else {
      colors = _lerp(n, 201, 500, 11, 12);
    }
    // Every 10th level above 10 is a breather: two fewer colours.
    if (n > 10 && n % 10 == 0) return math.max(3, colors - 2);
    return colors;
  }

  static int _capacity(int n) {
    if (n <= 30) return 4;
    if (n <= 100) return n % 4 == 0 ? 5 : 4;
    if (n <= 300) return n % 3 == 0 ? 4 : 5;
    return n % 10 == 5 ? 6 : 5;
  }

  /// Shortest par we will publish. About `colours * 2` on level 1 and
  /// `colours * 3` on level 500.
  static int parFloor(int level) {
    final colors = specFor(level).colors;
    const span = 499;
    final grown = (colors * (level - 1) + span ~/ 2) ~/ span;
    return colors * 2 + grown;
  }

  /// Rounded linear step from [c0] at [n0] to [c1] at [n1].
  static int _lerp(int n, int n0, int n1, int c0, int c1) {
    final span = n1 - n0;
    final add = (n - n0) * (c1 - c0);
    return c0 + (add + span ~/ 2) ~/ span;
  }
}
