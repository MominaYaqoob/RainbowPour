/// A bottle of liquid. [layers] run from the bottom to the top as colour ids.
class Bottle {
  Bottle(this.capacity, [List<int> layers = const []])
    : layers = List<int>.unmodifiable(layers) {
    if (capacity < 1) {
      throw ArgumentError.value(capacity, 'capacity', 'must be at least 1');
    }
    if (this.layers.length > capacity) {
      throw ArgumentError('a bottle cannot hold more than $capacity layers');
    }
  }

  final int capacity;

  /// Colour ids, bottom first.
  final List<int> layers;

  bool get isEmpty => layers.isEmpty;

  bool get isFull => layers.length == capacity;

  /// How many more layers fit.
  int get space => capacity - layers.length;

  /// Colour of the top layer, or null when the bottle is empty.
  int? get topColour => layers.isEmpty ? null : layers.last;

  /// How many layers of [topColour] sit together at the top.
  int get topRun {
    if (layers.isEmpty) return 0;
    final colour = layers.last;
    var run = 1;
    for (var i = layers.length - 2; i >= 0; i--) {
      if (layers[i] != colour) break;
      run++;
    }
    return run;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Bottle ||
        other.capacity != capacity ||
        other.layers.length != layers.length) {
      return false;
    }
    for (var i = 0; i < layers.length; i++) {
      if (other.layers[i] != layers[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(capacity, Object.hashAll(layers));

  @override
  String toString() => '$layers/$capacity';
}

/// The bottles on the table. Every bottle has the same [capacity].
class Board {
  Board(List<Bottle> bottles) : bottles = List<Bottle>.unmodifiable(bottles) {
    if (this.bottles.isEmpty) {
      throw ArgumentError('a board needs at least one bottle');
    }
    final capacity = this.bottles.first.capacity;
    for (final bottle in this.bottles) {
      if (bottle.capacity != capacity) {
        throw ArgumentError('every bottle on a board shares one capacity');
      }
    }
  }

  /// [layers] is one stack per bottle, each stack bottom to top.
  factory Board.layers(int capacity, List<List<int>> layers) {
    return Board([for (final stack in layers) Bottle(capacity, stack)]);
  }

  final List<Bottle> bottles;

  int get capacity => bottles.first.capacity;

  Board replace(int index, Bottle bottle) {
    final next = [...bottles];
    next[index] = bottle;
    return Board(next);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Board || other.bottles.length != bottles.length) return false;
    for (var i = 0; i < bottles.length; i++) {
      if (other.bottles[i] != bottles[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(bottles);

  @override
  String toString() => bottles.join(' ');
}

/// One pour: [count] top layers move from bottle [from] to bottle [to].
class Move {
  const Move({required this.from, required this.to, required this.count});

  final int from;
  final int to;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.count == count;

  @override
  int get hashCode => Object.hash(from, to, count);

  @override
  String toString() => '$from->$to x$count';
}
