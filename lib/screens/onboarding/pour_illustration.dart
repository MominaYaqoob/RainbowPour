import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../widgets/cone_bottle.dart';
import 'tap_lift_illustration.dart';

/// Page 2: the red top layer is poured from a tilted bottle into another red
/// layer. The liquid stays level, a stream falls, ripples and droplets show at
/// the landing point and the target fills up.
class PourIllustration extends StatefulWidget {
  const PourIllustration({super.key});

  @override
  State<PourIllustration> createState() => _PourIllustrationState();
}

class _PourIllustrationState extends State<PourIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _scale = 0.85;
  static const _srcPos = Offset(46, -12);
  static const _dstPos = Offset(105.6, 68);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kIllustrationSize,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final alpha = seg(v, 0, 0.05) * (1 - seg(v, 0.93, 1));
          // Tilt until the red layer reaches the lip (about 80 degrees), then
          // keep tilting slowly while it spills; liquid above the lip is what
          // pours out, so the top layer drains by itself.
          final rise =
              (80 * seg(v, 0, 0.25, Curves.easeInOutCubic) +
                  5 * seg(v, 0.27, 0.68, Curves.easeInOut)) *
              math.pi /
              180;
          final tilt = rise * (1 - seg(v, 0.7, 0.85, Curves.easeInOutCubic));
          final drain = ConeBottle.topLayerFractionForTilt(rise, 3);
          final fill = seg(v, 0.38, 0.72, Curves.easeInOut);
          return Opacity(
            opacity: alpha,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // shelf
                Positioned(
                  left: 12,
                  right: 12,
                  top: 167,
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
                  top: 164,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // ground shadow under the target bottle
                Positioned(
                  left: _dstPos.dx + 18 * _scale - 13,
                  top: 161,
                  child: Container(
                    width: 26,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  left: _dstPos.dx,
                  top: _dstPos.dy,
                  child: ConeBottle(
                    layers: const [0],
                    width: 36 * _scale,
                    showShadow: false,
                    extraColor: 0,
                    extraProgress: fill,
                  ),
                ),
                Positioned(
                  left: _srcPos.dx,
                  top: _srcPos.dy,
                  child: ConeBottle(
                    layers: const [1, 4, 0],
                    width: 36 * _scale,
                    showShadow: false,
                    tilt: tilt,
                    topLayerFraction: drain,
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _StreamPainter(v))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StreamPainter extends CustomPainter {
  _StreamPainter(this.v);

  final double v;

  // neck of the tilted bottle (panel coordinates) and the landing point
  static const _neck = Offset(104.9, 33.8);
  static const _land = Offset(120.9, 129);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(_neck.dx, _neck.dy + 2)
      ..cubicTo(
        _neck.dx + 10,
        _neck.dy + 3,
        _land.dx,
        _neck.dy + 12,
        _land.dx,
        _neck.dy + 34,
      )
      ..lineTo(_land.dx, _land.dy);
    final PathMetric m = path.computeMetrics().first;
    final head = seg(v, 0.27, 0.37);
    final tail = seg(v, 0.68, 0.78);
    if (head > tail) {
      final part = m.extractPath(m.length * tail, m.length * head);
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.2
          ..color = AppColors.liquid[0],
      );
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.3
          ..color = Colors.white.withValues(alpha: 0.45),
      );
    }

    // impact ripples and droplets while the stream lands
    final on = seg(v, 0.37, 0.42) * (1 - seg(v, 0.7, 0.75));
    if (on > 0) {
      final t = (v * 4.2 / 0.9) % 1; // 0.9s ripple period
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(_land.dx, _land.dy - 4),
          width: 8 + 24 * t,
          height: 3 + 4 * t,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.8 * (1 - t) * on),
      );
      const drops = [(-7.0, 0.0), (6.0, 0.25), (-2.0, 0.5)];
      for (final (dx, ph) in drops) {
        final p = ((v * 4.2 / 0.7) + ph) % 1;
        canvas.drawCircle(
          Offset(
            _land.dx + dx * (1 + p),
            _land.dy - 4 - 12 * math.sin(math.pi * p),
          ),
          1.7,
          Paint()..color = AppColors.liquid[0].withValues(alpha: on),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StreamPainter old) => old.v != v;
}
