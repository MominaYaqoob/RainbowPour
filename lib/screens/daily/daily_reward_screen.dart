import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../widgets/entrance.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/water_button.dart';

/// 7-day reward calendar. UI demo: days 1-2 are claimed, day 3 is today.
class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  static const _amounts = [20, 30, 40, 50, 60, 80, 150];
  static const _today = 2; // index of today's day
  bool _claimed = false;

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final gridW = math.min(size.width - 40, 380.0);
    const gap = 10.0;
    final cell = (gridW - gap * 3) / 4;
    return PageShell(
      title: 'Daily Reward',
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Entrance(
              progress: _in,
              begin: 0,
              end: 0.3,
              child: _streakBanner(gridW),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: gridW,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 4; i++)
                        _entranceTile(i, cell, cell * 1.12),
                    ],
                  ),
                  const SizedBox(height: gap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _entranceTile(4, cell, cell * 1.12),
                      _entranceTile(5, cell, cell * 1.12),
                      _entranceTile(6, cell * 2 + gap, cell * 1.12),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Entrance(
              progress: _in,
              begin: 0.6,
              end: 1,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, child) => Transform.scale(
                  scale: _claimed
                      ? 1
                      : 1 + 0.025 * math.sin(2 * math.pi * _loop.value),
                  child: child,
                ),
                child: WaterButton(
                  width: math.min(size.width - 56, 300),
                  label: _claimed ? 'Claimed' : 'Claim +${_amounts[_today]}',
                  icon: _claimed
                      ? Icons.check_rounded
                      : Icons.card_giftcard_rounded,
                  dim: _claimed,
                  onPressed: () {
                    if (!_claimed) setState(() => _claimed = true);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Entrance(
              progress: _in,
              begin: 0.7,
              end: 1,
              child: GestureDetector(
                onTap: () => showSoon(context, 'Rewarded ads'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
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
                        size: 18,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Watch an ad for 2x',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakBanner(double w) => Container(
    width: w,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF141B66), Color(0xFF070B2E)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Row(
      children: [
        AnimatedBuilder(
          animation: _loop,
          builder: (context, _) => Transform.scale(
            scale: 1 + 0.06 * math.sin(2 * math.pi * _loop.value * 3),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 38,
              color: Color(0xFFFF7A1C),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '3-day streak',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Come back every day for bigger rewards.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _entranceTile(int i, double w, double h) {
    final a = 0.15 + i * 0.07;
    return Entrance(
      progress: _in,
      begin: a,
      end: a + 0.3,
      rise: 26,
      child: _tile(i, w, h),
    );
  }

  Widget _tile(int i, double w, double h) {
    final done = i < _today || (i == _today && _claimed);
    final today = i == _today && !_claimed;
    final big = i == 6;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * _loop.value);
        return Transform.scale(
          scale: today ? 1 + 0.04 * pulse : 1,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: today
                    ? const [Color(0xFFFFF27A), Color(0xFFFFA000)]
                    : (big
                          ? const [Color(0xFF6B3BE0), Color(0xFF3A1FB0)]
                          : const [Color(0xFF1B2480), Color(0xFF0E1550)]),
              ),
              border: Border.all(
                color: today
                    ? Colors.white
                    : Colors.white.withValues(alpha: done ? 0.25 : 0.4),
                width: today ? 2.4 : 1.4,
              ),
              boxShadow: today
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.45 * pulse),
                        blurRadius: 14,
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: done ? 0.45 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        big ? 'DAY 7 BONUS' : 'DAY ${i + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: today
                              ? const Color(0xFF5A3700)
                              : Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (big)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GemIcon(size: 30),
                            SizedBox(width: 2),
                            GemIcon(size: 36),
                            SizedBox(width: 2),
                            GemIcon(size: 30),
                          ],
                        )
                      else
                        GemIcon(size: w * 0.34),
                      const SizedBox(height: 3),
                      Text(
                        '${_amounts[i]}',
                        style: GoogleFonts.outfit(
                          fontSize: big ? 18 : 15,
                          fontWeight: FontWeight.w800,
                          color: today ? const Color(0xFF3A2400) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (done)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2FD071),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
