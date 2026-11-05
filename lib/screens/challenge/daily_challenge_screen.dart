import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../core/daily_challenge.dart';
import '../../core/daily_reward.dart';
import '../../game/difficulty.dart';
import '../../widgets/info_dialog.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/entrance.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/water_button.dart';
import '../game/game_screen.dart';

/// Daily challenge. Play opens today's board. The calendar and the streak
/// come from the save.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key, this.clock});

  /// Clock for "today". Tests pass a fixed time; the app uses [DateTime.now].
  final DateTime Function()? clock;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  DateTime _today = DateTime.now();
  Set<String> _doneDays = {};
  int _streak = 0;
  int _weekCount = 0;
  int _gems = 0;
  bool _ready = false;
  bool _clockBlocked = false;

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  bool get _doneToday => _doneDays.contains(dayKey(_today));

  @override
  void initState() {
    super.initState();
    final now = _now();
    _today = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final now = _now();
    final savedFuture = AppPrefs.daily();
    final gemsFuture = AppPrefs.gems();
    final saved = await savedFuture;
    final gems = await gemsFuture;
    if (!mounted) return;
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _today = today;
      _doneDays = saved.challengeDone;
      _streak = challengeStreakOf(saved.challengeDone, today);
      _weekCount = weekDays(
        today,
      ).where((date) => saved.challengeDone.contains(dayKey(date))).length;
      _gems = gems;
      _clockBlocked = clockWentBack(saved.lastSeenMs, now);
      _ready = true;
    });
  }

  Future<void> _play() async {
    if (!_ready) return;
    if (_clockBlocked) {
      InfoDialog.clockChanged(context);
      return;
    }
    if (_doneToday) return;
    await Navigator.of(
      context,
    ).push(fadeRoute(GameScreen.challenge(day: _today), zoom: true));
    if (mounted) await _load();
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
    return PageShell(
      title: 'Daily Challenge',
      gems: _ready ? _gems : null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Entrance(progress: _in, begin: 0, end: 0.4, child: _todayCard(size)),
          const SizedBox(height: 16),
          Entrance(progress: _in, begin: 0.2, end: 0.6, child: _weekBonus()),
          const SizedBox(height: 16),
          Entrance(progress: _in, begin: 0.35, end: 0.8, child: _calendar()),
        ],
      ),
    );
  }

  Widget _todayCard(Size size) {
    final spec = DifficultyCurve.challengeSpecFor(_today);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B3CF0), Color(0xFF3A1FB0)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000020),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S CHALLENGE",
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_weekdays[_today.weekday - 1]}, ${_today.day} ${_months[_today.month - 1]}',
                      style: GoogleFonts.outfit(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip('HARD', const Color(0xFFFF3D5A), Colors.white),
                        const SizedBox(width: 8),
                        _chip(
                          '${spec.colors} colors',
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => Transform.translate(
                  offset: Offset(0, math.sin(2 * math.pi * _loop.value) * 3),
                  child: const SizedBox(
                    width: 62,
                    height: 100,
                    child: FittedBox(
                      child: ConeBottle(
                        layers: [6, 7, 4, 2],
                        width: 36,
                        showShadow: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Reward',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 10),
                const GemIcon(size: 22),
                const SizedBox(width: 5),
                Text(
                  '$challengeRewardGems',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: Color(0xFFFF7A1C),
                ),
                Text(
                  '$_streak-day streak',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          WaterButton(
            width: math.min(size.width - 80, 270),
            label: _doneToday ? 'Done for today' : 'Play',
            icon: _doneToday ? Icons.check_rounded : Icons.play_arrow_rounded,
            dim: !_ready || _doneToday || _clockBlocked,
            onPressed: () {
              _play();
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String t, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      t,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: fg,
      ),
    ),
  );

  Widget _weekBonus() {
    final n = _weekCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2480), Color(0xFF0E1550)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF27A), Color(0xFFFFA000)],
              ),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.redeem_rounded,
              size: 26,
              color: Color(0xFF4A2A00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly bonus: $weeklyBonusGems gems',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Container(
                          height: 9,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: i < n
                                ? AppColors.gold
                                : Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$n of 7 days this week',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendar() {
    final first = DateTime(_today.year, _today.month, 1);
    final days = DateTime(_today.year, _today.month + 1, 0).day;
    final lead = first.weekday - 1; // empty cells before day 1
    final cells = lead + days;
    final rows = (cells / 7).ceil();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141B66), Color(0xFF070B2E)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            '${_months[_today.month - 1]} ${_today.year}',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: _cell(r * 7 + c - lead + 1, days)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(int day, int days) {
    if (day < 1 || day > days) return const SizedBox(height: 38);
    final today = day == _today.day;
    final done = _doneDays.contains(
      dayKey(DateTime(_today.year, _today.month, day)),
    );
    final past = day < _today.day;
    Widget inner;
    if (done) {
      inner = Container(
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
          size: 19,
          color: Color(0xFF4A2A00),
        ),
      );
    } else if (today) {
      inner = AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final p = 0.5 + 0.5 * math.sin(2 * math.pi * _loop.value);
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5 * p),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$day',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        },
      );
    } else {
      inner = Center(
        child: Text(
          past ? '' : '$day',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
      if (past) {
        // missed day: a small dim cross
        inner = Center(
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        );
      }
    }
    return SizedBox(
      height: 38,
      child: Padding(padding: const EdgeInsets.all(2), child: inner),
    );
  }
}
