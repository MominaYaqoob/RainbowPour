import 'package:flutter/material.dart';

import '../core/app_prefs.dart';

/// The glass shapes a bottle can have. All are drawn in a 36 x 110 box.
enum BottleShape {
  cone('Cone Beaker'),
  flask('Round Flask'),
  tube('Test Tube'),
  potion('Potion'),
  jar('Wide Jar'),
  diamond('Diamond');

  const BottleShape(this.label);

  final String label;

  /// Half the width of the opening, used for the rim and the spill point.
  double get lipHalf => switch (this) {
    BottleShape.cone || BottleShape.flask => 6,
    BottleShape.potion || BottleShape.diamond => 6,
    BottleShape.tube => 11,
    BottleShape.jar => 14,
  };

  /// Shine strokes: (x, y from, y to, width, opacity).
  List<(double, double, double, double, double)> get shines => switch (this) {
    BottleShape.cone => const [
      (8, 58, 92, 2.6, 0.9),
      (16, 9, 24, 2.2, 0.9),
      (29, 66, 82, 1.6, 0.3),
    ],
    BottleShape.flask => const [
      (6.5, 54, 90, 2.6, 0.9),
      (14, 9, 24, 2.2, 0.9),
      (29, 60, 84, 1.6, 0.3),
    ],
    BottleShape.tube => const [
      (11.5, 14, 92, 2.6, 0.9),
      (25, 30, 80, 1.6, 0.3),
    ],
    BottleShape.potion => const [
      (7, 52, 84, 2.6, 0.9),
      (14.5, 9, 22, 2.2, 0.9),
      (30, 56, 80, 1.6, 0.3),
    ],
    BottleShape.jar => const [(8.5, 16, 92, 2.6, 0.9), (28, 30, 80, 1.6, 0.3)],
    BottleShape.diamond => const [
      (7, 52, 76, 2.6, 0.9),
      (15, 9, 20, 2.2, 0.9),
      (29, 52, 72, 1.6, 0.3),
    ],
  };

  Path path() {
    switch (this) {
      case BottleShape.cone:
        return Path()
          ..moveTo(12, 4)
          ..lineTo(12, 30)
          ..lineTo(2, 96)
          ..cubicTo(1, 104, 6, 110, 12, 110)
          ..lineTo(24, 110)
          ..cubicTo(30, 110, 35, 104, 34, 96)
          ..lineTo(24, 30)
          ..lineTo(24, 4)
          ..close();
      case BottleShape.flask:
        return Path()
          ..moveTo(11, 4)
          ..lineTo(11, 26)
          ..cubicTo(11, 34, 2, 36, 2, 50)
          ..lineTo(2, 92)
          ..cubicTo(2, 104, 10, 110, 18, 110)
          ..cubicTo(26, 110, 34, 104, 34, 92)
          ..lineTo(34, 50)
          ..cubicTo(34, 36, 25, 34, 25, 26)
          ..lineTo(25, 4)
          ..close();
      case BottleShape.tube:
        return Path()
          ..moveTo(7, 4)
          ..lineTo(7, 96)
          ..cubicTo(7, 106, 12, 110, 18, 110)
          ..cubicTo(24, 110, 29, 106, 29, 96)
          ..lineTo(29, 4)
          ..close();
      case BottleShape.potion:
        return Path()
          ..moveTo(12, 4)
          ..lineTo(12, 28)
          ..cubicTo(0, 38, 0, 80, 6, 94)
          ..cubicTo(10, 104, 14, 110, 18, 110)
          ..cubicTo(22, 110, 26, 104, 30, 94)
          ..cubicTo(36, 80, 36, 38, 24, 28)
          ..lineTo(24, 4)
          ..close();
      case BottleShape.jar:
        return Path()
          ..moveTo(4, 9)
          ..quadraticBezierTo(4, 4, 9, 4)
          ..lineTo(27, 4)
          ..quadraticBezierTo(32, 4, 32, 9)
          ..lineTo(32, 96)
          ..cubicTo(32, 105, 26, 110, 18, 110)
          ..cubicTo(10, 110, 4, 105, 4, 96)
          ..close();
      case BottleShape.diamond:
        return Path()
          ..moveTo(12, 4)
          ..lineTo(12, 22)
          ..lineTo(2, 46)
          ..lineTo(2, 78)
          ..lineTo(18, 110)
          ..lineTo(34, 78)
          ..lineTo(34, 46)
          ..lineTo(24, 22)
          ..lineTo(24, 4)
          ..close();
    }
  }

  static final Map<BottleShape, List<Offset>> _outlines = {};

  /// The glass outline as a polygon (used to work out how liquid sits when
  /// the bottle is tilted).
  List<Offset> get outline => _outlines.putIfAbsent(this, () {
    final pts = <Offset>[];
    for (final m in path().computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 2) {
        pts.add(m.getTangentForOffset(d)!.position);
      }
    }
    return pts;
  });
}

/// The bottle shape the player has equipped; Home and Game follow it.
abstract final class BottleSkin {
  static final ValueNotifier<BottleShape> shape = ValueNotifier(
    BottleShape.cone,
  );

  static Future<void> load() async {
    final i = await AppPrefs.skin();
    if (i >= 0 && i < BottleShape.values.length) {
      shape.value = BottleShape.values[i];
    }
  }

  static Future<void> equip(BottleShape s) async {
    shape.value = s;
    await AppPrefs.setSkin(s.index);
  }
}
