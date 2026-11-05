import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../ads/ad_service.dart';
import '../../ads/rewarded_flow.dart';
import '../../core/app_colors.dart';
import '../../core/app_prefs.dart';
import '../../core/audio_service.dart';
import '../../core/challenge_timer.dart';
import '../../core/daily_challenge.dart' as daily_challenge;
import '../../core/haptics.dart';
import '../../core/save_data.dart';
import '../../game/difficulty.dart';
import '../../game/engine.dart';
import '../../game/generator.dart';
import '../../game/hint_planner.dart';
import '../../game/level_repository.dart';
import '../../game/models.dart';
import '../../game/resume.dart';
import '../../game/rewards.dart';
import '../../game/solver.dart';
import '../../widgets/background_theme.dart';
import '../../widgets/bottle_shape.dart';
import '../../widgets/cone_bottle.dart';
import '../../widgets/entrance.dart';
import '../../widgets/game_text.dart';
import '../../widgets/gem_icon.dart';
import '../../widgets/gem_pill.dart';
import '../../widgets/info_dialog.dart';
import '../../widgets/night_background.dart';
import '../../widgets/water_button.dart';
import '../shop/not_enough_gems_dialog.dart';
import 'board_layout.dart';
import 'level_complete_dialog.dart';
import 'level_failed_dialog.dart';
import 'sample_board.dart';

/// Game screen: a campaign level, or one daily challenge board.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.level})
    : day = null,
      challengeSeconds = daily_challenge.challengeSeconds,
      elapsed = null;

  /// Today's daily board. No campaign progress is written from this mode.
  ///
  /// [elapsed] replaces the monotonic stopwatch in tests. The phone clock
  /// does not feed the countdown.
  const GameScreen.challenge({
    super.key,
    required this.day,
    this.challengeSeconds = daily_challenge.challengeSeconds,
    this.elapsed,
  }) : level = null;

  /// Null = the player's current level. Ignored for [GameScreen.challenge].
  final int? level;

  /// Local day of a daily challenge, or null for a campaign level.
  final DateTime? day;

  /// Countdown length. Tests pass a short one; the game uses 5 minutes.
  final int challengeSeconds;

  /// Monotonic elapsed time for tests. Null uses a [Stopwatch].
  final Duration Function()? elapsed;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();
  late final AnimationController _pour = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _celeb = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Empty until the worker isolate finishes the level.
  SampleBoard _sample = const SampleBoard(4, []);
  GameState? _play;
  int _par = 0;
  int? _selected;

  List<List<int>> get _board {
    final play = _play;
    if (play == null) return _sample.bottles;
    return [for (final bottle in play.board.bottles) bottle.layers];
  }

  int get _capacity => _play?.board.capacity ?? _sample.capacity;

  int _gems = 0;
  late int _level = widget.level ?? 1;

  /// Short "preparing" overlay shown while a level loads.
  bool _loading = true;
  bool _animating = false;
  bool _settling = false;
  final Set<int> _celebrating = {};
  final Map<int, int> _celebrateColor = {};
  int _pourToken = 0;
  int? _pourFrom;
  int? _pourTo;
  int _pourCount = 0;
  int _pourColor = 0;

  UndoCredits _undos = UndoCredits();
  ExtraBottle _extra = ExtraBottle();
  bool _rewarded = false;

  /// Hint: bottle to pour from and into (glow), -1 = none.
  int _hintFrom = -1;
  int _hintTo = -1;
  bool _undoPulse = false;

  /// Level 1 teaching: the pours to guide the player through, or null.
  /// Hints that always lead to a win (or say how far to undo).
  HintPlanner? _planner;

  List<Move>? _tutorialMoves;
  int _tutorialStep = 0;
  bool _tutorialDone = false;
  int _pulseToken = 0;

  /// 0.78..1: shrinks the bottom buttons on short screens.
  double _f = 1;

  bool get _busy => _loading || _animating || _settling || _timeUp;

  bool get _isChallenge => widget.day != null;

  ChallengeTimer? _challengeTimer;
  Timer? _clockTick;
  bool _timeUp = false;
  bool _challengeOver = false;
  int _dialogHolds = 0;
  bool _inBackground = false;

  /// Restart is reloading the board; do not resume the old countdown.
  bool _holdResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A full-screen ad Activity moves the app to inactive/paused, which
    // pauses this clock. [_watch] also holds it, so the gap before that
    // Activity starts does not keep counting.
    if (!_isChallenge || _challengeOver || _timeUp) return;
    final away =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden;
    if (away == _inBackground) return;
    _inBackground = away;
    if (away) {
      _challengeTimer?.pause();
    } else if (_dialogHolds == 0 && !_holdResume) {
      _challengeTimer?.resume();
    }
  }

  Future<void> _load() async {
    final gemsFuture = AppPrefs.gems();
    final day = widget.day;
    if (day != null) {
      // The campaign tutorial and the saved campaign board stay untouched.
      _tutorialDone = true;
      final boardFuture = LevelRepository.getChallenge(day);
      final pause = Future<void>.delayed(const Duration(milliseconds: 900));
      final gems = await gemsFuture;
      final generated = await boardFuture;
      await pause;
      if (!mounted) return;
      _install(generated, level: generated.spec.level, gems: gems);
      return;
    }
    _tutorialDone = await AppPrefs.flag('tutorial', def: false);
    final level = widget.level ?? await AppPrefs.level();
    final boardFuture = LevelRepository.getLevel(level);
    final pause = Future<void>.delayed(const Duration(milliseconds: 900));
    final gems = await gemsFuture;
    final generated = await boardFuture;
    await pause;
    final saved = _tutorialDone ? await AppPrefs.inProgress() : null;
    if (!mounted) return;
    _install(generated, level: level, gems: gems, resume: saved);
    LevelRepository.prefetch(level);
    final play = _play;
    if (_resumed && play != null && play.isStuck) {
      // a saved board with no moves left: show the same popup again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showStuck();
      });
    }
  }

  /// True when the board on screen came from the save, not a new shuffle.
  bool _resumed = false;

  /// Stores the board after a move so the level can be picked up again.
  void _saveProgress() {
    // The one in-progress slot belongs to campaign levels.
    if (_isChallenge) return;
    final play = _play;
    if (play == null || _tutorialMoves != null || play.isWon) return;
    AppPrefs.setInProgress(
      InProgress(
        mode: 'level',
        level: _level,
        capacity: play.board.capacity,
        bottles: [for (final b in play.board.bottles) b.layers.toList()],
        moves: play.moves,
        history: [
          for (final m in play.history) [m.from, m.to, m.count],
        ],
        freeUndos: _undos.free,
        bonusUndos: _undos.bonus,
        extraBottleUsed: _extra.used,
      ),
    );
  }

  void _install(
    GeneratedLevel generated, {
    required int level,
    int? gems,
    InProgress? resume,
  }) {
    final restored = restoreProgress(resume, generated);
    _resumed = restored != null;
    _pourToken++;
    _pour.stop();
    _celeb.stop();
    _pulseToken++;
    setState(() {
      if (gems != null) _gems = gems;
      _level = level;
      _par = generated.par;
      _play = restored ?? GameState(board: generated.board);
      _planner = HintPlanner(generated.board, generated.solution);
      _sample = SampleBoard.fromGenerated(generated);
      _loading = false;
      _animating = false;
      _settling = false;
      _celebrating.clear();
      _selected = null;
      _pourFrom = _pourTo = null;
      _hintFrom = _hintTo = -1;
      _undoPulse = false;
      _tutorialMoves =
          !_isChallenge && generated.spec.isTutorial && !_tutorialDone
          ? generated.solution
          : null;
      _tutorialStep = 0;
      _undos = restored != null
          ? (UndoCredits(free: resume!.freeUndos)..bonus = resume.bonusUndos)
          : UndoCredits();
      _extra = ExtraBottle()
        ..used = restored != null && resume!.extraBottleUsed;
      _rewarded = false;
    });
    if (_isChallenge) _startChallengeClock();
  }

  /// Full countdown, started only once the board can be played.
  void _startChallengeClock() {
    _timeUp = false;
    _challengeOver = false;
    _holdResume = false;
    final timer = _challengeTimer ??= ChallengeTimer(
      total: Duration(seconds: widget.challengeSeconds),
      elapsed: widget.elapsed,
    );
    timer.start();
    if (_inBackground || _dialogHolds > 0) timer.pause();
    if (mounted) setState(() {});
    _clockTick ??= Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _onClockTick(),
    );
  }

  void _onClockTick() {
    if (!mounted || !_isChallenge || _challengeOver || _timeUp) return;
    final timer = _challengeTimer;
    if (timer == null) return;
    if (timer.isRunning && timer.isExpired) {
      _onTimeUp();
      return;
    }
    if (timer.isRunning) setState(() {});
  }

  void _holdTimer() {
    if (!_isChallenge || _challengeOver || _timeUp) return;
    _dialogHolds++;
    _challengeTimer?.pause();
  }

  void _releaseTimer() {
    if (_dialogHolds > 0) _dialogHolds--;
    if (_holdResume ||
        _challengeOver ||
        _timeUp ||
        _inBackground ||
        _dialogHolds > 0) {
      return;
    }
    _challengeTimer?.resume();
  }

  void _openDialog(Future<void> Function() show) {
    if (!_isChallenge || _challengeOver || _timeUp) {
      show();
      return;
    }
    _holdTimer();
    show().whenComplete(() {
      if (mounted) _releaseTimer();
    });
  }

  /// The quiet moment after a win: an interstitial may play if the gate
  /// allows it (never in levels 1 to 3, one per three levels, 90 s apart),
  /// then the next level starts. With no ad ready there is no delay.
  Future<void> _nextAfterAd() async {
    await AdService.instance.maybeShowInterstitial(level: _level);
    if (!mounted) return;
    await _next();
  }

  /// Moves on to the next level. The furthest unlocked level is saved on a win.
  Future<void> _next() async {
    if (_busy) return;
    Haptics.light();
    final next = _level >= DifficultyCurve.maxLevel
        ? DifficultyCurve.maxLevel
        : _level + 1;
    setState(() {
      _loading = true;
      _hintFrom = _hintTo = -1;
      _selected = null;
    });
    final pending = LevelRepository.getLevel(next);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final generated = await pending;
    if (!mounted) return;
    _install(generated, level: next);
    LevelRepository.prefetch(next);
  }

  /// Puts the level back on the generated board. No new shuffle.
  Future<void> _restart() async {
    if (_loading) return;
    Haptics.light();
    setState(() {
      _loading = true;
      _animating = false;
      _hintFrom = _hintTo = -1;
      _selected = null;
    });
    if (_isChallenge) _holdResume = true;
    if (!_isChallenge) AppPrefs.setInProgress(null);
    final day = widget.day;
    final pending = day != null
        ? LevelRepository.getChallenge(day)
        : LevelRepository.getLevel(_level);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final generated = await pending;
    if (!mounted) return;
    _install(generated, level: _level);
    if (day == null) LevelRepository.prefetch(_level);
  }

  /// The bottle the tutorial wants tapped next, or null outside the tutorial.
  int? get _tutorialTarget {
    final moves = _tutorialMoves;
    if (moves == null || _busy || _tutorialStep >= moves.length) return null;
    final move = moves[_tutorialStep];
    return _selected == null ? move.from : move.to;
  }

  void _tapBottle(int index) {
    if (_busy) return;
    final play = _play;
    if (play == null) return;
    if (_tutorialMoves != null && index != _tutorialTarget) {
      Haptics.light();
      return;
    }
    final selected = _selected;
    if (selected == null) {
      Haptics.tap();
      AudioService.instance.play(Sfx.select);
      setState(() => _selected = index);
      return;
    }
    if (selected == index) {
      Haptics.tap();
      AudioService.instance.play(Sfx.select);
      setState(() => _selected = null);
      return;
    }
    final next = play.pour(selected, index);
    if (next == null) {
      Haptics.light();
      setState(() => _selected = null);
      return;
    }
    final count = GameEngine.pourCount(play.board, selected, index);
    final color = play.board.bottles[selected].topColour ?? 0;
    final token = ++_pourToken;
    setState(() {
      _animating = true;
      _selected = null;
      _hintFrom = _hintTo = -1;
      _pourFrom = selected;
      _pourTo = index;
      _pourCount = count;
      _pourColor = color;
    });
    _pour.duration = Duration(milliseconds: math.min(1700, 880 + 150 * count));
    AudioService.instance.play(Sfx.pour);
    _pour.forward(from: 0).whenComplete(() async {
      if (!mounted || token != _pourToken) return;
      final landed = next.board.bottles[index];
      final done =
          landed.isFull && landed.layers.every((l) => l == landed.layers.first);
      setState(() {
        _play = next;
        _animating = false;
        _pourFrom = _pourTo = null;
        if (_tutorialMoves != null) _tutorialStep++;
        if (done) {
          _celebrating.add(index);
          _celebrateColor[index] = landed.layers.first;
          _settling = true;
        }
      });
      _saveProgress();
      if (done) {
        Haptics.success();
        AudioService.instance.play(Sfx.bottleFull);
        _celeb.forward(from: 0).whenComplete(() {
          if (mounted) setState(_celebrating.clear);
        });
        // let the effect play before a win popup covers it
        await Future<void>.delayed(const Duration(milliseconds: 750));
        if (!mounted || token != _pourToken) return;
        setState(() => _settling = false);
      }
      _afterMove();
    });
  }

  void _afterMove() {
    final play = _play;
    if (play == null) return;
    if (play.isWon) {
      _showWin();
    } else if (play.isStuck) {
      _showStuck();
    }
  }

  Future<void> _showWin() async {
    if (_rewarded) return;
    final play = _play;
    if (play == null) return;
    _rewarded = true;
    if (_isChallenge) {
      _challengeOver = true;
      _challengeTimer?.pause();
      Haptics.success();
      AudioService.instance.play(Sfx.win);
      final result = await AppPrefs.completeChallenge(
        widget.day!,
        DateTime.now(),
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (result.clockBlocked) {
        await InfoDialog.clockChanged(context);
        if (mounted) nav.pop();
        return;
      }
      if (result.wrongDay) {
        await InfoDialog.show(
          context,
          icon: Icons.bedtime_rounded,
          title: 'Challenge ended at midnight',
          message:
              'The day changed before you finished, so there is no reward.',
          primary: 'Continue',
          onPrimary: () => nav.pop(),
        );
        return;
      }
      final bonus = result.weeklyBonus
          ? '\nWeekly bonus: +${daily_challenge.weeklyBonusGems} gems.'
          : '';
      final message = result.alreadyDone
          ? 'You already finished this day.'
          : 'You earned ${result.gems} gems.\nStreak: ${result.streak} days.$bonus';
      await InfoDialog.show(
        context,
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFC107),
        title: 'Challenge complete',
        message: message,
        primary: 'Continue',
        onPrimary: () => nav.pop(),
      );
      return;
    }
    AppPrefs.setInProgress(null);
    if (_tutorialMoves != null) {
      setState(() => _tutorialMoves = null);
      _tutorialDone = true;
      AppPrefs.setFlag('tutorial', true);
    }
    final stars = Stars.count(level: _level, par: _par, moves: play.moves);
    final reward = Rewards.gemsForStars(stars);
    Haptics.success();
    AudioService.instance.play(Sfx.win);
    final total = await AppPrefs.addGems(reward);
    // best stars, completed count, total moves and the next level
    await AppPrefs.recordWin(
      level: _level,
      stars: stars,
      moves: play.moves,
      maxLevel: DifficultyCurve.maxLevel,
    );
    AdService.instance.onLevelCompleted();
    if (!mounted) return;
    setState(() => _gems = total);
    LevelCompleteDialog.show(
      context,
      level: _level,
      stars: stars,
      moves: play.moves,
      gems: reward,
      offerDouble: _level != 1,
      onDouble: () => _doubleWin(reward),
      onNext: () {
        Navigator.of(context).pop();
        _nextAfterAd();
      },
      onReplay: () {
        Navigator.of(context).pop();
        _restart();
      },
      onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
    );
  }

  void _showStuck() {
    Haptics.fail();
    AudioService.instance.play(Sfx.fail);
    _openDialog(
      () => LevelFailedDialog.show(
        context,
        onUndo: () {
          Navigator.of(context).pop();
          _undo();
        },
        onExtraBottle: () {
          final already = _extra.used;
          final navigator = Navigator.of(context);
          _addBottle().then((_) {
            if (!already && _extra.used && mounted) navigator.pop();
          });
        },
        onRestart: () {
          Navigator.of(context).pop();
          _restart();
        },
        onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
        onWatchAd: () {
          if (_extra.used || _tutorialMoves != null) return;
          Navigator.of(context).pop();
          _watch(_grantFreeBottle);
        },
      ),
    );
  }

  Future<void> _undo() async {
    if (_busy || _tutorialMoves != null) return;
    final play = _play;
    if (play == null || !play.canUndo) {
      Haptics.light();
      return;
    }
    if (!_undos.hasAny) {
      _openDialog(
        () => InfoDialog.extraUndo(
          context,
          onWatch: () {
            _watch(() async {
              _undos.grantWatchedAd();
              if (!mounted) return;
              await _undo();
            });
          },
        ),
      );
      return;
    }
    _undos.spend();
    Haptics.tap();
    setState(() {
      _play = play.undo();
      _selected = null;
      _hintFrom = _hintTo = -1;
    });
    _saveProgress();
  }

  Future<void> _hint() async {
    if (_busy || _tutorialMoves != null) return;
    final play = _play;
    if (play == null || play.isWon) return;
    Haptics.tap();
    final advice = _planner?.next(play.board, play.history);
    final move = advice?.move;
    if (move == null) {
      // no gems are taken when the hint is "undo"
      _pulseUndo();
      final steps = advice?.undoSteps ?? 0;
      _openDialog(
        () => InfoDialog.show(
          context,
          icon: Icons.undo_rounded,
          title: steps > 0
              ? 'Undo $steps ${steps == 1 ? 'move' : 'moves'}'
              : 'Undo a few moves',
          message: steps > 0
              ? 'Undo $steps to get back on a way to win, then ask for a hint again.'
              : 'This board has no way forward. Undo, then try again.',
        ),
      );
      return;
    }
    const cost = Rewards.hintCost;
    if (_gems < cost) {
      _needGems(cost);
      return;
    }
    if (!await AppPrefs.spendGems(cost)) return;
    if (!mounted) return;
    setState(() {
      _gems -= cost;
      _hintFrom = move.from;
      _hintTo = move.to;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _hintFrom = _hintTo = -1);
  }

  Future<void> _addBottle() async {
    if (_busy || _tutorialMoves != null) return;
    final play = _play;
    if (play == null) return;
    Haptics.tap();
    if (!_extra.take()) {
      _openDialog(
        () => InfoDialog.show(
          context,
          icon: Icons.add_rounded,
          title: 'One Bottle Only',
          message: 'You can add one extra bottle on this level.',
        ),
      );
      _extra.used = true;
      return;
    }
    const cost = Rewards.bottleCost;
    if (_gems < cost) {
      _extra.used = false;
      _needGems(cost);
      return;
    }
    if (!await AppPrefs.spendGems(cost)) {
      _extra.used = false;
      return;
    }
    if (!mounted) return;
    setState(() {
      _gems -= cost;
      _selected = null;
      _play = GameState(
        board: GameEngine.addEmptyBottle(play.board),
        moves: play.moves,
        history: play.history,
      );
    });
    _saveProgress();
  }

  void _needGems(int cost) {
    _openDialog(
      () => NotEnoughGemsDialog.show(
        context,
        need: cost,
        have: _gems,
        onGetGems: () {
          Navigator.of(context).pop();
          _soon('The shop');
        },
        onWatchAd: () {
          Navigator.of(context).pop();
          _watch(_grantGemAd, gems: true);
        },
      ),
    );
  }

  void _pulseUndo() {
    final token = ++_pulseToken;
    setState(() => _undoPulse = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || token != _pulseToken) return;
      setState(() => _undoPulse = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTick?.cancel();
    _in.dispose();
    _loop.dispose();
    _pour.dispose();
    _celeb.dispose();
    super.dispose();
  }

  /// Pauses the challenge clock for the whole ad, including the moment
  /// before the ad Activity sends the app to the background.
  Future<RewardedResult> _watch(
    Future<void> Function() onReward, {
    bool gems = false,
  }) {
    _holdTimer();
    return RewardedFlow.run(
      context,
      gemCap: gems,
      onReward: onReward,
    ).whenComplete(() {
      if (mounted) _releaseTimer();
    });
  }

  Future<bool> _doubleWin(int base) async {
    var granted = false;
    await _watch(() async {
      final total = await AppPrefs.addGems(base);
      granted = true;
      if (mounted) setState(() => _gems = total);
    });
    return granted;
  }

  Future<void> _grantGemAd() async {
    final ok = await AppPrefs.watchedGemAd();
    if (!mounted) return;
    if (!ok) {
      await InfoDialog.dailyLimit(context);
      return;
    }
    final total = await AppPrefs.gems();
    if (!mounted) return;
    setState(() => _gems = total);
  }

  Future<void> _grantFreeBottle() async {
    final play = _play;
    if (play == null || play.isWon || !_extra.take()) return;
    if (!mounted) return;
    setState(() {
      _selected = null;
      _play = GameState(
        board: GameEngine.addEmptyBottle(play.board),
        moves: play.moves,
        history: play.history,
      );
    });
    _saveProgress();
  }

  void _soon(String what) {
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

  void _onTimeUp() {
    if (!_isChallenge || _timeUp || _challengeOver) return;
    _timeUp = true;
    _challengeTimer?.pause();
    AudioService.instance.play(Sfx.fail);
    setState(() {});
    final nav = Navigator.of(context);
    InfoDialog.show(
      context,
      icon: Icons.timer_off_rounded,
      color: const Color(0xFFFF3D5A),
      title: "Time's up",
      message: 'The clock ran out. Try the same board again?',
      primary: 'Retry',
      secondary: 'Exit',
      onPrimary: () {
        _restart();
      },
      onSecondary: () => nav.pop(),
    );
  }

  void _pause() {
    if (_animating) return;
    Haptics.tap();
    _openDialog(
      () => showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Pause',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, _, _) => const SizedBox.shrink(),
        transitionBuilder: (context, a, _, _) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
          return FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(c),
              child: Center(child: _pauseCard(context)),
            ),
          );
        },
      ),
    );
  }

  Widget _pauseCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: math.min(MediaQuery.sizeOf(context).width - 56, 320),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2480), Color(0xFF0A1040)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000020),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameText(
              'Paused',
              size: 34,
              gradient: [Color(0xFFFFF27A), Color(0xFFFFA000)],
            ),
            const SizedBox(height: 18),
            WaterButton(
              width: 220,
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ghost('Restart', Icons.refresh_rounded, () {
                  Navigator.of(context).pop();
                  _restart();
                }),
                const SizedBox(width: 12),
                _ghost('Home', Icons.home_rounded, () {
                  // closes the popup and the game, back to Home
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghost(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _f = (MediaQuery.sizeOf(context).height / 760).clamp(0.78, 1.0);
    return Scaffold(
      body: NightBackground(
        theme: BackgroundSkin.themeFor(_level),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Entrance(
                    progress: _in,
                    begin: 0,
                    end: 0.35,
                    rise: -14,
                    child: _topBar(),
                  ),
                  Expanded(
                    child: Entrance(
                      progress: _in,
                      begin: 0.15,
                      end: 0.7,
                      rise: 30,
                      child: _boardArea(),
                    ),
                  ),
                  Entrance(
                    progress: _in,
                    begin: 0.5,
                    end: 0.95,
                    child: _actionBar(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_loading,
                  child: AnimatedOpacity(
                    opacity: _loading ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0A1040,
                          ).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Preparing level…',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pause,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0A1040).withValues(alpha: 0.85),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1040).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  _isChallenge ? 'Daily Challenge' : 'Level $_level',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              GemPill(gems: _gems, onTap: () => _soon('The shop')),
            ],
          ),
          if (_isChallenge)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(child: _timerChip()),
            ),
        ],
      ),
    );
  }

  Widget _timerChip() {
    final left =
        _challengeTimer?.remaining ??
        Duration(seconds: widget.challengeSeconds);
    final urgent = !_loading && left.inSeconds <= 30;
    final text = _clockText(left);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1040).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent
              ? const Color(0xFFFF3D5A)
              : AppColors.gold.withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: urgent ? const Color(0xFFFF3D5A) : Colors.white,
        ),
      ),
    );
    if (!urgent) return chip;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final pulse = 0.55 + 0.45 * math.sin(2 * math.pi * _loop.value).abs();
        return Opacity(opacity: pulse, child: child);
      },
      child: chip,
    );
  }

  String _clockText(Duration left) {
    final seconds = left.inSeconds;
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Rows of bottles on shelves. The pour carries a bottle over its target.
  BoardLayout _layoutFor(BoxConstraints c) => layoutBoard(
    bottles: _board.length,
    maxWidth: c.maxWidth,
    maxHeight: c.maxHeight,
  );

  Widget _boardArea() {
    return LayoutBuilder(
      builder: (context, c) {
        if (_board.isEmpty) return const SizedBox.shrink();
        final lay = _layoutFor(c);
        return AnimatedBuilder(
          animation: Listenable.merge([_loop, _pour, _celeb]),
          builder: (context, _) {
            final pose = _animating && _pourFrom != null
                ? _pourPose(lay)
                : null;
            return SizedBox(
              width: c.maxWidth,
              height: c.maxHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final r in lay.shelves)
                    Positioned.fromRect(rect: r, child: _shelf()),
                  for (var i = 0; i < lay.tops.length; i++)
                    if (pose == null || i != _pourFrom) _bottle(i, lay, pose),
                  if (pose != null) _pouringBottle(lay, pose),
                  if (_tutorialTarget != null) ..._tutorialGuide(lay),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _FxPainter(
                          lay: lay,
                          shape: BottleSkin.shape.value,
                          stream: pose?.stream,
                          streamColor: AppColors.liquid[_pourColor],
                          celebrating: [
                            for (final i in _celebrating)
                              if (i < lay.tops.length)
                                (i, AppColors.liquid[_celebrateColor[i] ?? 0]),
                          ],
                          t: _celeb.value,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _shelf() => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(5),
      boxShadow: const [
        BoxShadow(color: Color(0x55000020), offset: Offset(0, 4)),
      ],
    ),
  );

  Widget _bottle(int i, BoardLayout lay, _PourPose? pose) {
    final w = lay.w;
    final up = i == _selected;
    final bob = up ? math.sin(2 * math.pi * _loop.value) * 2 : 0.0;
    final lift = up ? w * 0.3 : 0.0;
    final look = pose != null && i == _pourTo
        ? pose.target
        : _BottleLook(_board[i]);
    Widget glass = ConeBottle(
      layers: look.layers,
      width: w,
      showShadow: false,
      shape: BottleSkin.shape.value,
      capacity: _capacity,
      extraColor: look.extraColor,
      extraProgress: look.extra,
    );
    if (_celebrating.contains(i)) {
      // a small squash and stretch when the bottle fills up
      final b = math.sin(math.pi * math.min(1.0, _celeb.value * 2.2));
      glass = Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(1 - 0.05 * b, 1 + 0.08 * b, 1),
        child: glass,
      );
    }
    return Positioned(
      left: lay.tops[i].dx,
      top: lay.tops[i].dy,
      width: w,
      height: lay.h,
      child: GestureDetector(
        onTap: () => _tapBottle(i),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ground shadow, smaller while the bottle is lifted
            Positioned(
              bottom: -2,
              child: Container(
                width: w * (up ? 0.6 : 0.9),
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: up ? 0.18 : 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i == _hintFrom || i == _hintTo || i == _tutorialTarget)
              Positioned(
                bottom: -4,
                child: Container(
                  width: w * 1.25,
                  height: lay.h + 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(w * 0.45),
                    color:
                        (i == _hintFrom || i == _tutorialTarget
                                ? AppColors.gold
                                : Colors.white)
                            .withValues(alpha: 0.22),
                    border: Border.all(
                      color: i == _hintFrom || i == _tutorialTarget
                          ? AppColors.gold
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            Positioned(bottom: lift + bob, child: glass),
          ],
        ),
      ),
    );
  }

  static const _tutorialSelect = [
    'Welcome! Tap the glowing bottle',
    'Good! Tap the glowing bottle again',
    'Last one! Tap the glowing bottle',
  ];
  static const _tutorialPour = [
    'Now tap the empty bottle to pour',
    'Pour it onto the same colour',
    'Pour it in to finish the colours',
  ];

  /// A hand over the bottle to tap and a short instruction.
  List<Widget> _tutorialGuide(BoardLayout lay) {
    final target = _tutorialTarget!;
    final step = math.min(_tutorialStep, _tutorialSelect.length - 1);
    final text = _selected == null
        ? _tutorialSelect[step]
        : _tutorialPour[step];
    final top = lay.tops[target];
    final bob = math.sin(2 * math.pi * _loop.value) * 6;
    return [
      Positioned(
        left: 16,
        right: 16,
        top: 6,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1040).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold, width: 1.6),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: top.dx + lay.w / 2 - 6,
        top: top.dy + lay.h * 0.55 + bob,
        child: const IgnorePointer(
          child: Icon(
            Icons.touch_app_rounded,
            size: 40,
            color: Colors.white,
            shadows: [Shadow(color: Color(0xAA000020), blurRadius: 6)],
          ),
        ),
      ),
    ];
  }

  /// The bottle that is pouring, drawn above everything else so it can sit
  /// over its target and over the bottles around it.
  Widget _pouringBottle(BoardLayout lay, _PourPose pose) {
    return Positioned(
      left: pose.topLeft.dx,
      top: pose.topLeft.dy,
      width: lay.w,
      height: lay.h,
      child: ConeBottle(
        layers: pose.source.layers,
        width: lay.w,
        showShadow: false,
        shape: BottleSkin.shape.value,
        capacity: _capacity,
        tilt: pose.tilt,
        topLayerFraction: pose.source.fraction,
      ),
    );
  }

  /// Which way the pouring bottle leans: 1 tips clockwise (its body ends up
  /// left of the target), -1 the other way. Never toward a screen edge.
  int _pourDir(BoardLayout lay, int from, int to) {
    final fx = lay.tops[from].dx;
    final tx = lay.tops[to].dx;
    final room = lay.w * 2.4;
    final rightOk = tx - room >= 0;
    final leftOk = tx + lay.w + room <= lay.width;
    var dir = tx > fx + 1
        ? 1
        : (tx < fx - 1 ? -1 : (tx + lay.w / 2 < lay.width / 2 ? -1 : 1));
    if (dir == 1 && !rightOk && leftOk) dir = -1;
    if (dir == -1 && !leftOk && rightOk) dir = 1;
    return dir;
  }

  /// One frame of a pour: lift and travel to the target (0 to 0.22), pour
  /// with the lip held above the target's mouth (to 0.8), then go home.
  _PourPose _pourPose(BoardLayout lay) {
    final from = _pourFrom!;
    final to = _pourTo!;
    final play = _play!;
    final src = play.board.bottles[from].layers;
    final dst = play.board.bottles[to].layers;
    final shape = BottleSkin.shape.value;
    final w = lay.w;
    final s = lay.s;
    final dir = _pourDir(lay, from, to);
    final home = lay.tops[from];
    final target = lay.tops[to];
    // the lip stays here, a little above the target's opening
    final hold = Offset(target.dx + w / 2, target.dy + 4 * s - 0.5 * w);
    final lip = Offset(18 + dir * shape.lipHalf, 4);

    Offset lipAt(double theta) {
      final dx = lip.dx - 18;
      final dy = lip.dy - 55;
      final c = math.cos(theta);
      final n = math.sin(theta);
      return Offset(18 + dx * c - dy * n, 55 + dx * n + dy * c) * s;
    }

    Offset locked(double theta) => hold - lipAt(theta);

    final spill = _tiltAngle(0.998, src.length);
    final end = _tiltAngle(0.001, math.max(1, src.length - _pourCount + 1));
    final v = _pour.value;
    const a = 0.22;
    const b = 0.8;

    if (v < a) {
      final e = Curves.easeInOutCubic.transform(v / a);
      final theta = dir * spill * e;
      final lifted = home - Offset(0, w * 0.3);
      return _PourPose(
        Offset.lerp(lifted, locked(theta), e)!,
        theta,
        _BottleLook(src),
        _BottleLook(dst),
        null,
      );
    }
    if (v <= b) {
      final p = (v - a) / (b - a);
      final progress = (p * _pourCount).clamp(0.0, _pourCount - 0.001);
      final gone = progress.floor();
      final part = progress - gone;
      final left = src.sublist(0, src.length - gone);
      final fraction = (1 - part).clamp(0.0, 1.0);
      final theta = dir * _tiltAngle(fraction, left.length);
      final lh = 72 / _capacity;
      final surface = target.dy + (110 - lh * (dst.length + progress)) * s;
      final sw = math.max(3.0, w * 0.13);
      final showStream = p > 0.03 && p < 0.97 && surface > hold.dy;
      return _PourPose(
        locked(theta),
        theta,
        _BottleLook(left, fraction: fraction),
        _BottleLook(dst, extraColor: _pourColor, extra: progress),
        showStream
            ? Rect.fromLTRB(
                hold.dx - sw / 2,
                hold.dy,
                hold.dx + sw / 2,
                surface,
              )
            : null,
      );
    }
    final e = Curves.easeInOutCubic.transform(
      ((v - b) / (1 - b)).clamp(0.0, 1.0),
    );
    final theta = dir * end * (1 - e);
    return _PourPose(
      Offset.lerp(locked(theta), home, e)!,
      theta,
      _BottleLook(src.sublist(0, src.length - _pourCount)),
      _BottleLook(dst, extraColor: _pourColor, extra: _pourCount.toDouble()),
      null,
    );
  }

  /// Tilt (radians, always positive) at which only [remaining] of the top
  /// layer is left in a bottle holding [layers] layers.
  double _tiltAngle(double remaining, int layers) {
    final r = remaining.clamp(0.0, 0.998);
    if (layers < 1) return 0;
    final shape = BottleSkin.shape.value;
    var lo = 0.0;
    var hi = 1.35;
    for (var n = 0; n < 10; n++) {
      final mid = (lo + hi) / 2;
      final got = ConeBottle.topLayerFractionForTilt(mid, layers, shape: shape);
      if (got > r) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  Widget _actionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: EdgeInsets.fromLTRB(4, 6 * _f, 4, 5 * _f),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF141B66).withValues(alpha: 0.9),
            const Color(0xFF070B2E).withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000020),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _action(
            Icons.undo_rounded,
            'Undo',
            null,
            onTap: _undo,
            pulse: _undoPulse,
          ),
          _action(
            Icons.lightbulb_rounded,
            'Hint',
            Rewards.hintCost,
            onTap: _hint,
          ),
          _action(
            Icons.add_rounded,
            '+ Bottle',
            Rewards.bottleCost,
            onTap: _addBottle,
          ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    int? cost, {
    VoidCallback? onTap,
    bool pulse = false,
  }) {
    Widget button(double scale) => GestureDetector(
      onTap: onTap ?? () => _soon(label),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 42 * _f,
                    height: 42 * _f,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3E6BFF), Color(0xFF1B3FB0)],
                      ),
                      border: Border.all(color: Colors.white, width: 2.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000020),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 3,
                          child: Container(
                            width: 22,
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        Icon(icon, size: 22 * _f, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                if (cost != null)
                  Positioned(
                    right: -12,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GemIcon(size: 9),
                          const SizedBox(width: 2),
                          Text(
                            '$cost',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF4A2A00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
    if (!pulse) return button(1);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) =>
          button(1 + 0.07 * math.sin(2 * math.pi * _loop.value).abs()),
    );
  }
}

class _BottleLook {
  const _BottleLook(
    this.layers, {
    this.fraction = 1,
    this.extraColor,
    this.extra = 0,
  });

  final List<int> layers;
  final double fraction;
  final int? extraColor;
  final double extra;
}

/// The pouring bottle and its target for one frame of a pour.
class _PourPose {
  const _PourPose(
    this.topLeft,
    this.tilt,
    this.source,
    this.target,
    this.stream,
  );

  final Offset topLeft;
  final double tilt;
  final _BottleLook source;
  final _BottleLook target;
  final Rect? stream;
}

/// Effects drawn over the board: the falling stream, and the shine and
/// sparkles of a bottle that has just been filled with one colour.
class _FxPainter extends CustomPainter {
  _FxPainter({
    required this.lay,
    required this.shape,
    required this.stream,
    required this.streamColor,
    required this.celebrating,
    required this.t,
  });

  final BoardLayout lay;
  final BottleShape shape;
  final Rect? stream;
  final Color streamColor;
  final List<(int, Color)> celebrating;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final st = stream;
    if (st != null) {
      final r = Radius.circular(st.width / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(st, r),
        Paint()..color = Color.lerp(streamColor, Colors.white, 0.15)!,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            st.left + st.width * 0.2,
            st.top,
            st.width * 0.25,
            st.height,
          ),
          r,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(st.center.dx, st.bottom),
          width: st.width * 3.2,
          height: st.width * 1.1,
        ),
        Paint()..color = streamColor.withValues(alpha: 0.55),
      );
    }
    for (final (index, color) in celebrating) {
      _celebrate(canvas, lay.tops[index], color);
    }
  }

  void _celebrate(Canvas canvas, Offset top, Color color) {
    final w = lay.w;
    final s = lay.s;
    // shine: a soft diagonal band sweeping up the glass
    final path = shape.path().transform(
      Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, top.dx, top.dy, 0, 1).storage,
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(top.dx + w / 2, top.dy + lay.h * (1 - 1.2 * t));
    canvas.rotate(-0.55);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w * 3, height: w * 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6 * math.sin(math.pi * t)),
    );
    canvas.restore();
    // sparkles fanning out above the opening
    for (var k = 0; k < 7; k++) {
      final angle = -math.pi * (0.15 + 0.7 * k / 6);
      final dist = w * (0.4 + 1.6 * t);
      final c = Offset(
        top.dx + w / 2 + math.cos(angle) * dist * 1.3,
        top.dy + 6 * s + math.sin(angle) * dist * 1.5,
      );
      final r = w * 0.34 * (1 - t) * (k.isEven ? 1 : 0.7);
      _star(
        canvas,
        c,
        r,
        Paint()
          ..color =
              (k.isEven ? Colors.white : Color.lerp(color, Colors.white, 0.5)!)
                  .withValues(alpha: (1 - t).clamp(0.0, 1.0)),
      );
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    if (r <= 0.3) return;
    final k = r * 0.28;
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + k, c.dy - k)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + k, c.dy + k)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - k, c.dy + k)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - k, c.dy - k)
      ..close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(_FxPainter old) => true;
}
