import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' show Colors;

/// One vector symbol per liquid colour, drawn on the liquid in colorblind
/// mode. Index = colour id in `AppColors.liquid`.
///
/// Close colours get very different silhouettes: cream (moon), lime (ring)
/// and mint (hourglass); maroon (bolt), brown (cross) and red (heart); sky
/// (arrow) and cyan (drop).
abstract final class LiquidSymbols {
  static const count = 20;

  /// Names in colour-id order (also used by tests).
  static const names = <String>[
    'heart', // 0 red
    'triangle', // 1 orange
    'star', // 2 yellow
    'disc', // 3 green
    'drop', // 4 cyan
    'square', // 5 blue
    'diamond', // 6 purple
    'plus', // 7 pink
    'ring', // 8 lime
    'cross', // 9 brown
    'hexagon', // 10 teal
    'stripes', // 11 grey
    'moon', // 12 cream
    'bolt', // 13 maroon
    'pentagon', // 14 indigo
    'wave', // 15 peach
    'arrow', // 16 sky
    'flower', // 17 magenta
    'dots', // 18 olive
    'hourglass', // 19 mint
  ];

  static final List<Path> _paths = List<Path>.generate(count, _build);

  /// The symbol of [colorId] in a unit box: it fits in -1..1 on both axes.
  static Path pathFor(int colorId) => _paths[colorId % count];

  /// Draws the symbol centred on [center], about [size] wide: white with a
  /// thin dark outline, so it reads on light and on dark liquid.
  static void paint(Canvas canvas, int colorId, Offset center, double size) {
    final path = pathFor(colorId).transform(_matrix(center, size / 2));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, size * 0.13)
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white,
    );
  }

  static Float64List _matrix(Offset c, double s) {
    final m = Float64List(16);
    m[0] = s;
    m[5] = s;
    m[10] = 1;
    m[12] = c.dx;
    m[13] = c.dy;
    m[15] = 1;
    return m;
  }

  static Path _poly(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  static List<Offset> _regular(int n, double r, double startDeg) => [
    for (var i = 0; i < n; i++)
      Offset(
        r * math.cos((startDeg + 360 * i / n) * math.pi / 180),
        r * math.sin((startDeg + 360 * i / n) * math.pi / 180),
      ),
  ];

  static Path _plus() => _poly(const [
    Offset(-0.3, -0.95),
    Offset(0.3, -0.95),
    Offset(0.3, -0.3),
    Offset(0.95, -0.3),
    Offset(0.95, 0.3),
    Offset(0.3, 0.3),
    Offset(0.3, 0.95),
    Offset(-0.3, 0.95),
    Offset(-0.3, 0.3),
    Offset(-0.95, 0.3),
    Offset(-0.95, -0.3),
    Offset(-0.3, -0.3),
  ]);

  static Path _union(List<Path> parts) {
    var out = parts.first;
    for (final p in parts.skip(1)) {
      out = Path.combine(PathOperation.union, out, p);
    }
    return out;
  }

  static Path _circle(Offset c, double r) =>
      Path()..addOval(Rect.fromCircle(center: c, radius: r));

  static Path _build(int id) {
    switch (id) {
      case 0: // heart
        return Path()
          ..moveTo(0, 0.9)
          ..cubicTo(-1.0, 0.1, -1.0, -0.8, -0.5, -0.8)
          ..cubicTo(-0.2, -0.8, 0, -0.55, 0, -0.35)
          ..cubicTo(0, -0.55, 0.2, -0.8, 0.5, -0.8)
          ..cubicTo(1.0, -0.8, 1.0, 0.1, 0, 0.9)
          ..close();
      case 1: // triangle
        return _poly(const [
          Offset(0, -0.9),
          Offset(0.95, 0.75),
          Offset(-0.95, 0.75),
        ]);
      case 2: // star
        return _poly([
          for (var i = 0; i < 10; i++)
            Offset(
              (i.isEven ? 1.0 : 0.45) *
                  math.cos((-90 + 36 * i) * math.pi / 180),
              (i.isEven ? 1.0 : 0.45) *
                  math.sin((-90 + 36 * i) * math.pi / 180),
            ),
        ]);
      case 3: // disc
        return _circle(Offset.zero, 0.85);
      case 4: // drop
        return Path()
          ..moveTo(0, -1)
          ..cubicTo(0.3, -0.55, 0.75, -0.1, 0.75, 0.22)
          ..arcToPoint(
            const Offset(-0.75, 0.22),
            radius: const Radius.circular(0.75),
          )
          ..cubicTo(-0.75, -0.1, -0.3, -0.55, 0, -1)
          ..close();
      case 5: // square
        return Path()..addRect(const Rect.fromLTRB(-0.78, -0.78, 0.78, 0.78));
      case 6: // diamond
        return _poly(const [
          Offset(0, -1),
          Offset(0.8, 0),
          Offset(0, 1),
          Offset(-0.8, 0),
        ]);
      case 7: // plus
        return _plus();
      case 8: // ring
        return Path.combine(
          PathOperation.difference,
          _circle(Offset.zero, 0.88),
          _circle(Offset.zero, 0.42),
        );
      case 9: // cross
        final m = Float64List(16)
          ..[0] = math.cos(math.pi / 4)
          ..[1] = math.sin(math.pi / 4)
          ..[4] = -math.sin(math.pi / 4)
          ..[5] = math.cos(math.pi / 4)
          ..[10] = 1
          ..[15] = 1;
        return _plus().transform(m);
      case 10: // hexagon
        return _poly(_regular(6, 0.95, 0));
      case 11: // stripes
        return _union([
          Path()..addRect(const Rect.fromLTRB(-0.9, -0.82, 0.9, -0.5)),
          Path()..addRect(const Rect.fromLTRB(-0.9, -0.16, 0.9, 0.16)),
          Path()..addRect(const Rect.fromLTRB(-0.9, 0.5, 0.9, 0.82)),
        ]);
      case 12: // moon
        return Path.combine(
          PathOperation.difference,
          _circle(Offset.zero, 0.9),
          _circle(const Offset(0.5, -0.25), 0.78),
        );
      case 13: // bolt
        return _poly(const [
          Offset(0.3, -1),
          Offset(-0.6, 0.12),
          Offset(-0.05, 0.12),
          Offset(-0.3, 1),
          Offset(0.65, -0.22),
          Offset(0.1, -0.22),
        ]);
      case 14: // pentagon
        return _poly(_regular(5, 0.98, -90));
      case 15: // wave
        return _poly(const [
          Offset(-0.95, -0.1),
          Offset(-0.48, -0.62),
          Offset(0, -0.1),
          Offset(0.48, -0.62),
          Offset(0.95, -0.1),
          Offset(0.95, 0.5),
          Offset(0.48, 0.0),
          Offset(0, 0.5),
          Offset(-0.48, 0.0),
          Offset(-0.95, 0.5),
        ]);
      case 16: // arrow
        return _poly(const [
          Offset(0, -1),
          Offset(0.85, 0),
          Offset(0.32, 0),
          Offset(0.32, 0.92),
          Offset(-0.32, 0.92),
          Offset(-0.32, 0),
          Offset(-0.85, 0),
        ]);
      case 17: // flower
        return _union([
          _circle(const Offset(0.45, 0), 0.42),
          _circle(const Offset(-0.45, 0), 0.42),
          _circle(const Offset(0, 0.45), 0.42),
          _circle(const Offset(0, -0.45), 0.42),
          _circle(Offset.zero, 0.4),
        ]);
      case 18: // dots
        return _union([
          _circle(const Offset(0, -0.52), 0.34),
          _circle(const Offset(-0.55, 0.42), 0.34),
          _circle(const Offset(0.55, 0.42), 0.34),
        ]);
      default: // 19 hourglass
        return _poly(const [
          Offset(-0.82, -0.88),
          Offset(0.82, -0.88),
          Offset(0.12, 0),
          Offset(0.82, 0.88),
          Offset(-0.82, 0.88),
          Offset(-0.12, 0),
        ]);
    }
  }
}
