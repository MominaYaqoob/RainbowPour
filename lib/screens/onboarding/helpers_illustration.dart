import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../widgets/gem_icon.dart';
import 'tap_lift_illustration.dart';

/// Page 4: the three helper buttons hop one after another; the first two cost
/// gems, and a pill reminds that an ad gives them for free.
class HelpersIllustration extends StatefulWidget {
  const HelpersIllustration({super.key});

  @override
  State<HelpersIllustration> createState() => _HelpersIllustrationState();
}

class _HelpersIllustrationState extends State<HelpersIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _items = [
    (Icons.undo_rounded, 'Undo', null),
    (Icons.lightbulb_rounded, 'Hint', 25),
    (Icons.add_rounded, '+ Bottle', 40),
  ];
  static const _xs = [36.0, 108.0, 180.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kIllustrationSize,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < 3; i++) _button(i, v),
              Positioned(
                left: 0,
                right: 0,
                top: 138,
                child: Center(child: _adPill(v)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _button(int i, double v) {
    // each button hops in turn, with a soft ring when it lands
    final p = (v - i * 0.22) % 1.0;
    final up = seg(p, 0, 0.18, Curves.easeOut);
    final down = seg(p, 0.18, 0.36, Curves.bounceOut);
    final hop = 14 * up * (1 - down);
    final ring = seg(p, 0.34, 0.7);
    final (icon, label, cost) = _items[i];
    const r = 27.0;
    return Positioned(
      left: _xs[i] - 40,
      top: 22,
      width: 80,
      child: Column(
        children: [
          SizedBox(
            height: r * 2 + 8,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (ring > 0 && ring < 1)
                  Positioned(
                    top: r + 4 - (r + 14 * ring),
                    child: Container(
                      width: (r + 14 * ring) * 2,
                      height: (r + 14 * ring) * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.5 * (1 - ring),
                          ),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6 - hop + 2,
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x4D000000),
                    ),
                  ),
                ),
                Positioned(
                  top: 4 - hop,
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3E6BFF), Color(0xFF1B3FB0)],
                      ),
                      border: Border.all(color: Colors.white, width: 2.2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 5,
                          child: Container(
                            width: 30,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        Icon(icon, size: 28, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                if (cost != null)
                  Positioned(
                    right: 2,
                    top: -2 - hop,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GemIcon(size: 11),
                          const SizedBox(width: 2),
                          Text(
                            '$cost',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF4A2A00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adPill(double v) {
    final glow = 0.5 + 0.5 * math.sin(2 * math.pi * v);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5 + 0.4 * glow),
          width: 1.4,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            size: 16,
            color: AppColors.gold,
          ),
          const SizedBox(width: 6),
          Text(
            'Watch an ad: get one free',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
