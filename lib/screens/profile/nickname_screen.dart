import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../widgets/avatar_face.dart';
import '../../widgets/entrance.dart';
import '../../widgets/game_text.dart';
import '../../widgets/night_background.dart';
import '../../widgets/water_button.dart';
import '../home/home_screen.dart';

final _valid = RegExp(r'^[A-Za-z0-9 ]{3,12}$');

const _adjectives = [
  'Happy',
  'Swift',
  'Lucky',
  'Brave',
  'Sunny',
  'Jolly',
  'Zippy',
  'Fizzy',
];
const _nouns = [
  'Drop',
  'Pour',
  'Splash',
  'Wave',
  'Fox',
  'Panda',
  'Otter',
  'Bubble',
];

String _randomName(math.Random r) =>
    '${_adjectives[r.nextInt(_adjectives.length)]}${_nouns[r.nextInt(_nouns.length)]}';

/// Pick a nickname and an avatar, then continue to Home.
class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  final _rng = math.Random();
  late final TextEditingController _name = TextEditingController(
    text: _randomName(_rng),
  );
  final _focus = FocusNode();
  int _avatar = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _avatar = _rng.nextInt(kAvatarCount);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _in.dispose();
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _ok => _valid.hasMatch(_name.text.trim());

  void _randomize() {
    HapticFeedback.selectionClick();
    setState(() {
      _name.text = _randomName(_rng);
      _error = null;
    });
  }

  Future<void> _continue() async {
    if (!_ok) {
      setState(() => _error = 'Use 3 to 12 letters or numbers.');
      return;
    }
    FocusScope.of(context).unfocus();
    await AppPrefs.saveProfile(_name.text.trim(), _avatar);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(fadeRoute(const HomeScreen(), zoom: true));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = (size.width / 240).clamp(0.9, 1.5);
    final w = math.min(size.width - 56, 300.0);
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height - MediaQuery.paddingOf(context).vertical - 16,
              ),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.03),
                  Entrance(
                    progress: _in,
                    begin: 0,
                    end: 0.3,
                    child: GameText('Create Your', size: 22 * s),
                  ),
                  Entrance(
                    progress: _in,
                    begin: 0.06,
                    end: 0.36,
                    child: GameText(
                      'Player',
                      size: 33 * s,
                      gradient: const [Color(0xFFFFF27A), Color(0xFFFFA000)],
                    ),
                  ),
                  SizedBox(height: 14 * s),
                  Entrance(
                    progress: _in,
                    begin: 0.15,
                    end: 0.5,
                    child: _bigAvatar(s),
                  ),
                  SizedBox(height: 16 * s),
                  Entrance(
                    progress: _in,
                    begin: 0.3,
                    end: 0.65,
                    child: _field(w),
                  ),
                  SizedBox(
                    height: 22,
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
                  Entrance(
                    progress: _in,
                    begin: 0.4,
                    end: 0.75,
                    child: Text(
                      'Choose an avatar',
                      style: GoogleFonts.outfit(
                        fontSize: 12 * s,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  Entrance(
                    progress: _in,
                    begin: 0.45,
                    end: 0.85,
                    child: _grid(w),
                  ),
                  SizedBox(height: 22 * s),
                  Entrance(
                    progress: _in,
                    begin: 0.65,
                    end: 1,
                    child: ListenableBuilder(
                      listenable: _name,
                      builder: (context, _) => WaterButton(
                        width: w,
                        label: 'Continue',
                        dim: !_ok,
                        onPressed: _continue,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigAvatar(double s) {
    final d = 92 * s;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
      child: Container(
        key: ValueKey(_avatar),
        width: d + 10,
        height: d + 10,
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
        child: AvatarFace(index: _avatar, size: d),
      ),
    );
  }

  Widget _field(double w) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: w,
      padding: const EdgeInsets.only(left: 18, right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1040).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: focused ? AppColors.gold : Colors.white.withValues(alpha: 0.3),
          width: focused ? 2 : 1.4,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              focusNode: _focus,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
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
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Your nickname',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _randomize,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF27A), Color(0xFFFFA000)],
                ),
              ),
              child: const Icon(
                Icons.casino_rounded,
                size: 22,
                color: Color(0xFF4A2A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(double w) {
    const gap = 12.0;
    final cell = ((w - gap * 3) / 4).clamp(48.0, 64.0);
    // exactly four avatars per row
    return SizedBox(
      width: 4 * (cell + 3) + 3 * gap + 2,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < kAvatarCount; i++)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _avatar = i);
              },
              child: AnimatedScale(
                scale: i == _avatar ? 1.1 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i == _avatar ? AppColors.gold : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: AvatarFace(index: i, size: cell - 8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
