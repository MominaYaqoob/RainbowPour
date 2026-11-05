import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/save_data.dart';
import 'package:rainbow_pour/game/engine.dart';
import 'package:rainbow_pour/game/generator.dart';
import 'package:rainbow_pour/game/resume.dart';

InProgress _save(
  GeneratedLevel g, {
  int? level,
  int? capacity,
  List<List<int>>? bottles,
  bool extra = false,
  List<List<int>> history = const [],
}) {
  return InProgress(
    mode: 'level',
    level: level ?? g.spec.level,
    capacity: capacity ?? g.board.capacity,
    bottles:
        bottles ??
        [for (final b in g.board.bottles) b.layers.toList(), if (extra) []],
    moves: history.length,
    history: history,
    extraBottleUsed: extra,
  );
}

void main() {
  final g = LevelGenerator.forLevel(12);

  test('a save of this level comes back as it was', () {
    final first = g.solution.first;
    final poured = GameEngine.pour(g.board, first.from, first.to)!;
    final saved = _save(
      g,
      bottles: [for (final b in poured.board.bottles) b.layers.toList()],
      history: [
        [first.from, first.to, first.count],
      ],
    );
    final state = restoreProgress(saved, g)!;
    expect(state.board, poured.board);
    expect(state.moves, 1);
    expect(state.history.single, first);
  });

  test('a save with an extra bottle needs one more bottle', () {
    expect(restoreProgress(_save(g, extra: true), g), isNotNull);
    // claims an extra bottle but has none
    final wrong = InProgress(
      mode: 'level',
      level: 12,
      capacity: g.board.capacity,
      bottles: [for (final b in g.board.bottles) b.layers.toList()],
      moves: 0,
      history: [],
      extraBottleUsed: true,
    );
    expect(restoreProgress(wrong, g), isNull);
  });

  test('a save from another level or board is ignored', () {
    expect(restoreProgress(null, g), isNull);
    expect(restoreProgress(_save(g, level: 13), g), isNull);
    expect(
      restoreProgress(_save(g, capacity: g.board.capacity + 1), g),
      isNull,
    );
    // one unit of a colour missing
    final broken = [for (final b in g.board.bottles) b.layers.toList()];
    broken.firstWhere((b) => b.isNotEmpty).removeLast();
    expect(restoreProgress(_save(g, bottles: broken), g), isNull);
  });

  test('a history that points at bottles that do not exist is ignored', () {
    expect(
      restoreProgress(
        _save(
          g,
          history: [
            [0, 999, 1],
          ],
        ),
        g,
      ),
      isNull,
    );
  });
}
