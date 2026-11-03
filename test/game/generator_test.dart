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
    'every level generates, solves, and stays under the time budget',
    () {
      final pars = <int, int>{};
      const marks = [1, 10, 50, 100, 150, 200, 250, 300];
      var total = 0;
      var maxUs = 0;
      var maxLevel = 1;

      for (var level = 1; level <= DifficultyCurve.maxLevel; level++) {
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
        // the tutorial is a fixed three-pour board, shorter on purpose
        if (!spec.isTutorial) {
          expect(
            generated.par,
            greaterThanOrEqualTo(DifficultyCurve.parFloor(level)),
          );
        }
        if (marks.contains(level)) pars[level] = generated.par;
      }

      final avgMs = total / DifficultyCurve.maxLevel / 1000;
      final maxMs = maxUs / 1000;
      stdout.writeln(
        'levels 1-300: avg ${avgMs.toStringAsFixed(2)} ms, '
        'max ${maxMs.toStringAsFixed(2)} ms at level $maxLevel',
      );
      stdout.writeln(
        'par L1=${pars[1]} L10=${pars[10]} L50=${pars[50]} '
        'L100=${pars[100]} L150=${pars[150]} L200=${pars[200]} '
        'L250=${pars[250]} L300=${pars[300]}',
      );
      expect(pars[250], greaterThan(pars[10]! * 3 ~/ 2));
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
  final counts = <int, int>{};
  var empties = 0;
  var partial = 0;
  for (final bottle in board.bottles) {
    expect(bottle.capacity, spec.capacity);
    if (bottle.isEmpty) {
      empties++;
      continue;
    }
    for (final colour in bottle.layers) {
      expect(colour, inInclusiveRange(0, DifficultyCurve.maxColors - 1));
      counts[colour] = (counts[colour] ?? 0) + 1;
    }
  }
  expect(board.bottles, hasLength(spec.bottles));
  expect(empties, greaterThanOrEqualTo(spec.empties));
  expect(counts.length, spec.colors);
  var units = 0;
  for (final count in counts.values) {
    // every colour fills one bottle, or two for the repeated colours
    expect(count % spec.capacity, 0);
    expect(count ~/ spec.capacity, inInclusiveRange(1, 2));
    units += count;
  }
  expect(units, spec.fullBottles * spec.capacity);
  expect(partial, 0);
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
