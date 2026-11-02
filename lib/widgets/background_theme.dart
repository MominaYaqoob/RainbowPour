import 'package:flutter/material.dart';

import '../core/app_prefs.dart';

enum Celestial { crescent, sun, none }

/// Colours and decoration of one level background.
class BackgroundTheme {
  const BackgroundTheme({
    required this.name,
    required this.sky,
    required this.far,
    required this.near,
    required this.lakeTop,
    required this.lakeBottom,
    required this.wave,
    required this.celestial,
    required this.celestialColor,
    this.stars = false,
    this.hasAurora = false,
    this.price = 0,
  });

  final String name;
  final List<Color> sky; // top, middle, bottom
  final Color far;
  final Color near;
  final Color lakeTop;
  final Color lakeBottom;
  final Color wave;
  final Celestial celestial;
  final Color celestialColor;
  final bool stars;
  final bool hasAurora;

  /// Gems needed to buy it early in the shop (0 = free).
  final int price;

  static const night = BackgroundTheme(
    name: 'Night Lake',
    sky: [Color(0xFF060B33), Color(0xFF1B2680), Color(0xFF5646B5)],
    far: Color(0xBF36359A),
    near: Color(0xFF2A2A86),
    lakeTop: Color(0xFF4A45B0),
    lakeBottom: Color(0xFF0A1040),
    wave: Color(0xFFA9AEFF),
    celestial: Celestial.crescent,
    celestialColor: Color(0xFFFFF3C4),
    stars: true,
  );

  static const sunset = BackgroundTheme(
    name: 'Sunset Sea',
    sky: [Color(0xFFFFB38A), Color(0xFFFF6F9C), Color(0xFF7B4FB8)],
    far: Color(0xCCB467C9),
    near: Color(0xFF6A3FA8),
    lakeTop: Color(0xFF8A4FC2),
    lakeBottom: Color(0xFF3E2690),
    wave: Color(0xFFFFD7E8),
    celestial: Celestial.sun,
    celestialColor: Color(0xFFFFE9C4),
    price: 200,
  );

  static const lavender = BackgroundTheme(
    name: 'Lavender Peaks',
    sky: [Color(0xFFFFD6EA), Color(0xFFC9BBFF), Color(0xFF8E98F5)],
    far: Color(0xCCB7A5F5),
    near: Color(0xFF6F62D0),
    lakeTop: Color(0xFF8D7BE0),
    lakeBottom: Color(0xFF4A3FA8),
    wave: Color(0xFFFFFFFF),
    celestial: Celestial.sun,
    celestialColor: Color(0xFFFFF6FB),
    price: 200,
  );

  static const turquoise = BackgroundTheme(
    name: 'Turquoise Waves',
    sky: [Color(0xFFB8F3E8), Color(0xFF4FD1C5), Color(0xFF0E8FA8)],
    far: Color(0xCC5BC7C0),
    near: Color(0xFF148F9E),
    lakeTop: Color(0xFF1B97B0),
    lakeBottom: Color(0xFF0A5C74),
    wave: Color(0xFFFFFFFF),
    celestial: Celestial.sun,
    celestialColor: Color(0xFFFFFFFF),
    price: 300,
  );

  static const aurora = BackgroundTheme(
    name: 'Aurora',
    sky: [Color(0xFF041C32), Color(0xFF064663), Color(0xFF0B6E75)],
    far: Color(0xCC0A3550),
    near: Color(0xFF06263D),
    lakeTop: Color(0xFF0B5560),
    lakeBottom: Color(0xFF031A26),
    wave: Color(0xFF8FFFE0),
    celestial: Celestial.none,
    celestialColor: Color(0xFFFFFFFF),
    stars: true,
    hasAurora: true,
    price: 400,
  );

  static const dunes = BackgroundTheme(
    name: 'Golden Dunes',
    sky: [Color(0xFFFFF0CF), Color(0xFFFFC27A), Color(0xFFF0794A)],
    far: Color(0xCCF5A25D),
    near: Color(0xFFC25E38),
    lakeTop: Color(0xFFE5804A),
    lakeBottom: Color(0xFF8A3A1C),
    wave: Color(0xFFFFE9B0),
    celestial: Celestial.sun,
    celestialColor: Color(0xFFFFF8E5),
    price: 400,
  );

  static const all = [night, sunset, lavender, turquoise, aurora, dunes];

  /// The background a level gets automatically: a new one every 20 levels.
  static BackgroundTheme forLevel(int level) =>
      all[((level < 1 ? 1 : level) - 1) ~/ 20 % all.length];
}

/// Which background is used: [auto] follows the level, otherwise a pinned one.
abstract final class BackgroundSkin {
  /// -1 = automatic, otherwise an index into [BackgroundTheme.all].
  static final ValueNotifier<int> mode = ValueNotifier(-1);

  static Future<void> load() async {
    final m = await AppPrefs.bgMode();
    if (m >= -1 && m < BackgroundTheme.all.length) mode.value = m;
  }

  static Future<void> set(int m) async {
    mode.value = m;
    await AppPrefs.setBgMode(m);
  }

  static BackgroundTheme themeFor(int level) => mode.value < 0
      ? BackgroundTheme.forLevel(level)
      : BackgroundTheme.all[mode.value];
}
