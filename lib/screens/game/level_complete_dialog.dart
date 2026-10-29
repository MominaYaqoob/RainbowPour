import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../widgets/game_text.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/water_button.dart';

/// "Level complete" popup (UI only): stars pop in one by one, confetti falls
/// and the gem reward counts up.
class LevelCompleteDialog extends StatefulWidget {
  const LevelCompleteDialog({
    super.key,
    required this.level,
    required this.stars,
    required this.moves,
    required this.gems,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final int level;
  final int stars; // 1..3
  final int moves;
  final int gems;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  static Future<void> show(
    BuildContext context, {
    required int level,
    int stars = 3,
    int moves = 24,
    int gems = 30,
    required VoidCallback onNext,
    required VoidCallback onReplay,
    required VoidCallback onHome,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Level complete',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, _, _) => LevelCompleteDialog(
        level: level,
        stars: stars,
        moves: moves,
        gems: gems,
        onNext: onNext,
        onReplay: onReplay,
        onHome: onHome,
      ),
      transitionBuilder: (context, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.0).animate(c),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = math.min(size.width - 40, 340.0);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) =>
                    CustomPaint(painter: _ConfettiPainter(_loop.value)),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: Listenable.merge([_in, _loop]),
                builder: (context, _) => _card(w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(double w) {
    final v = _in.value;
    final gems = (widget.gems * seg(v, 0.55, 0.85, Curves.easeOut)).round();
    return Container(
      width: w,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2480), Color(0xFF0A1040)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000020),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameText('Level Complete!', size: 26),
          const SizedBox(height: 2),
          Text(
            'LEVEL ${widget.level}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: CustomPaint(
              size: Size(w - 40, 96),
              painter: _StarsPainter(v, widget.stars),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Solved in ${widget.moves} moves',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          Opacity(
            opacity: seg(v, 0.5, 0.65),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 18, 6),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GemIcon(size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+$gems',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4A2A00),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          WaterButton(
            width: math.min(w - 40, 270),
            label: 'Next Level',
            icon: Icons.arrow_forward_rounded,
            onPressed: widget.onNext,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onNext,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 17,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Watch an ad for 2x gems',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ghost('Replay', Icons.refresh_rounded, widget.onReplay),
              const SizedBox(width: 12),
              _ghost('Home', Icons.home_rounded, widget.onHome),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ghost(String label, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Three stars (the middle one bigger and higher); earned ones pop in with a
/// small burst, the rest stay as dim outlines.
class _StarsPainter extends CustomPainter {
  _StarsPainter(this.v, this.earned);

  final double v;
  final int earned;

  static Path _star(double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const spots = [(-1.0, 30.0, 26.0), (0.0, 22.0, 36.0), (1.0, 30.0, 26.0)];
    for (var i = 0; i < 3; i++) {
      final (dx, dy, r) = spots[i];
      final c = Offset(
        cx + dx * (size.width * 0.27),
        size.height / 2 + dy - 22,
      );
      final on = i < earned;
      final t0 = 0.12 + i * 0.16;
      final pop = on ? Curves.elasticOut.transform(seg(v, t0, t0 + 0.28)) : 1.0;
      if (pop <= 0) continue;

      final b = seg(v, t0, t0 + 0.22);
      if (on && b > 0 && b < 1) {
        for (var k = 0; k < 8; k++) {
          final a = k * math.pi / 4 + i;
          final d = r * 0.9 + r * 0.9 * Curves.easeOut.transform(b);
          canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * d,
            2.2 * (1 - b),
            Paint()..color = const Color(0xFFFFE680).withValues(alpha: 1 - b),
          );
        }
      }

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(on ? (1 - pop.clamp(0, 1)) * -0.6 : 0);
      canvas.scale(on ? pop : 1);
      final star = _star(r);
      if (on) {
        canvas.drawPath(
          star,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF27A), Color(0xFFFFA000)],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
        );
      } else {
        canvas.drawPath(
          star,
          Paint()..color = Colors.white.withValues(alpha: 0.08),
        );
      }
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round
          ..color = on ? Colors.white : Colors.white.withValues(alpha: 0.3),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.v != v || old.earned != earned;
}

/// Slowly falling coloured confetti over the whole screen.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble();
      final speed = 1 + rnd.nextInt(2); // whole loops per cycle, so it repeats
      final phase = rnd.nextDouble();
      final spin = rnd.nextDouble() * 6;
      final color = AppColors.liquid[rnd.nextInt(8)];
      final p = (t * speed + phase) % 1;
      final y = -20 + (size.height + 40) * p;
      final sway = math.sin(2 * math.pi * (t * 2 + phase)) * 14;
      canvas.save();
      canvas.translate(x * size.width + sway, y);
      canvas.rotate(spin + t * 2 * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -2.5, 8, 5),
          const Radius.circular(1.5),
        ),
        Paint()..color = color.withValues(alpha: 0.9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
