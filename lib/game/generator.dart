import 'dart:math';

import 'difficulty.dart';
import 'engine.dart';
import 'models.dart';
import 'solver.dart';

/// A solved, shuffled level plus the line the solver checked.
class GeneratedLevel {
  const GeneratedLevel({
    required this.spec,
    required this.board,
    required this.par,
    required this.solution,
    required this.attempts,
  });

  final LevelSpec spec;
  final Board board;

  /// Length of [solution]. This is the best line found within the node budget,
  /// or the checked reverse-shuffle line when that budget runs out.
  final int par;
  final List<Move> solution;

  /// How many seeds were tried. 1 means the first seed worked.
  final int attempts;
}

/// Seeded boards. Level n uses seed `n * 7919 + 13`.
///
/// Reverse pours run for up to N = 60 + 12*colours steps. Burying a run
/// freezes it, so a shuffle usually stops before N; what remains is still
/// far longer than the old colours+2 cutoff. The fast solver then checks
/// the board. A line shorter than [DifficultyCurve.parFloorOf] is rejected
/// and the next seed is tried. If the solver cannot finish, the checked
/// reverse-shuffle line is the solution and its length is par.
abstract final class LevelGenerator {
  static final Map<int, GeneratedLevel> _cache = {};

  static GeneratedLevel forLevel(int level) {
    return _cache.putIfAbsent(level, () {
      final spec = DifficultyCurve.specFor(level);
      return generate(spec, level * 7919 + 13);
    });
  }

  /// How many seeds a daily challenge may try. Big boards miss the par floor
  /// more often than campaign levels; the checks themselves stay the same.
  static const challengeAttempts = 48;

  /// One board for [day], cached by its `yyyyMMdd` seed. The solution replays
  /// to a win, same as [forLevel].
  static GeneratedLevel forChallenge(DateTime day) {
    final seed = DifficultyCurve.challengeSeed(day);
    return _cache.putIfAbsent(seed, () {
      final spec = DifficultyCurve.challengeSpecFor(day);
      return generate(spec, seed, attempts: challengeAttempts);
    });
  }

  /// Level 1: two colours, three bottles, three pours. The tutorial walks
  /// the player through exactly this line.
  static GeneratedLevel _tutorial(LevelSpec spec) {
    final board = Board.layers(4, [
      [0, 0, 1, 1],
      [1, 1, 0, 0],
      [],
    ]);
    const line = [
      Move(from: 0, to: 2, count: 2),
      Move(from: 1, to: 0, count: 2),
      Move(from: 1, to: 2, count: 2),
    ];
    return GeneratedLevel(
      spec: spec,
      board: board,
      par: line.length,
      solution: line,
      attempts: 1,
    );
  }

  static GeneratedLevel generate(
    LevelSpec spec,
    int seed, {
    int attempts = 24,
  }) {
    if (spec.isTutorial) return _tutorial(spec);
    for (var attempt = 0; attempt < attempts; attempt++) {
      final built = _build(spec, seed + attempt);
      if (built != null) {
        return GeneratedLevel(
          spec: spec,
          board: built.board,
          par: built.moves.length,
          solution: List<Move>.unmodifiable(built.moves),
          attempts: attempt + 1,
        );
      }
    }
    throw StateError('no solvable board for $spec from seed $seed');
  }

  static _Built? _build(LevelSpec spec, int seed) {
    final rng = Random(seed);
    final tubes = <List<int>>[
      for (var color = 0; color < spec.colors; color++)
        [for (var i = 0; i < spec.capacity; i++) color],
      // colours that fill a second bottle
      for (var color = 0; color < spec.duplicates; color++)
        [for (var i = 0; i < spec.capacity; i++) color],
      for (var i = 0; i < spec.bottles - spec.fullBottles; i++) <int>[],
    ];
    final history = <String>[_key(tubes)];
    final guide = <Move>[];
    final steps = DifficultyCurve.scrambleSteps(spec);
    final floor = DifficultyCurve.parFloorOf(spec);
    List<List<int>>? bestTubes;
    List<Move>? bestGuide;
    var bestExtra = -1;

    void remember() {
      if (_emptyCount(tubes) < spec.empties || _won(tubes, spec.capacity)) {
        return;
      }
      final extra = _segments(tubes) - spec.fullBottles;
      final longer = bestGuide == null || guide.length > bestGuide!.length;
      if (extra > bestExtra || (extra == bestExtra && longer)) {
        bestExtra = extra;
        bestTubes = _copy(tubes);
        bestGuide = [...guide];
      }
    }

    while (guide.length < steps) {
      if (!_directedPeel(tubes, rng, history, guide, spec.capacity)) break;
    }
    // Mixed bottles cannot be emptied. Step the scramble back until two
    // one-colour bottles can be parked onto a filled bottle. Every peel adds
    // a segment, so the longest prefix that can be parked is the hardest.
    while (bestTubes == null) {
      final snapTubes = _copy(tubes);
      final snapGuide = [...guide];
      final snapHistory = [...history];
      var parked = 0;
      while (_emptyCount(tubes) < spec.empties && parked < spec.bottles) {
        parked++;
        final edge = _pickEdge(
          tubes,
          rng,
          history,
          spec.capacity,
          splits: false,
        );
        if (edge == null) break;
        _commitEdge(tubes, edge, history, guide, spec.capacity);
      }
      remember();
      if (bestTubes != null) break;
      _assign(tubes, snapTubes);
      guide
        ..clear()
        ..addAll(snapGuide);
      history
        ..clear()
        ..addAll(snapHistory);
      if (guide.isEmpty) break;
      _undoLast(tubes, guide, history);
    }
    if (bestTubes == null || bestGuide == null) return null;
    // Below the floor this seed is an easy board: a real solution cannot be
    // longer than the checked line, nor shorter than the extra segments.
    if (bestExtra < floor && bestGuide!.length < floor) return null;
    _assign(tubes, bestTubes!);
    guide
      ..clear()
      ..addAll(bestGuide!);

    // A different set of palette colours on every level.
    final palette = List<int>.generate(DifficultyCurve.maxColors, (i) => i)
      ..shuffle(rng);
    for (final tube in tubes) {
      for (var i = 0; i < tube.length; i++) {
        tube[i] = palette[tube[i]];
      }
    }
    final board = _board(tubes, spec.capacity);
    final forward = guide.reversed.toList();
    if (!_replay(board, forward)) {
      throw StateError('reverse line does not win $spec from seed $seed');
    }

    final found = Solver.solve(board);
    if (found != null) {
      if (found.length < floor) return null;
      if (!_replay(board, found)) {
        throw StateError('solver line does not win $spec');
      }
      return _Built(board, found);
    }
    if (forward.length < floor) return null;
    return _Built(board, forward);
  }
}

class _Built {
  _Built(this.board, this.moves);

  final Board board;
  final List<Move> moves;
}

/// Peels one unit off a bottle that still has a run of two or more.
///
/// The target is any other bottle with space, except a bottle we could still
/// peel: covering that run would freeze the units under it. Seeds only change
/// which legal peel is chosen.
bool _directedPeel(
  List<List<int>> tubes,
  Random rng,
  List<String> history,
  List<Move> guide,
  int capacity,
) {
  final n = tubes.length;
  final open = <int>[];
  for (var i = 0; i < n; i++) {
    final tube = tubes[i];
    if (tube.length >= 2 && _topRun(tube) >= 2) open.add(i);
  }
  if (open.isEmpty) return false;
  _shuffle(open, rng);

  final openAt = List<bool>.filled(n, false);
  for (final i in open) {
    openAt[i] = true;
  }
  final targets = <int>[];
  for (var i = 0; i < n; i++) {
    if (openAt[i] || tubes[i].length >= capacity) continue;
    targets.add(i);
  }
  _shuffle(targets, rng);

  for (final from in open) {
    for (final to in targets) {
      if (!_pourOne(tubes, from, to, capacity, history, guide)) continue;
      return true;
    }
  }

  // No safe home. Cover the shortest remaining run so the other colours can
  // keep peeling into the space this frees on the source.
  var sacrifice = open.first;
  for (final i in open) {
    if (tubes[i].length < tubes[sacrifice].length) sacrifice = i;
  }
  final donors = [...open]..remove(sacrifice);
  _shuffle(donors, rng);
  if (tubes[sacrifice].length >= capacity) return false;
  for (final from in donors) {
    if (_pourOne(tubes, from, sacrifice, capacity, history, guide)) return true;
  }
  return false;
}

bool _pourOne(
  List<List<int>> tubes,
  int from,
  int to,
  int capacity,
  List<String> history,
  List<Move> guide,
) {
  if (tubes[to].isNotEmpty && tubes[to].last == tubes[from].last) return false;
  final added = <Move>[];
  if (!_transfer(tubes, from, to, 1, capacity, history, added)) return false;
  guide.addAll(added);
  return true;
}

void _shuffle(List<int> values, Random rng) {
  for (var i = values.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final swap = values[i];
    values[i] = values[j];
    values[j] = swap;
  }
}

/// A split (one unit, source keeps that colour) when [splits] is set.
/// Otherwise a whole one-colour bottle moved onto a filled bottle, which
/// frees a slot without throwing segments away.
int? _pickEdge(
  List<List<int>> tubes,
  Random rng,
  List<String> history,
  int capacity, {
  required bool splits,
}) {
  final found = <int>[];
  final n = tubes.length;
  for (var from = 0; from < n; from++) {
    final src = tubes[from];
    if (src.isEmpty) continue;
    final run = _topRun(src);
    for (var to = 0; to < n; to++) {
      if (to == from) continue;
      final space = capacity - tubes[to].length;
      if (space < 1) continue;
      final int k;
      if (splits) {
        if (run < 2) continue;
        k = 1;
      } else {
        if (run != src.length || tubes[to].isEmpty) continue;
        if (src.length > space) continue;
        k = src.length;
      }
      final added = <Move>[];
      if (!_transfer(tubes, from, to, k, capacity, history, added)) continue;
      _undoAdded(tubes, added, history);
      found.add(from | (to << 8) | (k << 16));
    }
  }
  if (found.isEmpty) return null;
  return found[rng.nextInt(found.length)];
}

void _commitEdge(
  List<List<int>> tubes,
  int edge,
  List<String> history,
  List<Move> guide,
  int capacity,
) {
  final added = <Move>[];
  final ok = _transfer(
    tubes,
    edge & 255,
    (edge >> 8) & 255,
    edge >> 16,
    capacity,
    history,
    added,
  );
  if (!ok) throw StateError('reverse move disappeared');
  guide.addAll(added);
}

void _undoAdded(List<List<int>> tubes, List<Move> added, List<String> history) {
  for (var i = added.length - 1; i >= 0; i--) {
    _applyMove(tubes, added[i]);
    if (history.length > 1) history.removeLast();
  }
}

int _segments(List<List<int>> tubes) {
  var n = 0;
  for (final tube in tubes) {
    if (tube.isEmpty) continue;
    n++;
    for (var i = 1; i < tube.length; i++) {
      if (tube[i] != tube[i - 1]) n++;
    }
  }
  return n;
}

void _undoLast(List<List<int>> tubes, List<Move> guide, List<String> history) {
  _applyMove(tubes, guide.removeLast());
  if (history.length > 1) history.removeLast();
}

void _applyMove(List<List<int>> tubes, Move move) {
  final src = tubes[move.from];
  final dst = tubes[move.to];
  final start = src.length - move.count;
  for (var i = start; i < src.length; i++) {
    dst.add(src[i]);
  }
  src.removeRange(start, src.length);
}

/// Moves [count] layers from [from] to [to]. Appends the pour that undoes it.
bool _transfer(
  List<List<int>> tubes,
  int from,
  int to,
  int count,
  int capacity,
  List<String> recent,
  List<Move> added,
) {
  final src = tubes[from];
  final dst = tubes[to];
  if (from == to || count < 1 || src.length < count) return false;
  if (dst.length + count > capacity) return false;
  final run = _topRun(src);
  if (count > run) return false;
  if (dst.isNotEmpty && dst.last == src.last) return false;
  final clears = count == src.length;
  if (!clears && count >= run) return false;
  if (clears && dst.isEmpty) return false;

  final colour = src.last;
  for (var i = 0; i < count; i++) {
    dst.add(colour);
  }
  src.removeRange(src.length - count, src.length);
  final key = _key(tubes);
  final start = recent.length > 10 ? recent.length - 10 : 0;
  for (var i = start; i < recent.length; i++) {
    if (recent[i] != key) continue;
    dst.removeRange(dst.length - count, dst.length);
    for (var n = 0; n < count; n++) {
      src.add(colour);
    }
    return false;
  }
  recent.add(key);
  added.add(Move(from: to, to: from, count: count));
  return true;
}

bool _replay(Board board, List<Move> moves) {
  var current = board;
  for (final move in moves) {
    if (!GameEngine.isUseful(current, move.from, move.to)) return false;
    final poured = GameEngine.pour(current, move.from, move.to);
    if (poured == null || poured.move != move) return false;
    current = poured.board;
  }
  return GameEngine.isWon(current);
}

List<List<int>> _copy(List<List<int>> tubes) => [
  for (final tube in tubes) [...tube],
];

void _assign(List<List<int>> dst, List<List<int>> src) {
  for (var i = 0; i < dst.length; i++) {
    dst[i]
      ..clear()
      ..addAll(src[i]);
  }
}

Board _board(List<List<int>> tubes, int capacity) =>
    Board.layers(capacity, tubes);

int _emptyCount(List<List<int>> tubes) {
  var n = 0;
  for (final tube in tubes) {
    if (tube.isEmpty) n++;
  }
  return n;
}

bool _won(List<List<int>> tubes, int capacity) {
  for (final tube in tubes) {
    if (tube.isEmpty) continue;
    if (tube.length != capacity) return false;
    final colour = tube.first;
    for (final layer in tube) {
      if (layer != colour) return false;
    }
  }
  return true;
}

int _topRun(List<int> layers) {
  final colour = layers.last;
  var run = 1;
  for (var i = layers.length - 2; i >= 0; i--) {
    if (layers[i] != colour) break;
    run++;
  }
  return run;
}

String _key(List<List<int>> tubes) {
  final parts = [for (final tube in tubes) tube.join(',')];
  parts.sort();
  return parts.join('|');
}
