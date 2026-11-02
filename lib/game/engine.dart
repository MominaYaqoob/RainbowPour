import 'models.dart';

/// Water-sort rules: which pours are legal, when a level is over, and undo.
///
/// No Flutter here, so the rules can be tested on their own.
abstract final class GameEngine {
  /// How many layers a pour would move. `0` means the pour is illegal.
  static int pourCount(Board board, int from, int to) {
    if (!_onBoard(board, from) || !_onBoard(board, to) || from == to) {
      return 0;
    }
    final source = board.bottles[from];
    final target = board.bottles[to];
    if (source.isEmpty || target.space == 0) return 0;
    if (!target.isEmpty && target.topColour != source.topColour) return 0;
    final run = source.topRun;
    return run < target.space ? run : target.space;
  }

  static bool canPour(Board board, int from, int to) =>
      pourCount(board, from, to) > 0;

  /// A legal pour that can still change the puzzle.
  ///
  /// Sliding a one-colour bottle into an empty one only changes its slot,
  /// so the solver, the hint, and [isStuck] ignore it.
  static bool isUseful(Board board, int from, int to) {
    if (pourCount(board, from, to) == 0) return false;
    if (!board.bottles[to].isEmpty) return true;
    return !_oneColour(board.bottles[from]);
  }

  /// Pours the top run, or as much of it as fits. Returns null when illegal.
  static ({Board board, Move move})? pour(Board board, int from, int to) {
    final count = pourCount(board, from, to);
    if (count == 0) return null;
    final source = board.bottles[from];
    final target = board.bottles[to];
    final split = source.layers.length - count;
    final next = board
        .replace(from, Bottle(source.capacity, source.layers.sublist(0, split)))
        .replace(
          to,
          Bottle(target.capacity, [
            ...target.layers,
            ...source.layers.sublist(split),
          ]),
        );
    return (board: next, move: Move(from: from, to: to, count: count));
  }

  /// Puts [move]'s layers back. Used by [GameState.undo].
  static Board reverse(Board board, Move move) {
    final source = board.bottles[move.from];
    final target = board.bottles[move.to];
    if (move.count < 1 ||
        move.count > target.layers.length ||
        source.layers.length + move.count > source.capacity) {
      throw ArgumentError.value(move, 'move', 'cannot be reversed on $board');
    }
    final split = target.layers.length - move.count;
    return board
        .replace(
          move.to,
          Bottle(target.capacity, target.layers.sublist(0, split)),
        )
        .replace(
          move.from,
          Bottle(source.capacity, [
            ...source.layers,
            ...target.layers.sublist(split),
          ]),
        );
  }

  /// Won when every bottle is empty, or full of a single colour.
  static bool isWon(Board board) => board.bottles.every(_isSolved);

  /// Lost when the level is not won and no useful pour is left.
  static bool isStuck(Board board) => !isWon(board) && !hasUsefulMove(board);

  static bool hasUsefulMove(Board board) {
    final bottles = board.bottles;
    for (var from = 0; from < bottles.length; from++) {
      if (bottles[from].isEmpty) continue;
      for (var to = 0; to < bottles.length; to++) {
        if (isUseful(board, from, to)) return true;
      }
    }
    return false;
  }

  /// Every legal pour, scanning sources from left to right.
  ///
  /// This includes slot-only pours. [usefulMoves] is the set that can win.
  static List<Move> legalMoves(Board board) => _moves(board, usefulOnly: false);

  /// Legal pours that are not just relocating a one-colour bottle.
  static List<Move> usefulMoves(Board board) => _moves(board, usefulOnly: true);

  static List<Move> _moves(Board board, {required bool usefulOnly}) {
    final moves = <Move>[];
    for (var from = 0; from < board.bottles.length; from++) {
      for (var to = 0; to < board.bottles.length; to++) {
        final count = pourCount(board, from, to);
        if (count == 0) continue;
        if (usefulOnly && !isUseful(board, from, to)) continue;
        moves.add(Move(from: from, to: to, count: count));
      }
    }
    return List<Move>.unmodifiable(moves);
  }

  /// One extra empty bottle, same capacity as the rest.
  static Board addEmptyBottle(Board board) {
    return Board([...board.bottles, Bottle(board.capacity)]);
  }

  static bool _onBoard(Board board, int index) =>
      index >= 0 && index < board.bottles.length;

  static bool _oneColour(Bottle bottle) {
    final layers = bottle.layers;
    if (layers.length <= 1) return true;
    final colour = layers.first;
    for (final layer in layers) {
      if (layer != colour) return false;
    }
    return true;
  }

  static bool _isSolved(Bottle bottle) {
    if (bottle.isEmpty) return true;
    if (!bottle.isFull) return false;
    final colour = bottle.layers.first;
    for (final layer in bottle.layers) {
      if (layer != colour) return false;
    }
    return true;
  }
}

/// One play: the board, the move count, and the pours that can be undone.
class GameState {
  GameState({
    required this.board,
    this.moves = 0,
    List<Move> history = const [],
  }) : history = List<Move>.unmodifiable(history);

  final Board board;

  /// Successful pours plus undos. Undos count so they cannot raise the score.
  final int moves;

  /// Undo stack, oldest pour first.
  final List<Move> history;

  bool get isWon => GameEngine.isWon(board);

  bool get isStuck => GameEngine.isStuck(board);

  bool get canUndo => history.isNotEmpty;

  /// Applies a pour. Returns null and changes nothing when it is illegal.
  /// Several layers of one colour still count as a single move.
  GameState? pour(int from, int to) {
    final poured = GameEngine.pour(board, from, to);
    if (poured == null) return null;
    return GameState(
      board: poured.board,
      moves: moves + 1,
      history: [...history, poured.move],
    );
  }

  /// Puts the bottles back to how they were before the last pour.
  ///
  /// [moves] still goes up by one: an undo counts, matching the star rule.
  GameState? undo() {
    if (history.isEmpty) return null;
    final last = history.last;
    return GameState(
      board: GameEngine.reverse(board, last),
      moves: moves + 1,
      history: history.sublist(0, history.length - 1),
    );
  }
}
