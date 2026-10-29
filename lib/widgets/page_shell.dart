import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_prefs.dart';
import 'gem_pill.dart';
import 'night_background.dart';

/// Shows a short floating "coming soon" message.
void showSoon(BuildContext context, String what) {
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

/// Common frame for inner screens: night background, a back button, a title
/// and (optionally) the gem balance.
class PageShell extends StatefulWidget {
  const PageShell({
    super.key,
    required this.title,
    required this.child,
    this.showGems = true,
    this.gemsTappable = true,
  });

  final String title;
  final Widget child;
  final bool showGems;

  /// When false the gem pill is shown but does nothing (used by the shop).
  final bool gemsTappable;

  @override
  State<PageShell> createState() => _PageShellState();
}

class _PageShellState extends State<PageShell> {
  int _gems = 0;

  @override
  void initState() {
    super.initState();
    AppPrefs.gems().then((g) {
      if (mounted) setState(() => _gems = g);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF0A1040,
                          ).withValues(alpha: 0.85),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF120F52),
                                offset: Offset(0, 2.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    widget.showGems
                        ? GemPill(
                            gems: _gems,
                            onTap: widget.gemsTappable
                                ? () => showSoon(context, 'The shop')
                                : null,
                          )
                        : const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
