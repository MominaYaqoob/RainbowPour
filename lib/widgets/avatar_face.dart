import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Number of built-in avatars.
const kAvatarCount = 8;

/// Round mascot: a water drop with a face. Each [index] has its own color and
/// expression.
class AvatarFace extends StatelessWidget {
  const AvatarFace({super.key, required this.index, this.size = 56});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _AvatarPainter(index % kAvatarCount),
  );
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.i);

  final int i;

  @override
  void paint(Canvas canvas, Size size) {
    final base = AppColors.liquid[i];
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 56);

    // badge background
    canvas.drawCircle(
      Offset.zero,
      27,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B3590), Color(0xFF0E1550)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 27)),
    );

    // drop
    final drop = Path()
      ..moveTo(0, -20)
      ..cubicTo(9, -8, 17, 1, 17, 8)
      ..cubicTo(17, 17, 9, 23, 0, 23)
      ..cubicTo(-9, 23, -17, 17, -17, 8)
      ..cubicTo(-17, 1, -9, -8, 0, -20)
      ..close();
    canvas.drawPath(
      drop,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(base, Colors.white, 0.35)!, base],
        ).createShader(drop.getBounds()),
    );
    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    // shine
    canvas.drawLine(
      const Offset(-12.5, 1),
      const Offset(-12.5, 8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    _face(canvas);
    canvas.restore();

    // ring
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _face(Canvas canvas) {
    final dark = Paint()..color = const Color(0xFF1A1450);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8
      ..color = const Color(0xFF1A1450);
    const l = Offset(-5.5, 6);
    const r = Offset(5.5, 6);

    void eyes() {
      for (final e in [l, r]) {
        canvas.drawCircle(e, 3.2, Paint()..color = Colors.white);
        canvas.drawCircle(e + const Offset(0.6, 0.6), 1.7, dark);
      }
    }

    void smile([double w = 5, double drop = 4]) {
      final p = Path()
        ..moveTo(-w, 13)
        ..quadraticBezierTo(0, 13 + drop, w, 13);
      canvas.drawPath(p, line);
    }

    switch (i) {
      case 0: // happy
        eyes();
        smile();
      case 1: // wink
        canvas.drawCircle(l, 3.2, Paint()..color = Colors.white);
        canvas.drawCircle(l + const Offset(0.6, 0.6), 1.7, dark);
        canvas.drawLine(r + const Offset(-3, 0), r + const Offset(3, 0), line);
        smile();
      case 2: // open mouth
        eyes();
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, 14), width: 8, height: 6),
          dark,
        );
      case 3: // closed happy eyes
        for (final e in [l, r]) {
          canvas.drawPath(
            Path()
              ..moveTo(e.dx - 3, e.dy + 1)
              ..quadraticBezierTo(e.dx, e.dy - 3, e.dx + 3, e.dy + 1),
            line,
          );
        }
        smile(5.5, 5);
      case 4: // sunglasses
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(-10, 2.5, 10, 9),
            const Radius.circular(3),
          ),
          dark,
        );
        canvas.drawLine(
          const Offset(-8, 4),
          const Offset(-5, 4),
          Paint()
            ..color = Colors.white54
            ..strokeWidth = 1.2,
        );
        smile(4, 3);
      case 5: // tongue out
        eyes();
        smile(5, 3);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(2, 17), width: 4.5, height: 5),
          Paint()..color = const Color(0xFFFF6F9C),
        );
      case 6: // surprised
        eyes();
        canvas.drawCircle(
          const Offset(0, 14.5),
          2.4,
          line..style = PaintingStyle.stroke,
        );
      default: // cool: raised brow
        eyes();
        canvas.drawLine(const Offset(2, 1), const Offset(9, -0.5), line);
        canvas.drawPath(
          Path()
            ..moveTo(-4, 14)
            ..quadraticBezierTo(0, 15 + math.sqrt(2), 5, 12.5),
          line,
        );
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.i != i;
}
