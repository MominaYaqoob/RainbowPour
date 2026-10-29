import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../widgets/avatar_face.dart';
import '../../widgets/bottle_shape.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/entrance.dart';
import '../../widgets/game_text.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/night_background.dart';
import '../../widgets/water_button.dart';
import '../challenge/daily_challenge_screen.dart';
import '../daily/daily_reward_screen.dart';
import '../game/game_screen.dart';
import '../levels/level_map_screen.dart';
import '../profile/profile_screen.dart';
import 'exit_dialog.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';

/// Main menu: profile and gems on top, the title with idle bottles, the Play
/// button, three feature tiles and a reserved banner-ad slot at the bottom.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  String _name = 'Player';
  int _avatar = 0;
  int _gems = 0;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await AppPrefs.nickname();
    final avatar = await AppPrefs.avatar();
    final gems = await AppPrefs.gems();
    final level = await AppPrefs.level();
    if (!mounted) return;
    setState(() {
      _name = name ?? 'Player';
      _avatar = avatar;
      _gems = gems;
      _level = level;
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _go(Widget page) =>
      Navigator.of(context).push(fadeRoute(page)).then((_) => _load());

  void _soon(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10175E),
          duration: const Duration(milliseconds: 1400),
          content: Text(
            '$what is coming soon',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // scale by width and by height so short windows do not squash the layout
    final s = math.min(size.width / 240, size.height / 520).clamp(0.8, 1.5);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ExitDialog.show(context, onQuit: () => SystemNavigator.pop());
        }
      },
      child: Scaffold(
        body: NightBackground(
          child: SafeArea(
            child: Column(
              children: [
                Entrance(
                  progress: _in,
                  begin: 0,
                  end: 0.35,
                  rise: -14,
                  child: _topBar(),
                ),
                Expanded(child: _hero(s)),
                Entrance(
                  progress: _in,
                  begin: 0.45,
                  end: 0.8,
                  child: _levelChip(),
                ),
                const SizedBox(height: 10),
                Entrance(
                  progress: _in,
                  begin: 0.5,
                  end: 0.85,
                  child: WaterButton(
                    width: math.min(
                      size.width - 56,
                      math.min(300, size.height * 0.46),
                    ),
                    label: 'Play',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).push(fadeRoute(const GameScreen(), zoom: true)),
                  ),
                ),
                const SizedBox(height: 16),
                Entrance(
                  progress: _in,
                  begin: 0.6,
                  end: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _tile(
                        'Daily',
                        Icons.card_giftcard_rounded,
                        const [Color(0xFFFFF27A), Color(0xFFFFA000)],
                        badge: true,
                        onTap: () => _go(const DailyRewardScreen()),
                      ),
                      _tile(
                        'Challenge',
                        Icons.flag_rounded,
                        const [Color(0xFFFF9AB0), Color(0xFFE0245B)],
                        onTap: () => _go(const DailyChallengeScreen()),
                      ),
                      _tile(
                        'Levels',
                        Icons.map_rounded,
                        const [Color(0xFF8EF0A0), Color(0xFF2DBE60)],
                        onTap: () => _go(const LevelMapScreen()),
                      ),
                      _tile(
                        'Shop',
                        Icons.storefront_rounded,
                        const [Color(0xFF7FE9FF), Color(0xFF1FA9FF)],
                        onTap: () => _go(const ShopScreen()),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.012),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _go(const ProfileScreen()),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: AvatarFace(index: _avatar, size: 42),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Level $_level',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          _gemPill(),
          const SizedBox(width: 10),
          _roundIcon(Icons.settings_rounded, () => _go(const SettingsScreen())),
        ],
      ),
    );
  }

  Widget _gemPill() => GestureDetector(
    onTap: () => _go(const ShopScreen()),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1040).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GemIcon(size: 20),
          const SizedBox(width: 6),
          Text(
            _fmt(_gems),
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF27A), Color(0xFFFFA000)],
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 17,
              color: Color(0xFF4A2A00),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _roundIcon(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A1040).withValues(alpha: 0.85),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 21, color: Colors.white),
    ),
  );

  /// Title and three idle bottles standing on a shelf.
  Widget _hero(double s) {
    return LayoutBuilder(
      builder: (context, c) {
        final titleH = 96 * s;
        final bottleArea = math.max(0.0, c.maxHeight - titleH - 18);
        final centerW = math.min(bottleArea * 0.8, 250) * 36 / 118;
        final bigW = math.max(34.0, centerW);
        return Column(
          children: [
            SizedBox(height: 4 * s),
            Entrance(
              progress: _in,
              begin: 0.1,
              end: 0.45,
              child: GameText('Rainbow', size: 22 * s),
            ),
            Entrance(
              progress: _in,
              begin: 0.18,
              end: 0.55,
              child: GameText(
                'Pour',
                size: 38 * s,
                gradient: const [Color(0xFFFFF27A), Color(0xFFFFA000)],
              ),
            ),
            Entrance(
              progress: _in,
              begin: 0.25,
              end: 0.6,
              child: Text(
                'WATER SORT',
                style: GoogleFonts.outfit(
                  fontSize: 11.5 * s,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5,
                  color: const Color(0xFFBFC4FF),
                ),
              ),
            ),
            Expanded(
              child: Entrance(
                progress: _in,
                begin: 0.3,
                end: 0.75,
                rise: 36,
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (context, _) => Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SparklePainter(_loop.value),
                        ),
                      ),
                      Positioned(
                        left: 28,
                        right: 28,
                        bottom: 10,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000020),
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _bob(0, bigW * 0.72, const [3, 2, 0, 1]),
                            SizedBox(width: bigW * 0.28),
                            _bob(1, bigW, const [4, 5, 6, 7]),
                            SizedBox(width: bigW * 0.28),
                            _bob(2, bigW * 0.72, const [6, 3, 5]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bob(int i, double w, List<int> layers) {
    final dy = math.sin(2 * math.pi * (_loop.value * 2 + i / 3)) * 3;
    return Transform.translate(
      offset: Offset(0, -dy.abs() * 0 + dy),
      child: ConeBottle(
        layers: layers,
        width: w,
        showShadow: false,
        shape: BottleSkin.shape.value,
      ),
    );
  }

  Widget _levelChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.gold,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white, width: 1.4),
    ),
    child: Text(
      'LEVEL $_level',
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: const Color(0xFF4A2A00),
      ),
    ),
  );

  Widget _tile(
    String label,
    IconData icon,
    List<Color> colors, {
    bool badge = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => _soon(label),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors,
                  ),
                  border: Border.all(color: Colors.white, width: 2.4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000020),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 6,
                      child: Container(
                        width: 44,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.32),
                        ),
                      ),
                    ),
                    Icon(
                      icon,
                      size: 34,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Color(0x66000030), offset: Offset(0, 2)),
                      ],
                    ),
                  ],
                ),
              ),
              if (badge)
                Positioned(
                  right: -4,
                  top: -4,
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (context, _) {
                      final p =
                          1 + 0.12 * math.sin(2 * math.pi * _loop.value * 4);
                      return Transform.scale(
                        scale: p,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF3D5A),
                            border: Border.all(color: Colors.white, width: 1.8),
                          ),
                          child: Center(
                            child: Text(
                              '1',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
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
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const spots = [
      Offset(0.2, 0.3),
      Offset(0.82, 0.22),
      Offset(0.7, 0.62),
      Offset(0.14, 0.7),
    ];
    for (var i = 0; i < spots.length; i++) {
      final a =
          0.1 +
          0.9 * (0.5 + 0.5 * math.sin(2 * math.pi * (t * (2 + i) + i / 4)));
      final c = Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      final r = 6.0 + i % 2 * 2;
      final k = r * 0.25;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + k, c.dy - k)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx + k, c.dy + k)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - k, c.dy + k)
        ..lineTo(c.dx - r, c.dy)
        ..lineTo(c.dx - k, c.dy - k)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}
