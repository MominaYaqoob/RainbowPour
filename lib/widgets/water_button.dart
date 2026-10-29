import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/anim.dart';
import '../core/app_colors.dart';

/// Primary button made of water: aqua gel body, two drifting waves, rising
/// bubbles, a glossy top highlight and a shine that sweeps across. Presses
/// down like a real 3D button.
class WaterButton extends StatefulWidget {
  const WaterButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.width = 260,
    this.dim = false,
  });

  /// Shows the button faded (e.g. while a form is incomplete); it still
  /// reacts to taps so the screen can explain what is missing.
  final bool dim;

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final double width;

  @override
  State<WaterButton> createState() => _WaterButtonState();
}

class _WaterButtonState extends State<WaterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 58 / 208;
    final s = w / 208;
    return Opacity(
      opacity: widget.dim ? 0.55 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 110),
                    padding: EdgeInsets.only(top: _down ? 3 * s : 0),
                    child: CustomPaint(painter: _WaterPainter(_c)),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: _down ? 3 * s : 0,
                  height: 48 * s,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22 * s),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: GoogleFonts.outfit(
                                fontSize: 18 * s,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF0B4F8F),
                                    offset: Offset(0, 1.6 * s),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6 * s),
                            Icon(
                              widget.icon,
                              size: 22 * s,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF0B4F8F),
                                  offset: Offset(0, 1.6 * s),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  Path _wave(double base, double amp, double drift) {
    final p = Path()..moveTo(-104 + drift, base);
    var x = -104.0 + drift;
    for (var i = 0; i < 8; i++) {
      p.quadraticBezierTo(x + 26, base + (i.isEven ? -amp : amp), x + 52, base);
      x += 52;
    }
    p
      ..lineTo(x, 60)
      ..lineTo(-104 + drift, 60)
      ..close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final s = size.width / 208;
    canvas.scale(s);

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 208, 48),
      const Radius.circular(24),
    );
    // 3D edge below the body
    canvas.drawRRect(
      body.shift(const Offset(0, 6)),
      Paint()..color = AppColors.waterEdge,
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9AF5FF), AppColors.aquaDeep],
        ).createShader(body.outerRect),
    );

    canvas.save();
    canvas.clipRRect(body);

    // waves: slow vertical breathing plus horizontal drift
    final amp1 = 8 * math.sin(2 * math.pi * v * 4.6);
    final amp2 = 6 * math.sin(2 * math.pi * v * 3.5 + 1);
    canvas.drawPath(
      _wave(30, amp1, (v * 104 * 3) % 104),
      Paint()..color = const Color(0xFF1696F0).withValues(alpha: 0.55),
    );
    canvas.drawPath(
      _wave(35, amp2, 104 - (v * 104 * 2) % 104),
      Paint()..color = const Color(0xFF7FE6FF).withValues(alpha: 0.5),
    );

    // rising bubbles
    const bubbles = [
      [38.0, 2.6, 4.0, 0.0],
      [96.0, 2.0, 3.5, 0.3],
      [158.0, 3.0, 4.0, 0.6],
      [188.0, 2.0, 5.0, 0.15],
    ];
    final bp = Paint();
    for (final b in bubbles) {
      final p = (v * b[2] + b[3]) % 1;
      bp.color = Colors.white.withValues(alpha: 0.8 * math.sin(math.pi * p));
      canvas.drawCircle(Offset(b[0], 46 - 40 * p), b[1], bp);
    }

    // glossy highlight
    final gloss = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 3, 188, 17),
      const Radius.circular(8.5),
    );
    canvas.drawRRect(
      gloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(gloss.outerRect),
    );
    canvas.drawCircle(
      const Offset(19, 14),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // shine sweep
    final sp = (v * 3) % 1;
    final x = lerpX(seg(sp, 0, 0.4, Curves.easeInOut));
    final shine = Path()
      ..moveTo(x + 10, 0)
      ..lineTo(x + 40, 0)
      ..lineTo(x + 30, 48)
      ..lineTo(x, 48)
      ..close();
    canvas.drawPath(
      shine,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.7),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(x, 0, 40, 48)),
    );
    canvas.restore();

    canvas.drawRRect(
      body.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  static double lerpX(double p) => -60 + 320 * p;

  @override
  bool shouldRepaint(_WaterPainter old) => false;
}
