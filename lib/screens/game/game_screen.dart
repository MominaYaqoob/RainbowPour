import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../core/haptics.dart';
import '../../widgets/bottle_shape.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/entrance.dart';
import '../../widgets/game_text.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/gem_pill.dart';
import '../../widgets/night_background.dart';
import '../../widgets/water_button.dart';
import 'level_complete_dialog.dart';
import '../../widgets/background_theme.dart';
import '../shop/not_enough_gems_dialog.dart';
import 'level_failed_dialog.dart';
import 'sample_board.dart';

/// Game screen, UI only: a sample board, the top bar, the three helper
/// buttons, a pause popup and the reserved banner-ad slot. No game rules yet.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.level});

  /// Null = the player's current level.
  final int? level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  // sample board: layers bottom to top as color ids
  late SampleBoard _sample = SampleBoard.forLevel(widget.level ?? 1);
  List<List<int>> get _board => _sample.bottles;
  static const _selected = 1;

  int _gems = 0;
  late int _level = widget.level ?? 1;

  /// Short "preparing" overlay shown while a level loads.
  bool _loading = true;

  /// Hint: bottle to pour from and into (glow), -1 = none.
  int _hintFrom = -1;
  int _hintTo = -1;

  /// 0.78..1: shrinks the bottom buttons on short screens.
  double _f = 1;

  @override
  void initState() {
    super.initState();
    _load();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _load() async {
    final gems = await AppPrefs.gems();
    final level = widget.level ?? await AppPrefs.level();
    if (!mounted) return;
    setState(() {
      _gems = gems;
      _level = level;
      _sample = SampleBoard.forLevel(level);
    });
  }

  /// Moves on to the next level and keeps the furthest level saved.
  Future<void> _next() async {
    Haptics.light();
    final next = _level + 1;
    setState(() {
      _loading = true;
      _hintFrom = _hintTo = -1;
    });
    if (next > await AppPrefs.level()) await AppPrefs.setLevel(next);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _level = next;
      _sample = SampleBoard.forLevel(next);
      _loading = false;
    });
  }

  /// Puts the level back to its starting board.
  Future<void> _restart() async {
    Haptics.light();
    setState(() {
      _loading = true;
      _hintFrom = _hintTo = -1;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _sample = SampleBoard.forLevel(_level);
      _loading = false;
    });
  }

  /// Demo hint: finds a loading overlay, then glows two bottles for 2 seconds.
  Future<void> _hint() async {
    Haptics.tap();
    const cost = 25;
    if (_gems < cost) {
      NotEnoughGemsDialog.show(
        context,
        need: cost,
        have: _gems,
        onGetGems: () {
          Navigator.of(context).pop();
          _soon('The shop');
        },
        onWatchAd: () {
          Navigator.of(context).pop();
          _soon('Rewarded ads');
        },
      );
      return;
    }
    if (!await AppPrefs.spendGems(cost)) return;
    if (mounted) setState(() => _gems -= cost);
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final from = _board.indexWhere((b) => b.isNotEmpty);
    final to = _board.lastIndexWhere((b) => b.isEmpty);
    setState(() {
      _loading = false;
      _hintFrom = from;
      _hintTo = to;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _hintFrom = _hintTo = -1);
  }

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _soon(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10175E),
          duration: const Duration(milliseconds: 1300),
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

  /// Demo trigger: tapping the level pill shows the level-complete popup.
  void _levelComplete() {
    Haptics.success();
    LevelCompleteDialog.show(
      context,
      level: _level,
      onNext: () {
        Navigator.of(context).pop();
        _next();
      },
      onReplay: () {
        Navigator.of(context).pop();
        _restart();
      },
      onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
    );
  }

  /// Demo trigger: tapping Undo shows the "no moves left" popup.
  void _levelFailed() {
    Haptics.fail();
    LevelFailedDialog.show(
      context,
      onUndo: () {
        Navigator.of(context).pop();
        _soon('Undo');
      },
      onExtraBottle: () {
        Navigator.of(context).pop();
        _soon('The extra bottle');
      },
      onRestart: () {
        Navigator.of(context).pop();
        _restart();
      },
      onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
    );
  }

  void _pause() {
    Haptics.tap();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pause',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, a, _, _) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(c),
            child: Center(child: _pauseCard(context)),
          ),
        );
      },
    );
  }

  Widget _pauseCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: math.min(MediaQuery.sizeOf(context).width - 56, 320),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2480), Color(0xFF0A1040)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000020),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameText(
              'Paused',
              size: 34,
              gradient: [Color(0xFFFFF27A), Color(0xFFFFA000)],
            ),
            const SizedBox(height: 18),
            WaterButton(
              width: 220,
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ghost('Restart', Icons.refresh_rounded, () {
                  Navigator.of(context).pop();
                  _restart();
                }),
                const SizedBox(width: 12),
                _ghost('Home', Icons.home_rounded, () {
                  // closes the popup and the game, back to Home
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghost(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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

  @override
  Widget build(BuildContext context) {
    _f = (MediaQuery.sizeOf(context).height / 760).clamp(0.78, 1.0);
    return Scaffold(
      body: NightBackground(
        theme: BackgroundSkin.themeFor(_level),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Entrance(
                    progress: _in,
                    begin: 0,
                    end: 0.35,
                    rise: -14,
                    child: _topBar(),
                  ),
                  Expanded(
                    child: Entrance(
                      progress: _in,
                      begin: 0.15,
                      end: 0.7,
                      rise: 30,
                      child: _boardArea(),
                    ),
                  ),
                  Entrance(
                    progress: _in,
                    begin: 0.5,
                    end: 0.95,
                    child: _actionBar(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_loading,
                  child: AnimatedOpacity(
                    opacity: _loading ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1040).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Preparing level…',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
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
              ),
            ],
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
            onTap: _pause,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A1040).withValues(alpha: 0.85),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.pause_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _levelComplete,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1040).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                'Level $_level',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
          GemPill(gems: _gems, onTap: () => _soon('The shop')),
        ],
      ),
    );
  }

  /// Two rows of four bottles, each row on its own shelf. Sizes adapt to the
  /// free space so it fits short screens too.
  Widget _boardArea() {
    return LayoutBuilder(
      builder: (context, c) {
        final n = _board.length;
        // 8 bottles: 2x4, up to 12: two even rows, more: three rows of five
        final perRow = n <= 8 ? 4 : (n <= 12 ? (n + 1) ~/ 2 : 5);
        final rows = (n / perRow).ceil();
        final gap = perRow > 5 ? 8.0 : 14.0;
        const shelf = 16.0;
        final rowGap = c.maxHeight < 440 || rows > 2 ? 14.0 : 26.0;
        final byWidth = (c.maxWidth - 40 - gap * (perRow - 1)) / perRow;
        // leave breathing room above, between and below the rows
        final byHeight =
            ((c.maxHeight - rowGap * (rows - 1) - shelf * rows - 28) / rows) *
            0.9 *
            36 /
            118;
        // keep bottles a sensible size: about 14% of the screen width
        final maxW = (c.maxWidth * 0.145).clamp(36.0, 56.0);
        final w = math.max(26.0, math.min(math.min(byWidth, byHeight), maxW));
        return Center(
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) SizedBox(height: rowGap),
                  _row(r * perRow, math.min(n, (r + 1) * perRow), w, gap, shelf),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(int start, int end, double w, double gap, double shelf) {
    final h = w * 118 / 36;
    final rowW = w * (end - start) + gap * (end - start - 1);
    return SizedBox(
      width: rowW + 24,
      height: h + shelf,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(color: Color(0x55000020), offset: Offset(0, 4)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [for (var i = start; i < end; i++) _bottle(i, w)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottle(int i, double w) {
    final up = i == _selected;
    final bob = up ? math.sin(2 * math.pi * _loop.value) * 2 : 0.0;
    final lift = up ? w * 0.42 : 0.0;
    return SizedBox(
      width: w,
      height: w * 118 / 36,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ground shadow, smaller while the bottle is lifted
          Positioned(
            bottom: -2,
            child: Container(
              width: w * (up ? 0.6 : 0.9),
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: up ? 0.18 : 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i == _hintFrom || i == _hintTo)
            Positioned(
              bottom: -4,
              child: Container(
                width: w * 1.25,
                height: w * 118 / 36 + 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(w * 0.45),
                  color: (i == _hintFrom ? AppColors.gold : Colors.white)
                      .withValues(alpha: 0.22),
                  border: Border.all(
                    color: i == _hintFrom ? AppColors.gold : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: lift + bob,
            child: ConeBottle(
              layers: _board[i],
              width: w,
              showShadow: false,
              shape: BottleSkin.shape.value,
              capacity: _sample.capacity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.fromLTRB(4, 10 * _f, 4, 8 * _f),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF141B66).withValues(alpha: 0.9),
            const Color(0xFF070B2E).withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000020),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _action(Icons.undo_rounded, 'Undo', null, onTap: _levelFailed),
          _action(Icons.lightbulb_rounded, 'Hint', 25, onTap: _hint),
          _action(Icons.add_rounded, '+ Bottle', 40),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    int? cost, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => _soon(label),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58 * _f,
                  height: 58 * _f,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF3E6BFF), Color(0xFF1B3FB0)],
                    ),
                    border: Border.all(color: Colors.white, width: 2.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000020),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 5,
                        child: Container(
                          width: 32,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                      Icon(icon, size: 30 * _f, color: Colors.white),
                    ],
                  ),
                ),
                if (cost != null)
                  Positioned(
                    right: -13,
                    top: -10,
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
            const SizedBox(height: 6),
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
}
