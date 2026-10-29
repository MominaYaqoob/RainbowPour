import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../widgets/avatar_face.dart';
import '../../widgets/entrance.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_text.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/water_button.dart';
import 'stats_screen.dart';

/// Player profile: avatar, nickname, a few numbers and the avatar picker.
/// The numbers are sample data until the real game saves progress.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  String _name = 'Player';
  int _avatar = 0;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await AppPrefs.nickname();
    final avatar = await AppPrefs.avatar();
    final level = await AppPrefs.level();
    if (!mounted) return;
    setState(() {
      _name = name ?? 'Player';
      _avatar = avatar;
      _level = level;
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(int i) async {
    HapticFeedback.selectionClick();
    setState(() => _avatar = i);
    await AppPrefs.saveProfile(_name, i);
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: _name);
    final result = await showGameDialog<String>(
      context,
      builder: (ctx) => _NameDialog(controller: c),
    );
    c.dispose();
    if (result == null) return;
    setState(() => _name = result);
    await AppPrefs.saveProfile(result, _avatar);
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Profile',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Entrance(
            progress: _in,
            begin: 0,
            end: 0.4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000020),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AvatarFace(index: _avatar, size: 96),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _editName,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _name,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
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
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 1.4),
                  ),
                  child: Text(
                    'LEVEL $_level',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: const Color(0xFF4A2A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Entrance(
            progress: _in,
            begin: 0.2,
            end: 0.6,
            child: Row(
              children: [
                _stat(Icons.emoji_events_rounded, '24', 'Levels'),
                const SizedBox(width: 10),
                _stat(Icons.star_rounded, '63', 'Stars'),
                const SizedBox(width: 10),
                _stat(Icons.local_fire_department_rounded, '5', 'Best streak'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Entrance(
            progress: _in,
            begin: 0.35,
            end: 0.75,
            child: Center(
              child: WaterButton(
                width: 240,
                label: 'Score & Stats',
                icon: Icons.bar_chart_rounded,
                onPressed: () =>
                    Navigator.of(context).push(fadeRoute(const StatsScreen())),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Entrance(
            progress: _in,
            begin: 0.5,
            end: 0.9,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'CHOOSE AN AVATAR',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          Entrance(
            progress: _in,
            begin: 0.55,
            end: 1,
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < kAvatarCount; i++)
                  GestureDetector(
                    onTap: () => _pickAvatar(i),
                    child: AnimatedScale(
                      scale: i == _avatar ? 1.1 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == _avatar
                                ? AppColors.gold
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: AvatarFace(index: i, size: 58),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2480), Color(0xFF0E1550)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: AppColors.gold),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Small popup to change the nickname (3 to 12 letters or numbers).
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.controller});

  final TextEditingController controller;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameText('Your Nickname', size: 24),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1040),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: TextField(
              controller: widget.controller,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                LengthLimitingTextInputFormatter(12),
              ],
              cursorColor: AppColors.gold,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          SizedBox(
            height: 24,
            child: Center(
              child: _error == null
                  ? null
                  : Text(
                      _error!,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF8A9B),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GhostButton(
                label: 'Cancel',
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              GhostButton(
                label: 'Save',
                icon: Icons.check_rounded,
                gold: true,
                onTap: () {
                  final v = widget.controller.text.trim();
                  if (!RegExp(r'^[A-Za-z0-9 ]{3,12}$').hasMatch(v)) {
                    setState(() => _error = 'Use 3 to 12 letters or numbers.');
                    return;
                  }
                  Navigator.of(context).pop(v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
