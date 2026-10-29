import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../widgets/cone_bottle.dart';

/// Design canvas shared by all onboarding illustrations.
const kIllustrationSize = Size(216, 176);

/// Page 1: a finger taps the middle bottle, it lifts, then it is tapped again
/// and settles back on the shelf.
class TapLiftIllustration extends StatefulWidget {
  const TapLiftIllustration({super.key});

  @override
  State<TapLiftIllustration> createState() => _TapLiftIllustrationState();
}

class _TapLiftIllustrationState extends State<TapLiftIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _xs = [24.0, 90.0, 156.0];
  static const _layers = [
    [0, 1, 2, 3],
    [4, 5, 4, 5],
    [2, 6, 0, 6],
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kIllustrationSize,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final up = seg(v, 0.05, 0.3, Curves.easeOutBack);
          final down = seg(v, 0.68, 0.86, Curves.easeInCubic);
          final lift = 16 * up * (1 - down);
          // tiny settle bounce when the bottle lands
          final land = math.sin(math.pi * seg(v, 0.86, 0.95)) * 2.5;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // shelf
              Positioned(
                left: 12,
                right: 12,
                top: 152,
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
              // ground shadows (the middle one shrinks as the bottle lifts)
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: _xs[i] + 18 - 16 * (i == 1 ? 1 - lift / 40 : 1),
                  top: 145.5,
                  child: Container(
                    width: 32 * (i == 1 ? 1 - lift / 40 : 1),
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: i == 1 ? 0.32 - lift * 0.008 : 0.32,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: _xs[i],
                  top: 34 - (i == 1 ? lift - land : 0),
                  child: ConeBottle(
                    layers: _layers[i],
                    width: 36,
                    showShadow: false,
                  ),
                ),
              Positioned.fill(child: CustomPaint(painter: _TapPainter(v))),
            ],
          );
        },
      ),
    );
  }
}

class _TapPainter extends CustomPainter {
  _TapPainter(this.v);

  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    const c = Offset(108, 118);
    // two taps: lift and put back
    for (final (a, b) in [(0.0, 0.3), (0.64, 0.9)]) {
      final p = seg(v, a, b);
      if (p <= 0 || p >= 1) continue;
      canvas.drawCircle(
        c,
        6 + 24 * Curves.easeOut.transform(p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Colors.white.withValues(alpha: 0.8 * (1 - p)),
      );
    }
    // finger press dot
    final press =
        math.sin(math.pi * seg(v, 0.0, 0.14)) +
        math.sin(math.pi * seg(v, 0.64, 0.78));
    if (press > 0) {
      canvas.drawCircle(
        c,
        7 + 2 * press,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * press.clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_TapPainter old) => old.v != v;
}
