import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/app_links.dart';
import '../../core/review_prompt.dart';
import '../../widgets/info_dialog.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_text.dart';
import '../../widgets/water_button.dart';

/// "Rate us" popup: pick 1 to 5 stars. 4 or 5 go to the store, 1 to 3 get a
/// thank-you.
class RateUsDialog extends StatefulWidget {
  const RateUsDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showGameDialog<void>(context, builder: (_) => const RateUsDialog());

  @override
  State<RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<RateUsDialog> {
  int _stars = 0;

  static const _hint = [
    'Tap a star to rate',
    'We will try harder',
    'We can do better',
    'Good to hear!',
    'Great, thank you!',
    'You are awesome!',
  ];

  /// 4 or 5 stars go to the store (the in-app review sheet, or the store page
  /// if the sheet is not available). 1 to 3 stars only get a thank-you: the
  /// player is not sent to a public rating page from here.
  Future<void> _submit() async {
    final stars = _stars;
    if (stars == 0) return;
    // The dialog is about to close; keep what is needed from its context.
    final nav = Navigator.of(context);
    nav.pop();
    final host = nav.context;
    if (stars <= 3) {
      await InfoDialog.show(
        host,
        icon: Icons.favorite_rounded,
        title: 'Thank you!',
        message: 'We read every rating. We will keep improving Rainbow Pour.',
      );
      return;
    }
    final shown = await ReviewPrompt.rateNow();
    if (!shown && host.mounted) {
      await AppLinks.open(host, AppLinks.playStoreUrl, title: 'Rate us');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameText('Enjoying', size: 22),
          const GameText(
            'Rainbow Pour?',
            size: 30,
            gradient: [Color(0xFFFFF27A), Color(0xFFFFA000)],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _stars = i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedScale(
                    scale: i == _stars ? 1.25 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.star_rounded,
                        size: 46,
                        color: i <= _stars
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.22),
                        shadows: i <= _stars
                            ? const [
                                Shadow(
                                  color: Color(0x88FFB300),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _hint[_stars],
              key: ValueKey(_stars),
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 16),
          WaterButton(
            width: math.min(MediaQuery.sizeOf(context).width - 100, 270),
            label: _stars > 0 && _stars <= 3 ? 'Send' : 'Rate us',
            icon: Icons.favorite_rounded,
            dim: _stars == 0,
            onPressed: _submit,
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Maybe later',
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
