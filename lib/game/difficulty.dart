import 'dart:math' as math;

/// How big a level is. See BACKEND_THEORY section 4.4.
class LevelSpec {
  const LevelSpec({
    required this.level,
    required this.colors,
    required this.capacity,
    required this.bottles,
    required this.empties,
    required this.duplicates,
    required this.backgroundIndex,
  });

  final int level;
  final int colors;
  final int capacity;

  /// Bottles on the table. Every bottle but the empty ones starts full.
  final int bottles;

  /// Colours that fill two bottles instead of one, so a level can have more
  /// full bottles than colours.
  final int duplicates;

  /// Bottles that end up full of one colour.
  int get fullBottles => colors + duplicates;

  /// Fewest empty bottles a level starts with.
  final int empties;
  final int backgroundIndex;

  /// Level 1 teaches the game with a fixed three-bottle board.
  bool get isTutorial => level == 1;

  @override
  String toString() =>
      'L$level C$colors K$capacity B$bottles E$empties bg$backgroundIndex';
}

/// Level number to colours, capacity, bottle count, and background.
abstract final class DifficultyCurve {
  /// Levels in the game.
  static const maxLevel = 300;

  /// Most bottles on the screen (four rows of up to seven).
  static const maxBottles = 25;

  /// Most colours on one level (the palette has this many).
  static const maxColors = 20;

  static LevelSpec specFor(int level) {
    if (level < 1 || level > maxLevel) {
      throw ArgumentError.value(level, 'level', 'expected 1..$maxLevel');
    }
    var colors = _colors(level);
    var bottles = _bottles(level);
    // Every 5th level after the 5th is a breather: fewer colours and bottles.
    if (level > 5 && level % 5 == 0) {
      colors = math.max(3, colors - 2);
      bottles = math.max(colors + 2, bottles - 3);
    }
    // Levels 1 and 2 keep one empty bottle; from level 3 there are two.
    final empties = level <= 2 ? 1 : 2;
    final full = bottles - empties;
    // Enough colours that no colour needs more than two bottles.
    colors = math.min(maxColors, math.max(colors, (full + 1) ~/ 2));
    colors = math.min(colors, full);
    return LevelSpec(
      level: level,
      colors: colors,
      capacity: _capacity(level),
      bottles: bottles,
      empties: empties,
      duplicates: full - colors,
      backgroundIndex: ((level - 1) ~/ 20) % 6,
    );
  }

  /// 2 colours in the tutorial, then 3, 4, ... up to 20 at level 100.
  static int _colors(int n) {
    if (n == 1) return 2;
    if (n == 2) return 3;
    if (n <= 10) return _lerp(n, 3, 10, 4, 8);
    if (n <= 30) return _lerp(n, 10, 30, 8, 13);
    if (n <= 60) return _lerp(n, 30, 60, 13, 17);
    if (n <= 100) return _lerp(n, 60, 100, 17, maxColors);
    return maxColors;
  }

  /// 3 bottles in the tutorial, 4 on level 2, then 6, 7, 8, ... up to 25 at
  /// level 100.
  static int _bottles(int n) {
    if (n == 1) return 3;
    if (n == 2) return 4;
    if (n <= 5) return 6 + (n - 3);
    if (n <= 10) return _lerp(n, 5, 10, 8, 13);
    if (n <= 40) return _lerp(n, 10, 40, 13, 19);
    if (n <= 100) return _lerp(n, 40, 100, 19, maxBottles);
    return maxBottles;
  }

  static int _capacity(int n) {
    if (n <= 60) return 4;
    return n % 3 == 0 ? 4 : 5;
  }

  /// How many single-layer reverse pours scramble a level: a few on the
  /// early levels, many by level 100.
  static int scrambleSteps(LevelSpec spec) {
    final t = math.min(1.0, math.max(0, spec.level - 2) / 98);
    final steps = (spec.fullBottles * (2.5 + 7.5 * t)).round();
    return math.max(steps, parFloor(spec.level) + 2);
  }

  /// Shortest par we will publish: about 1.6 pours per full bottle, a little
  /// more as the levels go on.
  static int parFloor(int level) {
    final spec = specFor(level);
    const span = maxLevel - 1;
    final grown = (spec.colors * (level - 1)) ~/ (3 * span);
    return (spec.fullBottles * 16 + 5) ~/ 10 + grown;
  }

  /// Rounded linear step from [c0] at [n0] to [c1] at [n1].
  static int _lerp(int n, int n0, int n1, int c0, int c1) {
    final span = n1 - n0;
    final add = (n - n0) * (c1 - c0);
    return c0 + (add + span ~/ 2) ~/ span;
  }
}
