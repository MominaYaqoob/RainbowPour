import 'package:flutter/material.dart';

/// Moonlit night palette (see docs/PLAN.md, section 1).
abstract final class AppColors {
  static const skyTop = Color(0xFF060B33);
  static const skyMid = Color(0xFF1B2680);
  static const skyBottom = Color(0xFF5646B5);
  static const lakeTop = Color(0xFF4A45B0);
  static const lakeBottom = Color(0xFF0A1040);
  static const studioBg = Color(0xFF050922);

  static const gold = Color(0xFFFFD43B);
  static const goldDeep = Color(0xFFD9930A);
  static const titleShadow = Color(0xFF120F52);
  static const panel = Color(0xFF0B1040);

  static const aqua = Color(0xFF7FE9FF);
  static const aquaDeep = Color(0xFF1FA9FF);
  static const waterEdge = Color(0xFF0B63B0);

  /// Liquid colors, index = color id used by the game.
  static const liquid = <Color>[
    Color(0xFFFF3D5A), // red
    Color(0xFFFF9F0A), // orange
    Color(0xFFFFD60A), // yellow
    Color(0xFF2FD071), // green
    Color(0xFF18C8F0), // cyan
    Color(0xFF3B7BFF), // blue
    Color(0xFFA24BFF), // purple
    Color(0xFFFF5FB0), // pink
  ];
}
