import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../widgets/entrance.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/page_shell.dart';

/// Score and stats. All numbers are sample data until the game saves progress.
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

  // (level, stars, moves, is a new best)
  static const _recent = <(int, int, int, bool)>[
    (24, 3, 22, true),
    (23, 2, 31, false),
    (22, 3, 19, true),
    (21, 1, 44, false),
    (20, 3, 25, false),
  ];

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
                _tile(Icons.emoji_events_rounded, '24', 'Levels done'),
                const SizedBox(width: 12),
                _tile(Icons.local_fire_department_rounded, '5', 'Best streak'),
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
                _tile(null, '412', 'Gems earned', gem: true),
                const SizedBox(width: 12),
                _tile(Icons.workspace_premium_rounded, '11', '3-star levels'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'RECENT LEVELS',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: AppColors.gold,
              ),
            ),
          ),
          for (var i = 0; i < _recent.length; i++)
            Entrance(
              progress: _in,
              begin: 0.4 + i * 0.08,
              end: 0.8 + i * 0.08 > 1 ? 1 : 0.8 + i * 0.08,
              child: _row(_recent[i]),
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
              '63',
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
              ' / 72',
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
                  widthFactor: 63 / 72,
                  child: const ColoredBox(color: AppColors.gold),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tile(
    IconData? icon,
    String value,
    String label, {
    bool gem = false,
  }) => Expanded(
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
          gem
              ? const GemIcon(size: 28)
              : Icon(icon, size: 28, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
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

  Widget _row((int, int, int, bool) r) {
    final (level, stars, moves, best) = r;
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
          const Spacer(),
          if (best)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2FD071),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'BEST',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
          Text(
            '$moves moves',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
