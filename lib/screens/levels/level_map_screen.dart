import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:google_fonts/google_fonts.dart';

import '../../ads/ad_widgets.dart';
import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../game/difficulty.dart';
import '../../widgets/info_dialog.dart';
import '../../widgets/page_shell.dart';
import '../game/game_screen.dart';

/// Level map: a winding path of finished, current and locked levels.
/// The open level and the stars come from [AppPrefs].
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  ScrollController? _scroll;
  bool _ready = false;
  int _current = 1;
  Map<int, int> _stars = const {};

  /// Inclusive node indexes currently built. Null until progress is loaded.
  (int, int)? _window;

  List<Offset>? _points;
  double? _pointsW;
  double? _pointsH;
  List<_PathDash> _dashes = const [];
  List<Offset>? _dashPoints;
  int _dashDone = -1;

  static const _gap = 96.0;
  static const _buffer = 10;

  int get _count => DifficultyCurve.maxLevel;

  double get _mapHeight => _count * _gap + 140;

  bool get _finished => _stars.containsKey(_count);

  @override
  void initState() {
    super.initState();
    // Started here, not on first use: a finished map has no current node,
    // so nothing else would read the controller before dispose.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadInitial();
  }

  Future<({int level, Map<int, int> stars})> _readProgress() async {
    final levelFuture = AppPrefs.level();
    final starsFuture = AppPrefs.stars();
    return (level: await levelFuture, stars: await starsFuture);
  }

  Future<void> _loadInitial() async {
    final progress = await _readProgress();
    if (!mounted) return;
    final offset = _offsetFor(progress.level);
    final scroll = ScrollController(initialScrollOffset: offset);
    scroll.addListener(_onScroll);
    setState(() {
      _current = progress.level;
      _stars = progress.stars;
      _scroll = scroll;
      _ready = true;
      _window = _rangeAt(offset, 900, _mapHeight);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpAfterLayout());
  }

  Future<void> _refreshProgress() async {
    final progress = await _readProgress();
    if (!mounted) return;
    setState(() {
      _current = progress.level;
      _stars = progress.stars;
    });
  }

  /// About `(_current - 3) * gap`, so the open level sits near the middle.
  /// Level 1 is at the bottom of a reversed list, so the offset grows upward.
  double _offsetFor(int level) => math.max(0, (level - 3) * _gap);

  void _jumpAfterLayout() {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients) return;
    if (!scroll.position.haveDimensions) return;
    final max = scroll.position.maxScrollExtent;
    final raw = _offsetFor(_current);
    final target = raw > max ? max : raw;
    if (scroll.offset != target) scroll.jumpTo(target);
    _publishWindow(scroll.offset, scroll.position.viewportDimension);
  }

  void _onScroll() {
    if (!mounted || !_ready) return;
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients) return;
    if (!scroll.position.haveDimensions) return;
    // The first layout can correct the offset while the tree is still building.
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
      return;
    }
    _publishWindow(scroll.offset, scroll.position.viewportDimension);
  }

  void _publishWindow(double pixels, double viewport) {
    final next = _rangeAt(pixels, viewport, _mapHeight);
    if (_window == next) return;
    setState(() => _window = next);
  }

  (int, int) _rangeAt(double pixels, double viewport, double height) {
    final count = _count;
    final visibleBottom = height - pixels;
    final visibleTop = visibleBottom - math.max(viewport, 1);
    final low = ((height - 80 - visibleBottom) / _gap).floor() - _buffer;
    final high = ((height - 80 - visibleTop) / _gap).ceil() + _buffer;
    final from = low < 0 ? 0 : (low >= count ? count - 1 : low);
    final to = high < 0 ? 0 : (high >= count ? count - 1 : high);
    return (math.min(from, to), math.max(from, to));
  }

  bool _isDone(int level) {
    if (_finished && level == _count) return true;
    return level < _current;
  }

  bool _isCurrent(int level) => !_finished && level == _current;

  int get _doneUntil => _finished ? _count - 1 : _current - 1;

  List<Offset> _pointsFor(double w, double h) {
    final cached = _points;
    if (cached != null && _pointsW == w && _pointsH == h) return cached;
    _pointsW = w;
    _pointsH = h;
    return _points = <Offset>[
      for (var i = 0; i < _count; i++) _center(i, w, h),
    ];
  }

  void _ensureDashes(List<Offset> points, int doneUntil) {
    if (identical(points, _dashPoints) && doneUntil == _dashDone) return;
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = AppColors.gold.withValues(alpha: 0.85);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.2);
    final next = <_PathDash>[];
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(a.dx, mid.dy, mid.dx, mid.dy)
        ..quadraticBezierTo(b.dx, mid.dy, b.dx, b.dy);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = i < doneUntil ? gold : faint;
      for (final metric in path.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(
            metric.extractPath(d, math.min(d + 10, metric.length)),
            paint,
          );
          d += 18;
        }
      }
      next.add(
        _PathDash(
          math.min(a.dy, b.dy),
          math.max(a.dy, b.dy),
          recorder.endRecording(),
        ),
      );
    }
    final previous = _dashes;
    _dashes = next;
    _dashPoints = points;
    _dashDone = doneUntil;
    if (previous.isEmpty) return;
    // The frame being built may still paint the previous pictures.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final dash in previous) {
        dash.dispose();
      }
    });
  }

  Future<void> _onNodeTap(int level) async {
    if (!_isDone(level) && !_isCurrent(level)) {
      await InfoDialog.show(
        context,
        icon: Icons.lock_rounded,
        title: 'Locked',
        message: 'Finish level $_current first',
      );
      return;
    }
    final navigator = Navigator.of(context);
    await navigator.push(fadeRoute(GameScreen(level: level), zoom: true));
    if (!mounted) return;
    await _refreshProgress();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll?.removeListener(_onScroll);
    _scroll?.dispose();
    for (final dash in _dashes) {
      dash.dispose();
    }
    super.dispose();
  }

  Offset _center(int i, double w, double h) =>
      Offset(w / 2 + math.sin(i * 0.95) * w * 0.27, h - 80 - i * _gap);

  @override
  Widget build(BuildContext context) {
    final scroll = _scroll;
    return PageShell(
      title: 'Levels',
      child: Column(
        children: [
          Expanded(
            child: !_ready || scroll == null
                ? const Center(
                    child: SizedBox(
                      key: ValueKey('levels-loading'),
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final h = _mapHeight;
                      final points = _pointsFor(w, h);
                      final doneUntil = _doneUntil;
                      _ensureDashes(points, doneUntil);
                      final range = _window ?? (0, math.min(_count - 1, 16));
                      final bandTop = points[range.$2].dy - 24;
                      final bandBottom = points[range.$1].dy + 24;
                      return SingleChildScrollView(
                        key: const ValueKey('level-map-scroll'),
                        controller: scroll,
                        reverse: true,
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PathPainter(
                                    points: points,
                                    doneUntil: doneUntil,
                                    dashes: _dashes,
                                    top: bandTop,
                                    bottom: bandBottom,
                                  ),
                                ),
                              ),
                              for (var i = range.$1; i <= range.$2; i++)
                                _node(i, points[i]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const BannerAdSlot(),
        ],
      ),
    );
  }

  Widget _node(int i, Offset p) {
    final level = i + 1;
    final done = _isDone(level);
    final cur = _isCurrent(level);
    final size = cur ? 78.0 : 62.0;
    final filled = _stars[level] ?? 0;
    Widget body;
    if (cur) {
      body = AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Transform.scale(
          scale: 1 + 0.07 * _pulse.value,
          child: _circle(
            size,
            const [Color(0xFF9AF5FF), Color(0xFF1FA9FF)],
            Text(
              '$level',
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0xFF0B4F8F), offset: Offset(0, 2)),
                ],
              ),
            ),
            glow: true,
          ),
        ),
      );
    } else if (done) {
      body = _circle(
        size,
        const [Color(0xFFFFF27A), Color(0xFFFFA000)],
        Text(
          '$level',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4A2A00),
          ),
        ),
      );
    } else {
      body = _circle(
        size,
        const [Color(0xFF3A4194), Color(0xFF1B2060)],
        Icon(
          Icons.lock_rounded,
          size: 24,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      );
    }
    return Positioned(
      key: ValueKey<int>(level),
      left: p.dx - 45,
      top: p.dy - size / 2 - 4,
      width: 90,
      child: GestureDetector(
        onTap: () => _onNodeTap(level),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            body,
            const SizedBox(height: 3),
            if (done)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var s = 0; s < 3; s++)
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: s < filled
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                ],
              ),
            if (cur)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  'PLAY',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: const Color(0xFF4A2A00),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(
    double size,
    List<Color> colors,
    Widget child, {
    bool glow = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          const BoxShadow(
            color: Color(0x66000020),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          if (glow)
            BoxShadow(
              color: colors.last.withValues(alpha: 0.7),
              blurRadius: 18,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.1,
            child: Container(
              width: size * 0.55,
              height: size * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PathDash {
  _PathDash(this.top, this.bottom, this.picture);

  final double top;
  final double bottom;
  final ui.Picture picture;
  var _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    picture.dispose();
  }
}

/// Dashed path through the level circles; the part already walked is gold.
class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.points,
    required this.doneUntil,
    required this.dashes,
    required this.top,
    required this.bottom,
  });

  final List<Offset> points;
  final int doneUntil;
  final List<_PathDash> dashes;
  final double top;
  final double bottom;

  @override
  void paint(Canvas canvas, Size size) {
    var top = this.top;
    var bottom = this.bottom;
    final clip = canvas.getLocalClipBounds();
    if (clip.height < size.height && clip.height > 0) {
      if (clip.top > top) top = clip.top - 16;
      if (clip.bottom < bottom) bottom = clip.bottom + 16;
    }
    for (final dash in dashes) {
      if (dash.bottom < top - 8 || dash.top > bottom + 8) continue;
      canvas.drawPicture(dash.picture);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      doneUntil != old.doneUntil ||
      top != old.top ||
      bottom != old.bottom ||
      !listEquals(points, old.points);
}
