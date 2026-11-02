import 'dart:math' as math;

/// Demo board for the UI only. The real generator and solver replace this in
/// the game-logic step; it only shows how bigger levels will look.
class SampleBoard {
  const SampleBoard(this.capacity, this.bottles);

  final int capacity;
  final List<List<int>> bottles;

  static SampleBoard forLevel(int level) {
    final l = level < 1 ? 1 : level;
    final colors = math.min(4 + (l - 1) ~/ 6, 12);
    final capacity = l < 10 ? 4 : (l < 40 ? 5 : 6);
    final rnd = math.Random(l * 7919);
    final pool = <int>[
      for (var c = 0; c < colors; c++)
        for (var k = 0; k < capacity; k++) c,
    ]..shuffle(rnd);
    final bottles = <List<int>>[
      for (var b = 0; b < colors; b++)
        pool.sublist(b * capacity, (b + 1) * capacity),
      [],
      [],
    ];
    return SampleBoard(capacity, bottles);
  }
}
