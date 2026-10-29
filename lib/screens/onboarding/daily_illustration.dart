import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../widgets/gem_icon.dart';
import 'tap_lift_illustration.dart';

/// Page 5: a streak card. The flame flickers, the week's days tick off one by
/// one, today's gift pulses and the reward chip slides in.
class DailyIllustration extends StatefulWidget {
  const DailyIllustration({super.key});

  @override
  State<DailyIllustration> createState() => _DailyIllustrationState();
}

class _DailyIllustrationState extends State<DailyIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kIllustrationSize,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final alpha = seg(v, 0, 0.05) * (1 - seg(v, 0.94, 1));
          final chip = seg(v, 0.62, 0.78, Curves.easeOutBack);
          return Opacity(
            opacity: alpha,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 14,
                  top: 10,
                  child: CustomPaint(
                    size: const Size(44, 52),
                    painter: _FlamePainter(v),
                  ),
                ),
                Positioned(
                  left: 68,
                  top: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5-day streak',
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Keep it going!',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < 7; i++) _day(i, v),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 142 + (1 - chip) * 14,
                  child: Opacity(
                    opacity: chip.clamp(0.0, 1.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 4, 14, 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 1.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GemIcon(size: 17),
                            const SizedBox(width: 6),
                            Text(
                              'Today: +40 gems',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4A2A00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _day(int i, double v) {
    const d = 28.0;
    final cx = 20 + i * 29.3;
    final done = i < 5;
    final today = i == 5;
    final pop = done
        ? Curves.elasticOut.transform(
            seg(v, 0.1 + i * 0.09, 0.1 + i * 0.09 + 0.16),
          )
        : 0.0;
    Widget circle;
    if (done) {
      circle = Stack(
        alignment: Alignment.center,
        children: [
          _ring(d, Colors.white.withValues(alpha: 0.35)),
          Transform.scale(
            scale: pop,
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF27A), Color(0xFFFFA000)],
                ),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Color(0xFF4A2A00),
              ),
            ),
          ),
        ],
      );
    } else if (today) {
      final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * v * 5);
      circle = Transform.scale(
        scale: 1 + 0.1 * pulse,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.5 * pulse),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.card_giftcard_rounded,
            size: 16,
            color: AppColors.gold,
          ),
        ),
      );
    } else {
      circle = Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Icon(
          Icons.emoji_events_rounded,
          size: 15,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      );
    }
    return Positioned(
      left: cx - 18,
      top: 78,
      width: 36,
      child: Column(
        children: [
          SizedBox(
            height: d + 4,
            child: Center(child: circle),
          ),
          Text(
            _days[i],
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double d, Color c) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.08),
      border: Border.all(color: c),
    ),
  );
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.v);

  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final wob = math.sin(2 * math.pi * v * 10);
    canvas.save();
    canvas.translate(size.width / 2, size.height - 3);
    canvas.scale(1.04 + 0.06 * wob, 1.0 - 0.05 * wob);
    canvas.scale(size.width / 40);
    canvas.translate(0, -25);

    final outer = Path()
      ..moveTo(0, -24)
      ..cubicTo(8, -12, 18, -6, 18, 6)
      ..cubicTo(18, 18, 10, 25, 0, 25)
      ..cubicTo(-10, 25, -18, 18, -18, 6)
      ..cubicTo(-18, -2, -12, -7, -7, -15)
      ..cubicTo(-5, -8, -2, -7, 0, -24)
      ..close();
    final inner = Path()
      ..moveTo(0, -3)
      ..cubicTo(5, 4, 10, 8, 10, 14)
      ..cubicTo(10, 21, 5, 25, 0, 25)
      ..cubicTo(-5, 25, -10, 21, -10, 14)
      ..cubicTo(-10, 8, -4, 4, 0, -3)
      ..close();
    canvas.drawPath(outer, Paint()..color = const Color(0xFFFF7A1C));
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.drawPath(inner, Paint()..color = const Color(0xFFFFD60A));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.v != v;
}
