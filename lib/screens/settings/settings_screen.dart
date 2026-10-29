import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../widgets/entrance.dart';
import '../../widgets/page_shell.dart';
import 'rate_us_dialog.dart';

/// Settings. UI demo: the switches work on screen but are not saved yet.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  bool _sound = true;
  bool _music = true;
  bool _vibration = true;
  bool _colorblind = false;

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Settings',
      showGems: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _section('GAME', 0, [
            _toggle(
              Icons.volume_up_rounded,
              'Sound',
              null,
              _sound,
              (v) => setState(() => _sound = v),
              const [Color(0xFF7FE9FF), Color(0xFF1FA9FF)],
            ),
            _toggle(
              Icons.music_note_rounded,
              'Music',
              null,
              _music,
              (v) => setState(() => _music = v),
              const [Color(0xFFB98CFF), Color(0xFF6B3BE0)],
            ),
            _toggle(
              Icons.vibration_rounded,
              'Vibration',
              null,
              _vibration,
              (v) => setState(() => _vibration = v),
              const [Color(0xFF8EF0A0), Color(0xFF2DBE60)],
            ),
            _toggle(
              Icons.visibility_rounded,
              'Colorblind mode',
              'Adds symbols on the liquids',
              _colorblind,
              (v) => setState(() => _colorblind = v),
              const [Color(0xFFFFF27A), Color(0xFFFFA000)],
            ),
          ]),
          const SizedBox(height: 18),
          _section('MORE', 1, [
            _link(Icons.language_rounded, 'Language', 'English', const [
              Color(0xFF7FE9FF),
              Color(0xFF1FA9FF),
            ]),
            _link(Icons.star_rounded, 'Rate Rainbow Pour', null, const [
              Color(0xFFFFF27A),
              Color(0xFFFFA000),
            ]),
            _link(Icons.tune_rounded, 'Ad privacy options', null, const [
              Color(0xFFB98CFF),
              Color(0xFF6B3BE0),
            ]),
            _link(Icons.lock_rounded, 'Privacy Policy', null, const [
              Color(0xFF8EF0A0),
              Color(0xFF2DBE60),
            ]),
            _link(Icons.description_rounded, 'Terms of Service', null, const [
              Color(0xFFFF9AB0),
              Color(0xFFE0245B),
            ]),
          ]),
          const SizedBox(height: 22),
          Entrance(
            progress: _in,
            begin: 0.6,
            end: 1,
            child: Column(
              children: [
                Text(
                  'Rainbow Pour 1.0.0',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Made by Gamezium Studio',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, int order, List<Widget> rows) {
    final a = order * 0.2;
    return Entrance(
      progress: _in,
      begin: a,
      end: a + 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: AppColors.gold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF141B66), Color(0xFF070B2E)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000020),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 70,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, List<Color> colors) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(13),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ),
      border: Border.all(color: Colors.white, width: 1.8),
    ),
    child: Icon(icon, size: 22, color: Colors.white),
  );

  Widget _titleBlock(String title, String? sub) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (sub != null)
          Text(
            sub,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
      ],
    ),
  );

  Widget _toggle(
    IconData icon,
    String title,
    String? sub,
    bool value,
    ValueChanged<bool> onChanged,
    List<Color> colors,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            _badge(icon, colors),
            const SizedBox(width: 14),
            _titleBlock(title, sub),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.aquaDeep,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              trackOutlineColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _link(
    IconData icon,
    String title,
    String? trailing,
    List<Color> colors,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => title.startsWith('Rate')
          ? RateUsDialog.show(context)
          : showSoon(context, title),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            _badge(icon, colors),
            const SizedBox(width: 14),
            _titleBlock(title, null),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  trailing,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
