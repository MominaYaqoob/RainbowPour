import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../widgets/cone_bottle.dart';
import 'tap_lift_illustration.dart';

/// Page 3: three bottles fill with one color each, then a star pops over
/// every finished bottle.
class FillIllustration extends StatefulWidget {
  const FillIllustration({super.key});

  @override
  State<FillIllustration> createState() => _FillIllustrationState();
}

class _FillIllustrationState extends State<FillIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _scale = 0.92;
  static const _colors = [0, 3, 5]; // red, green, blue
  static const _centers = [42.0, 108.0, 174.0];
  static const _top = 46.0;

  @override
  Widget build(BuildContext context) {
    final w = 36 * _scale;
    return SizedBox.fromSize(
      size: kIllustrationSize,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final alpha = seg(v, 0, 0.05) * (1 - seg(v, 0.94, 1));
          return Opacity(
            opacity: alpha,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: _GlowPainter(v))),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 151,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 148,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                for (var i = 0; i < 3; i++) _bottle(i, v, w),
                Positioned.fill(child: CustomPaint(painter: _StarPainter(v))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bottle(int i, double v, double w) {
    // each bottle fills layer by layer, one after another
    final p = seg(v, 0.04 + 0.1 * i, 0.38 + 0.1 * i, Curves.easeInOut);
    final amount = 4 * p;
    final whole = amount.floor().clamp(0, 4);
    final frac = whole >= 4 ? 0.0 : amount - whole;
    // small hop when the bottle becomes full
    final done = 0.4 + 0.1 * i;
    final hop = math.sin(math.pi * seg(v, done, done + 0.1)) * 4;
    return Positioned(
      left: _centers[i] - w / 2,
      top: _top - hop,
      child: ConeBottle(
        layers: [for (var k = 0; k < whole; k++) _colors[i]],
        extraColor: frac > 0 ? _colors[i] : null,
        extraProgress: frac,
        width: w,
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.v);

  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final on = seg(v, 0.5, 0.62);
    if (on <= 0) return;
    final pulse = 0.65 + 0.35 * math.sin(2 * math.pi * v * 3);
    final rect = Rect.fromCenter(
      center: const Offset(108, 96),
      width: 210,
      height: 120,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD43B).withValues(alpha: 0.28 * on * pulse),
            const Color(0x00FFD43B),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.v != v;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.v);

  final double v;

  static const _spots = [Offset(42, 26), Offset(108, 14), Offset(174, 26)];

  static Path _star(double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final t0 = 0.52 + 0.09 * i;
      final pop = seg(v, t0, t0 + 0.2, Curves.elasticOut);
      if (pop <= 0) continue;
      final c = _spots[i];

      // little burst of dots as the star appears
      final b = seg(v, t0, t0 + 0.16);
      if (b > 0 && b < 1) {
        for (var k = 0; k < 7; k++) {
          final a = k * 2 * math.pi / 7 + i;
          final d = 12 + 16 * Curves.easeOut.transform(b);
          canvas.drawCircle(
            c + Offset(math.cos(a) * d, math.sin(a) * d),
            1.8 * (1 - b),
            Paint()..color = const Color(0xFFFFE680).withValues(alpha: 1 - b),
          );
        }
      }

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate((1 - pop.clamp(0, 1)) * -0.5);
      canvas.scale(pop);
      final star = _star(13);
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFD43B));
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.v != v;
}
