import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../widgets/background_theme.dart';
import '../../widgets/bottle_shape.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/entrance.dart';
import '../../widgets/gem_icon.dart';
import '../../core/app_prefs.dart';
import '../../widgets/info_dialog.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/water_button.dart';
import 'not_enough_gems_dialog.dart';

/// Shop (UI only): free gems by ad, bottle skins and backgrounds.
/// Nothing is bought or saved yet; equipping just switches the highlight.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  int _tab = 0;
  int _gems = 0;
  int _skin = 0; // equipped bottle skin
  Set<String> _owned = {};
  int _theme = -1; // equipped background: -1 = Auto (follows the level)

  static const _tabs = ['Gems', 'Bottles', 'Backgrounds'];

  // (shape, gems needed; 0 = owned)
  static const _skins = <(BottleShape, int)>[
    (BottleShape.cone, 0),
    (BottleShape.flask, 0),
    (BottleShape.tube, 700),
    (BottleShape.potion, 1500),
    (BottleShape.jar, 3000),
    (BottleShape.diamond, 6000),
  ];

  @override
  void initState() {
    super.initState();
    _skin = math.max(
      0,
      _skins.indexWhere((e) => e.$1 == BottleSkin.shape.value),
    );
    _theme = BackgroundSkin.mode.value;
    AppPrefs.owned().then((o) {
      if (mounted) setState(() => _owned = o);
    });
    AppPrefs.adsToday().then((n) {
      if (mounted) setState(() => _adsToday = n);
    });
    AppPrefs.gems().then((g) {
      if (mounted) setState(() => _gems = g);
    });
  }

  /// Buys [id] for [cost] gems, or shows "not enough gems". [onBought] runs
  /// after a successful purchase (to equip the item).
  Future<void> _buy(String id, int cost, VoidCallback onBought) async {
    if (cost > _gems) {
      NotEnoughGemsDialog.show(
        context,
        need: cost,
        have: _gems,
        onGetGems: () {
          Navigator.of(context).pop();
          setState(() => _tab = 0);
        },
        onWatchAd: () {
          Navigator.of(context).pop();
          setState(() => _tab = 0);
          _watchAd();
        },
      );
      return;
    }
    if (!await AppPrefs.spendGems(cost)) return;
    await AppPrefs.addOwned(id);
    if (!mounted) return;
    setState(() {
      _gems -= cost;
      _owned = {..._owned, id};
    });
    onBought();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Shop',
      gemsTappable: false,
      gems: _gems,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Entrance(progress: _in, begin: 0, end: 0.35, child: _tabBar()),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: switch (_tab) {
                  0 => _gemsTab(),
                  1 => _skinsTab(),
                  _ => _themesTab(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ tab bar

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1040).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / _tabs.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: _tab * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF27A), Color(0xFFFFA000)],
                    ),
                    border: Border.all(color: Colors.white, width: 1.4),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _tab = i),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: i == _tab
                                  ? const Color(0xFF4A2A00)
                                  : Colors.white.withValues(alpha: 0.8),
                            ),
                            child: Text(_tabs[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------- gems tab

  static const _adGems = 10;
  static const _adLimit = 3;

  /// Ads watched today (saved per day).
  int _adsToday = 0;

  void _watchAd() {
    if (_adsToday >= _adLimit) {
      InfoDialog.dailyLimit(context);
      return;
    }
    // demo: pretend the ad finished
    setState(() {
      _adsToday++;
      _gems += _adGems;
    });
    AppPrefs.addGems(_adGems);
    AppPrefs.addAdToday();
  }

  Widget _gemsTab() {
    final left = _adLimit - _adsToday;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _label('FREE GEMS'),
        const SizedBox(height: 10),
        Entrance(
          progress: _in,
          begin: 0.1,
          end: 0.5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E3AB8), Color(0xFF141B66)],
              ),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const GemIcon(size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watch an ad',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Get +$_adGems gems each time',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.aqua,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _adLimit; i++)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _adsToday
                              ? AppColors.gold
                              : Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  left > 0
                      ? '$_adsToday / $_adLimit watched today'
                      : 'All $_adLimit watched. Come back tomorrow!',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 14),
                WaterButton(
                  width: math.min(MediaQuery.sizeOf(context).width - 64, 320),
                  label: left > 0 ? 'Watch Ad' : 'Come Back Tomorrow',
                  icon: left > 0
                      ? Icons.play_circle_fill_rounded
                      : Icons.schedule_rounded,
                  dim: left == 0,
                  onPressed: _watchAd,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _label('OTHER WAYS'),
        const SizedBox(height: 10),
        _tip(Icons.card_giftcard_rounded, 'Daily reward', 'Log in every day'),
        const SizedBox(height: 10),
        _tip(
          Icons.emoji_events_rounded,
          'Complete levels',
          'Earn gems as you win',
        ),
        const SizedBox(height: 10),
        _tip(
          Icons.local_fire_department_rounded,
          'Daily challenge',
          'Finish it for a big bonus',
        ),
      ],
    );
  }

  Widget _tip(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      t,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
        color: AppColors.gold,
      ),
    ),
  );

  // --------------------------------------------------------- bottles tab

  Widget _skinsTab() {
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        for (var i = 0; i < _skins.length; i++)
          Entrance(
            progress: _in,
            begin: 0.1 + i * 0.07,
            end: 0.5 + i * 0.07,
            child: _skinCard(i),
          ),
      ],
    );
  }

  Widget _skinCard(int i) {
    final (shape, cost) = _skins[i];
    final name = shape.label;
    final id = 'skin:${shape.name}';
    final owned = cost == 0 || _owned.contains(id);
    final on = _skin == i;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2480), Color(0xFF0E1550)],
        ),
        border: Border.all(
          color: on ? AppColors.gold : Colors.white.withValues(alpha: 0.3),
          width: on ? 2.2 : 1.4,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = math.min(c.maxHeight * 36 / 118, 54.0);
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: w * 2,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ConeBottle(
                          layers: const [0, 1, 2, 3],
                          shape: shape,
                          width: w,
                          showShadow: false,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _stateButton(
            owned: owned,
            on: on,
            cost: cost,
            onTap: () {
              void equip() {
                setState(() => _skin = i);
                BottleSkin.equip(shape);
              }

              owned ? equip() : _buy(id, cost, equip);
            },
          ),
        ],
      ),
    );
  }

  Widget _stateButton({
    required bool owned,
    required bool on,
    required int cost,
    required VoidCallback onTap,
  }) {
    final Color c1, c2;
    final Widget label;
    if (on) {
      c1 = const Color(0xFF6BE58F);
      c2 = const Color(0xFF1FA85A);
      label = _btnText('Equipped', icon: Icons.check_rounded);
    } else if (owned) {
      c1 = const Color(0xFF9AF5FF);
      c2 = const Color(0xFF1FA9FF);
      label = _btnText('Use');
    } else {
      c1 = const Color(0xFFFFF27A);
      c2 = const Color(0xFFFFA000);
      label = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GemIcon(size: 16),
          const SizedBox(width: 5),
          Text(
            '$cost',
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4A2A00),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c1, c2],
          ),
          border: Border.all(color: Colors.white, width: 1.6),
        ),
        child: Center(child: label),
      ),
    );
  }

  Widget _btnText(String t, {IconData? icon}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 17, color: Colors.white),
        const SizedBox(width: 4),
      ],
      Text(
        t,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: const [
            Shadow(color: Color(0x66000030), offset: Offset(0, 1.5)),
          ],
        ),
      ),
    ],
  );

  // ------------------------------------------------------- backgrounds tab

  Widget _themesTab() {
    // card 0 = Auto, then every theme
    final n = BackgroundTheme.all.length + 1;
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: [
        for (var i = 0; i < n; i++)
          Entrance(
            progress: _in,
            begin: (0.05 + i * 0.06).clamp(0.0, 0.5),
            end: (0.45 + i * 0.06).clamp(0.2, 1.0),
            child: _themeCard(i - 1),
          ),
      ],
    );
  }

  /// [index] -1 is the Auto card, otherwise an index into the theme list.
  Widget _themeCard(int index) {
    final auto = index < 0;
    final theme = auto ? null : BackgroundTheme.all[index];
    final cost = theme?.price ?? 0;
    final id = 'bg:$index';
    final owned = cost == 0 || _owned.contains(id);
    final on = _theme == index;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2480), Color(0xFF0E1550)],
        ),
        border: Border.all(
          color: on ? AppColors.gold : Colors.white.withValues(alpha: 0.3),
          width: on ? 2.2 : 1.4,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (auto)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            for (final t in BackgroundTheme.all) t.sky[1],
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.autorenew_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    CustomPaint(
                      painter: _ThemePainter(
                        theme!.sky.first,
                        theme.sky.last,
                        theme.celestialColor,
                      ),
                    ),
                  if (!owned)
                    Container(
                      color: Colors.black.withValues(alpha: 0.28),
                      child: const Center(
                        child: Icon(
                          Icons.lock_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            auto ? 'Auto' : theme!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            auto ? 'New look every 20 levels' : ' ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          _stateButton(
            owned: owned,
            on: on,
            cost: cost,
            onTap: () {
              void equip() {
                setState(() => _theme = index);
                BackgroundSkin.set(index);
              }

              owned ? equip() : _buy(id, cost, equip);
            },
          ),
        ],
      ),
    );
  }
}

/// Tiny preview of a background: sky gradient, a sun or moon and two hills.
class _ThemePainter extends CustomPainter {
  _ThemePainter(this.top, this.bottom, this.accent);

  final Color top;
  final Color bottom;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(r),
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      size.width * 0.1,
      Paint()..color = accent,
    );
    final far = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.55,
        size.width * 0.6,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.6,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(far, Paint()..color = Colors.black.withValues(alpha: 0.2));
    final near = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.72,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      near,
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );
  }

  @override
  bool shouldRepaint(_ThemePainter old) => false;
}
