import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_text.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/water_button.dart';

/// "Not enough gems" popup (UI only): shows how many gems are missing and
/// offers a gem pack or a rewarded ad.
class NotEnoughGemsDialog extends StatelessWidget {
  const NotEnoughGemsDialog({
    super.key,
    required this.need,
    required this.have,
    required this.onGetGems,
    required this.onWatchAd,
  });

  final int need;
  final int have;
  final VoidCallback onGetGems;
  final VoidCallback onWatchAd;

  static Future<void> show(
    BuildContext context, {
    required int need,
    required int have,
    required VoidCallback onGetGems,
    required VoidCallback onWatchAd,
  }) => showGameDialog<void>(
    context,
    builder: (_) => NotEnoughGemsDialog(
      need: need,
      have: have,
      onGetGems: onGetGems,
      onWatchAd: onWatchAd,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final frac = (have / need).clamp(0.0, 1.0);
    return DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const GemIcon(size: 74),
              Positioned(
                right: -10,
                top: -4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF3D5A),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '!',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const GameText('Not Enough Gems', size: 25),
          const SizedBox(height: 6),
          Text(
            'You need $need gems but have $have.',
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
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
                  ColoredBox(color: Colors.white.withValues(alpha: 0.18)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: frac,
                    child: const ColoredBox(color: AppColors.gold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${need - have} more to go',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          WaterButton(
            width: math.min(MediaQuery.sizeOf(context).width - 100, 270),
            label: 'Get Gems',
            icon: Icons.storefront_rounded,
            onPressed: onGetGems,
          ),
          const SizedBox(height: 12),
          GhostButton(
            label: 'Watch an ad: +25 gems',
            icon: Icons.play_circle_fill_rounded,
            gold: true,
            onTap: onWatchAd,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Later',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
