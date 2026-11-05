/// Countdown for the daily challenge.
///
/// Time comes from a [Stopwatch], which does not follow the phone clock.
/// Tests pass [elapsed] instead of waiting.
class ChallengeTimer {
  ChallengeTimer({required this.total, Duration Function()? elapsed})
    : _elapsed = elapsed,
      _watch = elapsed == null ? Stopwatch() : null;

  final Duration total;

  /// Monotonic reading. Null means the internal [Stopwatch] is used.
  final Duration Function()? _elapsed;
  final Stopwatch? _watch;

  Duration _banked = Duration.zero;
  Duration _mark = Duration.zero;
  bool _running = false;
  bool _started = false;

  bool get isRunning => _running;

  Duration get _read {
    final elapsed = _elapsed;
    if (elapsed != null) return elapsed();
    return _watch!.elapsed;
  }

  /// Starts from the full [total], dropping any time already counted.
  void start() {
    _banked = Duration.zero;
    _started = true;
    _running = true;
    final watch = _watch;
    if (watch != null) {
      watch
        ..reset()
        ..start();
    }
    _mark = _read;
  }

  void pause() {
    if (!_running) return;
    _banked += _read - _mark;
    _running = false;
    _watch?.stop();
  }

  void resume() {
    if (_running || !_started || isExpired) return;
    _watch?.start();
    _mark = _read;
    _running = true;
  }

  Duration get _used {
    final extra = _running ? _read - _mark : Duration.zero;
    final used = _banked + extra;
    return used.isNegative ? Duration.zero : used;
  }

  Duration get remaining {
    final left = total - _used;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isExpired => _started && _used >= total;

  /// Back to the full [total]. Keeps running if it was running.
  void reset() {
    _banked = Duration.zero;
    _started = true;
    final watch = _watch;
    if (watch != null) {
      watch.reset();
      if (_running) watch.start();
    }
    _mark = _read;
  }
}
