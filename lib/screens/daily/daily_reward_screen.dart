import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../ads/ad_widgets.dart';
import '../../ads/rewarded_flow.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../core/daily_reward.dart';
import '../../widgets/entrance.dart';
import '../../widgets/info_dialog.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/water_button.dart';

/// 7-day reward calendar. The streak and the claim come from the save.
class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key, this.clock});

  /// Clock for the claim. Tests pass a fixed time; the app uses [DateTime.now].
  final DateTime Function()? clock;

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

  DailyStatus _status = const DailyStatus(
    claimedToday: false,
    nextRewardDay: 1,
    displayStreakCount: 0,
  );
  int _gems = 0;
  bool _ready = false;
  bool _busy = false;
  bool _clockBlocked = false;
  bool _doubled = false;

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final ok = await AppPrefs.touchClock(_now());
    if (!mounted) return;
    if (!ok) {
      setState(() => _clockBlocked = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        InfoDialog.clockChanged(context);
      });
    }
    await _load();
  }

  Future<void> _load() async {
    final now = _now();
    final savedFuture = AppPrefs.daily();
    final gemsFuture = AppPrefs.gems();
    final saved = await savedFuture;
    final gems = await gemsFuture;
    if (!mounted) return;
    setState(() {
      _status = dailyStatus(saved, now);
      _gems = gems;
      _doubled = saved.rewardDoubledDay == dayKey(now);
      _ready = true;
    });
  }

  Future<void> _claim() async {
    if (_busy || !_ready || _clockBlocked || _status.claimedToday) return;
    setState(() => _busy = true);
    final result = await AppPrefs.claimDaily(_now());
    if (!mounted) return;
    if (result.clockBlocked) {
      setState(() {
        _clockBlocked = true;
        _busy = false;
      });
      InfoDialog.clockChanged(context);
      return;
    }
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _double() async {
    if (_busy ||
        !_ready ||
        _clockBlocked ||
        !_status.claimedToday ||
        _doubled) {
      return;
    }
    setState(() => _busy = true);
    await RewardedFlow.run(
      context,
      onReward: () async {
        final added = await AppPrefs.doubleDailyReward(_now());
        if (added > 0) await _load();
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
  }

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
    final claimed = _ready && _status.claimedToday;
    final held = claimed || _busy || _clockBlocked;
    final canDouble = claimed && !_doubled && !_clockBlocked && !_busy;
    final amount = dailyRewardAmounts[_status.nextRewardDay - 1];
    return PageShell(
      title: 'Daily Reward',
      gems: _ready ? _gems : null,
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
                  scale: held
                      ? 1
                      : 1 + 0.025 * math.sin(2 * math.pi * _loop.value),
                  child: child,
                ),
                child: WaterButton(
                  width: math.min(size.width - 56, 300),
                  label: claimed ? 'Claimed' : 'Claim +$amount',
                  icon: claimed
                      ? Icons.check_rounded
                      : Icons.card_giftcard_rounded,
                  dim: held || !_ready,
                  onPressed: () {
                    if (_clockBlocked) {
                      InfoDialog.clockChanged(context);
                      return;
                    }
                    _claim();
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
                onTap: () {
                  _double();
                },
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: canDouble ? 1 : 0.45,
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
                        Icon(
                          _doubled
                              ? Icons.check_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _doubled ? 'Doubled' : 'Watch an ad for 2x',
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
            ),
            const SizedBox(height: 18),
            Entrance(
              progress: _in,
              begin: 0.8,
              end: 1,
              child: NativeAdCard(width: gridW),
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
                _status.displayStreakCount == 0
                    ? 'Start your streak!'
                    : '${_status.displayStreakCount}-day streak',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                _ready && _status.claimedToday
                    ? 'Come back tomorrow'
                    : 'Come back every day for bigger rewards.',
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

  bool _tileDone(int day) {
    if (!_status.claimedToday) return day < _status.nextRewardDay;
    // Day 7 was claimed today, so the finished week stays checked until tomorrow.
    if (_status.nextRewardDay == 1) return true;
    return day < _status.nextRewardDay;
  }

  bool _tileToday(int day) =>
      !_status.claimedToday && day == _status.nextRewardDay;

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
    final day = i + 1;
    final done = _ready && _tileDone(day);
    final today = _ready && _tileToday(day);
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
                        '${dailyRewardAmounts[i]}',
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
