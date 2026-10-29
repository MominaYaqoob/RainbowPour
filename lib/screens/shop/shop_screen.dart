import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../widgets/bottle_shape.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/entrance.dart';
import '../../widgets/gem_icon.dart';
import '../../core/app_prefs.dart';
import '../../widgets/page_shell.dart';
import 'not_enough_gems_dialog.dart';

/// Shop (UI only): gem packs with Remove Ads, bottle skins and backgrounds.
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
  int _theme = 0; // equipped background

  static const _tabs = ['Gems', 'Bottles', 'Backgrounds'];

  // (shape, gems needed; 0 = owned)
  static const _skins = <(BottleShape, int)>[
    (BottleShape.cone, 0),
    (BottleShape.flask, 0),
    (BottleShape.tube, 150),
    (BottleShape.potion, 300),
    (BottleShape.jar, 500),
    (BottleShape.diamond, 800),
  ];

  // (name, gems needed, sky top, sky bottom, accent)
  static const _themes = <(String, int, Color, Color, Color)>[
    ('Night Lake', 0, Color(0xFF060B33), Color(0xFF5646B5), Color(0xFFFFF3C4)),
    (
      'Sunset Sea',
      200,
      Color(0xFFFFD1A9),
      Color(0xFF8E5BD6),
      Color(0xFFFFF6E0),
    ),
    (
      'Lavender Peaks',
      200,
      Color(0xFFFFE3F1),
      Color(0xFF9FA8FF),
      Color(0xFFFFFFFF),
    ),
    (
      'Turquoise Waves',
      300,
      Color(0xFFB8F3E8),
      Color(0xFF0E8FA8),
      Color(0xFFFFFFFF),
    ),
    ('Aurora', 400, Color(0xFF041C32), Color(0xFF0B6E75), Color(0xFF4FFFB0)),
    (
      'Golden Dunes',
      400,
      Color(0xFFFFF0CF),
      Color(0xFFF0794A),
      Color(0xFFFFF8E5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _skin = math.max(
      0,
      _skins.indexWhere((e) => e.$1 == BottleSkin.shape.value),
    );
    AppPrefs.gems().then((g) {
      if (mounted) setState(() => _gems = g);
    });
  }

  void _tooExpensive(int cost) {
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
          showSoon(context, 'Rewarded ads');
        },
      );
    } else {
      showSoon(context, 'Buying with gems');
    }
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

  static const _packs = <(int, String, String?, int)>[
    (100, '\$0.99', null, 1),
    (550, '\$4.99', 'POPULAR', 2),
    (1200, '\$9.99', null, 3),
    (3000, '\$19.99', 'BEST VALUE', 4),
  ];

  Widget _gemsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Entrance(progress: _in, begin: 0.1, end: 0.5, child: _removeAds()),
        const SizedBox(height: 18),
        _label('GEM PACKS'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _packs.length; i++)
                  Entrance(
                    progress: _in,
                    begin: 0.2 + i * 0.08,
                    end: 0.6 + i * 0.08,
                    child: _pack(_packs[i], w),
                  ),
              ],
            );
          },
        ),
      ],
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

  Widget _removeAds() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.block_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remove Ads',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'No banners or popups. Ads you choose to watch for rewards stay.',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _priceButton('\$2.99', onTap: () => showSoon(context, 'Purchases')),
        ],
      ),
    );
  }

  Widget _pack((int, String, String?, int) p, double w) {
    final (gems, price, tag, size) = p;
    final hot = tag != null;
    return SizedBox(
      width: w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: w,
            padding: const EdgeInsets.fromLTRB(10, 22, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: hot
                    ? const [Color(0xFF2E3AB8), Color(0xFF141B66)]
                    : const [Color(0xFF1B2480), Color(0xFF0E1550)],
              ),
              border: Border.all(
                color: hot
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.3),
                width: hot ? 2 : 1.4,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 62,
                  width: double.infinity,
                  child: _pile(size),
                ),
                const SizedBox(height: 6),
                Text(
                  '$gems',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'GEMS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: AppColors.aqua,
                  ),
                ),
                const SizedBox(height: 10),
                _priceButton(
                  price,
                  wide: true,
                  onTap: () => showSoon(context, 'Purchases'),
                ),
              ],
            ),
          ),
          if (tag != null)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tag == 'BEST VALUE'
                        ? const Color(0xFFFF3D5A)
                        : AppColors.gold,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.4),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: tag == 'BEST VALUE'
                          ? Colors.white
                          : const Color(0xFF4A2A00),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// More gems in the pile for bigger packs.
  Widget _pile(int level) {
    final big = 34.0 + level * 4;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (level >= 2)
          Positioned(
            left: 8,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.3,
              child: GemIcon(size: big * 0.62),
            ),
          ),
        if (level >= 3)
          Positioned(
            right: 8,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.3,
              child: GemIcon(size: big * 0.62),
            ),
          ),
        if (level >= 4) Positioned(top: -2, child: GemIcon(size: big * 0.5)),
        GemIcon(size: big),
      ],
    );
  }

  Widget _priceButton(String price, {bool wide = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: wide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9AF5FF), Color(0xFF1FA9FF)],
          ),
          border: Border.all(color: Colors.white, width: 1.8),
          boxShadow: const [
            BoxShadow(color: Color(0xFF0B63B0), offset: Offset(0, 3)),
          ],
        ),
        child: Text(
          price,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: const [
              Shadow(color: Color(0xFF0B4F8F), offset: Offset(0, 1.5)),
            ],
          ),
        ),
      ),
    );
  }

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
    final owned = cost == 0;
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
              if (owned) {
                setState(() => _skin = i);
                BottleSkin.equip(shape);
              } else {
                _tooExpensive(cost);
              }
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
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: [
        for (var i = 0; i < _themes.length; i++)
          Entrance(
            progress: _in,
            begin: 0.1 + i * 0.07,
            end: 0.5 + i * 0.07,
            child: _themeCard(i),
          ),
      ],
    );
  }

  Widget _themeCard(int i) {
    final (name, cost, top, bottom, accent) = _themes[i];
    final owned = cost == 0;
    final on = _theme == i;
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
                  CustomPaint(painter: _ThemePainter(top, bottom, accent)),
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
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          _stateButton(
            owned: owned,
            on: on,
            cost: cost,
            onTap: () {
              if (owned) {
                setState(() => _theme = i);
              } else {
                _tooExpensive(cost);
              }
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
