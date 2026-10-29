import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../widgets/entrance.dart';
import '../../widgets/game_text.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/night_background.dart';
import '../../widgets/water_button.dart';
import '../profile/nickname_screen.dart';

const kWelcomeGems = 100;

/// Welcome gift: rays turn behind a big gem, the amount counts up, and
/// tapping Claim bursts the gems and moves on.
class WelcomeRewardScreen extends StatefulWidget {
  const WelcomeRewardScreen({super.key});

  @override
  State<WelcomeRewardScreen> createState() => _WelcomeRewardScreenState();
}

class _WelcomeRewardScreenState extends State<WelcomeRewardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool _claimed = false;

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    _burst.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    if (_claimed || _in.value < 0.7) return;
    setState(() => _claimed = true);
    await AppPrefs.claimWelcome(kWelcomeGems);
    _burst.forward();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(fadeRoute(const NicknameScreen(), zoom: true));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = (size.width / 240).clamp(0.9, 1.5);
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
              Entrance(
                progress: _in,
                begin: 0,
                end: 0.2,
                child: GameText('Welcome', size: 24 * s),
              ),
              Entrance(
                progress: _in,
                begin: 0.05,
                end: 0.25,
                child: GameText(
                  'Gift!',
                  size: 42 * s,
                  gradient: const [Color(0xFFFFF27A), Color(0xFFFFA000)],
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_in, _loop, _burst]),
                  builder: (context, _) {
                    final v = _in.value;
                    final pop = Curves.elasticOut.transform(seg(v, 0.1, 0.4));
                    final bob = math.sin(2 * math.pi * _loop.value * 3) * 5;
                    final b = _burst.value;
                    final gone = 1 - seg(b, 0.3, 1);
                    final count =
                        (kWelcomeGems * seg(v, 0.3, 0.7, Curves.easeOutCubic))
                            .round();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RaysPainter(
                              _loop.value,
                              seg(v, 0.05, 0.4) * (1 + b * 0.6),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(painter: _BurstPainter(b)),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: gone,
                              child: SizedBox(
                                width: 190 * s,
                                height: 150 * s,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: 6 * s,
                                      bottom: 6 * s,
                                      child: Transform.rotate(
                                        angle: -0.35,
                                        child: Transform.scale(
                                          scale: Curves.elasticOut.transform(
                                            seg(v, 0.22, 0.5),
                                          ),
                                          child: GemIcon(size: 62 * s),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8 * s,
                                      bottom: 10 * s,
                                      child: Transform.rotate(
                                        angle: 0.3,
                                        child: Transform.scale(
                                          scale: Curves.elasticOut.transform(
                                            seg(v, 0.28, 0.56),
                                          ),
                                          child: GemIcon(size: 52 * s),
                                        ),
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: Offset(0, bob - b * 14),
                                      child: Transform.scale(
                                        scale: pop * (1 + 0.15 * b),
                                        child: GemIcon(size: 120 * s),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 4 * s),
                            Opacity(
                              opacity: seg(v, 0.25, 0.4) * gone,
                              child: GameText(
                                '+$count',
                                size: 52 * s,
                                gradient: const [
                                  Color(0xFFFFF27A),
                                  Color(0xFFFFA000),
                                ],
                              ),
                            ),
                            Opacity(
                              opacity: seg(v, 0.3, 0.5) * gone,
                              child: Text(
                                'GEMS',
                                style: GoogleFonts.outfit(
                                  fontSize: 13 * s,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 6,
                                  color: AppColors.aqua,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Entrance(
                progress: _in,
                begin: 0.5,
                end: 0.75,
                child: Text(
                  'A little something to get you started.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              Entrance(
                progress: _in,
                begin: 0.7,
                end: 1,
                child: WaterButton(
                  width: math.min(size.width - 56, 300),
                  label: 'Claim',
                  icon: Icons.card_giftcard_rounded,
                  onPressed: _claim,
                ),
              ),
              SizedBox(height: size.height * 0.035),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft golden rays turning behind the gem.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t, this.strength);

  final double t;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final c = Offset(size.width / 2, size.height * 0.4);
    final r = size.shortestSide * 0.95;
    final shader = RadialGradient(
      colors: [
        const Color(0xFFFFE680).withValues(alpha: 0.4 * strength.clamp(0, 1)),
        const Color(0x00FFE680),
      ],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < 12; i++) {
      final a = t * 2 * math.pi * 0.5 + i * 2 * math.pi / 12;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.09) * r, c.dy + math.sin(a - 0.09) * r)
        ..lineTo(c.dx + math.cos(a + 0.09) * r, c.dy + math.sin(a + 0.09) * r)
        ..close();
      canvas.drawPath(path, Paint()..shader = shader);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => true;
}

/// Gems and sparkles flying outward when the gift is claimed.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.b);

  final double b;

  @override
  void paint(Canvas canvas, Size size) {
    if (b <= 0 || b >= 1) return;
    final c = Offset(size.width / 2, size.height * 0.4);
    final e = Curves.easeOutCubic.transform(b);
    for (var i = 0; i < 18; i++) {
      final a = i * 2 * math.pi / 18 + (i.isOdd ? 0.15 : 0);
      final d = (60 + (i % 3) * 36) * e + 20;
      final p = c + Offset(math.cos(a), math.sin(a)) * d;
      final color = i % 3 == 0
          ? AppColors.aqua
          : (i % 3 == 1 ? AppColors.gold : Colors.white);
      canvas.drawCircle(
        p,
        (5 - 4 * b) * (i.isEven ? 1 : 0.7),
        Paint()..color = color.withValues(alpha: 1 - b),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.b != b;
}
