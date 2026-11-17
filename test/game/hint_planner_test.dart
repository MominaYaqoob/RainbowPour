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

  group('nextAsync (the isolate version)', () {
    /// A board a few random pours away from the level's own line, with the
    /// player's history.
    ({Board board, List<Move> history}) wander(int level, int pours) {
      final generated = LevelGenerator.forLevel(level);
      var board = generated.board;
      final history = <Move>[];
      final rng = Random(level * 31 + pours);
      for (var i = 0; i < pours && !GameEngine.isWon(board); i++) {
        final moves = GameEngine.usefulMoves(board);
        if (moves.isEmpty) break;
        final move = moves[rng.nextInt(moves.length)];
        board = GameEngine.pour(board, move.from, move.to)!.board;
        history.add(move);
      }
      return (board: board, history: history);
    }

    test('gives the same advice as the synchronous version', () async {
      var undoCases = 0;
      for (final level in [2, 5, 9, 15, 30, 60, 100, 109, 150, 250]) {
        for (final pours in [0, 2, 5]) {
          final generated = LevelGenerator.forLevel(level);
          final a = HintPlanner(generated.board, generated.solution);
          final b = HintPlanner(generated.board, generated.solution);
          final w = wander(level, pours);
          final sync = a.next(w.board, w.history);
          final async = await b.nextAsync(w.board, w.history);
          expect(async?.isUndo, sync?.isUndo, reason: 'level $level/$pours');
          expect(async?.move, sync?.move, reason: 'level $level/$pours');
          expect(
            async?.undoSteps,
            sync?.undoSteps,
            reason: 'level $level/$pours',
          );
          if (sync != null && sync.isUndo) undoCases++;
        }
      }
      // ignore: avoid_print
      print('nextAsync compared 30 boards, undo advice in $undoCases');
    });

    test('a won board has no advice', () async {
      final generated = LevelGenerator.forLevel(2);
      final planner = HintPlanner(generated.board, generated.solution);
      var board = generated.board;
      for (final move in generated.solution) {
        board = GameEngine.pour(board, move.from, move.to)!.board;
      }
      expect(GameEngine.isWon(board), isTrue);
      expect(await planner.nextAsync(board, const []), isNull);
    });

    test('what the isolate found is remembered for the next hint', () async {
      final generated = LevelGenerator.forLevel(150);
      final planner = HintPlanner(generated.board, generated.solution);
      final w = wander(150, 4);
      final first = await planner.nextAsync(w.board, w.history);
      final second = planner.next(w.board, w.history);
      expect(second?.move, first?.move);
      expect(second?.isUndo, first?.isUndo);
    });

    test(
      'a hint search returns well inside a second on this machine',
      () async {
        final generated = LevelGenerator.forLevel(250);
        final planner = HintPlanner(generated.board, generated.solution);
        final w = wander(250, 6);
        final watch = Stopwatch()..start();
        await planner.nextAsync(w.board, w.history);
        watch.stop();
        expect(watch.elapsedMilliseconds, lessThan(3000));
      },
    );
  });
}
