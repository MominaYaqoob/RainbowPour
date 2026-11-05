import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../game/difficulty.dart';
import '../../widgets/entrance.dart';
import '../../widgets/page_shell.dart';

/// Score and stats loaded from the player's save.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  int _completed = 0;
  int _moves = 0;
  int _starSum = 0;
  int _bestStreak = 0;
  int _threeStars = 0;
  List<({int level, int stars})> _latest = const [];

  int get _starCap => DifficultyCurve.maxLevel * 3;

  double get _starFill {
    final cap = _starCap;
    if (cap <= 0) return 0;
    final raw = _starSum / cap;
    if (raw < 0) return 0;
    if (raw > 1) return 1;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totalsFuture = AppPrefs.totals();
    final starsFuture = AppPrefs.stars();
    final streakFuture = AppPrefs.bestStreak();
    final totals = await totalsFuture;
    final stars = await starsFuture;
    final streak = await streakFuture;
    if (!mounted) return;
    final ranked = stars.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    setState(() {
      _completed = totals.completed;
      _moves = totals.moves;
      _starSum = stars.values.fold(0, (sum, n) => sum + n);
      _bestStreak = streak;
      _threeStars = stars.values.where((n) => n == 3).length;
      _latest = [
        for (final entry in ranked.take(5))
          (level: entry.key, stars: entry.value),
      ];
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Score & Stats',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Entrance(progress: _in, begin: 0, end: 0.4, child: _starsCard()),
          const SizedBox(height: 14),
          Entrance(
            progress: _in,
            begin: 0.15,
            end: 0.55,
            child: Row(
              children: [
                _tile(
                  Icons.emoji_events_rounded,
                  _formatCount(_completed),
                  'Levels done',
                ),
                const SizedBox(width: 12),
                _tile(
                  Icons.local_fire_department_rounded,
                  _formatCount(_bestStreak),
                  'Best streak',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Entrance(
            progress: _in,
            begin: 0.25,
            end: 0.65,
            child: Row(
              children: [
                _tile(Icons.swipe_rounded, _formatCount(_moves), 'Total moves'),
                const SizedBox(width: 12),
                _tile(
                  Icons.workspace_premium_rounded,
                  _formatCount(_threeStars),
                  '3-star levels',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'LATEST LEVELS',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: AppColors.gold,
              ),
            ),
          ),
          if (_latest.isEmpty)
            Entrance(
              progress: _in,
              begin: 0.4,
              end: 0.8,
              child: Text(
                'Play your first level!',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          for (var i = 0; i < _latest.length; i++)
            Entrance(
              progress: _in,
              begin: 0.4 + i * 0.08,
              end: 0.8 + i * 0.08 > 1 ? 1 : 0.8 + i * 0.08,
              child: _row(_latest[i].level, _latest[i].stars),
            ),
        ],
      ),
    );
  }

  Widget _starsCard() => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, size: 46, color: AppColors.gold),
            const SizedBox(width: 8),
            Text(
              _formatCount(_starSum),
              style: GoogleFonts.outfit(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0xFF120F52), offset: Offset(0, 3)),
                ],
              ),
            ),
            Text(
              ' / $_starCap',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Text(
          'TOTAL STARS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.white.withValues(alpha: 0.2)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _starFill,
                  child: const ColoredBox(color: AppColors.gold),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tile(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
          Icon(icon, size: 28, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    ),
  );

  Widget _row(int level, int stars) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141B66), Color(0xFF0A1040)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Text(
            'Level $level',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          for (var i = 0; i < 3; i++)
            Icon(
              Icons.star_rounded,
              size: 22,
              color: i < stars
                  ? AppColors.gold
                  : Colors.white.withValues(alpha: 0.2),
            ),
        ],
      ),
    );
  }
}

/// Groups [n] with commas. Very large totals use K or M so a tile stays one line.
String _formatCount(int n) {
  final value = n < 0 ? 0 : n;
  if (value < 100000) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }
  if (value < 1000000) return '${_compact(value / 1000)}K';
  return '${_compact(value / 1000000)}M';
}

String _compact(double v) {
  final text = v.toStringAsFixed(v >= 100 ? 0 : 1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
