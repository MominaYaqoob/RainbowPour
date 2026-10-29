import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/game_text.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/water_button.dart';

/// "No moves left" popup (UI only): a shaking bottle with a red stop badge,
/// two ways to carry on (undo or an extra bottle), restart and home.
class LevelFailedDialog extends StatefulWidget {
  const LevelFailedDialog({
    super.key,
    required this.onUndo,
    required this.onExtraBottle,
    required this.onRestart,
    required this.onHome,
  });

  final VoidCallback onUndo;
  final VoidCallback onExtraBottle;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUndo,
    required VoidCallback onExtraBottle,
    required VoidCallback onRestart,
    required VoidCallback onHome,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'No moves left',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, _) => LevelFailedDialog(
        onUndo: onUndo,
        onExtraBottle: onExtraBottle,
        onRestart: onRestart,
        onHome: onHome,
      ),
      transitionBuilder: (context, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(c),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<LevelFailedDialog> createState() => _LevelFailedDialogState();
}

class _LevelFailedDialogState extends State<LevelFailedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = math.min(MediaQuery.sizeOf(context).width - 40, 340.0);
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: w,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B2480), Color(0xFF0A1040)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000020),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GameText(
                  'No Moves Left',
                  size: 28,
                  gradient: [Color(0xFFFFFFFF), Color(0xFFFFB3C0)],
                ),
                const SizedBox(height: 4),
                Text(
                  'Do not give up, pick a helper.',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                _stuckBottle(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _option(
                        Icons.undo_rounded,
                        'Undo',
                        'Last move',
                        null,
                        widget.onUndo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _option(
                        Icons.add_rounded,
                        '+ Bottle',
                        'Extra space',
                        40,
                        widget.onExtraBottle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                WaterButton(
                  width: math.min(w - 40, 270),
                  label: 'Restart',
                  icon: Icons.refresh_rounded,
                  onPressed: widget.onRestart,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: widget.onExtraBottle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
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
                          size: 17,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Watch an ad: free extra bottle',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: widget.onHome,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.home_rounded,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Home',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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

  /// A mixed-up bottle that shakes, with a pulsing red stop badge.
  Widget _stuckBottle() {
    return SizedBox(
      height: 130,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final v = _loop.value;
          // short shake in the first third of each loop
          final shake = v < 0.35
              ? math.sin(v / 0.35 * math.pi * 6) * 5 * (1 - v / 0.35)
              : 0.0;
          final pulse = 1 + 0.08 * math.sin(2 * math.pi * v * 2);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(shake, 0),
                child: ConeBottle(
                  layers: const [1, 4, 0, 5],
                  width: 36,
                  showShadow: false,
                ),
              ),
              Transform.translate(
                offset: const Offset(34, -34),
                child: Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF3D5A),
                      border: Border.all(color: Colors.white, width: 2.4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000020),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _option(
    IconData icon,
    String title,
    String sub,
    int? cost,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF3E6BFF), Color(0xFF1B3FB0)],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                if (cost != null)
                  Positioned(
                    right: -16,
                    top: -4,
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
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
