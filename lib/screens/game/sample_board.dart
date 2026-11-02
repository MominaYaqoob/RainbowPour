import '../../game/generator.dart';

/// The level the game screen draws. Layers come from a generated level that
/// was built off the UI isolate.
class SampleBoard {
  const SampleBoard(this.capacity, this.bottles);

  final int capacity;
  final List<List<int>> bottles;

  factory SampleBoard.fromGenerated(GeneratedLevel level) {
    return SampleBoard(level.board.capacity, [
      for (final bottle in level.board.bottles) bottle.layers.toList(),
    ]);
  }
}
