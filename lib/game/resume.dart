import '../core/save_data.dart';
import 'engine.dart';
import 'generator.dart';
import 'models.dart';

/// The saved board as a game state, if it really belongs to [generated]: the
/// same level, the same capacity, the same colours in the same amounts, and
/// the same number of bottles (one more after an extra bottle). Anything else
/// returns null and the level starts fresh.
GameState? restoreProgress(InProgress? saved, GeneratedLevel generated) {
  if (saved == null ||
      saved.mode != 'level' ||
      saved.level != generated.spec.level ||
      saved.capacity != generated.board.capacity) {
    return null;
  }
  final spare = saved.extraBottleUsed ? 1 : 0;
  if (saved.bottles.length != generated.board.bottles.length + spare) {
    return null;
  }
  Map<int, int> colours(Iterable<List<int>> bottles) {
    final counts = <int, int>{};
    for (final layers in bottles) {
      for (final c in layers) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    return counts;
  }

  final want = colours([for (final b in generated.board.bottles) b.layers]);
  final have = colours(saved.bottles);
  if (want.length != have.length) return null;
  for (final e in want.entries) {
    if (have[e.key] != e.value) return null;
  }
  for (final h in saved.history) {
    if (h[0] < 0 ||
        h[1] < 0 ||
        h[0] >= saved.bottles.length ||
        h[1] >= saved.bottles.length ||
        h[2] < 1) {
      return null;
    }
  }
  return GameState(
    board: Board.layers(saved.capacity, saved.bottles),
    moves: saved.moves,
    history: [
      for (final h in saved.history) Move(from: h[0], to: h[1], count: h[2]),
    ],
  );
}
