import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';

/// Bold title text with a crisp 3D drop shadow. Pass [gradient] for a vertical
/// color fill (e.g. the gold second line of a title).
class GameText extends StatelessWidget {
  const GameText(
    this.text, {
    super.key,
    required this.size,
    this.gradient,
    this.color = Colors.white,
    this.letterSpacing = 0,
  });

  final String text;
  final double size;
  final List<Color>? gradient;
  final Color color;
  final double letterSpacing;

  TextStyle _style(Color c) => GoogleFonts.outfit(
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: letterSpacing,
    height: 1.05,
    color: c,
  );

  @override
  Widget build(BuildContext context) {
    final shadow = Transform.translate(
      offset: Offset(0, size * 0.09),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: _style(AppColors.titleShadow),
      ),
    );
    Widget face = Text(text, textAlign: TextAlign.center, style: _style(color));
    if (gradient != null) {
      face = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient!,
        ).createShader(r),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: _style(Colors.white),
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [shadow, face],
    );
  }
}
