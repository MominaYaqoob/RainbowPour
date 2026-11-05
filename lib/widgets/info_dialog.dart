import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_dialog.dart';
import 'game_text.dart';
import 'water_button.dart';

/// One small popup for all simple messages (ad not ready, daily limit, clock
/// problem, extra undo ...): an icon, a title, a line of text and one or two
/// buttons.
class InfoDialog extends StatelessWidget {
  const InfoDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = const Color(0xFF3E6BFF),
    this.primary = 'OK',
    this.onPrimary,
    this.secondary,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Color color = const Color(0xFF3E6BFF),
    String primary = 'OK',
    VoidCallback? onPrimary,
    String? secondary,
    VoidCallback? onSecondary,
  }) => showGameDialog<void>(
    context,
    builder: (_) => InfoDialog(
      icon: icon,
      title: title,
      message: message,
      color: color,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
    ),
  );

  // ---- the standard messages, so every screen words them the same way

  static Future<void> adNotReady(BuildContext context) => show(
    context,
    icon: Icons.hourglass_empty_rounded,
    color: const Color(0xFFFFA000),
    title: 'Ad Not Ready',
    message: 'No ad is available right now. Please try again in a moment.',
  );

  static Future<void> dailyLimit(BuildContext context) => show(
    context,
    icon: Icons.event_busy_rounded,
    color: const Color(0xFFFF3D5A),
    title: 'Daily Limit Reached',
    message: 'You have watched all 3 gem ads for today. Come back tomorrow!',
  );

  static Future<void> clockChanged(BuildContext context) => show(
    context,
    icon: Icons.schedule_rounded,
    color: const Color(0xFFFF3D5A),
    title: 'Check Your Clock',
    message:
        'Your phone time looks wrong. Set the date and time to automatic to '
        'claim rewards.',
  );

  static Future<void> extraUndo(
    BuildContext context, {
    required VoidCallback onWatch,
  }) => show(
    context,
    icon: Icons.undo_rounded,
    title: 'Need More Undos?',
    message: 'Watch a short ad to get 3 extra undos for this level.',
    primary: 'Watch Ad: +3 Undos',
    onPrimary: onWatch,
    secondary: 'Not now',
  );

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(color, Colors.white, 0.35)!, color],
              ),
              border: Border.all(color: Colors.white, width: 2.4),
            ),
            child: Icon(icon, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 12),
          GameText(title, size: 25),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          WaterButton(
            width: math.min(MediaQuery.sizeOf(context).width - 100, 270),
            label: primary,
            onPressed: () {
              Navigator.of(context).pop();
              onPrimary?.call();
            },
          ),
          if (secondary != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onSecondary?.call();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  secondary!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
