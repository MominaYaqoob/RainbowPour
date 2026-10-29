import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'bottle_shape.dart';

/// Cone beaker (no cork) drawn with layered, shaded liquid. Layers are listed
/// bottom to top as color ids (see [AppColors.liquid]).
///
/// * [extraColor] / [extraProgress]: an extra layer on top that fills in.
/// * [tilt] (radians, clockwise): rotates the bottle around its middle while
///   the liquid stays level, like real water.
/// * [topLayerFraction]: how much of the top layer is left (1 = full, 0 =
///   poured out).
class ConeBottle extends StatelessWidget {
  const ConeBottle({
    super.key,
    required this.layers,
    this.width = 72,
    this.extraColor,
    this.extraProgress = 0,
    this.showShadow = true,
    this.tilt = 0,
    this.topLayerFraction = 1,
    this.shape = BottleShape.cone,
  });

  final List<int> layers;
  final double width;
  final int? extraColor;
  final double extraProgress;
  final bool showShadow;
  final double tilt;
  final double topLayerFraction;
  final BottleShape shape;

  /// How much of the top layer is still in the bottle when it has been
  /// tilted to [tilt] radians: liquid above the lip has already spilled.
  static double topLayerFractionForTilt(
    double tilt,
    int layerCount, {
    BottleShape shape = BottleShape.cone,
  }) => _ConeBottlePainter.fractionForTilt(tilt, layerCount, shape);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 118 / 36),
      painter: _ConeBottlePainter(
        layers,
        extraColor,
        extraProgress,
        showShadow,
        tilt,
        topLayerFraction,
        shape,
      ),
    );
  }
}

class _ConeBottlePainter extends CustomPainter {
  _ConeBottlePainter(
    this.layers,
    this.extraColor,
    this.extra,
    this.shadow,
    this.tilt,
    this.topFraction,
    this.shape,
  );

  final List<int> layers;
  final int? extraColor;
  final double extra;
  final bool shadow;
  final double tilt;
  final double topFraction;
  final BottleShape shape;

  static const _pivot = Offset(18, 55);

  /// Gradient is built on the nominal layer rect so extended fills keep the
  /// same look (colors clamp beyond the rect).
  static Paint _liquid(Rect nominal, Color c) =>
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(c, Colors.white, 0.3)!,
            Color.lerp(c, Colors.black, 0.1)!,
          ],
        ).createShader(nominal);

  void _rotateAbout(Canvas canvas, double angle) {
    canvas.translate(_pivot.dx, _pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-_pivot.dx, -_pivot.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 36);

    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(18, 113), width: 32, height: 7),
        Paint()..color = Colors.black.withValues(alpha: 0.32),
      );
    }

    final cone = shape.path();
    canvas.save();
    _rotateAbout(canvas, tilt);
    canvas.save();
    canvas.clipPath(cone);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 36, 110),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    // liquid, drawn in the level (counter-rotated) frame, extended sideways
    // and downwards so it still fills the bottle when tilted
    canvas.save();
    _rotateAbout(canvas, -tilt);
    const wide = 120.0;
    if (tilt.abs() >= 1e-4) {
      _paintTilted(canvas);
    } else {
      double top = 110;
      for (var i = 0; i < layers.length; i++) {
        final isTop = i == layers.length - 1 && extraColor == null;
        final f = isTop ? topFraction : 1.0;
        final nominal = Rect.fromLTWH(0, 110 - 18.0 * (i + 1), 36, 18);
        final y = nominal.top + 18 * (1 - f);
        final bottom = i == 0 ? 260.0 : nominal.bottom + 0.6;
        if (f > 0) {
          canvas.drawRect(
            Rect.fromLTRB(-wide, y, 36 + wide, bottom),
            _liquid(nominal, AppColors.liquid[layers[i]]),
          );
          if (i > 0) {
            canvas.drawRect(
              Rect.fromLTWH(-wide, y - 0.5, 36 + 2 * wide, 1),
              Paint()..color = Colors.white.withValues(alpha: 0.3),
            );
          }
          top = y;
        }
      }
      if (extraColor != null && extra > 0) {
        final h = 18.6 * extra;
        final nominal = Rect.fromLTWH(0, top - 18, 36, 18);
        canvas.drawRect(
          Rect.fromLTRB(-wide, top - h, 36 + wide, top + 0.6),
          _liquid(nominal, AppColors.liquid[extraColor!]),
        );
        top -= h;
      }
      final hasLiquid = layers.isNotEmpty || (extraColor != null && extra > 0);
      if (hasLiquid && top < 110) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(18, top),
            width: 40 + 90 * math.sin(tilt).abs(),
            height: 6,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.45),
        );
      }
    }
    canvas.restore();

    // side shading for a rounded, 3D look
    const edgeRect = Rect.fromLTWH(0, 0, 36, 110);
    canvas.drawRect(
      edgeRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x66000000),
            Color(0x4DFFFFFF),
            Color(0x00FFFFFF),
            Color(0x61000000),
          ],
          stops: [0, 0.26, 0.5, 1],
        ).createShader(edgeRect),
    );
    canvas.restore();

    Paint stroke(double w, double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w
      ..color = Colors.white.withValues(alpha: alpha);
    canvas.drawPath(cone, stroke(2, 1));
    for (final (x, y0, y1, w, a) in shape.shines) {
      canvas.drawLine(Offset(x, y0), Offset(x, y1), stroke(w, a));
    }
    final rim = Rect.fromCenter(
      center: const Offset(18, 4),
      width: shape.lipHalf * 2 + 1.6,
      height: 5,
    );
    canvas.drawOval(rim, Paint()..color = Colors.white.withValues(alpha: 0.3));
    canvas.drawOval(rim, stroke(1.7, 1));
    canvas.restore();
    canvas.restore();
  }

  // ---- tilted liquid: volume is conserved, the surface stays horizontal ----

  static final List<Offset> _coneOutline = _buildOutline();

  static List<Offset> _outlineOf(BottleShape s) =>
      s == BottleShape.cone ? _coneOutline : s.outline;

  static List<Offset> _buildOutline() {
    final pts = <Offset>[
      const Offset(12, 4),
      const Offset(12, 30),
      const Offset(2, 96),
    ];
    Offset cubic(Offset a, Offset b, Offset c, Offset d, double t) {
      final u = 1 - t;
      return a * (u * u * u) +
          b * (3 * u * u * t) +
          c * (3 * u * t * t) +
          d * (t * t * t);
    }

    for (var i = 1; i <= 8; i++) {
      pts.add(
        cubic(
          const Offset(2, 96),
          const Offset(1, 104),
          const Offset(6, 110),
          const Offset(12, 110),
          i / 8,
        ),
      );
    }
    pts.add(const Offset(24, 110));
    for (var i = 1; i <= 8; i++) {
      pts.add(
        cubic(
          const Offset(24, 110),
          const Offset(30, 110),
          const Offset(35, 104),
          const Offset(34, 96),
          i / 8,
        ),
      );
    }
    pts.addAll(const [Offset(24, 30), Offset(24, 4)]);
    return pts;
  }

  static double fractionForTilt(
    double tilt,
    int layerCount,
    BottleShape shape,
  ) {
    final outline = _outlineOf(shape);
    final c = math.cos(tilt);
    final s = math.sin(tilt);
    final rot = [
      for (final o in outline)
        Offset(
          _pivot.dx + (o.dx - _pivot.dx) * c - (o.dy - _pivot.dy) * s,
          _pivot.dy + (o.dx - _pivot.dx) * s + (o.dy - _pivot.dy) * c,
        ),
    ];
    // the lower of the two rim points is where liquid spills over
    final lh = shape.lipHalf;
    final lipL = _pivot.dy + (-lh) * s + (4 - _pivot.dy) * c;
    final lipR = _pivot.dy + lh * s + (4 - _pivot.dy) * c;
    final lip = math.max(lipL, lipR);
    final held = _areaBelow(rot, lip);
    final prev = layerCount <= 1
        ? 0.0
        : _areaBelow(outline, 110 - 18.0 * (layerCount - 1));
    final full = _areaBelow(outline, 110 - 18.0 * layerCount);
    return ((held - prev) / (full - prev)).clamp(0.0, 1.0);
  }

  /// Area of [p] lying at or below the horizontal line y = [level].
  static double _areaBelow(List<Offset> p, double level) {
    final out = <Offset>[];
    for (var i = 0; i < p.length; i++) {
      final a = p[i];
      final b = p[(i + 1) % p.length];
      final aIn = a.dy >= level;
      final bIn = b.dy >= level;
      Offset cross() {
        final t = (level - a.dy) / (b.dy - a.dy);
        return Offset(a.dx + t * (b.dx - a.dx), level);
      }

      if (bIn) {
        if (!aIn) out.add(cross());
        out.add(b);
      } else if (aIn) {
        out.add(cross());
      }
    }
    var sum = 0.0;
    for (var i = 0; i < out.length; i++) {
      final a = out[i];
      final b = out[(i + 1) % out.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }

  /// Horizontal line y whose region below it inside [p] holds [volume].
  static double _levelFor(List<Offset> p, double volume) {
    var lo = p.map((e) => e.dy).reduce(math.min);
    var hi = p.map((e) => e.dy).reduce(math.max);
    for (var i = 0; i < 26; i++) {
      final mid = (lo + hi) / 2;
      if (_areaBelow(p, mid) > volume) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  /// x extent of [p] on the line y = [level].
  static (double, double) _chord(List<Offset> p, double level) {
    var minX = double.infinity;
    var maxX = -double.infinity;
    for (var i = 0; i < p.length; i++) {
      final a = p[i];
      final b = p[(i + 1) % p.length];
      if ((a.dy - level) * (b.dy - level) <= 0 && a.dy != b.dy) {
        final t = (level - a.dy) / (b.dy - a.dy);
        final x = a.dx + t * (b.dx - a.dx);
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
      }
    }
    return (minX, maxX);
  }

  void _paintTilted(Canvas canvas) {
    const wide = 120.0;
    final outline = _outlineOf(shape);
    // bottle outline in the level frame
    final c = math.cos(tilt);
    final s = math.sin(tilt);
    final rot = [
      for (final o in outline)
        Offset(
          _pivot.dx + (o.dx - _pivot.dx) * c - (o.dy - _pivot.dy) * s,
          _pivot.dy + (o.dx - _pivot.dx) * s + (o.dy - _pivot.dy) * c,
        ),
    ];
    // cumulative volume up to the top of each layer, measured upright
    final cum = <double>[];
    var prev = 0.0;
    for (var i = 0; i < layers.length; i++) {
      final full = _areaBelow(outline, 110 - 18.0 * (i + 1));
      final isTop = i == layers.length - 1;
      final v = isTop ? prev + (full - prev) * topFraction : full;
      cum.add(v);
      prev = full;
    }
    double? below;
    double? topLevel;
    for (var i = 0; i < layers.length; i++) {
      if (cum[i] <= (i == 0 ? 0 : cum[i - 1]) + 1e-6) continue;
      final level = _levelFor(rot, cum[i]);
      final nominal = Rect.fromLTWH(0, 110 - 18.0 * (i + 1), 36, 18);
      canvas.drawRect(
        Rect.fromLTRB(-wide, level, 36 + wide, below ?? 300),
        _liquid(nominal, AppColors.liquid[layers[i]]),
      );
      if (below != null) {
        canvas.drawRect(
          Rect.fromLTWH(-wide, level - 0.5, 36 + 2 * wide, 1),
          Paint()..color = Colors.white.withValues(alpha: 0.3),
        );
      }
      below = level;
      topLevel = level;
    }
    if (topLevel != null) {
      final (x0, x1) = _chord(rot, topLevel);
      if (x1 > x0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset((x0 + x1) / 2, topLevel),
            width: x1 - x0,
            height: 4,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.45),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConeBottlePainter old) =>
      old.extra != extra ||
      old.extraColor != extraColor ||
      old.shadow != shadow ||
      old.tilt != tilt ||
      old.topFraction != topFraction ||
      old.shape != shape ||
      old.layers != layers;
}
