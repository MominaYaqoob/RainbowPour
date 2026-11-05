import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/difficulty.dart';
import 'package:rainbow_pour/game/engine.dart';
import 'package:rainbow_pour/game/generator.dart';
import 'package:rainbow_pour/game/level_repository.dart';
import 'package:rainbow_pour/game/models.dart';

void main() {
  test(
    'daily challenges stay in range and replay to a win',
    () {
      final dates = <DateTime>[
        for (var i = 0; i < 40; i++)
          DateTime(2024, 2, 1).add(Duration(days: i)),
        DateTime(2025, 12, 31),
        DateTime(2026, 1, 1),
      ];
      expect(dates.any((d) => d.month == 2 && d.day == 29), isTrue);
      expect(dates.any((d) => d.month == 3 && d.day == 1), isTrue);

      final times = <int>[];
      GeneratedLevel? first;
      GeneratedLevel? second;
      for (final day in dates) {
        final spec = DifficultyCurve.challengeSpecFor(day);
        expect(spec.level, DifficultyCurve.challengeLevel);
        expect(spec.isTutorial, isFalse);
        expect(spec.bottles, inInclusiveRange(25, 28));
        expect(spec.empties, inInclusiveRange(2, 3));
        expect(spec.colors, inInclusiveRange(1, DifficultyCurve.maxColors));
        expect(spec.colors, lessThanOrEqualTo(20));
        expect(spec.capacity, 4);
        expect(spec.duplicates, inInclusiveRange(0, spec.colors));
        expect(
          spec.bottles,
          lessThanOrEqualTo(DifficultyCurve.challengeLayoutMaxBottles),
        );
        expect(DifficultyCurve.challengeSeed(day), _yyyymmdd(day));
        // par floor must not call specFor(0)
        expect(DifficultyCurve.parFloorOf(spec), greaterThan(0));

        final watch = Stopwatch()..start();
        final generated = LevelGenerator.forChallenge(day);
        watch.stop();
        times.add(watch.elapsedMilliseconds);

        expect(generated.spec.bottles, spec.bottles);
        expect(generated.board.bottles.length, spec.bottles);
        expect(generated.board.capacity, 4);
        expect(
          _emptyCount(generated.board),
          greaterThanOrEqualTo(spec.empties),
        );
        expect(GameEngine.isWon(generated.board), isFalse);
        _expectColourTotals(generated.board, spec);

        final again = LevelGenerator.forChallenge(
          DateTime(day.year, day.month, day.day, 23, 59),
        );
        expect(again.board, generated.board);
        expect(again.solution, generated.solution);

        final won = _replay(generated.board, generated.solution);
        expect(GameEngine.isWon(won), isTrue);
        for (final bottle in won.bottles) {
          if (bottle.isEmpty) continue;
          expect(bottle.isFull, isTrue);
          expect(
            bottle.layers.every((layer) => layer == bottle.layers.first),
            isTrue,
          );
        }

        first ??= generated;
        second ??= day == dates[1] ? generated : null;
      }

      expect(second, isNotNull);
      expect(first!.board == second!.board, isFalse);

      final total = times.fold<int>(0, (sum, ms) => sum + ms);
      final avg = total / times.length;
      final max = times.reduce((a, b) => a > b ? a : b);
      // ignore: avoid_print
      print(
        'Challenge boards: avg ${avg.toStringAsFixed(1)} ms, '
        'max $max ms over ${times.length} dates',
      );
      expect(max, lessThan(1000), reason: 'one challenge took ${max}ms');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('the repository returns the same challenge as the generator', () async {
    final day = DateTime(2026, 11, 5);
    expect(DifficultyCurve.challengeSeed(day), 20261105);
    final direct = LevelGenerator.forChallenge(day);
    final loaded = await LevelRepository.getChallenge(day);
    expect(loaded.board, direct.board);
    expect(loaded.solution, direct.solution);
    expect(await LevelRepository.getChallenge(day), loaded);
  });
}

int _yyyymmdd(DateTime day) => int.parse(
  '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}',
);

int _emptyCount(Board board) =>
    board.bottles.where((bottle) => bottle.isEmpty).length;

void _expectColourTotals(Board board, LevelSpec spec) {
  final counts = <int, int>{};
  for (final bottle in board.bottles) {
    for (final layer in bottle.layers) {
      counts[layer] = (counts[layer] ?? 0) + 1;
    }
  }
  expect(counts.length, spec.colors);
  for (final total in counts.values) {
    expect(total == spec.capacity || total == spec.capacity * 2, isTrue);
  }
}

Board _replay(Board board, List<Move> line) {
  var current = board;
  expect(line, isNotEmpty);
  for (final move in line) {
    final step = GameEngine.pour(current, move.from, move.to);
    expect(step, isNotNull, reason: 'illegal pour $move');
    expect(step!.move.count, move.count);
    current = step.board;
  }
  return current;
}
