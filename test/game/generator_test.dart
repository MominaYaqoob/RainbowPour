import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/difficulty.dart';
import 'package:rainbow_pour/game/engine.dart';
import 'package:rainbow_pour/game/generator.dart';
import 'package:rainbow_pour/game/models.dart';

void main() {
  test('the same seed builds the same board', () {
    final spec = DifficultyCurve.specFor(42);
    final seed = 42 * 7919 + 13;
    final a = LevelGenerator.generate(spec, seed);
    final b = LevelGenerator.generate(spec, seed);

    expect(a.board, b.board);
    expect(a.par, b.par);
    expect(a.solution, b.solution);
    expect(LevelGenerator.forLevel(42).board, a.board);
  });

  test(
    'levels 1 to 500 generate, solve, and stay under the time budget',
    () {
      final pars = <int, int>{};
      const marks = [1, 10, 50, 100, 200, 300, 400, 500];
      var total = 0;
      var maxUs = 0;
      var maxLevel = 1;

      for (var level = 1; level <= 500; level++) {
        final spec = DifficultyCurve.specFor(level);
        final seed = level * 7919 + 13;
        final watch = Stopwatch()..start();
        final generated = LevelGenerator.generate(spec, seed);
        final us = watch.elapsedMicroseconds;
        total += us;
        if (us > maxUs) {
          maxUs = us;
          maxLevel = level;
        }
        _expectPlayable(generated.board, generated.solution, spec);
        expect(generated.par, generated.solution.length);
        expect(
          generated.par,
          greaterThanOrEqualTo(DifficultyCurve.parFloor(level)),
        );
        if (marks.contains(level)) pars[level] = generated.par;
      }

      final avgMs = total / 500 / 1000;
      final maxMs = maxUs / 1000;
      stdout.writeln(
        'levels 1-500: avg ${avgMs.toStringAsFixed(2)} ms, '
        'max ${maxMs.toStringAsFixed(2)} ms at level $maxLevel',
      );
      stdout.writeln(
        'par L1=${pars[1]} L10=${pars[10]} L50=${pars[50]} '
        'L100=${pars[100]} L200=${pars[200]} L300=${pars[300]} '
        'L400=${pars[400]} L500=${pars[500]}',
      );
      expect(pars[400], greaterThan(pars[10]! * 3 ~/ 2));
      expect(
        avgMs,
        lessThan(200),
        reason: 'average ${avgMs.toStringAsFixed(1)} ms',
      );
      expect(
        maxMs,
        lessThan(200),
        reason: 'max ${maxMs.toStringAsFixed(1)} ms',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

void _expectPlayable(Board board, List<Move> moves, LevelSpec spec) {
  final counts = List<int>.filled(spec.colors, 0);
  var empties = 0;
  for (final bottle in board.bottles) {
    expect(bottle.capacity, spec.capacity);
    if (bottle.isEmpty) {
      empties++;
      continue;
    }
    for (final colour in bottle.layers) {
      expect(colour, inInclusiveRange(0, spec.colors - 1));
      counts[colour]++;
    }
  }
  expect(board.bottles, hasLength(spec.bottles));
  expect(empties, 2);
  for (final count in counts) {
    expect(count, spec.capacity);
  }
  expect(GameEngine.isWon(board), isFalse);
  expect(GameEngine.isStuck(board), isFalse);

  var current = board;
  for (final move in moves) {
    expect(GameEngine.isUseful(current, move.from, move.to), isTrue);
    final poured = GameEngine.pour(current, move.from, move.to);
    expect(poured, isNotNull);
    expect(poured!.move, move);
    current = poured.board;
  }
  expect(GameEngine.isWon(current), isTrue);
}
