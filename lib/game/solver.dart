import 'dart:typed_data';

import 'engine.dart';
import 'models.dart';

/// A bottle is one int: colour ids (plus one) in four bits per layer from the
/// bottom, and the layer count above bit 24. Six layers is the most we pack.
/// (Five bits per layer was tried for 20 colours and broke the search.)
const int _bits = 4;
const int _mask = 15;
const int _lenShift = 24;
const int _maxLayers = 6;

/// Best-first search over useful pours, plus a hint when the search is short.
///
/// The visited set stores a sorted pack of bottle ints (one int per bottle).
/// The hot loop writes into that table and a state arena; it does not allocate.
abstract final class Solver {
  /// Hard stop for a full search. Generation and hints use a smaller budget.
  static const maxNodes = 300000;

  /// Budget that still finishes quickly on a generated level.
  static const fastNodes = 4000;

  static List<Move>? solve(
    Board board, {
    int maxNodes = fastNodes,
    List<Move>? prefer,
  }) {
    if (maxNodes < 1) return null;
    // The search packs a colour into four bits, so colours are renumbered
    // 0, 1, 2 ... first. More than 14 different colours do not fit, so big
    // boards use the greedy hint instead.
    final ids = <int, int>{};
    for (final bottle in board.bottles) {
      for (final layer in bottle.layers) {
        ids.putIfAbsent(layer, () => ids.length);
      }
    }
    if (ids.length > 14 || board.capacity > _maxLayers) return null;
    final packed = Board([
      for (final bottle in board.bottles)
        Bottle(bottle.capacity, [
          for (final layer in bottle.layers) ids[layer]!,
        ]),
    ]);
    if (maxNodes > Solver.maxNodes) maxNodes = Solver.maxNodes;
    return _Search(packed, maxNodes, prefer).run();
  }

  /// A canonical text for a board: bottles sorted, so two boards that only
  /// differ by the order of the bottles have the same key.
  static String boardKey(Board board) {
    final parts = [for (final bottle in board.bottles) bottle.layers.join(',')]
      ..sort();
    return parts.join('|');
  }

  /// First move of a solution, or a greedy useful pour if the budget runs out.
  ///
  /// [visited] holds the [boardKey] of every board the player has already
  /// been on. The greedy hint never leads back to one of them, so following
  /// hints cannot go round in circles.
  static Move? hint(
    Board board, {
    int maxNodes = fastNodes,
    Set<String>? visited,
  }) {
    final solved = solve(board, maxNodes: maxNodes);
    if (solved != null) {
      if (solved.isEmpty) return null;
      final first = solved.first;
      final after = GameEngine.pour(board, first.from, first.to);
      final seen =
          after != null && visited?.contains(boardKey(after.board)) == true;
      // a searched line that leads back to an old board is not followed
      if (!seen) return first;
    }
    return _greedy(board, visited);
  }

  /// A good next pour for a board too big to search. It picks the useful
  /// pour that leaves the table closest to sorted (see [_potential]).
  static Move? _greedy(Board board, Set<String>? visited) {
    final moves = GameEngine.usefulMoves(board);
    Move? best;
    var bestScore = 1 << 30;
    Move? bestSeen;
    var bestSeenScore = 1 << 30;
    for (final move in moves) {
      final after = GameEngine.pour(board, move.from, move.to)!.board;
      // never walk into a board with no useful pour left
      if (!GameEngine.isWon(after) && !GameEngine.hasUsefulMove(after)) {
        continue;
      }
      var score = potential(after) * 8;
      // on equal footing prefer bigger pours, and stacking on the same colour
      score -= move.count;
      if (!board.bottles[move.to].isEmpty) score -= 3;
      if (visited != null && visited.contains(boardKey(after))) {
        // a board we have been on: only used if nothing new is left
        if (score < bestSeenScore) {
          bestSeenScore = score;
          bestSeen = move;
        }
        continue;
      }
      if (score < bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best ?? bestSeen;
  }

  /// Lower is closer to solved. Three for every extra bottle a colour is
  /// spread over, two for every unit sitting above a different colour; less
  /// for each empty bottle kept free (6), each finished bottle (8) and each
  /// pair of open bottles that share a top colour (2).
  static int potential(Board board) {
    final homes = <int, int>{};
    final tops = <int, int>{};
    var buried = 0;
    var empties = 0;
    var done = 0;
    for (final bottle in board.bottles) {
      final layers = bottle.layers;
      if (layers.isEmpty) {
        empties++;
        continue;
      }
      final seen = <int>{};
      var base = true;
      for (var i = 0; i < layers.length; i++) {
        if (i > 0 && layers[i] != layers[i - 1]) base = false;
        if (!base) buried++;
        seen.add(layers[i]);
      }
      for (final colour in seen) {
        homes[colour] = (homes[colour] ?? 0) + 1;
      }
      if (bottle.isFull && base) done++;
      if (!bottle.isFull) tops[layers.last] = (tops[layers.last] ?? 0) + 1;
    }
    var spread = 0;
    for (final count in homes.values) {
      spread += count - 1;
    }
    var match = 0;
    for (final count in tops.values) {
      if (count > 1) match += count - 1;
    }
    return spread * 3 + buried * 2 - empties * 6 - done * 8 - match * 2;
  }
}

/// 3 stars / 2 stars / 1 star from the move count against par.
abstract final class Stars {
  static int count({required int level, required int par, required int moves}) {
    if (level <= 3) return 3;
    final three = (par * 115 + 99) ~/ 100 + 1;
    if (moves <= three) return 3;
    final two = (par * 3 + 1) ~/ 2 + 2;
    if (moves <= two) return 2;
    return 1;
  }
}

class _Search {
  _Search(this.board, this.maxNodes, this.prefer)
    : capacity = board.capacity,
      count = board.bottles.length,
      _arena = Int32List(maxNodes * board.bottles.length),
      _parent = Int32List(maxNodes),
      _edge = Int32List(maxNodes),
      _f = Int32List(maxNodes),
      _g = Int32List(maxNodes),
      _h = Int32List(maxNodes),
      _onGuide = Uint8List(maxNodes),
      _heap = Int32List(maxNodes),
      _key = Int32List(board.bottles.length),
      _slots = 1 << _pow2AtLeast(maxNodes * 2),
      _vstate = Int32List(1 << _pow2AtLeast(maxNodes * 2)),
      _vkey = Int32List(
        (1 << _pow2AtLeast(maxNodes * 2)) * board.bottles.length,
      ) {
    for (var i = 0; i < _vstate.length; i++) {
      _vstate[i] = -1;
    }
    _mask = _slots - 1;
  }

  final Board board;
  final int maxNodes;
  final List<Move>? prefer;
  final int capacity;
  final int count;

  final Int32List _arena;
  final Int32List _parent;
  final Int32List _edge;
  final Int32List _f;
  final Int32List _g;
  final Int32List _h;
  final Uint8List _onGuide;
  final Int32List _heap;
  final Int32List _key;
  final int _slots;
  final Int32List _vstate;
  final Int32List _vkey;
  late final int _mask;

  int _nodes = 0;
  int _heapSize = 0;

  List<Move>? run() {
    for (var i = 0; i < count; i++) {
      _arena[i] = _pack(board.bottles[i]);
    }
    if (_isWon(0)) return const [];
    _nodes = 1;
    _remember(0);
    _h[0] = _heuristic(0);
    _f[0] = _h[0];
    _onGuide[0] = prefer == null ? 0 : 1;
    _push(0);
    while (_heapSize > 0) {
      final node = _pop();
      if (_isWon(node)) return _path(node);
      if (_nodes >= maxNodes) return null;
      _expand(node);
    }
    return null;
  }

  void _expand(int node) {
    final base = node * count;
    final depth = _g[node];
    final guided =
        _onGuide[node] == 1 && prefer != null && depth < prefer!.length;
    final guide = guided ? prefer![depth] : null;
    if (guide != null) {
      _consider(node, base, guide.from, guide.to, guide);
      if (_nodes >= maxNodes) return;
    }
    for (var from = 0; from < count; from++) {
      final src = _arena[base + from];
      if (src >>> _lenShift == 0) continue;
      for (var to = 0; to < count; to++) {
        if (to == from) continue;
        if (_nodes >= maxNodes) return;
        _consider(node, base, from, to, guide);
      }
    }
  }

  void _consider(int node, int base, int from, int to, Move? guide) {
    if (from == to || from < 0 || to < 0 || from >= count || to >= count) {
      return;
    }
    final src = _arena[base + from];
    final srcLen = src >>> _lenShift;
    if (srcLen == 0) return;
    final dst = _arena[base + to];
    final dstLen = dst >>> _lenShift;
    final space = capacity - dstLen;
    if (space == 0) return;
    final run = _run(src);
    if (dstLen == 0) {
      if (run == srcLen) return;
    } else if (((dst >> ((dstLen - 1) * _bits)) & _mask) !=
        ((src >> ((srcLen - 1) * _bits)) & _mask)) {
      return;
    }
    final pour = run < space ? run : space;
    final follows =
        guide != null &&
        guide.from == from &&
        guide.to == to &&
        guide.count == pour;
    _addChild(
      node,
      from,
      to,
      pour,
      _cut(src, pour),
      _addLayers(dst, (src >> ((srcLen - 1) * _bits)) & _mask, pour),
      follows,
    );
  }

  void _addChild(
    int parent,
    int from,
    int to,
    int pour,
    int nextSrc,
    int nextDst,
    bool follows,
  ) {
    final node = _nodes;
    final fromBase = parent * count;
    final toBase = node * count;
    for (var i = 0; i < count; i++) {
      _arena[toBase + i] = _arena[fromBase + i];
    }
    _arena[toBase + from] = nextSrc;
    _arena[toBase + to] = nextDst;
    if (!_remember(node)) return;
    _nodes++;
    _parent[node] = parent;
    _g[node] = _g[parent] + 1;
    _edge[node] = from | (to << 8) | (pour << 16);
    final h = _heuristic(node);
    _h[node] = h;
    _onGuide[node] = follows ? 1 : 0;
    // Guide steps are popped before anything else, so a known line is checked
    // in a handful of nodes. Every other node is best-first on g + h.
    _f[node] = follows ? -1 : (_g[node] + h);
    _push(node);
  }

  bool _remember(int node) {
    final base = node * count;
    for (var i = 0; i < count; i++) {
      _key[i] = _arena[base + i];
    }
    _sortKey();
    var hash = 2166136261;
    for (var i = 0; i < count; i++) {
      hash = 0x7fffffff & ((hash ^ _key[i]) * 16777619);
    }
    var slot = hash & _mask;
    while (true) {
      final seen = _vstate[slot];
      if (seen < 0) {
        final at = slot * count;
        for (var i = 0; i < count; i++) {
          _vkey[at + i] = _key[i];
        }
        _vstate[slot] = node;
        return true;
      }
      if (_same(slot)) return false;
      slot = (slot + 1) & _mask;
    }
  }

  bool _same(int slot) {
    final at = slot * count;
    for (var i = 0; i < count; i++) {
      if (_vkey[at + i] != _key[i]) return false;
    }
    return true;
  }

  void _sortKey() {
    for (var i = 1; i < count; i++) {
      final value = _key[i];
      var j = i - 1;
      while (j >= 0 && _key[j] > value) {
        _key[j + 1] = _key[j];
        j--;
      }
      _key[j + 1] = value;
    }
  }

  int _heuristic(int node) {
    final base = node * count;
    var changes = 0;
    var mixed = 0;
    for (var b = 0; b < count; b++) {
      final packed = _arena[base + b];
      final len = packed >>> _lenShift;
      if (len == 0) continue;
      var previous = packed & _mask;
      var uniform = true;
      for (var i = 1; i < len; i++) {
        final nibble = (packed >> (i * _bits)) & _mask;
        if (nibble != previous) {
          changes++;
          uniform = false;
          previous = nibble;
        }
      }
      if (!uniform) mixed++;
    }
    return changes + mixed;
  }

  bool _isWon(int node) {
    final base = node * count;
    for (var i = 0; i < count; i++) {
      final packed = _arena[base + i];
      final len = packed >>> _lenShift;
      if (len == 0) continue;
      if (len != capacity || _run(packed) != len) return false;
    }
    return true;
  }

  List<Move> _path(int node) {
    var length = 0;
    for (var n = node; n != 0; n = _parent[n]) {
      length++;
    }
    final moves = List<Move>.filled(
      length,
      const Move(from: 0, to: 0, count: 1),
    );
    var i = length - 1;
    for (var n = node; n != 0; n = _parent[n]) {
      final edge = _edge[n];
      moves[i--] = Move(
        from: edge & 255,
        to: (edge >> 8) & 255,
        count: edge >> 16,
      );
    }
    return moves;
  }

  void _push(int node) {
    var i = _heapSize++;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_before(_heap[parent], node)) break;
      _heap[i] = _heap[parent];
      i = parent;
    }
    _heap[i] = node;
  }

  int _pop() {
    final top = _heap[0];
    final last = _heap[--_heapSize];
    if (_heapSize == 0) return top;
    var i = 0;
    while (true) {
      final left = i * 2 + 1;
      if (left >= _heapSize) break;
      final right = left + 1;
      var child = left;
      if (right < _heapSize && _before(_heap[right], _heap[left])) {
        child = right;
      }
      if (_before(_heap[child], last)) {
        _heap[i] = _heap[child];
        i = child;
      } else {
        break;
      }
    }
    _heap[i] = last;
    return top;
  }

  bool _before(int a, int b) {
    if (_f[a] != _f[b]) return _f[a] < _f[b];
    if (_h[a] != _h[b]) return _h[a] < _h[b];
    return a < b;
  }

  static int _pack(Bottle bottle) {
    var colors = 0;
    final layers = bottle.layers;
    for (var i = 0; i < layers.length; i++) {
      colors |= (layers[i] + 1) << (i * _bits);
    }
    return colors | (layers.length << _lenShift);
  }
}

int _run(int packed) {
  final len = packed >>> _lenShift;
  final nibble = (packed >> ((len - 1) * _bits)) & _mask;
  var run = 1;
  for (var i = len - 2; i >= 0; i--) {
    if (((packed >> (i * _bits)) & _mask) != nibble) break;
    run++;
  }
  return run;
}

int _cut(int packed, int pour) {
  final len = (packed >>> _lenShift) - pour;
  if (len == 0) return 0;
  return (packed & ((1 << (len * _bits)) - 1)) | (len << _lenShift);
}

int _addLayers(int packed, int nibble, int pour) {
  final len = packed >>> _lenShift;
  var colors = packed & ((1 << _lenShift) - 1);
  for (var i = 0; i < pour; i++) {
    colors |= nibble << ((len + i) * _bits);
  }
  return colors | ((len + pour) << _lenShift);
}

int _pow2AtLeast(int n) {
  var bits = 1;
  var value = 2;
  while (value < n) {
    value <<= 1;
    bits++;
  }
  return bits;
}
