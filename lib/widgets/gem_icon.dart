import 'package:flutter/material.dart';

/// Small cyan gem used for prices and rewards.
class GemIcon extends StatelessWidget {
  const GemIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _GemPainter());
}

class _GemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // design box 18 x 21, scaled to fit
    final s = size.height / 21;
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.5);
    canvas.scale(s);
    canvas.translate(0, -0.5);
    final body = Path()
      ..moveTo(-9, -3)
      ..lineTo(-5, -10)
      ..lineTo(5, -10)
      ..lineTo(9, -3)
      ..lineTo(0, 11)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9DF6FF), Color(0xFF1E9BE0)],
        ).createShader(const Rect.fromLTRB(-9, -10, 9, 11)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-9, -3)
        ..lineTo(-5, -10)
        ..lineTo(5, -10)
        ..lineTo(9, -3)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawLine(const Offset(-9, -3), const Offset(9, -3), facet);
    canvas.drawLine(const Offset(-3, -3), const Offset(0, 11), facet);
    canvas.drawLine(const Offset(3, -3), const Offset(0, 11), facet);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GemPainter old) => false;
}
