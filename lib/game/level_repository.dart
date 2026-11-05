import 'dart:async';
import 'dart:isolate';

import 'difficulty.dart';
import 'generator.dart';

/// Cached levels. Building a board runs in a worker isolate, never on the
/// caller that paints the frame. The next two levels are warmed after the
/// current one is opened.
abstract final class LevelRepository {
  static final Map<int, GeneratedLevel> _cache = {};
  static final Map<int, Future<GeneratedLevel>> _inflight = {};

  static Future<GeneratedLevel> getLevel(int level) {
    final max = DifficultyCurve.maxLevel;
    final n = level < 1 ? 1 : (level > max ? max : level);
    final cached = _cache[n];
    if (cached != null) return Future<GeneratedLevel>.value(cached);
    final pending = _inflight[n];
    if (pending != null) return pending;
    final future = _load(n);
    _inflight[n] = future;
    return future;
  }

  /// Starts level+1 and level+2 if they are not already cached.
  static void prefetch(int level) {
    for (var step = 1; step <= 2; step++) {
      final n = level + step;
      if (n > DifficultyCurve.maxLevel) return;
      if (_cache.containsKey(n) || _inflight.containsKey(n)) continue;
      unawaited(
        getLevel(n).then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    }
  }

  static final Map<int, GeneratedLevel> _challengeCache = {};
  static final Map<int, Future<GeneratedLevel>> _challengeInflight = {};

  /// Today's daily board, built on a worker isolate (on the caller when the
  /// platform has no isolates). Cached by the local `yyyyMMdd` key.
  static Future<GeneratedLevel> getChallenge(DateTime day) {
    final key = DifficultyCurve.challengeSeed(day);
    final cached = _challengeCache[key];
    if (cached != null) return Future<GeneratedLevel>.value(cached);
    final pending = _challengeInflight[key];
    if (pending != null) return pending;
    final future = _loadChallenge(day, key);
    _challengeInflight[key] = future;
    return future;
  }

  static Future<GeneratedLevel> _loadChallenge(DateTime day, int key) async {
    try {
      final generated = await _challengeInWorker(day);
      _challengeCache[key] = generated;
      return generated;
    } finally {
      _challengeInflight.remove(key);
    }
  }

  static Future<GeneratedLevel> _challengeInWorker(DateTime day) async {
    try {
      return await Isolate.run(() => LevelGenerator.forChallenge(day));
    } on UnsupportedError {
      return LevelGenerator.forChallenge(day);
    }
  }

  static Future<GeneratedLevel> _load(int level) async {
    try {
      final generated = await _inWorker(level);
      _cache[level] = generated;
      return generated;
    } finally {
      _inflight.remove(level);
    }
  }

  /// Android builds the board on a worker isolate. Flutter web has no
  /// [Isolate.run], so that call falls back to the caller.
  static Future<GeneratedLevel> _inWorker(int level) async {
    try {
      return await Isolate.run(() => LevelGenerator.forLevel(level));
    } on UnsupportedError {
      // Flutter web has no worker isolates. UnimplementedError is the same
      // type there, so this one clause covers the browser build.
      return LevelGenerator.forLevel(level);
    }
  }
}
