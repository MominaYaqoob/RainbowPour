import 'dart:convert';

/// Everything the game remembers, as one JSON document (key `save_v1`).
///
/// Plain Dart on purpose: no Flutter, no storage here, so it can be tested on
/// its own. Reading is forgiving: a missing or wrongly typed field falls back
/// to its default instead of failing.
class SaveData {
  SaveData();

  static const version = 1;

  // ---- first launch and profile
  bool consentDone = false;
  bool onboardingDone = false;
  bool welcomeClaimed = false;
  bool profileDone = false;
  String? nickname;
  int avatar = 0;
  bool tutorialDone = false;

  // ---- economy
  int gems = 0;

  /// Shop items bought, e.g. `skin:tube` or `bg:2`.
  Set<String> owned = {};

  /// Equipped bottle skin index and background (-1 = automatic by level).
  int skin = 0;
  int bgMode = -1;

  // ---- progress
  /// The furthest level the player can open.
  int level = 1;

  /// Best stars per level (1 to 3).
  Map<int, int> stars = {};
  int levelsCompleted = 0;
  int totalMoves = 0;

  // ---- settings
  bool sound = true;
  bool music = true;
  bool vibration = true;
  bool colorblind = false;

  // ---- rewarded ads
  /// Local day (`yyyy-m-d`) the gem-ad counter belongs to, and the count.
  String? adsDay;
  int adsCount = 0;

  // ---- daily reward and challenge
  DailyState daily = DailyState();

  // ---- the level being played, so it can be resumed
  InProgress? inProgress;

  /// Records a won level. Keeps the best stars (1 to 3), counts the level as
  /// completed the first time, adds the moves to the total and opens the next
  /// level (never past [maxLevel], never closing one already open).
  /// Returns true when these stars are a new best for the level.
  bool recordWin({
    required int level,
    required int stars,
    required int moves,
    required int maxLevel,
  }) {
    final earned = stars.clamp(1, 3);
    final before = this.stars[level];
    if (before == null) levelsCompleted++;
    final better = before == null || earned > before;
    if (better) this.stars[level] = earned;
    totalMoves += moves < 0 ? 0 : moves;
    final next = level + 1;
    if (next <= maxLevel && next > this.level) this.level = next;
    return better;
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'consentDone': consentDone,
    'onboardingDone': onboardingDone,
    'welcomeClaimed': welcomeClaimed,
    'profileDone': profileDone,
    'nickname': nickname,
    'avatar': avatar,
    'tutorialDone': tutorialDone,
    'gems': gems,
    'owned': owned.toList()..sort(),
    'skin': skin,
    'bgMode': bgMode,
    'level': level,
    'stars': {for (final e in stars.entries) '${e.key}': e.value},
    'levelsCompleted': levelsCompleted,
    'totalMoves': totalMoves,
    'sound': sound,
    'music': music,
    'vibration': vibration,
    'colorblind': colorblind,
    'adsDay': adsDay,
    'adsCount': adsCount,
    'daily': daily.toJson(),
    'inProgress': inProgress?.toJson(),
  };

  String encode() => jsonEncode(toJson());

  factory SaveData.fromJson(Map<String, Object?> json) {
    final s = SaveData();
    s.consentDone = _bool(json['consentDone'], false);
    s.onboardingDone = _bool(json['onboardingDone'], false);
    s.welcomeClaimed = _bool(json['welcomeClaimed'], false);
    s.profileDone = _bool(json['profileDone'], false);
    s.nickname = json['nickname'] is String ? json['nickname'] as String : null;
    s.avatar = _int(json['avatar'], 0);
    s.tutorialDone = _bool(json['tutorialDone'], false);
    s.gems = _int(json['gems'], 0);
    s.owned = {
      if (json['owned'] is List)
        for (final v in json['owned'] as List)
          if (v is String) v,
    };
    s.skin = _int(json['skin'], 0);
    s.bgMode = _int(json['bgMode'], -1);
    s.level = _int(json['level'], 1);
    final rawStars = json['stars'];
    if (rawStars is Map) {
      for (final e in rawStars.entries) {
        final level = int.tryParse('${e.key}');
        final value = e.value;
        if (level != null && value is int && value >= 1 && value <= 3) {
          s.stars[level] = value;
        }
      }
    }
    s.levelsCompleted = _int(json['levelsCompleted'], 0);
    s.totalMoves = _int(json['totalMoves'], 0);
    s.sound = _bool(json['sound'], true);
    s.music = _bool(json['music'], true);
    s.vibration = _bool(json['vibration'], true);
    s.colorblind = _bool(json['colorblind'], false);
    s.adsDay = json['adsDay'] is String ? json['adsDay'] as String : null;
    s.adsCount = _int(json['adsCount'], 0);
    final daily = json['daily'];
    if (daily is Map) s.daily = DailyState.fromJson(_stringMap(daily));
    final progress = json['inProgress'];
    if (progress is Map) {
      s.inProgress = InProgress.tryFromJson(_stringMap(progress));
    }
    return s;
  }

  /// Reads a saved document. Returns null for missing or damaged text, so the
  /// caller can start fresh (or migrate old values).
  static SaveData? tryDecode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      return SaveData.fromJson(_stringMap(decoded));
    } on FormatException {
      return null;
    }
  }

  /// Builds a save from the values older builds kept one by one in
  /// SharedPreferences. [old] maps the old key to its stored value.
  factory SaveData.fromLegacy(Map<String, Object?> old) {
    final s = SaveData();
    s.consentDone = _bool(old['consent_done'], false);
    s.onboardingDone = _bool(old['onboarding_done'], false);
    s.welcomeClaimed = _bool(old['welcome_claimed'], false);
    s.profileDone = _bool(old['profile_done'], false);
    s.nickname = old['nickname'] is String ? old['nickname'] as String : null;
    s.avatar = _int(old['avatar'], 0);
    s.tutorialDone = _bool(old['opt_tutorial'], false);
    s.gems = _int(old['gems'], 0);
    s.owned = {
      if (old['owned'] is List)
        for (final v in old['owned'] as List)
          if (v is String) v,
    };
    s.skin = _int(old['bottle_skin'], 0);
    s.bgMode = _int(old['bg_mode'], -1);
    s.level = _int(old['level'], 1);
    s.sound = _bool(old['opt_sound'], true);
    s.music = _bool(old['opt_music'], true);
    s.vibration = _bool(old['opt_vibration'], true);
    s.colorblind = _bool(old['opt_colorblind'], false);
    s.adsDay = old['ads_day'] is String ? old['ads_day'] as String : null;
    s.adsCount = _int(old['ads_count'], 0);
    return s;
  }

  static bool _bool(Object? v, bool def) => v is bool ? v : def;
  static int _int(Object? v, int def) => v is int ? v : def;

  static Map<String, Object?> _stringMap(Map<Object?, Object?> m) => {
    for (final e in m.entries) '${e.key}': e.value,
  };
}

/// Daily reward streak, the clock check and the daily challenge record.
class DailyState {
  DailyState();

  /// Local day (`yyyy-m-d`) the reward was last claimed, or null.
  String? lastClaimDay;

  /// Reward day reached, 0 to 7 (the claim of day 7 starts again at 1).
  int streakDay = 0;

  /// Consecutive days claimed with no gap. Keeps growing after day 7.
  int streakCount = 0;
  int bestStreak = 0;

  /// The latest device time seen (milliseconds since epoch). If the clock
  /// goes more than two minutes behind this, daily claims are blocked.
  ///
  /// The value only moves forward. A clock jumped far ahead stays the mark,
  /// so returning to the real time stays blocked until real time catches up.
  int lastSeenMs = 0;

  /// Days (`yyyy-m-d`) the daily challenge was completed.
  Set<String> challengeDone = {};
  int challengeStreak = 0;

  /// Monday (`yyyy-m-d`) of the week whose 7-day bonus was already paid.
  String? weeklyBonusWeek;

  /// Local day (`yyyy-m-d`) whose claimed reward was already doubled by an ad.
  String? rewardDoubledDay;

  Map<String, Object?> toJson() => {
    'lastClaimDay': lastClaimDay,
    'streakDay': streakDay,
    'streakCount': streakCount,
    'bestStreak': bestStreak,
    'lastSeenMs': lastSeenMs,
    'challengeDone': challengeDone.toList()..sort(),
    'challengeStreak': challengeStreak,
    'weeklyBonusWeek': weeklyBonusWeek,
    'rewardDoubledDay': rewardDoubledDay,
  };

  factory DailyState.fromJson(Map<String, Object?> json) {
    final d = DailyState();
    d.lastClaimDay = json['lastClaimDay'] is String
        ? json['lastClaimDay'] as String
        : null;
    d.streakDay = SaveData._int(json['streakDay'], 0);
    d.streakCount = SaveData._int(json['streakCount'], 0);
    d.bestStreak = SaveData._int(json['bestStreak'], 0);
    d.lastSeenMs = SaveData._int(json['lastSeenMs'], 0);
    d.challengeDone = {
      if (json['challengeDone'] is List)
        for (final v in json['challengeDone'] as List)
          if (v is String) v,
    };
    d.challengeStreak = SaveData._int(json['challengeStreak'], 0);
    d.weeklyBonusWeek = json['weeklyBonusWeek'] is String
        ? json['weeklyBonusWeek'] as String
        : null;
    d.rewardDoubledDay = json['rewardDoubledDay'] is String
        ? json['rewardDoubledDay'] as String
        : null;
    return d;
  }
}

/// A level that was started and not finished.
class InProgress {
  InProgress({
    required this.mode,
    required this.level,
    this.date,
    required this.capacity,
    required this.bottles,
    required this.moves,
    required this.history,
    this.freeUndos = 3,
    this.bonusUndos = 0,
    this.extraBottleUsed = false,
  });

  /// `level` or `challenge`.
  final String mode;
  final int level;

  /// For a daily challenge, its day (`yyyy-m-d`).
  final String? date;
  final int capacity;

  /// Layers of every bottle, bottom to top, as they are now.
  final List<List<int>> bottles;
  final int moves;

  /// The pours made so far, `[from, to, count]`, oldest first.
  final List<List<int>> history;
  final int freeUndos;
  final int bonusUndos;
  final bool extraBottleUsed;

  Map<String, Object?> toJson() => {
    'mode': mode,
    'level': level,
    'date': date,
    'capacity': capacity,
    'bottles': bottles,
    'moves': moves,
    'history': history,
    'freeUndos': freeUndos,
    'bonusUndos': bonusUndos,
    'extraBottleUsed': extraBottleUsed,
  };

  /// Returns null if the stored data is incomplete or not a valid board.
  static InProgress? tryFromJson(Map<String, Object?> json) {
    final mode = json['mode'];
    final capacity = json['capacity'];
    final rawBottles = json['bottles'];
    if (mode is! String || capacity is! int || rawBottles is! List) {
      return null;
    }
    final bottles = <List<int>>[];
    for (final b in rawBottles) {
      if (b is! List) return null;
      final layers = <int>[];
      for (final v in b) {
        if (v is! int || v < 0) return null;
        layers.add(v);
      }
      if (layers.length > capacity) return null;
      bottles.add(layers);
    }
    if (bottles.isEmpty || capacity < 1) return null;
    final history = <List<int>>[];
    final rawHistory = json['history'];
    if (rawHistory is List) {
      for (final h in rawHistory) {
        if (h is! List || h.length != 3 || h.any((v) => v is! int)) {
          return null;
        }
        history.add([for (final v in h) v as int]);
      }
    }
    return InProgress(
      mode: mode,
      level: SaveData._int(json['level'], 1),
      date: json['date'] is String ? json['date'] as String : null,
      capacity: capacity,
      bottles: bottles,
      moves: SaveData._int(json['moves'], 0),
      history: history,
      freeUndos: SaveData._int(json['freeUndos'], 3),
      bonusUndos: SaveData._int(json['bonusUndos'], 0),
      extraBottleUsed: SaveData._bool(json['extraBottleUsed'], false),
    );
  }
}
