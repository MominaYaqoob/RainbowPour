// Draws the app icon (the "C" rainbow drop) and writes the Android launcher
// icons. Run from the project root:
//
//   flutter test tools/make_icon_test.dart
//
// Output: legacy `ic_launcher.png` in every mipmap-* folder, the adaptive
// icon layers (`ic_launcher_foreground.png`, `ic_launcher_background.png`),
// and a 512 px Play Store icon in `docs/store_icon_512.png`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _navy = Color(0xFF1B1F77);
const _glow = Color(0xFF2A33B0);
const _shadow = Color(0xFF12154F);
const _bands = <(double, double, Color)>[
  (20, 66, Color(0xFF9B5CFF)),
  (66, 92, Color(0xFF3BA8FF)),
  (92, 118, Color(0xFF3DDC84)),
  (118, 143, Color(0xFFFFB02E)),
  (143, 175, Color(0xFFFF4D5E)),
];

Path _drop() {
  final p = Path()..moveTo(90, 22);
  p.cubicTo(90, 22, 38, 80, 38, 112);
  p.arcTo(
    Rect.fromCircle(center: const Offset(90, 112), radius: 52),
    3.141592653589793,
    -3.141592653589793,
    false,
  );
  p.cubicTo(142, 80, 90, 22, 90, 22);
  p.close();
  return p;
}

void _sparkle(Canvas c, Offset at, double r) {
  final k = r * 0.3;
  final p = Path()
    ..moveTo(at.dx, at.dy - r)
    ..lineTo(at.dx + k, at.dy - k)
    ..lineTo(at.dx + r, at.dy)
    ..lineTo(at.dx + k, at.dy + k)
    ..lineTo(at.dx, at.dy + r)
    ..lineTo(at.dx - k, at.dy + k)
    ..lineTo(at.dx - r, at.dy)
    ..lineTo(at.dx - k, at.dy - k)
    ..close();
  c.drawPath(p, Paint()..color = const Color(0xFFFFE066));
}

/// The drop, in a 180 x 180 design space.
void _paintDrop(Canvas c, {required List<(Offset, double)> sparkles}) {
  final drop = _drop();
  c.save();
  c.clipPath(drop);
  for (final (top, bottom, color) in _bands) {
    c.drawRect(Rect.fromLTRB(30, top, 150, bottom), Paint()..color = color);
  }
  c.restore();
  c.drawPath(
    drop,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white,
  );
  c.save();
  c.translate(66, 108);
  c.rotate(18 * 3.141592653589793 / 180);
  c.drawOval(
    Rect.fromCenter(center: Offset.zero, width: 14, height: 44),
    Paint()..color = Colors.white.withValues(alpha: 0.5),
  );
  c.restore();
  for (final (at, r) in sparkles) {
    _sparkle(c, at, r);
  }
}

enum _Layer { full, background, foreground }

void _paint(Canvas c, double size, _Layer layer) {
  switch (layer) {
    case _Layer.full:
      c.scale(size / 180);
      c.clipRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 180, 180),
          const Radius.circular(40),
        ),
      );
      c.drawRect(const Rect.fromLTWH(0, 0, 180, 180), Paint()..color = _navy);
      c.drawCircle(const Offset(90, 80), 76, Paint()..color = _glow);
      c.drawOval(
        Rect.fromCenter(center: const Offset(90, 166), width: 92, height: 12),
        Paint()..color = _shadow,
      );
      _paintDrop(
        c,
        sparkles: const [(Offset(150, 40), 10), (Offset(30, 50), 7)],
      );
    case _Layer.background:
      c.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = _navy);
      c.drawCircle(
        Offset(size / 2, size * 0.46),
        size * 0.42,
        Paint()..color = _glow,
      );
    case _Layer.foreground:
      // The drop sits inside the 66% safe zone of the adaptive icon.
      final s = size * 0.60 / 142;
      c.translate(size / 2 - 90 * s, size / 2 - 93 * s);
      c.scale(s);
      c.drawOval(
        Rect.fromCenter(center: const Offset(90, 170), width: 80, height: 10),
        Paint()..color = _shadow.withValues(alpha: 0.6),
      );
      _paintDrop(
        c,
        sparkles: const [(Offset(136, 38), 9), (Offset(44, 50), 6)],
      );
  }
}

Future<void> _write(String path, double size, _Layer layer) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _paint(canvas, size, layer);
  final image = await recorder.endRecording().toImage(
    size.round(),
    size.round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
}

void main() {
  testWidgets('writes the launcher icons', (tester) async {
    await tester.runAsync(() async {
      const res = 'android/app/src/main/res';
      const legacy = {
        'mdpi': 48.0,
        'hdpi': 72.0,
        'xhdpi': 96.0,
        'xxhdpi': 144.0,
        'xxxhdpi': 192.0,
      };
      for (final e in legacy.entries) {
        final dir = '$res/mipmap-${e.key}';
        await _write('$dir/ic_launcher.png', e.value, _Layer.full);
        final layer = e.value / 48 * 108;
        await _write(
          '$dir/ic_launcher_foreground.png',
          layer,
          _Layer.foreground,
        );
        await _write(
          '$dir/ic_launcher_background.png',
          layer,
          _Layer.background,
        );
      }
      await _write('docs/store_icon_512.png', 512, _Layer.full);
      final xml = File('$res/mipmap-anydpi-v26/ic_launcher.xml');
      await xml.parent.create(recursive: true);
      await xml.writeAsString('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''');
    });
  });
}
