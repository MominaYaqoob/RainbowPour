import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/night_background.dart';
import '../app_flow.dart';

/// Splash 2: game title, a cone beaker that keeps filling, loading bar.
class GameSplash extends StatefulWidget {
  const GameSplash({super.key});

  @override
  State<GameSplash> createState() => _GameSplashState();
}

class _GameSplashState extends State<GameSplash> with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _load = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    _load.forward().whenComplete(_next);
  }

  Future<void> _next() async {
    final screen = await entryScreen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(screen, zoom: true));
  }

  @override
  void dispose() {
    _fill.dispose();
    _load.dispose();
    super.dispose();
  }

  // 0 -> 1 by 50% of the loop, hold until 80%, then drain.
  double _level(double v) =>
      seg(v, 0, 0.5, Curves.easeInOut) * (1 - seg(v, 0.8, 1, Curves.easeIn));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = math.min(size.width / 240, 1.6);
    final bottleH = size.height * 0.38;
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.24),
              Text(
                'Rainbow Pour',
                style: GoogleFonts.outfit(
                  fontSize: 31 * s,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppColors.titleShadow,
                      offset: Offset(0, 3 * s),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4 * s),
              Text(
                'WATER SORT',
                style: GoogleFonts.outfit(
                  fontSize: 12.5 * s,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5 * s,
                  color: const Color(0xFFBFC4FF),
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _fill,
                    builder: (_, _) => ConeBottle(
                      layers: const [1, 4, 3],
                      extraColor: 0,
                      extraProgress: _level(_fill.value),
                      width: bottleH * 36 / 118,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.035),
                child: AnimatedBuilder(
                  animation: _load,
                  builder: (_, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: size.width * 0.58,
                        height: 7 * s,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: Curves.easeInOut.transform(
                                  _load.value,
                                ),
                                child: const ColoredBox(color: AppColors.aqua),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      Text(
                        'Loading',
                        style: GoogleFonts.outfit(
                          fontSize: 11 * s,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
