import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../core/daily_challenge.dart' as daily_challenge;
import '../../game/difficulty.dart';
import '../../widgets/info_dialog.dart';
import '../game/level_complete_dialog.dart';
import '../game/level_failed_dialog.dart';
import '../shop/not_enough_gems_dialog.dart';

/// The QA menu: shortcuts that make testing on a phone fast (gems, jump to a
/// level, show popups, clock tricks, resets).
///
/// DEBUG BUILDS ONLY. Settings builds it inside `if (kDebugMode)`, and
/// [enabled] defaults to [kDebugMode], so a release build neither shows it nor
/// keeps its code. Every action goes through [AppPrefsQa] (the save file).
class QaSection extends StatefulWidget {
  const QaSection({super.key, bool? enabled, this.clock})
    : enabled = enabled ?? kDebugMode;

  final bool enabled;

  /// The time the actions use; tests pass a fixed time.
  final DateTime Function()? clock;

  @override
  State<QaSection> createState() => _QaSectionState();
}

class _QaSectionState extends State<QaSection> {
  final _level = TextEditingController(text: '100');

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  @override
  void dispose() {
    _level.dispose();
    super.dispose();
  }

  Future<void> _run(String label, Future<void> Function() job) async {
    await job();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10175E),
          duration: const Duration(milliseconds: 1300),
          content: Text(
            'QA: $label',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  Future<void> _goToLevel() async {
    final n = int.tryParse(_level.text.trim());
    if (n == null) return;
    await _run(
      'next Play opens level ${n.clamp(1, DifficultyCurve.maxLevel)}',
      () => AppPrefsQa.jumpToLevel(n, maxLevel: DifficultyCurve.maxLevel),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear the whole save?'),
        content: const Text('Level, gems, stars, daily records: everything.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await _run('save cleared', AppPrefsQa.clearAll);
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final max = DifficultyCurve.maxLevel;
    return Column(
      key: const ValueKey('qa-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'QA (DEBUG ONLY)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: const Color(0xFFFF7A7A),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF2A0F3A),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              _group('GEMS'),
              _row(
                'Gems +500',
                () => _run('+500 gems', () => AppPrefs.addGems(500)),
              ),
              _row(
                'Gems = 0',
                () => _run('gems 0', () => AppPrefsQa.setGems(0)),
              ),
              _group('LEVELS'),
              _levelRow(),
              _row(
                'Unlock all $max levels',
                () => _run(
                  'all levels open',
                  () => AppPrefsQa.unlockAll(maxLevel: max),
                ),
              ),
              _row(
                'Reset progress (level 1)',
                () => _run('progress reset', AppPrefsQa.resetProgress),
              ),
              _group('POPUPS'),
              _row('Win popup (first win, with 2x)', _winPopup),
              _row('Win popup (replay, no gems)', _replayPopup),
              _row('Level failed popup', _failedPopup),
              _row('Not enough gems popup', _notEnoughPopup),
              _row('Extra undo (ad) popup', () {
                InfoDialog.extraUndo(context, onWatch: _close);
              }),
              _row('Ad not ready', () => InfoDialog.adNotReady(context)),
              _row('Daily ad limit', () => InfoDialog.dailyLimit(context)),
              _row(
                'Clock changed dialog',
                () => InfoDialog.clockChanged(context),
              ),
              _row("Time's up popup", _timeUpPopup),
              _group('DAILY AND CLOCK'),
              _row(
                'Fake clock one day ahead (blocks claims)',
                () => _run(
                  'clock is "ahead": claims blocked',
                  () => AppPrefsQa.shiftClockAhead(_now()),
                ),
              ),
              _row(
                'Fix the clock again',
                () => _run('clock fixed', () => AppPrefsQa.resetClock(_now())),
              ),
              _row(
                'Daily reward: claimable as day 3',
                () => _run(
                  'daily reward is day 3',
                  () => AppPrefsQa.dailyClaimableDay3(_now()),
                ),
              ),
              _row(
                'Reset daily reward',
                () => _run('daily reward reset', AppPrefsQa.resetDailyReward),
              ),
              _row(
                "Complete today's challenge",
                () => _run("today's challenge done", () async {
                  final now = _now();
                  final day = DateTime(now.year, now.month, now.day);
                  await AppPrefs.completeChallenge(day, now);
                }),
              ),
              _row(
                'Reset daily challenge',
                () => _run('challenge reset', AppPrefsQa.resetChallenge),
              ),
              _group('ADS AND REVIEW'),
              _row(
                'Reset gem-ad counter (3 per day)',
                () => _run('ad counter 0', AppPrefsQa.resetAdCounters),
              ),
              _row(
                'Reset review record',
                () => _run('review can be asked', AppPrefsQa.resetReviewRecord),
              ),
              _group('DANGER'),
              _row('Clear the whole save', _confirmClear, danger: true),
            ],
          ),
        ),
      ],
    );
  }

  // ---- popups

  void _winPopup() => LevelCompleteDialog.show(
    context,
    level: 12,
    stars: 3,
    moves: 22,
    gems: 20,
    offerDouble: true,
    onDouble: () async => true,
    onNext: _close,
    onReplay: _close,
    onHome: _close,
  );

  void _replayPopup() => LevelCompleteDialog.show(
    context,
    level: 12,
    stars: 2,
    moves: 30,
    gems: 0,
    onNext: _close,
    onReplay: _close,
    onHome: _close,
  );

  void _failedPopup() => LevelFailedDialog.show(
    context,
    onUndo: _close,
    onExtraBottle: _close,
    onRestart: _close,
    onHome: _close,
    onWatchAd: _close,
  );

  void _notEnoughPopup() => NotEnoughGemsDialog.show(
    context,
    need: 70,
    have: 25,
    onGetGems: _close,
    onWatchAd: _close,
  );

  void _timeUpPopup() => InfoDialog.show(
    context,
    icon: Icons.timer_off_rounded,
    color: const Color(0xFFFF3D5A),
    title: "Time's up",
    message:
        'The clock ran out. Try the same board again? '
        '(reward ${daily_challenge.challengeRewardGems} gems)',
    primary: 'Retry',
    secondary: 'Exit',
    onPrimary: _close,
    onSecondary: _close,
  );

  // ---- pieces

  Widget _group(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: AppColors.gold,
        ),
      ),
    ),
  );

  Widget _row(String label, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: danger ? const Color(0xFFFF8A8A) : Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Jump to level',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: TextField(
              controller: _level,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _goToLevel,
            style: FilledButton.styleFrom(
              minimumSize: const Size(54, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
