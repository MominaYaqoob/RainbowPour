import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Moonlit night over a lake: sky, twinkling stars, crescent moon on the left,
/// two mountain layers and animated water with the moon's reflection.
class NightBackground extends StatefulWidget {
  const NightBackground({super.key, this.child});

  final Widget? child;

  @override
  State<NightBackground> createState() => _NightBackgroundState();
}

class _NightBackgroundState extends State<NightBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _NightPainter(_c), size: Size.infinite),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

// Star positions in a 240 x 480 design space.
// Kept to the side margins and top band so they never sit behind text.
const _stars = <Offset>[
  Offset(14, 150),
  Offset(205, 60),
  Offset(226, 110),
  Offset(30, 236),
  Offset(215, 266),
  Offset(12, 190),
  Offset(18, 336),
  Offset(225, 356),
  Offset(228, 200),
  Offset(10, 296),
  Offset(200, 130),
  Offset(228, 300),
];

const _sparkles = <Offset>[Offset(214, 90), Offset(222, 230), Offset(20, 260)];

class _NightPainter extends CustomPainter {
  _NightPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final s = size.width / 240;
    double yb(double y) => size.height - (480 - y) * s; // bottom anchored

    // sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.skyTop, AppColors.skyMid, AppColors.skyBottom],
          stops: [0, 0.5, 1],
        ).createShader(Offset.zero & size),
    );

    // stars (spread over the whole sky height)
    final star = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final p = Offset(
        _stars[i].dx / 240 * size.width,
        _stars[i].dy / 480 * size.height,
      );
      final k = 2 + i % 4;
      final a =
          0.2 + 0.7 * (0.5 + 0.5 * math.sin(2 * math.pi * (v * k + i / 12)));
      star.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(p, (0.9 + (i % 3) * 0.5) * s, star);
    }
    for (var i = 0; i < _sparkles.length; i++) {
      final p = Offset(
        _sparkles[i].dx / 240 * size.width,
        _sparkles[i].dy / 480 * size.height,
      );
      final a =
          0.1 +
          0.8 * (0.5 + 0.5 * math.sin(2 * math.pi * (v * (3 + i) + i / 3)));
      _sparkle(canvas, p, 6 * s, Colors.white.withValues(alpha: a));
    }

    paintMoon(canvas, Offset(40 * s, 78 * s), 18 * s, twinkle: v);

    // mountains
    _poly(canvas, s, yb, const [
      Offset(0, 398),
      Offset(36, 356),
      Offset(70, 384),
      Offset(120, 334),
      Offset(172, 380),
      Offset(214, 350),
      Offset(240, 372),
      Offset(240, 400),
      Offset(0, 400),
    ], const Color(0xFF36359A).withValues(alpha: 0.75));
    _poly(canvas, s, yb, const [
      Offset(0, 400),
      Offset(44, 376),
      Offset(96, 398),
      Offset(160, 364),
      Offset(240, 394),
      Offset(240, 400),
      Offset(0, 400),
    ], const Color(0xFF2A2A86));

    // lake
    final lake = Rect.fromLTRB(0, yb(398), size.width, size.height);
    canvas.drawRect(
      lake,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lakeTop, AppColors.lakeBottom],
        ).createShader(lake),
    );

    // waves: base y, amplitude, cycles per loop, alpha
    const waves = [
      [412.0, 3.0, 4.0, 0.35],
      [430.0, 4.0, 3.0, 0.28],
      [452.0, 4.0, 2.0, 0.22],
    ];
    final wp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s;
    for (final w in waves) {
      wp.color = const Color(0xFFA9AEFF).withValues(alpha: w[3]);
      final shift = 40 * w[2] * v; // design units
      final path = Path();
      for (var x = -4.0; x <= size.width + 4; x += 3) {
        final u = x / s - shift;
        final y = yb(w[0]) + math.sin(u / 40 * 2 * math.pi) * w[1] * s;
        x == -4.0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, wp);
    }

    // moon reflection
    const refl = [
      [404.0, 12.0, 0.5],
      [414.0, 18.0, 0.4],
      [426.0, 22.0, 0.35],
      [440.0, 16.0, 0.3],
    ];
    final rp = Paint();
    for (var i = 0; i < refl.length; i++) {
      final w =
          (refl[i][1] - 3 + 3 * math.sin(2 * math.pi * (v * (3 + i)))) * s;
      rp.color = const Color(0xFFFFF3C4).withValues(alpha: refl[i][2]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(40 * s, yb(refl[i][0]) + 1.1 * s),
            width: w,
            height: 2.2 * s,
          ),
          Radius.circular(1.1 * s),
        ),
        rp,
      );
    }
  }

  void _poly(
    Canvas canvas,
    double s,
    double Function(double) yb,
    List<Offset> pts,
    Color c,
  ) {
    final path = Path()..moveTo(pts.first.dx * s, yb(pts.first.dy));
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx * s, yb(p.dy));
    }
    canvas.drawPath(path, Paint()..color = c);
  }

  @override
  bool shouldRepaint(_NightPainter old) => false;
}

void _sparkle(Canvas canvas, Offset c, double r, Color color) {
  final k = r * 0.25;
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + k, c.dy - k)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx + k, c.dy + k)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - k, c.dy + k)
    ..lineTo(c.dx - r, c.dy)
    ..lineTo(c.dx - k, c.dy - k)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

/// Which side of the crescent is lit, and how far it is tilted (degrees,
/// negative = counter-clockwise). Change these two to restyle the moon.
const moonLitLeft = true;
const moonTilt = -20.0;

/// Thin crescent (about four days old), with
/// earthshine, craters, halo rings and a twinkling sparkle. [twinkle] is a
/// 0..1 loop value.
void paintMoon(Canvas canvas, Offset c, double r, {double twinkle = 0}) {
  final k = r / 19;
  // halo
  canvas.drawCircle(
    c,
    r + 26 * k,
    Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: 0.04),
  );
  canvas.drawCircle(
    c,
    r + 14 * k,
    Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: 0.05),
  );
  canvas.drawCircle(
    c,
    r + 8 * k,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.14),
  );
  // earthshine (the dark part of the disc)
  canvas.drawCircle(
    c,
    r,
    Paint()..color = Colors.white.withValues(alpha: 0.05),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.13),
  );

  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(moonTilt * math.pi / 180);
  canvas.scale(moonLitLeft ? -1 : 1, 1);
  canvas.translate(-c.dx, -c.dy);

  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..arcToPoint(
      Offset(c.dx, c.dy + r),
      radius: Radius.circular(r),
      clockwise: true,
    )
    ..arcToPoint(
      Offset(c.dx, c.dy - r),
      radius: Radius.elliptical(r * 0.6, r),
      clockwise: false,
    )
    ..close();

  canvas.drawPath(
    path,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFF0), Color(0xFFFFF1B8), Color(0xFFF6D77A)],
        stops: [0, 0.6, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );

  canvas.save();
  canvas.clipPath(path);
  final crater = Paint()
    ..color = const Color(0xFFD9C277).withValues(alpha: 0.65);
  canvas.drawCircle(Offset(c.dx + r * 0.5, c.dy - r * 0.35), r * 0.13, crater);
  canvas.drawCircle(Offset(c.dx + r * 0.3, c.dy + r * 0.3), r * 0.09, crater);
  canvas.drawCircle(Offset(c.dx + r * 0.62, c.dy + r * 0.15), r * 0.07, crater);
  canvas.drawCircle(Offset(c.dx + r * 0.4, c.dy - r * 0.72), r * 0.06, crater);
  canvas.restore();
  canvas.restore();

  final a = 0.2 + 0.8 * (0.5 + 0.5 * math.sin(2 * math.pi * twinkle * 5));
  _sparkle(
    canvas,
    Offset(c.dx - r - 6 * k, c.dy + r + 8 * k),
    6 * k,
    Colors.white.withValues(alpha: a),
  );
}
