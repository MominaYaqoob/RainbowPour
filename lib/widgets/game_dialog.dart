import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';

/// Opens [builder] as a popup that fades and scales in.
Future<T?> showGameDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => Center(child: builder(context)),
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

/// The dark rounded card all popups sit on.
class DialogCard extends StatelessWidget {
  const DialogCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = math.min(MediaQuery.sizeOf(context).width - 40, 340.0);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: w,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
        child: child,
      ),
    );
  }
}

/// Pill button with a white outline, for secondary actions.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gold = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Gold outline and icon (used for "watch an ad" options).
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: gold ? 0.08 : 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: gold
                ? AppColors.gold.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: gold ? AppColors.gold : Colors.white),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
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
