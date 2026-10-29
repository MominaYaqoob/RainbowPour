import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/anim.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/game_text.dart';
import '../../widgets/night_background.dart';
import '../../widgets/water_button.dart';
import '../welcome/welcome_reward_screen.dart';
import 'daily_illustration.dart';
import 'fill_illustration.dart';
import 'helpers_illustration.dart';
import 'pour_illustration.dart';
import 'tap_lift_illustration.dart';

class IntroSlide {
  const IntroSlide({
    required this.line1,
    required this.line2,
    required this.description,
    required this.illustration,
  });

  final String line1;
  final String line2;
  final String description;
  final Widget illustration;
}

// More pages are added here as they get built.
const _slides = <IntroSlide>[
  IntroSlide(
    line1: 'Tap & Lift',
    line2: 'A Bottle',
    description:
        'Tap any bottle to lift its top color.\nTap again to put it back.',
    illustration: TapLiftIllustration(),
  ),
  IntroSlide(
    line1: 'Pour Matching',
    line2: 'Colors',
    description:
        'Pour onto the same color or an empty\nbottle until it is full.',
    illustration: PourIllustration(),
  ),
  IntroSlide(
    line1: 'Fill Every',
    line2: 'Bottle!',
    description:
        'Sort until every bottle holds one color.\nEarn stars and gems for each win.',
    illustration: FillIllustration(),
  ),
  IntroSlide(
    line1: 'Stuck? Use',
    line2: 'Helpers',
    description:
        'Undo, get a hint or add a bottle.\nWatch an ad to get them for free.',
    illustration: HelpersIllustration(),
  ),
  IntroSlide(
    line1: 'Daily Rewards',
    line2: '& Streaks',
    description:
        'Claim gems every day and keep your\nstreak alive for bigger prizes.',
    illustration: DailyIllustration(),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppPrefs.setOnboardingDone();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(fadeRoute(const WelcomeRewardScreen(), zoom: true));
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      _finish();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: NightBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _IntroPage(
                    index: i,
                    count: _slides.length,
                    slide: _slides[i],
                  ),
                ),
              ),
              _dots(),
              const SizedBox(height: 18),
              WaterButton(
                width: math.min(width - 56, 300),
                label: _isLast ? "Let's Play!" : 'Next',
                icon: _isLast
                    ? Icons.play_arrow_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
              // keeps the button clear of the lake's bottom edge
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.035),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(
                height: 24,
                child: FittedBox(
                  child: ConeBottle(layers: [4], width: 36, showShadow: false),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rainbow Pour',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0x66000030), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _isLast ? 0 : 1,
            child: IgnorePointer(
              ignoring: _isLast,
              child: GestureDetector(
                onTap: _finish,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _slides.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _page ? 32 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: i == _page
                  ? const Color(0xFFFFE680)
                  : Colors.white.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(5),
              boxShadow: i == _page
                  ? const [BoxShadow(color: Color(0x88FFD24D), blurRadius: 10)]
                  : null,
            ),
          ),
      ],
    );
  }
}

/// One onboarding page. Its content slides and fades in one piece at a time.
class _IntroPage extends StatefulWidget {
  const _IntroPage({
    required this.index,
    required this.count,
    required this.slide,
  });

  final int index;
  final int count;
  final IntroSlide slide;

  @override
  State<_IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<_IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// Fade + rise for one element between [a] and [b] of the entrance.
  Widget _stagger(double a, double b, Widget child, {double rise = 22}) {
    final p = seg(_in.value, a, b, Curves.easeOutCubic);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, (1 - p) * rise),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = (size.width / 240).clamp(0.9, 1.5);
    return AnimatedBuilder(
      animation: _in,
      builder: (context, _) {
        final panelP = seg(_in.value, 0.2, 0.85, Curves.easeOutBack);
        final panelFade = seg(_in.value, 0.2, 0.55, Curves.easeOut);
        return Column(
          children: [
            SizedBox(height: size.height * 0.015),
            _stagger(
              0,
              0.35,
              Text(
                'STEP ${widget.index + 1} OF ${widget.count}',
                style: GoogleFonts.outfit(
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.gold,
                ),
              ),
            ),
            SizedBox(height: 6 * s),
            _stagger(0.08, 0.45, GameText(widget.slide.line1, size: 22 * s)),
            _stagger(
              0.18,
              0.55,
              GameText(
                widget.slide.line2,
                size: 33 * s,
                gradient: const [Color(0xFFFFF27A), Color(0xFFFFA000)],
              ),
            ),
            SizedBox(height: 8 * s),
            _stagger(
              0.32,
              0.7,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                // lines break only where the text has a newline; on narrow
                // phones the whole block shrinks instead of wrapping
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.slide.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5 * s,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth - 32;
                  final h = math.min(c.maxHeight - 26, w * 176 / 216 + 16);
                  return Center(
                    child: Opacity(
                      opacity: panelFade,
                      child: Transform.translate(
                        offset: Offset(0, (1 - panelP) * 40),
                        child: Transform.scale(
                          scale: 0.9 + 0.1 * panelP,
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: _Panel(child: widget.slide.illustration),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dark rounded stage the illustration sits on.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141B66), Color(0xFF070B2E)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000020),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 28,
            right: 28,
            height: 1.4,
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.35)),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(fit: BoxFit.contain, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
