import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'gem_icon.dart';

/// Dark pill with a gem, the gem count and a gold plus button.
class GemPill extends StatelessWidget {
  const GemPill({super.key, required this.gems, this.onTap});

  final int gems;
  final VoidCallback? onTap;

  static String format(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              format(gems),
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
  }
}
