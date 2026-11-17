# Rainbow Pour: Water Sort — Project Guide

This is the single document a new developer (or a new Claude session) should read first. It explains what the app is, how the code is organised, how every system works, how to run, test and release it, what is still open, and what could be improved. When this guide and an older doc disagree, **this guide wins** (see section 20 for obsolete docs).

Last updated: 2026-11-17. Code state: all work through Task 11 is committed (`86437b8`); Firebase integration (section 11) and this guide were added afterwards and may still be uncommitted when you read this, run `git status`.

---

## 1. What the app is

- **Rainbow Pour: Water Sort**, an Android-only puzzle game made with Flutter for **Gamezium Studio**.
- Package / application id: `com.gamezium.rainbowpour` (cannot change after the first Play upload). Version `1.0.0+1` in `pubspec.yaml`.
- Free, with ads (Google AdMob), no real-money purchases, no accounts, age 13+. Everything the player owns is stored on the device.
- Core loop: tap a bottle, tap another bottle, the top colour run pours across. A level is won when every non-empty bottle is full of one colour. 300 levels, a daily reward, a daily timed challenge, a gem shop (bottle shapes and backgrounds), ads for free gems/helpers, analytics.
- Look: moonlit-night theme, crescent moon on the left, glossy "water" buttons, bottle shapes and backgrounds are the shop items.
- The owner speaks Roman Urdu (Urdu in Latin letters). See section 19 for how to work with the owner.

### Feature status (everything below is built unless marked)

| Area | Status |
|---|---|
| 21 UI screens (splash x2, consent, onboarding x5, welcome gift, nickname, profile, stats, home, level map, game, daily reward, daily challenge, settings, shop, popups) | Done |
| Game engine, 300 levels, seeded generator, solver, hints, undo, extra bottle, tutorial (level 1) | Done |
| Resume the board after the app is killed | Done |
| Level map with real progress/stars, Profile/Stats with real counters | Done |
| Daily Reward (7-day streak) and Daily Challenge (timer, weekly bonus) with clock protection | Done |
| AdMob: consent (UMP), rewarded, banner, native, interstitial (test ad ids) | Done, needs real ids |
| Audio (sound + music) | Code done, **audio files are silent placeholders** |
| Colorblind mode (20 symbols) | Done |
| Firebase Analytics + Crashlytics (consent-gated) | Done, needs on-device verification |
| In-app review, Privacy/Terms links, Rate dialog | Done (the two policy URLs are empty until the owner supplies them) |
| Debug QA menu, hint in an isolate, QA checklist | **Not done** (Task 13) |
| Cleanup (remove demo section, docs, fonts) | **Not done** (Task 14) |
| Release (keystore, AAB, Play Console) | **Not done** (Task 15) |

---

## 2. Quick start

Windows machine, project at `D:\rainbow_pour`, Android SDK at `D:\AndroidSetup\AndroidSDK`.

```bash
flutter pub get
flutter analyze                       # must be clean
flutter test                          # about 160 tests, about 40 s
flutter build web --release           # fast smoke test / browser testing
flutter build apk --debug             # Android compile check (first build ~10 min, later ~1 min)
flutter build apk --release           # one universal APK (no per-ABI split)
D:/AndroidSetup/AndroidSDK/platform-tools/adb.exe devices
D:/AndroidSetup/AndroidSDK/platform-tools/adb.exe install -r build/app/outputs/flutter-apk/app-debug.apk
```

Things that are NOT in git and must be supplied on a new machine:

- `android/app/google-services.json` (Firebase project `rainbow-pour`, app `com.gamezium.rainbowpour`). Download it from the Firebase console (Project settings > Your apps). Without it the Android build fails because the `com.google.gms.google-services` Gradle plugin is applied.
- `android/key.properties` and the upload keystore (release only, never commit; see section 16).
- `local.properties` (created by Flutter, points at the Flutter and Android SDK).

Debug builds always start at the Consent screen (see `lib/screens/app_flow.dart`) so every first-launch screen can be reviewed; release builds start where the player left off.

---

## 3. Repository map

```
lib/
  main.dart                  start-up: orientation, loaders, error hooks, Firebase/ads init, runApp
  ads/                       AdMob + UMP (consent), rewarded flow, interstitial gate, banner/native widgets
  analytics/                 Firebase Analytics + Crashlytics wrapper (consent-gated)
  core/                      save data, prefs, audio, haptics, colours, daily rules, timers (no or little UI)
  game/                      pure Dart game logic: engine, models, generator, solver, hints, rewards, resume
  screens/                   one folder per feature; game/ is the big one
  widgets/                   shared drawing and UI widgets (bottle painter, buttons, backgrounds, dialogs)
test/                        ads/, analytics/, core/, game/, screens/, widgets/  (about 160 tests)
assets/audio/                7 placeholder .wav files + README.md
android/                     Gradle (AGP 9.0.1, Kotlin 2.3.20), manifest, google-services plugin (json is git-ignored)
docs/                        guides, policy notes, old planning docs (see section 20)
release/                     built APKs (git-ignored)
```

### lib/ file by file

**lib/ads/**

| File | Purpose |
|---|---|
| `ad_config.dart` | ALL AdMob ids. `useTestIds = true` until real ids exist. An empty real id never falls back to a test id (assert in debug, throw in release). |
| `ad_service.dart` | Singleton `AdService`: runs UMP consent, starts the Mobile Ads SDK once, preloads one rewarded and one interstitial ad, `showRewarded()`, `maybeShowInterstitial()`, `adsReady` notifier (other code listens), `showPrivacyOptions()`. Everything is a safe no-op on web or non-Android. |
| `ads_gateway.dart` | Interface for the plugin calls so tests use a fake. |
| `mobile_ads_gateway.dart` | The real implementation (google_mobile_ads, UMP). |
| `mobile_ads_gateway_stub.dart`, `gateway_loader.dart` | Web stub and the conditional import that picks one. |
| `rewarded_flow.dart` | `RewardedFlow.run(...)`: one tap = one ad. Busy guard, daily gem cap, "not ready" dialog, analytics, and the reward callback. |
| `interstitial_gate.dart` | Pure rules for when an interstitial may show. |
| `ad_widgets.dart` (+ `_io`, `_stub`) | `BannerAdSlot` (320x50) and `NativeAdCard`. Web gets empty widgets. |

**lib/analytics/**: `analytics_service.dart` (`AnalyticsService`, backend interface, typed event helpers, real Firebase backend).

**lib/core/**

| File | Purpose |
|---|---|
| `save_data.dart` | `SaveData` (the whole save as one JSON document), `DailyState`, `InProgress`. Tolerant reading. |
| `app_prefs.dart` | `AppPrefs`: static API over the save (gems, level, stars, flags, daily, challenge, ads counter...). One JSON string under key `save_v1` in SharedPreferences. |
| `daily_reward.dart` | Pure rules for the 7-day reward and the clock check (`recordClock`, `clockWentBack`, `dailyStatus`, `claimDaily`, `dayKey`). |
| `daily_challenge.dart` | Pure rules for the daily challenge reward, streak, weekly bonus (`completeChallenge`). |
| `challenge_timer.dart` | Stopwatch-based countdown (unaffected by changing the phone clock). |
| `audio_service.dart` | `AudioService`, `Sfx`, `AudioAssets`, `SoundPlayer` interface, real `audioplayers` player. |
| `haptics.dart` | Vibration helper following the Vibration switch. |
| `app_links.dart` | `AppLinks`: the Privacy Policy and Terms URLs (empty until the owner supplies them), the Play Store link, and `AppLinks.open(context, url, title:)` (empty URL shows "coming soon", launch errors show a message, never throws). |
| `review_prompt.dart` | `reviewAllowed` (pure rules), `ReviewPrompt.maybeAsk` (automatic request) and `ReviewPrompt.rateNow` (player chose to rate), behind a fakeable `ReviewGateway`. |
| `colorblind.dart` | `ColorblindMode.enabled` notifier. |
| `app_colors.dart` | Palette: night colours, gold, and the 20 liquid colours (`AppColors.liquid`, index = colour id). |
| `anim.dart` | Animation helpers and `fadeRoute`. |

**lib/game/** (no Flutter UI, fully unit-tested)

| File | Purpose |
|---|---|
| `models.dart` | `Bottle`, `Board`, `Move` (immutable). A bottle's `layers` run bottom to top as colour ids. |
| `engine.dart` | `GameEngine`: legal pours, `isWon`, `isStuck`, partial pours, undo; `GameState` keeps the move history. |
| `difficulty.dart` | `DifficultyCurve`: level number to `LevelSpec` (colours, capacity, bottles, empties); also the daily challenge spec. |
| `generator.dart` | `LevelGenerator`: seeded reverse-shuffle generator; `forLevel(n)`, `forChallenge(day)`. |
| `solver.dart` | Best-first solver on bit-packed boards, `Solver.potential`, `Stars.count`. |
| `hint_planner.dart` | `HintPlanner`: the hint the game uses (see section 6). |
| `level_repository.dart` | Builds levels in an isolate with a cache and prefetch; `getLevel`, `getChallenge`. |
| `rewards.dart` | Prices, win gems, `UndoCredits`, `ExtraBottle`. |
| `resume.dart` | `restoreProgress`: accepts a saved board only if it matches the generated level. |

**lib/screens/** (feature folders)

| Folder / file | Purpose |
|---|---|
| `app_flow.dart` | `entryScreen()`: which screen to open after the splash screens. |
| `splash/` | `studio_splash.dart` (1.2 s), `game_splash.dart` (1.6 s, then `entryScreen()`; about 2.8 s in total). |
| `consent/` | First launch: terms/privacy text and "Agree and continue" (also triggers UMP). |
| `onboarding/` | 5 pages with animated illustrations. |
| `welcome/` | Welcome gem gift. |
| `profile/` | `nickname_screen`, `profile_screen`, `stats_screen`. |
| `home/` | `home_screen` (Play, tiles, banner), `exit_dialog`. |
| `levels/` | `level_map_screen`: winding path of 300 levels, lazy node window. |
| `game/` | `game_screen.dart` (about 1900 lines: board, pour animation, tutorial, hint, undo, popups, challenge mode, timer, ads/analytics hooks), `board_layout.dart` (pure layout maths), `level_complete_dialog`, `level_failed_dialog`, `sample_board.dart`. |
| `daily/` | `daily_reward_screen`. |
| `challenge/` | `daily_challenge_screen`. |
| `shop/` | `shop_screen` (free gems ad, bottle shapes, backgrounds), `not_enough_gems_dialog`. |
| `settings/` | `settings_screen` (switches, links, a demo section to delete), `rate_us_dialog` (UI only). |

**lib/widgets/**: `cone_bottle.dart` (the bottle painter), `bottle_shape.dart` (shapes + `BottleSkin` notifier), `liquid_symbols.dart` (colorblind symbols), `night_background.dart` and `background_theme.dart` (backgrounds + `BackgroundSkin`), `water_button.dart` (primary button, plays the tap sound), `page_shell.dart` (screen frame, gem pill, `showSoon`), `info_dialog.dart` (all simple popups), `game_dialog.dart`, `gem_pill.dart`, `gem_icon.dart`, `avatar_face.dart`, `entrance.dart`, `game_text.dart`.

---

## 4. App flow

`main()` in `lib/main.dart`, in order: lock portrait, transparent system bars, then load `BottleSkin`, `BackgroundSkin`, `Haptics`, `AudioService`, `ColorblindMode` (each reads the save), record the launch time (`AppPrefs.touchClock`), install crash hooks (`FlutterError.onError`, `PlatformDispatcher.onError` -> Crashlytics), start Firebase in the background, listen to `AdService.adsReady` to switch analytics consent, `runApp(const RainbowPourApp())`, then for returning players start `AdService.initialize()` (UMP + ads) after the first frame.

Screens: `StudioSplash` (1.2 s) -> `GameSplash` (1.6 s) -> `entryScreen()`:

1. Consent (not yet agreed)
2. Onboarding (5 pages)
3. Welcome gift
4. Nickname + avatar
5. Home

Home links to: Game (Play, opens the player's furthest level), Daily Reward, Daily Challenge, Level map, Shop, Profile (-> Stats), Settings. Back on Home shows the exit dialog. The Home screen reloads gems/level when a pushed screen returns.

---

## 5. Game rules and engine (`lib/game/engine.dart`, `models.dart`)

- A `Bottle` has a `capacity` (4 or 5, 6 supported by the painter) and `layers` (colour ids, bottom to top). A `Board` is a list of bottles.
- A pour moves the **top run** of equal colours from bottle A to bottle B if B is empty or B's top colour equals A's top colour, and B has space. If B has less space than the run, only part moves (**partial pour**).
- **Won**: every bottle is empty or completely full of one colour (more full bottles than colours is allowed, a colour can fill two bottles).
- **Stuck**: no *useful* pour exists. Sliding a one-colour bottle into an empty bottle is legal but not useful, so it does not count.
- `GameState` keeps the history; **undo** restores the exact previous board (and counts as a move).
- Every non-empty bottle starts full. Levels 1-2 have 1 empty bottle, level 3+ have 2 empty bottles. The player can add one **extra empty bottle** per level (costs gems, or is free after a rewarded ad).

---

## 6. Levels, generator, solver, hints, stars

**Difficulty** (`DifficultyCurve.specFor(level)`), 300 levels, max 25 bottles and 20 colours:

- Colours: L1=2, L2=3, 8 at L10, 13 at L30, 17 at L60, 20 at L100 and after.
- Bottles: L1=3 (tutorial), L2=4, L3=6 ... 13 at L10, 19 at L40, 25 at L100 and after.
- A colour may fill two bottles (`duplicates`) so a level can have more full bottles than colours.
- Every 5th level after level 5 and BEFORE level 100 is a **breather** (2 fewer colours, 3 fewer bottles). From level 100 the bottle wave below replaces it.
- **Real numbers (printed from `DifficultyCurve.specFor`):** levels 1 to 99 follow the curve above and reach the maximum 25 bottles / 20 colours at **level 99**. Samples (bottles / colours): L1 3/2, L2 4/3, L3 6/4, L5 8/5, L9 12/7, L10 10/6 (breather), L16 14/10, L26 16/12, L41 19/14, L61 21/17, L81 23/19, L91 24/19, L99 25/20.
- **Bottle wave from level 100 (changed 2026-11-17):** `DifficultyCurve.waveBottles = [19, 21, 22, 23, 24, 25, 25, 25, 20, 15]`, repeated every 10 levels (level 100 uses the first value, 101 the second, ... 109 the last, 110 the first again). The old "breather every 5th level" rule now applies only below level 100. Colours follow the bottles: one colour per full bottle, 20 at most (so 19 bottles give 17 colours, 15 bottles give 13). Empty bottles stay 2. Examples: L100 19/17, L103 23/20, L105 25/20, L108 20/18, L109 15/13. Levels 1 to 99 are unchanged (tested). Capacity is 4 up to level 60, then 5 except levels divisible by 3 (4).
- Capacity 4 up to level 60, then 4 or 5 (`n % 3 == 0 ? 4 : 5`).
- Background index = `((level-1) ~/ 20) % 6` (used when the background mode is "Auto").

**Generator** (`LevelGenerator`): seed `level * 7919 + 13`. It starts from a solved board, applies a seeded **reverse shuffle** (peels runs onto other bottles), parks bottles to reach the required empties, shuffles the colour ids over the 20-colour palette per level, then replays the guide line and runs the solver. A board whose best line is shorter than `parFloor` is rejected and the next seed is tried (up to 24 attempts, 48 for challenges). **Level 1 is a fixed 3-bottle tutorial board.** All 300 levels generate (about 5 ms average, 30-70 ms worst case on a PC) and each is replay-verified in tests. **Changing seeds, specs or the generator changes every player's levels**, so treat them as frozen unless that is intended.

**Solver** (`solver.dart`): best-first search over bit-packed boards (4 bits per layer), colours renumbered 0,1,2... before search. Returns null for more than 14 colours or capacity above 6 (then the generator's guide line is used). `Solver.potential(board)` scores "how sorted".

**Hints** (`HintPlanner`, 40 gems): in order (1) the level's own solution line (the starting board is always on it), (2) a searched solution for small boards, (3) a beam search (width 10, depth 150, ranked by `Solver.potential`), (4) "Undo N moves" advice back to the latest board that is on the level's line (costs no gems). Every move it returns belongs to a line checked to a win. The beam search runs on the UI thread today (about 0.2 s on a PC; may be about 1 s on a phone, see section 17).

**Stars** (`Stars.count`): levels 1-3 always 3 stars. Otherwise 3 stars if `moves <= ceil(1.15 * par) + 1`, 2 stars if `moves <= 1.5 * par + 2`, else 1. `par` is the solver's best line, or the length of the generator's guide line when the solver could not finish (then par for big boards is only an upper bound and 3 stars is easy).

**Daily challenge board**: `DifficultyCurve.challengeSpecFor(day)`: 25 to 28 bottles and 2 or 3 empty bottles chosen by the date seed `yyyyMMdd` (for example 20261105), capacity 4, 20 colours, rated like level 300. Same board for everyone on the same local date. `LevelGenerator.forChallenge(day)` and `LevelRepository.getChallenge(day)`.

**Board layout** (`screens/game/board_layout.dart`, pure and tested): rows = 1 (up to 4 bottles), 2 (up to 12), 3 (up to 18), 4 (up to 25), 5 (up to 35). Bottles are slim (about 11.5% of the screen width, minimum 24 px). Room is reserved above the first row for the pour animation.

---

## 7. Daily Reward and Daily Challenge

### Daily Reward (`core/daily_reward.dart`, `screens/daily/`)
- Reward days 1..7 give **20, 30, 40, 50, 60, 80, 150 gems**. One claim per **local calendar day** (calendar days are compared as UTC dates, so DST is safe).
- Claiming the day after the last claim continues the cycle; missing a day restarts at day 1; after day 7 the next claim is day 1.
- `DailyState`: `lastClaimDay`, `streakDay` (1..7 cycle position), `streakCount` (consecutive days, keeps growing, `bestStreak` is its maximum), `rewardDoubledDay` (a rewarded ad can double a claim once per day).
- Gems and streak are written in one `_update` so they can never get out of sync.

### Clock protection
`DailyState.lastSeenMs` is the latest device time seen. If `now < lastSeenMs - 2 minutes` the clock "went back": claims are refused and the "Check Your Clock" dialog shows. `lastSeenMs` only moves forward, a fresh install is never blocked. It is updated at launch (`touchClock`), when the Daily Reward screen opens, and on every successful claim. Known trade-off: if the player moves the clock far forward and the app records it, going back to real time stays blocked until real time catches up.

### Daily Challenge (`core/daily_challenge.dart`, `screens/challenge/`, `GameScreen.challenge`)
- Opens today's big board with a **5 minute countdown** (`challengeSeconds = 300`, a `Stopwatch`, so changing the phone clock does not help). The timer starts when the board is playable, pauses while a popup/ad is open and while the app is in the background.
- Time up shows "Time's up" with Retry (same board, timer reset) and Exit. The challenge is not saved or resumed (the single in-progress slot belongs to campaign levels).
- Win: `completeChallenge` pays **30 gems**, increments the challenge streak, and pays a **40 gem weekly bonus** once when all 7 days Monday..Sunday of that week are done. The reward is credited to the board's day only if it is still that same local day when the player finishes (otherwise "Challenge ended at midnight", no reward). A blocked clock pays nothing. A day can be completed once, then Play shows "Done for today".
- Winning a challenge never touches campaign progress, stars or the saved level.

---

## 8. Economy (all numbers in one place)

| Item | Value | Where |
|---|---|---|
| Hint | 40 gems | `Rewards.hintCost` |
| Extra bottle | 70 gems (once per level, or free after a rewarded ad) | `Rewards.bottleCost` |
| Free undos per attempt | 3, then a rewarded ad gives +3 | `UndoCredits` |
| Win payout | 10 / 15 / 20 gems for 1 / 2 / 3 stars, **first win of a level only** (replays pay 0) | `Rewards.winGems` |
| Gem ad | +10 gems, max 3 per local day | `AppPrefs.gemAdDailyCap`, `watchedGemAd()` |
| Win 2x | extra gems equal to the base win payout, once per win (first wins only; not level 1, not challenge) | game screen `_doubleWin` |
| Daily reward | 20, 30, 40, 50, 60, 80, 150 | `dailyRewardAmounts` |
| Daily reward 2x | extra equal to the claim, once per day | `AppPrefs.doubleDailyReward` |
| Challenge | 30 gems, weekly bonus 40 | `challengeRewardGems`, `weeklyBonusGems` |
| Welcome gift | set in `WelcomeRewardScreen` | `AppPrefs.claimWelcome` |
| Bottle shapes | cone 0, flask 0, tube 700, potion 1500, jar 3000, diamond 6000 | shop |
| Backgrounds | Night free, Sunset 200, Lavender 200, Turquoise 300, Aurora 400, Dunes 400 | shop |

No real-money purchases and no "Remove Ads" exist anywhere. Gems cannot be bought.

---

## 9. Save data

Everything is one JSON document (`SaveData.toJson`) in SharedPreferences under key **`save_v1`**. `AppPrefs` loads it once, keeps it in memory, and rewrites the whole document after every change (`_update`). Reading is tolerant: a missing or wrongly-typed field falls back to its default, never throws. If `save_v1` is missing, the old separate preference keys of earlier builds are migrated once (`SaveData.fromLegacy`).

Fields: consent/onboarding/welcome/profile flags, `nickname`, `avatar`, `tutorialDone`, `firstRunDay` (first day the game was opened, set once, used by the challenge calendar), `reviewAskedDay` (last in-app review request), `gems`, `owned` (set like `skin:tube`, `bg:2`), `skin`, `bgMode` (-1 = auto), `level` (furthest open level), `stars` (map level to best stars 1..3), `levelsCompleted`, `totalMoves`, `sound`, `music`, `vibration`, `colorblind`, `adsDay`/`adsCount` (gem-ad counter), `daily` (`DailyState`: lastClaimDay, streakDay, streakCount, bestStreak, lastSeenMs, challengeDone, challengeStreak, weeklyBonusWeek, rewardDoubledDay), `inProgress`.

**Resume**: after every pour/undo/extra bottle the game stores `InProgress` (level, capacity, bottle layers, moves, history, undo credits, extra-bottle flag). On the next launch `restoreProgress` accepts it only if it matches the freshly generated level (same level, capacity, colours, bottle count), otherwise it is ignored. A restored stuck board shows the Level Failed popup again. The slot is cleared on win and restart.

Adding a field: add it to `SaveData`/`DailyState`, to `toJson` and `fromJson` (with a default), add an `AppPrefs` accessor, and add a test in `test/core/`. Never rename an existing JSON key without a migration.

`AppPrefs.recordWin` stores best stars, counts a level as completed the first time, adds the moves to `totalMoves` and opens the next level (never past 300).

---

## 10. Ads and consent

Files in `lib/ads/`. Test ad ids only (Google's official sample ids) until the owner supplies real ones.

- **Ids live only in `ad_config.dart`.** The manifest also holds the AdMob *app* id (`com.google.android.gms.ads.APPLICATION_ID`) because the SDK reads it before Dart starts. To go live: put the real ids in `ad_config.dart`, set `useTestIds = false`, and replace the manifest value, all at the same time.
- **Consent first**: `AdService.initialize()` runs the UMP flow (`requestConsentInfoUpdate`, `loadAndShowConsentFormIfRequired`) and only if `canRequestAds` is true does it configure the age rating (max content rating T, not child-directed) and start the SDK. Called at launch for returning players, from the Consent screen ("Agree and continue", 30 s timeout), and from Settings "Ad privacy options" (which opens the UMP privacy form if required, otherwise an info dialog). `adsReady` (ValueNotifier) turns true when ads are allowed and false again if the choice is withdrawn.
- **Rewarded** (`RewardedFlow.run`): the reward callback runs **only** when the user-earned callback fired. Closing early, not-ready and errors grant nothing. An earned reward is paid even if the player left the screen while the ad was open. Placements: `shop_gems`, `gems_game`, `win_double`, `extra_undo`, `extra_bottle`, `daily_double`. Gem ads are capped at 3 per local day.
- **Banner** (`BannerAdSlot`): Home and Level map only, standard 320x50, collapses if it fails. **Never** on the game screen, splash, consent, onboarding or popups.
- **Native** (`NativeAdCard`): bottom of the Daily Reward screen; shows nothing if it fails to load.
- **Interstitial** (`InterstitialGate`): never in levels 1-3 (`firstLevel = 4`), only after every 3 completed levels, at least 90 s apart, not within 60 s of a rewarded ad, never at launch, never in the daily challenge. It can only appear after a win when the player taps "Next level".
- Web and non-Android platforms skip the whole SDK; widgets render nothing.

---

## 11. Firebase Analytics and Crashlytics

- Firebase project: **`rainbow-pour`** (Spark plan), Android app `com.gamezium.rainbowpour`. Config file `android/app/google-services.json` is **git-ignored**.
- Gradle: `settings.gradle.kts` declares `com.google.gms.google-services` (4.6.0) and `com.google.firebase.crashlytics` (3.0.6); both are applied in `android/app/build.gradle.kts`. Packages: `firebase_core`, `firebase_analytics`, `firebase_crashlytics`.
- **Consent-gated**: the manifest sets `firebase_analytics_collection_enabled` and `firebase_crashlytics_collection_enabled` to `false`. `AnalyticsService.setConsent(true)` (fed by `AdService.adsReady`) turns collection on after UMP allows it. Crash reports are sent from release builds only. Web/desktop/tests are no-ops (`AnalyticsService.init()` is only effective on Android).
- `AnalyticsService` hides Firebase behind `AnalyticsBackend` (fakeable). A Firebase error never reaches the game; events are dropped (not queued) while collection is off.

### Events

| Event | Parameters | Fired when |
|---|---|---|
| `level_start` | `level_name` | a level board is shown (not on resume) |
| `level_end` | `level_name`, `success` (1/0), `level`, `stars`, `moves` | level won |
| `level_stuck` | `level`, `moves` | no useful move left |
| `level_quit` | `level`, `moves` | the player left a level after moving, without finishing (drop-off) |
| `challenge_start` | none | challenge board shown |
| `challenge_end` | `result` (`win`/`time_up`/`quit`), `seconds_left` | challenge result |
| `spend_virtual_currency` | `virtual_currency_name=gems`, `item_name`, `value` | hint, extra bottle, shop item |
| `earn_virtual_currency` | `virtual_currency_name=gems`, `source`, `value` | `level_win`, `win_double`, `daily_reward`, `ad_gems` |
| `shop_buy` | `item`, `cost` | a skin or background bought |
| `ad_rewarded` | `placement`, `result` (`earned`/`closed`/`not_ready`/`error`) | a rewarded ad was offered |
| `ad_interstitial` | `level` | an interstitial was shown |
| `daily_reward_claim` | `gems` | daily reward claimed |

Owner's goals for analytics: see where players stop (funnel of `level_start` vs `level_end`, `level_quit`, `level_stuck`), what they buy (`spend_virtual_currency`, `shop_buy`), and ad income/impact (link AdMob to Firebase in the AdMob console: App settings, Linked services; optionally link Google Ads). The app has no Unity Ads (AdMob only).

To verify on a phone: `adb shell setprop debug.firebase.analytics.app com.gamezium.rainbowpour`, play, open Firebase console > DebugView. Normal reports lag 24-48 h.

Adding an event: add a typed method to `AnalyticsService` (name <= 40 chars, letters/digits/underscore, <= 25 params, String or number values), call it from the code, and extend `test/analytics/analytics_service_test.dart` (it checks Firebase limits).

---

## 12. Audio, haptics, colorblind mode

- **Audio** (`core/audio_service.dart`, package `audioplayers`): `Sfx` = tap, select, pour, bottleFull, win, fail; plus a looping music track. Switches Sound and Music (Settings) apply instantly. Music starts when Home first shows, pauses when the app goes to the background, resumes on return. A small pool of 4 low-latency players lets effects overlap; audio focus is "mix with others". Nothing plays until `AudioService.load()` has run, and no player error escapes. Hooks: every `WaterButton` press (tap), bottle select, pour start, bottle complete, win, stuck/time up (fail).
- **The 7 files in `assets/audio/` are valid but silent placeholders** (generated). Replace them with real sounds keeping the names and `.wav` extension (or change `AudioAssets`). Advice: sound effects under about 100 KB, music under about 1 MB. See `assets/audio/README.md`.
- **Haptics** (`core/haptics.dart`): selection click, light/medium/heavy impacts at the same places, following the Vibration switch.
- **Colorblind mode** (`widgets/liquid_symbols.dart`, `widgets/cone_bottle.dart`, `core/colorblind.dart`): when on, a white symbol with a dark outline is drawn on every liquid layer; one distinct silhouette per colour id (heart, triangle, star, disc, drop, square, diamond, plus, ring, cross, hexagon, stripes, moon, bolt, pentagon, wave, arrow, flower, dots, hourglass). Close colours get very different shapes. Symbols are skipped when they would be under about 5.5 px. The bottle that is tilted for a pour draws no symbols while it moves. With the mode off the bottle renders pixel-identically to before (tested). Palette distances (CIE76) are all above 12; the closest pair is cyan/sky at about 19.

---

## 13. UI system

- Theme: night-sky gradient, moon on the left, gold accents (`AppColors`), fonts via `google_fonts` (**Outfit, downloaded at runtime today; see section 17**).
- `WaterButton` is the primary button. `PageShell` is the standard screen frame with a back button and gem pill. `InfoDialog` is the one popup for simple messages (`adNotReady`, `dailyLimit`, `clockChanged`, `extraUndo`, and `show(...)` for custom ones). `GameDialog`-based popups: level complete, level failed, not enough gems, exit, rate us.
- **Bottle shapes** (shop skins, `BottleShape`): cone, flask, tube, potion, jar, diamond. `BottleSkin.shape` is a notifier; the painter reads the shape path. **Backgrounds** (`BackgroundTheme`, 6): Night, Sunset, Lavender, Turquoise, Aurora, Dunes; mode `-1` = Auto (changes every 20 levels).
- Screens scale by width and height (`size.width / 240`, `size.height / 520`, clamped) so short windows do not squash the layout. Orientation is locked to portrait.
- The pour animation: the bottle lifts, **travels over its target**, tilts with its lip held above the target's mouth, a stream falls in, then it returns home (never toward a screen edge). A completed bottle bounces, shines, sparkles and vibrates.
- **Tutorial** (level 1, shown once, flag `tutorialDone`): a guiding hand and a one-line text; wrong taps are ignored.

---

## 14. Android configuration

- `android/settings.gradle.kts`: AGP 9.0.1, Kotlin 2.3.20, google-services 4.6.0, Crashlytics 3.0.6. `android/app/build.gradle.kts`: Java 17, `minSdk/targetSdk/compileSdk` from Flutter's defaults, applies both Firebase plugins. **The release build type still signs with the debug key** (TODO for Task 15).
- Manifest: `INTERNET`, AdMob app id meta-data (test id), Firebase collection flags (both false), `MainActivity` (singleTop), and a `<queries>` entry for https VIEW intents (needed by `url_launcher` on Android 11+). Label "Rainbow Pour".
- Merged manifest of a debug build (checked 2026-11-17) contains these permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `com.google.android.gms.permission.AD_ID`, `ACCESS_ADSERVICES_AD_ID/ATTRIBUTION/TOPICS`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `BIND_GET_INSTALL_REFERRER_SERVICE`, and a `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. `docs/RELEASE_AND_POLICY.md` says only three are expected, so before release check the release merged manifest and either justify the extras in the Play forms or remove them with `tools:node="remove"`.
- The build prints a warning that `firebase_analytics`, `firebase_core` and `firebase_crashlytics` still apply the Kotlin Gradle plugin; future Flutter versions may refuse that. Fix by upgrading the Firebase packages when versions with built-in Kotlin are published.
- `device_preview` was REMOVED on 2026-11-17 (no wrapper in `main.dart`, not in `pubspec.yaml`); the app runs as a plain `MaterialApp`.

---

## 15. Testing

About 160 tests, all passing. Run `flutter test`.

| Folder | Covers |
|---|---|
| `test/game/` | engine, difficulty (all 300 specs), generator (all 300 levels generate, solve and replay, timing), solver, hint planner (plays 23 levels with wrong turns and hints), repository (isolate), rewards, resume, challenge boards (42 dates) |
| `test/core/` | save data and migration, `AppPrefs`, daily reward and challenge rules (month/year/leap/DST), challenge timer, audio service |
| `test/ads/` | ad config, `AdService` with a fake gateway, rewarded flow (reward only on earned), interstitial gate |
| `test/analytics/` | event names/params, consent gating, Firebase limits |
| `test/screens/` | level map, profile, stats, daily reward, daily challenge, challenge timer in the game, board layout for 1-31 bottles |
| `test/widgets/` | colorblind symbols, pixel-identical when off, palette distance report |

Notes: use `pump(Duration)` not `pumpAndSettle` on screens with repeating animations. Keep temporary test files out of the repo. Tests never touch Firebase, AdMob or audio engines (services stay inert until initialised).

### Browser testing (the built-in browser pane or any browser)
1. `flutter build web --release`, then serve `build/web` (for example `python -m http.server 8765` from inside that folder) and open `http://localhost:8765`.
2. Emulate a phone at 360x740 and re-apply the size if screenshots look 800x600.
3. The app takes about 40 s to reach Home in the pane (2.8 s of splash plus Flutter web start-up).
4. To skip first launch, set `localStorage` key `flutter.save_v1` to `JSON.stringify(JSON.stringify({version:1,consentDone:true,onboardingDone:true,welcomeClaimed:true,profileDone:true,nickname:'Test',avatar:0,tutorialDone:true,gems:500,level:5}))` and reload. (Debug builds always start at Consent; the web release build honours the save.)
5. Web has no ads, audio engine behaviour differs (autoplay policy), Firebase is off. Haptics and real frame rate only show on a phone.

### Real phone
`flutter build apk --debug`, then `adb install -r build/app/outputs/flutter-apk/app-debug.apk`. Phone: Developer options, USB debugging, data cable. Task 13 plans a QA checklist (`docs/QA_CHECKLIST.md`).

---

## 16. Release process (Task 15, not done yet)

Full policy notes: `docs/RELEASE_AND_POLICY.md` (permissions, Data safety answers, content rating, ads declaration). Privacy policy draft: `docs/PRIVACY_POLICY_DRAFT.md` (must be updated for Firebase).

Steps: create the upload keystore (keep it outside git, two safe copies), `android/key.properties` (git-ignored) and a release signing config; set `versionCode/versionName` (`version:` in `pubspec.yaml`, the number after `+` must grow with every upload); put real AdMob ids in `ad_config.dart` and the manifest and set `useTestIds = false`; replace the audio placeholders; remove the Settings demo section; bundle the Outfit font; `flutter build appbundle --release`; test the matching `flutter build apk --release` on phones; upload to Play Console (listing, screenshots, Data safety, content rating, ads declaration, privacy URL). The company developer account is handled by the owner's company ("sir").

**Only the owner/company can supply:** real AdMob ids and linking AdMob to Firebase, Privacy Policy and Terms URLs, real audio files, Play Console account, the app icon and store graphics.

---

## 17. Known issues, risks and recommendations (audit of 2026-11-17)

Confirmed by code review and tests; items marked (browser) come from the browser walkthrough (see section 18).

### Must fix before release
0. **Release build crashed at launch (found on a real phone, 2026-11-17).** `flutter build apk --release` ran R8, which removed the default constructor of `androidx.work.impl.WorkDatabase_Impl`, so the app died on start with "Failed to create an instance of androidx.work.impl.WorkDatabase" (WorkManager comes from Google Mobile Ads/Firebase). The debug build never showed it. Fix: `android/app/proguard-rules.pro` keeps the constructor of every Room database and is referenced from the release build type in `android/app/build.gradle.kts`. ALWAYS install and open a RELEASE build on a phone before any upload.0b. **The launcher icon is still the default Flutter icon.** Make a real app icon (and adaptive icon) before release.0c. **Ad playback on a low-RAM phone:** on a debug build, the rewarded test ad hung and Android killed the app (ANR in AdActivity); the game keeps animating behind the ad. A release build is the real measure; if it still stutters, stop the tickers while an ad is showing (TickerMode).
1. ~~Settings had a "UI PREVIEW (DEMO ONLY)" section~~ **Removed 2026-11-17.**
2. **Fonts download at runtime** (`google_fonts`, no `fonts:` in `pubspec.yaml`). On a first launch with no network the text falls back to the system font and the layout shifts; it also contacts Google servers (mention in the privacy policy or avoid). Bundle Outfit (OFL licence) as an asset and use `GoogleFonts.config.allowRuntimeFetching = false`.
3. **Release signing uses the debug key** (`build.gradle.kts`). Add a real signing config (Task 15).
4. **Real ad ids** are empty; test ads ship until replaced.
5. **Privacy policy and Play Data safety** must now include Firebase Analytics/Crashlytics (device ids, app interactions, crash logs). The Privacy/Terms links in Consent and Settings now open `AppLinks.privacyPolicyUrl` and `AppLinks.termsUrl` in `lib/core/app_links.dart`, which are EMPTY until the owner gives the real URLs (until then the app says "This page is coming soon").
6. **Merged manifest permissions** exceed the documented three (section 14); review the release manifest.
7. ~~No in-app review~~ **Done (Task 12).** The in-app review is requested after a win of level 5 or later, at most once per 30 days (`reviewAskedDay` in the save), never in the challenge, never right after an interstitial, never when the clock looks wrong. The Settings Rate dialog sends 4 to 5 stars to the review sheet (or the store page) and 1 to 3 stars only get a thank-you. The review sheet itself only appears for apps installed from Google Play, so it cannot be fully tested locally.
8. **Audio files are silent placeholders.**

### Logic and economy risks
9. ~~Gem farming by replaying levels~~ **Fixed 2026-11-17.** Only the FIRST win of a level pays gems (`Rewards.winGems(stars:, firstClear:)`; the first-win check is "the level has no entry in `SaveData.stars` yet"). A replay pays nothing, the popup says "Gems are paid on the first win only" and does not offer the 2x ad. Stars and progress still update on a replay.
10. ~~Back button inside a level or the challenge left immediately~~ **Fixed 2026-11-17.** `game_screen.dart` now wraps the screen in a `PopScope`: Android Back during play opens the pause menu (the challenge clock is held while any popup is open); it still leaves freely while a level loads or after a result.
11. ~~The gem pill in the game, the "Get gems" button and the gem pill on inner screens showed "coming soon"~~ **Fixed 2026-11-17.** They open the Shop (`_openShop` in the game, `PageShell._openShop` elsewhere) and refresh the gem count on return; the challenge clock waits while the Shop is open.
12. ~~The Daily Challenge (and Daily Reward) screens kept the old date after midnight~~ **Fixed 2026-11-17.** Both re-read the date when the app returns to the foreground.
13. **The gem-ad daily counter uses the raw local date without the clock check**, so moving the phone clock forward resets the 3-per-day cap. Low value (10 gems), but could reuse `recordClock`.
14. **The hint beam search runs on the UI thread** (about 0.2 s on a PC, maybe about 1 s on a phone). Move it to an isolate (Task 13).
15. **`par` is only an upper bound for large boards**, so 3 stars are easy after level 100; levels 100-300 feel alike (20 colours, 25 bottles). Improve the generator (more scramble, mixed capacities, fewer duplicate colours) or add other difficulty levers.
16. **Colorblind symbols are not drawn on the bottle that is tilted during a pour** (about one second).
17. **The Firebase Gradle plugins print a Kotlin Gradle plugin deprecation warning** (section 14).
18. ~~Splash screens took 6.4 s~~ **Fixed 2026-11-17:** `studio_splash` 1.2 s + `game_splash` 1.6 s (about 2.8 s).
19. **`game_screen.dart` is about 1900 lines** and mixes board, animation, tutorial, challenge, ads and analytics. Splitting it (for example: pour animation controller, challenge controller, popups) would make future changes safer.
20. Several doc comments still say "UI only" although the screens are real (cosmetic).
21. The Level Failed popup, the extra-bottle flow, the "Undo N moves" hint and the 3-free-undos-then-ad popup were exercised by unit/widget tests and code review but never clicked through on a real phone.

### Things that are fine (checked)
- The 300 levels and all challenge dates generate and replay to a win; the generator and hint tests are strong.
- Rewards are granted only on the earned callback; double taps cannot double-grant; gems and streaks are written atomically.
- Clock tampering is handled for the daily reward and challenge.
- Ads never appear on the game screen; consent gates ads, analytics and crash reports; web builds skip native SDKs.

---

## 18. Browser walkthrough results

Release web build opened at 360x740 and clicked through on 2026-11-17 (save pre-filled with level 12, 11 levels won, 500 gems). Everything below rendered correctly with no layout overflow or errors.

**Checked and working:** first launch (Consent, Onboarding page 1), Home, Level map (stars, locks, current level pulse), Game level 12 (13 bottles in 3 rows, hint costs 40 gems and highlights source and target, pause menu Resume/Restart/Home, colorblind symbols on every layer), Shop (Gems tab with "Ad not ready" dialog on web, Bottles tab), Settings, Daily Reward (claim +20, streak "1-day", "Come back tomorrow", 2x pill appears), Daily Challenge screen (real reward, streak, weekly bar, calendar) and its board (26 bottles in 5 rows, timer chip, pause stops the clock), Profile and Stats (11 levels, 23 stars, 240 moves, 4 three-star levels, latest 5 levels; all numbers matched the pre-filled save).

**UI findings from the walkthrough:**
1. **Fixed 2026-11-17.** The Daily Challenge calendar used to draw an X (missed) on every earlier day of the month, even before the player installed the game. Now `SaveData.firstRunDay` (set once at the first launch by `AppPrefs.firstRunDay`) decides: only days from the first-open day on can be missed.
2. **Fixed in Task 12.** The Consent screen now also says that anonymous usage and crash data is collected with the player's consent, and the Terms/Privacy buttons call `AppLinks.open` (a "coming soon" dialog until the real URLs are set).
3. Settings still shows "UI PREVIEW (DEMO ONLY)" at the bottom.
4. **Fixed 2026-11-17.** The Shop "Other ways" rows (Daily reward, Complete levels, Daily challenge) now have a chevron and open their screens; the gem count refreshes when the player returns.
5. **Improved 2026-11-17.** On small bottles (under 34 px wide, the challenge board) symbols are drawn smaller (60% of a layer instead of 70%) with a thinner outline, so the board looks less crowded; every layer still gets its symbol.
6. The web build needs about 60 to 70 s before Home appears (Flutter web start-up). The splash is now about 2.8 s; measure the real cold start on a phone.
7. The onboarding copy and the tutorial text read well; no typos found.

**Not exercised in the browser** (web has no ads/audio/Firebase and these need long play): finishing a level (win popup, 2x), the stuck popup and extra-bottle flow, challenge time-up, a real rewarded ad, sounds, Firebase events, interstitial timing. Cover them on a phone with the Task 13 checklist.

---

## 19. Working with the owner

- The owner talks Roman Urdu. **Reply in Roman Urdu**, keep technical words in English, short and clear.
- One screen/feature at a time. Show a screenshot after UI changes. Do not disturb other screens. Plan first when a design is unclear: ask a few clear questions with options and a recommendation, then implement. At the end say what was checked and what was not.
- **Git: the owner pushes. Never run `git push`, `git checkout --`, `git reset` or other destructive git.** Give the commands instead. Commit messages end with the attribution line the session asks for. Never commit secrets (`.gitignore` already ignores keystores, `key.properties`, `google-services.json`, APKs, `build/`).
- The APK is shown to "sir" (company owner). WhatsApp blocks `.apk` (use Drive, Telegram, email or USB). **Ship one universal APK, not split per ABI.**
- Crisp, professional look, no blur, water-style buttons, moon on the left.

---

## 20. Documents in `docs/`

| File | Status |
|---|---|
| `PROJECT_GUIDE.md` | **This file. Current.** |
| `HANDOFF.md` | Older hand-over notes; partly outdated (it predates tasks 1-11). Prefer this guide. |
| `TODO.md` | The 15-task plan; tasks 1-11 and Firebase are done, 12-15 open (the checkboxes were not ticked). |
| `RELEASE_AND_POLICY.md` | Current policy and release checklist (kept up to date with ads/Firebase). |
| `PRIVACY_POLICY_DRAFT.md` | Needs a Firebase update before publishing. |
| `CURSOR_TASK_01_LEVEL_MAP.md` | Prompt for an old task; historical. |
| `BACKEND_THEORY.md`, `CURSOR_PROMPTS.md`, `CURSOR_MASTER_PROMPT.md`, `PLAN.md`, `UI_DONE_NOTES.md`, `design_preview.html` | **Obsolete** planning docs (they mention 500 levels, 12 colours, a spin wheel, etc.). Keep only for history or delete in Task 14. |

---

## 21. Roadmap and feature ideas

### Remaining planned tasks
- **Task 12 (done)**: in-app review (`in_app_review`; after a win of level 5 or later, at most once per 30 days, never after a failed level, never in the challenge, never when the clock looks wrong; the Settings Rate dialog sends 4-5 stars to the store and 1-3 to a thank-you), `url_launcher` for Privacy/Terms with one `AppLinks` config file (empty URL shows "link coming soon"), manifest `<queries>` for https.
- **Task 13**: debug-only QA menu (set gems, jump to level, show popups, clock tricks, reset records), hint planner in an isolate with stale-result protection, `docs/QA_CHECKLIST.md`, profile-mode frame timing notes.
- **Task 14**: cleanup (demo section, leftover stubs, debug prints, unused code), version text from `package_info_plus`, bundle fonts, rewrite obsolete docs, update the privacy policy.
- **Task 15**: release.

### Feature ideas (not started, none are required)
- Gem economy: first-clear bonus, replay payout rules, a gem sink for long-term players.
- Daily or weekly **missions** (win 3 levels, use no hints) with gem rewards; level-pack milestones (every 25 levels a chest).
- **Cloud save and login** (Firebase Auth + Firestore) so progress survives a new phone. Needs a privacy policy update and a conflict rule (highest level wins, merge `owned`).
- **Remote Config** for prices, ad frequency and reward sizes without an app update; A/B tests for the interstitial gap.
- **Push notifications** (FCM) for the daily reward and challenge streaks.
- **Leaderboard** for challenge speed (needs a backend).
- More levers for difficulty after level 100: mixed capacities, locked bottles, one-way bottles, limited moves.
- Themes by season, more bottle shapes and backgrounds (cheap content that drives gem spending).
- **Localisation** (the Language option was removed; the app is English only). If added, move strings out of widgets first.
- Accessibility: larger tap targets option, reduced motion switch (the pour and celebration effects are heavy), screen-reader labels for bottles.
- Tablet/landscape layout (currently portrait only).
- iOS build (the ad, consent and Firebase code is plugin-based, but no iOS project config, icons or ids exist).
- Undo/hint tuning from analytics: use `level_quit` and `level_stuck` to find levels that are too hard, then retune `DifficultyCurve` for those ranges.

---

## 22. Cheat sheet for common changes

| I want to... | Change this | Then |
|---|---|---|
| Change a price or reward | `lib/game/rewards.dart`, `core/daily_reward.dart`, `core/daily_challenge.dart`, shop prices in `shop_screen.dart` | update tests, this guide's section 8 |
| Change difficulty of a level range | `lib/game/difficulty.dart` | **changes every player's levels**; run `test/game/*`; check timings |
| Add a setting switch | `SaveData` field + `AppPrefs.flag/setFlag` case + `settings_screen.dart` + the service that reads it | test |
| Add a screen | a folder under `lib/screens/`, link from Home/Settings | use `PageShell`, `WaterButton`, `Entrance` |
| Add an analytics event | `AnalyticsService` method + call + test | update section 11 |
| Go live with ads | real ids in `ad_config.dart`, `useTestIds = false`, manifest app id | test on a phone |
| Add a bottle shape / background | `bottle_shape.dart` / `background_theme.dart` + shop entry + price | update section 8 |
| Replace sounds | files in `assets/audio/` with the same names | listen on a phone |
