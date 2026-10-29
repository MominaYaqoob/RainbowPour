import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cone_bottle.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_text.dart';
import '../../widgets/water_button.dart';

/// "Leave the game?" popup shown when Back is pressed on Home (UI only).
class ExitDialog extends StatelessWidget {
  const ExitDialog({super.key, required this.onQuit});

  final VoidCallback onQuit;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onQuit,
  }) =>
      showGameDialog<void>(context, builder: (_) => ExitDialog(onQuit: onQuit));

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 90,
            child: FittedBox(
              child: ConeBottle(
                layers: [4, 5, 6],
                width: 36,
                showShadow: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const GameText('Leave Game?', size: 28),
          const SizedBox(height: 6),
          Text(
            'Your progress and gems are safe.',
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          WaterButton(
            width: math.min(MediaQuery.sizeOf(context).width - 100, 270),
            label: 'Keep Playing',
            icon: Icons.play_arrow_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 12),
          GhostButton(
            label: 'Quit',
            icon: Icons.logout_rounded,
            onTap: () {
              Navigator.of(context).pop();
              onQuit();
            },
          ),
        ],
      ),
    );
  }
}
