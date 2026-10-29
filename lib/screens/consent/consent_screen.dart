import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/entrance.dart';
import '../../widgets/game_text.dart';
import '../../widgets/night_background.dart';
import '../../widgets/water_button.dart';
import '../onboarding/onboarding_screen.dart';

/// First-launch screen: privacy and terms, then "Agree and continue".
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _agree() async {
    await AppPrefs.setConsentDone();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(fadeRoute(const OnboardingScreen(), zoom: true));
  }

  void _showDoc(String title) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10175E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The full text will be linked here before the game is released.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.4,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Entrance(
                  progress: _in,
                  begin: 0,
                  end: 0.3,
                  child: Row(
                    children: [
                      const SizedBox(
                        height: 24,
                        child: FittedBox(
                          child: ConeBottle(
                            layers: [4],
                            width: 36,
                            showShadow: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rainbow Pour',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Entrance(
                          progress: _in,
                          begin: 0.05,
                          end: 0.45,
                          child: _ShieldBadge(loop: _loop, size: 92 * s),
                        ),
                        SizedBox(height: 18 * s),
                        Entrance(
                          progress: _in,
                          begin: 0.15,
                          end: 0.5,
                          child: GameText('Before We', size: 22 * s),
                        ),
                        Entrance(
                          progress: _in,
                          begin: 0.22,
                          end: 0.58,
                          child: GameText(
                            'Start',
                            size: 33 * s,
                            gradient: const [
                              Color(0xFFFFF27A),
                              Color(0xFFFFA000),
                            ],
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        Entrance(
                          progress: _in,
                          begin: 0.35,
                          end: 0.75,
                          child: _card(s),
                        ),
                        SizedBox(height: 14 * s),
                        Entrance(
                          progress: _in,
                          begin: 0.45,
                          end: 0.8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _link(
                                'Terms of Service',
                                Icons.description_rounded,
                              ),
                              const SizedBox(width: 10),
                              _link('Privacy Policy', Icons.lock_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Entrance(
                progress: _in,
                begin: 0.6,
                end: 1,
                child: WaterButton(
                  width: math.min(size.width - 56, 300),
                  label: 'Agree and continue',
                  icon: Icons.check_rounded,
                  onPressed: _agree,
                ),
              ),
              SizedBox(height: size.height * 0.035),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(double s) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF141B66), Color(0xFF070B2E)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000020),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'By continuing you agree to our Terms of Service and Privacy Policy.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13.5 * s,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10 * s),
        Text(
          'Rainbow Pour is free and shows ads. You must be 13 or older to play.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12 * s,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    ),
  );

  Widget _link(String label, IconData icon) => GestureDetector(
    onTap: () => _showDoc(label),
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Gold shield with a slowly turning dashed halo.
class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge({required this.loop, required this.size});

  final Animation<double> loop;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final pulse = 1 + 0.04 * math.sin(2 * math.pi * loop.value * 2);
        return SizedBox(
          width: size * 1.3,
          height: size * 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: loop.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size.square(size * 1.3),
                  painter: _HaloPainter(),
                ),
              ),
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF27A), Color(0xFFFFA000)],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000020),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: size * 0.5,
                    color: const Color(0xFF4A2A00),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HaloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (var i = 0; i < 24; i++) {
      final a = i * 2 * math.pi / 24;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r,
        i.isEven ? 2.2 : 1.2,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) => false;
}
