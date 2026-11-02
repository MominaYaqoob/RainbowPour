import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/game/engine.dart';
import 'package:rainbow_pour/game/models.dart';

void main() {
  group('pours', () {
    test('pours the whole top run into an empty bottle', () {
      final start = Board.layers(4, [
        [1, 0, 0],
        [],
      ]);
      final poured = GameEngine.pour(start, 0, 1)!;

      expect(poured.move, const Move(from: 0, to: 1, count: 2));
      expect(
        poured.board,
        Board.layers(4, [
          [1],
          [0, 0],
        ]),
      );
    });

    test('pours onto a bottle whose top colour matches', () {
      final start = Board.layers(4, [
        [5],
        [3, 3],
        [1, 5, 5],
      ]);
      final poured = GameEngine.pour(start, 2, 0)!;

      expect(poured.move.count, 2);
      expect(
        poured.board,
        Board.layers(4, [
          [5, 5, 5],
          [3, 3],
          [1],
        ]),
      );
    });

    test('allows pouring a uniform bottle into an empty one', () {
      final start = Board.layers(4, [
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [],
      ]);

      expect(GameEngine.canPour(start, 0, 2), isTrue);
      expect(GameEngine.pour(start, 0, 2)!.move.count, 4);
    });

    test('a multi-layer pour counts as one move', () {
      final start = GameState(
        board: Board.layers(4, [
          [0, 0, 0],
          [],
        ]),
      );
      final next = start.pour(0, 1)!;

      expect(next.history.single.count, 3);
      expect(next.moves, 1);
      expect(start.moves, 0);
    });

    test('rejects an empty source, a full target, and a colour mismatch', () {
      final board = Board.layers(4, [
        [],
        [1],
        [0, 0, 0, 0],
        [0, 0],
        [0],
      ]);

      expect(GameEngine.pour(board, 0, 1), isNull);
      expect(GameEngine.pour(board, 3, 2), isNull);
      expect(GameEngine.pour(board, 1, 3), isNull);
      expect(GameEngine.canPour(board, 3, 4), isTrue);
    });

    test('rejects pouring a bottle into itself or off the board', () {
      final board = Board.layers(4, [
        [0, 0],
        [],
      ]);

      expect(GameEngine.pour(board, 0, 0), isNull);
      expect(GameEngine.pour(board, -1, 0), isNull);
      expect(GameEngine.pour(board, 0, 2), isNull);
    });

    test('an illegal pour leaves the session unchanged', () {
      final state = GameState(
        board: Board.layers(4, [
          [0],
          [1],
        ]),
      );

      expect(state.pour(0, 1), isNull);
      expect(state.moves, 0);
      expect(state.history, isEmpty);
    });

    test('leaves the previous board unchanged', () {
      final start = Board.layers(4, [
        [0, 0],
        [],
      ]);
      final copy = Board.layers(4, [
        [0, 0],
        [],
      ]);

      GameEngine.pour(start, 0, 1);
      expect(start, copy);
    });
  });

  group('partial pour', () {
    test('moves only what fits, and only the top colour', () {
      // Three 0s on top, but the target has room for one.
      final start = Board.layers(4, [
        [2, 0, 0, 0],
        [1, 1, 0],
      ]);
      final poured = GameEngine.pour(start, 0, 1)!;

      expect(poured.move, const Move(from: 0, to: 1, count: 1));
      expect(
        poured.board,
        Board.layers(4, [
          [2, 0, 0],
          [1, 1, 0, 0],
        ]),
      );
      expect(GameEngine.isStuck(start), isFalse);
    });
  });

  group('win', () {
    test('wins when every filled bottle is full of one colour', () {
      final board = Board.layers(4, [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [2, 2, 2, 2],
        [],
        [],
      ]);

      expect(GameEngine.isWon(board), isTrue);
      expect(GameEngine.isStuck(board), isFalse);
    });

    test('a finished board with nowhere to pour is still a win', () {
      final board = Board.layers(2, [
        [0, 0],
        [1, 1],
      ]);

      expect(GameEngine.isWon(board), isTrue);
      expect(GameEngine.legalMoves(board), isEmpty);
      expect(GameEngine.isStuck(board), isFalse);
    });

    test('does not win while a single colour is short of full', () {
      final board = Board.layers(4, [
        [0, 0, 0],
        [1, 1, 1, 1],
        [],
      ]);

      expect(GameEngine.isWon(board), isFalse);
    });

    test('does not win while a full bottle is mixed', () {
      final board = Board.layers(4, [
        [0, 0, 1, 1],
        [1, 1, 0, 0],
        [],
        [],
      ]);

      expect(GameEngine.isWon(board), isFalse);
    });
  });

  group('dead end', () {
    test('is stuck when free space exists but no pour is legal', () {
      // Tops differ, and neither bottle is empty, so the space cannot be used.
      final board = Board.layers(4, [
        [0, 1],
        [1, 0],
      ]);

      expect(GameEngine.isWon(board), isFalse);
      expect(GameEngine.legalMoves(board), isEmpty);
      expect(GameEngine.isStuck(board), isTrue);
      expect(GameState(board: board).isStuck, isTrue);
    });

    test('is stuck when every bottle is full and mixed', () {
      final board = Board.layers(3, [
        [0, 1, 0],
        [1, 0, 1],
      ]);

      expect(GameEngine.isStuck(board), isTrue);
    });

    test('relocating a one-colour bottle does not count as progress', () {
      final board = Board.layers(4, [
        [0, 0],
        [1, 1, 1],
        [],
      ]);

      expect(GameEngine.canPour(board, 0, 2), isTrue);
      expect(GameEngine.legalMoves(board), isNotEmpty);
      expect(GameEngine.usefulMoves(board), isEmpty);
      expect(GameEngine.isStuck(board), isTrue);
    });
  });

  group('undo', () {
    test('restores every bottle and counts the undo as a move', () {
      final start = Board.layers(4, [
        [1, 0, 0, 0],
        [2, 2],
        [],
      ]);
      final poured = GameState(board: start).pour(0, 2)!;
      final back = poured.undo()!;

      expect(
        poured.board,
        Board.layers(4, [
          [1],
          [2, 2],
          [0, 0, 0],
        ]),
      );
      expect(back.board, start);
      expect(back.history, isEmpty);
      expect(back.moves, 2);
      expect(back.undo(), isNull);
    });

    test('restores a partial pour exactly', () {
      final start = Board.layers(4, [
        [2, 0, 0, 0],
        [1, 1, 0],
      ]);
      final back = GameState(board: start).pour(0, 1)!.undo()!;

      expect(back.board, start);
    });

    test('walks back through two pours', () {
      final start = Board.layers(4, [
        [3, 0, 0],
        [1, 0],
        [],
        [2, 2],
      ]);
      final once = GameState(board: start).pour(0, 1)!;
      final twice = once.pour(3, 2)!;
      final undone = twice.undo()!;

      expect(undone.board, once.board);
      expect(undone.undo()!.board, start);
      expect(undone.undo()!.moves, 4);
    });
  });

  test('addEmptyBottle appends one empty bottle of the same capacity', () {
    final start = Board.layers(5, [
      [0, 0],
      [],
    ]);
    final next = GameEngine.addEmptyBottle(start);

    expect(start.bottles, hasLength(2));
    expect(next.bottles, hasLength(3));
    expect(next.bottles.last.isEmpty, isTrue);
    expect(next.capacity, 5);
  });
}
