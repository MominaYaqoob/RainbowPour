import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/engine.dart';
import 'package:rainbow_pour/game/generator.dart';
import 'package:rainbow_pour/game/hint_planner.dart';
import 'package:rainbow_pour/game/models.dart';

/// Plays a level only by following hints, after a few wrong turns of its
/// own. Every level must still be won.
bool _playWithHints(int level) {
  final generated = LevelGenerator.forLevel(level);
  final planner = HintPlanner(generated.board, generated.solution);
  var board = generated.board;
  final history = <Move>[];
  final rng = Random(level);

  // a few random useful pours: the player leaves the level's own line
  for (var i = 0; i < 3 && !GameEngine.isWon(board); i++) {
    final moves = GameEngine.usefulMoves(board);
    if (moves.isEmpty) break;
    final move = moves[rng.nextInt(moves.length)];
    board = GameEngine.pour(board, move.from, move.to)!.board;
    history.add(move);
  }

  for (var step = 0; step < 600 && !GameEngine.isWon(board); step++) {
    final advice = planner.next(board, history);
    if (advice == null) return false;
    if (advice.isUndo) {
      for (var i = 0; i < advice.undoSteps; i++) {
        board = GameEngine.reverse(board, history.removeLast());
      }
    } else {
      final move = advice.move!;
      final poured = GameEngine.pour(board, move.from, move.to);
      if (poured == null) return false;
      board = poured.board;
      history.add(move);
    }
  }
  return GameEngine.isWon(board);
}

void main() {
  test('hints win small and big levels even after wrong turns', () {
    final failed = <int>[];
    for (var level = 2; level <= 300; level += 13) {
      if (!_playWithHints(level)) failed.add(level);
    }
    expect(failed, isEmpty, reason: 'levels not won by hints: $failed');
  });

  test('the starting board follows the level line to the end', () {
    for (final level in [2, 40, 120, 299]) {
      final generated = LevelGenerator.forLevel(level);
      final planner = HintPlanner(generated.board, generated.solution);
      var board = generated.board;
      var moves = 0;
      while (!GameEngine.isWon(board)) {
        final advice = planner.next(board, const []);
        expect(advice, isNotNull);
        expect(advice!.isUndo, isFalse);
        final move = advice.move!;
        board = GameEngine.pour(board, move.from, move.to)!.board;
        moves++;
        expect(moves, lessThan(500));
      }
    }
  });
}
