import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/engine.dart';
import 'package:rainbow_pour/game/models.dart';
import 'package:rainbow_pour/game/solver.dart';

void main() {
  test('solves a short board and the hint is that first pour', () {
    final board = Board.layers(2, [
      [0, 1],
      [1],
      [0],
      [],
    ]);

    final moves = Solver.solve(board);
    expect(moves, isNotNull);
    expect(moves, hasLength(2));
    expect(Solver.hint(board), moves!.first);
    expect(_wins(board, moves), isTrue);
  });

  test('a stuck board has no solution and no hint', () {
    final board = Board.layers(4, [
      [0, 0],
      [1, 1, 1],
      [],
    ]);

    expect(GameEngine.isStuck(board), isTrue);
    expect(Solver.solve(board), isNull);
    expect(Solver.hint(board), isNull);
  });

  test('hint falls back to a useful pour when the budget is empty', () {
    final board = Board.layers(2, [
      [0, 1],
      [1],
      [0],
      [],
    ]);
    final move = Solver.hint(board, maxNodes: 0);

    expect(move, isNotNull);
    expect(GameEngine.isUseful(board, move!.from, move.to), isTrue);
  });

  test('the same board solves to the same line twice', () {
    final board = Board.layers(3, [
      [0, 1],
      [1, 1],
      [0, 0],
      [],
      [],
    ]);
    expect(Solver.solve(board), Solver.solve(board));
  });

  test('stars follow par, and the first three levels are always 3', () {
    expect(Stars.count(level: 2, par: 4, moves: 40), 3);
    expect(Stars.count(level: 8, par: 10, moves: 13), 3);
    expect(Stars.count(level: 8, par: 10, moves: 14), 2);
    expect(Stars.count(level: 8, par: 10, moves: 17), 2);
    expect(Stars.count(level: 8, par: 10, moves: 18), 1);
  });
}

bool _wins(Board board, List<Move> moves) {
  var current = board;
  for (final move in moves) {
    final poured = GameEngine.pour(current, move.from, move.to);
    if (poured == null || poured.move != move) return false;
    current = poured.board;
  }
  return GameEngine.isWon(current);
}
