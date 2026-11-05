import 'engine.dart';
import 'models.dart';
import 'solver.dart';

/// What a hint says: pour one bottle into another, or undo some moves.
class HintAdvice {
  const HintAdvice.move(Move this.move) : undoSteps = 0;
  const HintAdvice.undo(this.undoSteps) : move = null;

  final Move? move;

  /// How many moves to undo to get back on a board that can be won.
  final int undoSteps;

  bool get isUndo => move == null;
}

/// Hints that always lead somewhere. Every move it returns is part of a line
/// that was checked all the way to a win, and when the player is on a board it
/// cannot finish it says how far to undo.
///
/// In order: the level's own solution line (the starting board is always on
/// it), the searched solution for small boards, a beam search for big ones,
/// and last "undo N moves" back to the most recent board on the level's line.
class HintPlanner {
  HintPlanner(Board start, List<Move> solution) {
    var board = start;
    for (final move in solution) {
      _line[_key(board)] = move;
      final poured = GameEngine.pour(board, move.from, move.to);
      if (poured == null) break;
      board = poured.board;
    }
  }

  /// Board key to the next pour of the level's own solution.
  final Map<String, Move> _line = {};

  /// Board key to the next pour of a line found by search.
  final Map<String, Move> _found = {};

  static const _beamWidth = 10;
  static const _beamDepth = 150;

  /// A text for a board with its bottles in place. Empty bottles at the end
  /// are ignored, so adding an extra bottle does not change the key.
  static String _key(Board board) {
    final parts = [for (final b in board.bottles) b.layers.join(',')];
    while (parts.isNotEmpty && parts.last.isEmpty) {
      parts.removeLast();
    }
    return parts.join('|');
  }

  /// The advice for [board]. [history] is the player's pours so far, oldest
  /// first. Null only if the board is already won.
  HintAdvice? next(Board board, List<Move> history) {
    if (GameEngine.isWon(board)) return null;
    final key = _key(board);

    final known = _line[key] ?? _found[key];
    if (known != null) return HintAdvice.move(known);

    final solved = Solver.solve(board);
    if (solved != null && solved.isNotEmpty) {
      _remember(board, solved);
      return HintAdvice.move(solved.first);
    }

    final beam = _beam(board);
    if (beam != null && beam.isNotEmpty) {
      _remember(board, beam);
      return HintAdvice.move(beam.first);
    }

    // Walk back through the player's pours to a board on the level's line.
    var back = board;
    for (var steps = 1; steps <= history.length; steps++) {
      final move = history[history.length - steps];
      try {
        back = GameEngine.reverse(back, move);
      } on ArgumentError {
        break;
      }
      if (_line.containsKey(_key(back))) return HintAdvice.undo(steps);
    }
    return null;
  }

  void _remember(Board board, List<Move> line) {
    var current = board;
    for (final move in line) {
      _found[_key(current)] = move;
      final poured = GameEngine.pour(current, move.from, move.to);
      if (poured == null) return;
      current = poured.board;
    }
  }

  /// Keeps the [_beamWidth] best boards at each depth, ranked by
  /// [Solver.potential]. Returns a line that ends on a won board, or null.
  static List<Move>? _beam(Board start) {
    var layer = [_Node(start, null, null, Solver.potential(start))];
    final seen = <String>{Solver.boardKey(start)};
    for (var depth = 1; depth <= _beamDepth; depth++) {
      final next = <_Node>[];
      for (final node in layer) {
        for (final move in GameEngine.usefulMoves(node.board)) {
          final after = GameEngine.pour(node.board, move.from, move.to)!.board;
          if (!seen.add(Solver.boardKey(after))) continue;
          if (GameEngine.isWon(after)) {
            final line = <Move>[move];
            for (var p = node; p.move != null; p = p.parent!) {
              line.add(p.move!);
            }
            return line.reversed.toList();
          }
          if (!GameEngine.hasUsefulMove(after)) continue;
          next.add(_Node(after, node, move, Solver.potential(after)));
        }
      }
      if (next.isEmpty) return null;
      next.sort((a, b) => a.score.compareTo(b.score));
      layer = next.length > _beamWidth ? next.sublist(0, _beamWidth) : next;
    }
    return null;
  }
}

class _Node {
  _Node(this.board, this.parent, this.move, this.score);

  final Board board;
  final _Node? parent;
  final Move? move;
  final int score;
}
