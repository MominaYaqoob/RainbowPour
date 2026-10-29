import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../widgets/page_shell.dart';
import '../game/game_screen.dart';

/// Level map: a winding path with finished, current and locked levels.
/// UI only; the progress (current level 8 here) is sample data.
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  final _scroll = ScrollController();

  static const _count = 30;
  static const _current = 8; // sample progress
  static const _gap = 96.0;

  @override
  void initState() {
    super.initState();
    // start with the current level near the middle (the list is bottom-up)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (_current - 3) * _gap;
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Offset _center(int i, double w, double h) =>
      Offset(w / 2 + math.sin(i * 0.95) * w * 0.27, h - 80 - i * _gap);

  int _stars(int level) => 1 + (level * 7 % 3); // sample: 1..3

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Levels',
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = _count * _gap + 140;
          return SingleChildScrollView(
            controller: _scroll,
            reverse: true,
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PathPainter([
                        for (var i = 0; i < _count; i++) _center(i, w, h),
                      ], _current - 1),
                    ),
                  ),
                  for (var i = 0; i < _count; i++) _node(i, w, h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _node(int i, double w, double h) {
    final level = i + 1;
    final p = _center(i, w, h);
    final done = level < _current;
    final cur = level == _current;
    final size = cur ? 78.0 : 62.0;
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
      left: p.dx - 45,
      top: p.dy - size / 2 - 4,
      width: 90,
      child: GestureDetector(
        onTap: () {
          if (done || cur) {
            Navigator.of(
              context,
            ).push(fadeRoute(const GameScreen(), zoom: true));
          } else {
            showSoon(context, 'Level $level');
          }
        },
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
                      color: s < _stars(level)
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

/// Dashed path through the level circles; the part already walked is gold.
class _PathPainter extends CustomPainter {
  _PathPainter(this.points, this.doneUntil);

  final List<Offset> points;
  final int doneUntil;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(a.dx, mid.dy, mid.dx, mid.dy)
        ..quadraticBezierTo(b.dx, mid.dy, b.dx, b.dy);
      final done = i < doneUntil;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = done ? 7 : 5
        ..color = done
            ? AppColors.gold.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.2);
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, math.min(d + 10, m.length)), paint);
          d += 18;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => false;
}
