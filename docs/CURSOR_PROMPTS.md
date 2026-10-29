# Cursor work plan: 3 days, copy-paste prompts

How to use: open `D:\rainbow_pour` in Cursor. Paste **Prompt 0** once at the start of each day (new chat), then the day's prompts one by one.
After every prompt run: `flutter analyze` and `flutter test`, then run the app (`flutter run -d chrome` or a phone) and check the "Done when" line.
Commit after every prompt (`git init` first if the folder is not a repo).

Day split:
- **Day 1: the real game** (engine, generator, solver, playable Game screen, progress/rewards, map, stats)
- **Day 2: features** (daily reward, daily challenge, shop, backgrounds, audio, settings)
- **Day 3: ads, services, polish, release** (AdMob + UMP, Firebase, rating, cleanup, AAB)

---------------------------------------------------------------------

## PROMPT 0: context (paste first, every day)

```
You are working on the Flutter Android game "Rainbow Pour: Water Sort" (package com.gamezium.rainbowpour) in this repo.
The whole UI is already built (lib/screens, lib/widgets). Read these files first and follow them exactly:
- docs/BACKEND_THEORY.md  (all rules, numbers, data model, architecture: the single source of truth)
- docs/PLAN.md            (screens)
- docs/RELEASE_AND_POLICY.md (Google Play rules)
Rules:
1. Do NOT redesign or restyle screens. Keep the existing look, widgets and animations. Only wire real logic into them and replace sample/demo data.
2. Put game rules in pure Dart under lib/game/ (no Flutter imports there). Put side effects in lib/services/. Use flutter_riverpod for state (lib/state/).
3. Android only, English only, no server, no login, no Google Play Billing, no in-app purchases.
4. Keep `flutter analyze` at zero issues. Add unit tests under test/ for every new pure-Dart piece.
5. Do not add permissions other than INTERNET, ACCESS_NETWORK_STATE and AD_ID.
6. When a decision is missing, follow docs/BACKEND_THEORY.md; if still unclear, choose the simplest safe option and note it in docs/DECISIONS_LOG.md.
Work in small steps, tell me what you changed, and stop after each prompt's "Done when".
```

---------------------------------------------------------------------

# DAY 1: the real game

## Prompt 1.1: models and engine
```
Create lib/game/models.dart and lib/game/engine.dart (pure Dart) following BACKEND_THEORY sections 4.1-4.3.
- Bottle = stack of color ids (bottom to top) with capacity K. Board = list of bottles + capacity + move counter.
- Move(from, to, count). GameEngine: legalMoves(board), canPour(from,to), pour(board,from,to) -> new Board + Move (pours the whole run of equal top colors that fits),
  isWon(board) (every bottle empty or full with one color), isStuck(board) (no legal move and not won),
  undo(board, history), addEmptyBottle(board) (once per level).
- Immutable boards (copyWith). Moves counter counts every pour and every undo.
- Unit tests in test/game/engine_test.dart: legal/illegal moves, partial pour into a bottle with less space, win, stuck, undo.
Done when: tests pass and analyze is clean.
```

## Prompt 1.2: difficulty curve and generator
```
Create lib/game/difficulty.dart and lib/game/generator.dart (pure Dart) per BACKEND_THEORY 4.4 and 4.6.
- DifficultyCurve.specFor(level) -> LevelSpec{colors, capacity, bottles, backgroundIndex}. Exact tables from section 4.4 (levels 1..500; level 1 = 3 colors, capacity 4, 5 bottles; breather every 10th level; background = ((n-1)~/20)%6).
- LevelGenerator.generate(spec, seed) -> Board using seeded Random, reverse-moves from the solved state (section 4.6), 2 empty bottles, never already solved. Seed for level n = n*7919+13; daily challenge seed = yyyyMMdd with colors 10, capacity 5.
- Tests: same seed gives identical board; every color appears exactly `capacity` times; exactly 2 empty bottles at start; spec values for levels 1,4,5,10,11,60,200,500.
Done when: tests pass.
```

## Prompt 1.3: solver, hint and par
```
Create lib/game/solver.dart (pure Dart) per BACKEND_THEORY 4.7.
- Solver.solve(board, {maxNodes: 300000}) -> List<Move>? using A*/best-first with canonical state hashing (sort bottles), heuristic = color changes + non-uniform bottles. Deterministic.
- Solver.hint(board) -> Move? : first move of a solution from the current board; fall back to a greedy legal move that avoids ping-pong; return null if none.
- Par = solution length. Stars(par, moves): 3 if moves <= ceil(par*1.15)+1, 2 if <= ceil(par*1.5)+2, else 1 (levels 1-3 always 3).
- Make generator verify solvability with the solver (retry seed+1 if not solved in budget) and cache {level -> board, par} in memory.
- Run solving/generation in an isolate (compute) from a LevelRepository class in lib/game/level_repository.dart: getLevel(n) async, prefetch(n+1,n+2).
- Tests: solver result applied move by move ends in isWon; batch test that levels 1..500 all generate and solve within a time limit (mark the long test with a tag so it can be skipped).
Done when: tests pass, level 500 generates in a reasonable time on desktop.
```

## Prompt 1.4: real Game screen
```
Wire the real game into lib/screens/game/game_screen.dart WITHOUT changing the look.
- GameController (Riverpod, lib/state/game_controller.dart): loads a level through LevelRepository, holds Board, selected bottle, move count, undoUsed, extraBottleUsed, history, hint highlight.
- Tap a bottle = lift (existing lifted style); tap another = pour if legal with the existing tilt/pour animation style (liquid stays level, stream, target fills; reuse ConeBottle tilt + topLayerFraction logic), tap same bottle = put down, illegal move = small shake.
- Bottle layer height must be 72/capacity so capacity 4, 5, 6 draw correctly (update ConeBottle painter). Layout rows per BACKEND_THEORY 4.4 (shrink bottle size for 10-14 bottles).
- Buttons: Undo (3 free per level, then ask for a rewarded ad: for now show the existing "coming soon" until ads exist), Hint (40 gems, highlights source and target 2 s), +Bottle (70 gems, once per level). Not enough gems -> existing NotEnoughGemsDialog.
- On win -> existing Level complete popup with real stars/moves/gems; on stuck -> existing Level failed popup. Remove the demo triggers (Level pill tap, Undo tap).
- Pause popup Restart really restarts the level. Level pill shows the real level.
Done when: levels 1-10 are fully playable and winnable with correct popups.
```

## Prompt 1.5: save, resume, economy, progress
```
Implement lib/services/save_service.dart and economy per BACKEND_THEORY 3.4 and 4.10 (Riverpod providers in lib/state/).
- SaveData JSON (key save_v1) with migration from the old separate keys in AppPrefs, then keep AppPrefs as a thin wrapper or remove it.
- Auto-save the in-progress board after every move; resume exactly (level, bottles, moves, undoUsed, extraBottleUsed, history) after app kill.
- Level complete: add gems 10/15/20 by stars, store best stars/moves, unlock next level, update `level`. Welcome gift 100 once.
- Economy: spendGems(n) atomic, never negative; gems pill everywhere reads the provider (no more AppPrefs.gems() in widgets).
- Level map, Profile, Score & Stats and Home read real data (current level, stars, totals, recent levels); remove sample numbers.
- Tests for save/migrate and economy.
Done when: kill the app mid-level and reopen: same board; gems and stars update after a win; map shows real progress.
```

---------------------------------------------------------------------

# DAY 2: features

## Prompt 2.1: Daily Reward
```
Implement lib/services/daily_service.dart and wire lib/screens/daily/daily_reward_screen.dart per BACKEND_THEORY 4.8 and 4.9 (clock guard).
- 7-day cycle 20,30,40,50,60,80,150 gems. One claim per local day, missed day resets to day 1, show real day states.
- Rewarded-ad x2 button is a stub for now (calls AdService.showRewarded when it exists; before that shows "coming soon").
- Clock guard: store guard.lastSeenMs; if now < lastSeenMs - 5 min, block claims and show a friendly message.
- Home Daily tile badge shows only when a claim is available.
- Unit tests with an injectable clock.
Done when: claim works once/day, resets after a skipped day, works with a fake clock in tests.
```

## Prompt 2.2: Daily Challenge and weekly bonus
```
Wire lib/screens/challenge/daily_challenge_screen.dart per BACKEND_THEORY 4.9.
- Today's puzzle = generator with seed yyyyMMdd, 10 colors, capacity 5. Play opens GameScreen in challenge mode (reuse GameController, mode: challenge). Win: +30 gems, streak +1, add date to doneDates, calendar tick. Fail/leave costs nothing, retry allowed same day.
- Calendar uses real doneDates, today highlighted; past days cannot be played.
- Weekly bonus: when all 7 days of the current ISO week (Mon-Sun) are done show a Claim button for 40 gems once per week; progress bar reads real data.
- Use the clock guard from daily_service. Tests with fake clock (week rollover, streak break).
Done when: completing today's challenge ticks the calendar and pays 30 gems once; weekly bonus claimable after 7/7.
```

## Prompt 2.3: Shop logic (change of scope)
```
Update lib/screens/shop/shop_screen.dart per BACKEND_THEORY 4.11. REMOVE all real-money UI.
- Replace the "Gems" tab: delete the 4 paid packs and the "Remove Ads" banner. Show one card "Watch ad: +10 gems" with a counter "x/3 today" (cap 3 per day, resets at local midnight, uses the clock guard). Reward is a stub until AdService exists. No price in money anywhere.
- Bottles tab: Cone Beaker and Round Flask free, Test Tube 700, Potion 1500, Wide Jar 3000, Diamond 6000 gems. Buy -> spend gems atomically -> owned; "Use" equips and persists (BottleSkin). Not enough gems -> NotEnoughGemsDialog.
- Backgrounds tab: add an "Auto" chip (default, background follows the level: ((level-1)~/20)%6, unlocking each automatically). Others can be bought early (200/200/300/400/400 gems); equipping one pins it; Auto switches back. Game and Home use the chosen background (extend NightBackground to accept a theme: night lake, sunset sea, lavender peaks, turquoise waves, aurora, golden dunes: sky gradient, decoration, mountains/water colors).
- Also update the onboarding copy that mentioned buying, and docs/PLAN.md.
Done when: no money wording left in the app; buying/equipping persists after restart.
```

## Prompt 2.4: Audio, haptics, colorblind, settings
```
Implement lib/services/audio_service.dart (audioplayers) and wire settings per BACKEND_THEORY 4.13.
- Add CC0 sounds in assets/audio/ (tap, lift, pour, bottle_full, win, fail, click, gem) and one calm music loop; list the sources in assets/audio/CREDITS.txt. Declare assets in pubspec.yaml.
- Play sounds on game events and button presses; music loops on Home/Game; respect Settings switches (Sound, Music, Vibration) and persist them in SaveData. Pause music when the app is in background.
- Haptics: light on tap, medium on full bottle, heavy on win (only if Vibration is on).
- Colorblind mode: draw a distinct small symbol on every liquid layer (12 symbols) when enabled; default off; works for all bottle shapes and capacities.
Done when: toggles work and persist; colorblind symbols visible in game.
```

---------------------------------------------------------------------

# DAY 3: ads, services, polish, release

## Prompt 3.1: AdMob + UMP (policy-safe)
```
Implement lib/services/ad_service.dart with google_mobile_ads per BACKEND_THEORY section 6 and docs/RELEASE_AND_POLICY.md.
- Startup: after our Agree screen, run Google UMP (request consent info, show form if required), then MobileAds.initialize ONLY when canRequestAds. Settings > "Ad privacy options" re-opens the UMP form when required. Never request ads before consent.
- Config: lib/core/ad_config.dart. Use Google TEST unit IDs in debug and read real IDs from --dart-define in release. Request config: tagForChildDirectedTreatment false, tagForUnderAgeOfConsent false, maxAdContentRating T.
- Interstitial: only after a completed level (not fail/pause), every 3rd completed level, >= 90 s since the last interstitial, never in levels 1-3, never during the first 5 minutes of the first session. Preload the next one.
- Rewarded: grant only in onUserEarnedReward. Hook into: Shop free gems (+10, 3/day), 2x level reward, 2x daily reward, free Hint, free +Bottle, extra Undo after the 3 free ones, Not-enough-gems popup. Show a loading state; if no ad is ready show "Ad not ready, try again".
- App Open: on app resume only, >= 4 h since the last one, max 2 per day, never in the first session, never right after another ad closed, never before consent.
- Native: only on the Daily Reward screen below the claim area, clearly labelled "Ad", never overlapping buttons. Use a styled NativeAdFactory (android/app) or the Flutter template style.
- AndroidManifest: INTERNET, ACCESS_NETWORK_STATE, AD_ID, AdMob APP_ID meta-data (test ID in debug).
- No ads on splash/consent/onboarding/popups other than the ones above. Persist counters/timestamps in SaveData.ads.
- Unit-test the frequency rules with an injectable clock (pure Dart class AdPolicy).
Done when: test ads show in the right places only; rules tests pass; app works with airplane mode.
```

## Prompt 3.2: Firebase Analytics + Crashlytics, rating, links
```
Add firebase_core, firebase_analytics, firebase_crashlytics, in_app_review, url_launcher, package_info_plus.
- Firebase: expect android/app/google-services.json from the company project (do not commit secrets; document where to put it). Initialise in main(); Crashlytics collection enabled only in release; record Flutter and platform errors. Events from BACKEND_THEORY 6.4 in lib/services/analytics_service.dart (no personal data, never the nickname).
- Rate us: Settings row and an automatic prompt after level 10 and level 30 (once each) using in_app_review (fallback: the existing Rate-us popup then open the store page). Never during gameplay.
- Links: lib/core/links.dart with privacyUrl and termsUrl placeholders (sir will provide). Consent screen chips and Settings rows open them with url_launcher in an external browser; if a link is empty show "Link will be added".
- Settings shows the real version from package_info_plus.
Done when: build works with and without google-services.json guarded by a flag; links open; events appear in Firebase DebugView.
```

## Prompt 3.3: cleanup for release
```
Prepare the code for release.
- Remove device_preview, the web/ folder, demo triggers, kDebugMode shortcuts (onboarding replay in debug, banner placeholders), test strings, unused files (e.g. docs/design_preview.html can stay in docs).
- Bundle the Outfit font as an asset and remove runtime google_fonts fetching (keep the same look); verify offline first launch.
- App icon (adaptive icon) and splash colour: use flutter_launcher_icons with a 1024x1024 icon (ask me for the file; until then a simple bottle on the night-sky colour).
- Review all strings for English typos; make sure no screen mentions purchases, Remove Ads or Spin.
- AndroidManifest label "Rainbow Pour", portrait lock, no extra permissions. Add ProGuard/R8 defaults (Flutter's) and keep rules for Firebase/AdMob if needed.
- Run flutter analyze, flutter test, and a release APK build; list any warnings.
Done when: analyze/test clean; no debug-only UI left.
```

## Prompt 3.4: signing, AAB and QA
```
Set up release signing and produce the bundle.
- Create android/key.properties (git-ignored; add to .gitignore) and wire signingConfigs.release in android/app/build.gradle.kts. Explain how to create the upload keystore with keytool (do not generate or store passwords in the repo).
- Set version 1.0.0+1. Build: flutter build appbundle --release (with --dart-define for real AdMob IDs when provided) and flutter build apk --release --split-per-abi for device testing.
- Write docs/QA_CHECKLIST.md from BACKEND_THEORY section 7 and RELEASE_AND_POLICY (first launch flow, resume after kill, offline, back button on every screen, small and large phones, Android 8-15, ads only in allowed places, consent first, daily clock rollback, shop persistence, no money wording).
- Produce docs/HANDOVER_FOR_SIR.md: the list of files to give (AAB, icon, feature graphic, screenshots, texts), what sir must create (AdMob app + units, Firebase project, privacy policy URL) and the Play Console steps.
Done when: app-release.aab builds and QA_CHECKLIST.md / HANDOVER_FOR_SIR.md exist.
```

---------------------------------------------------------------------

## Day checkpoints (tell me if you are behind)
- End of Day 1: levels 1-20 playable, win/fail popups real, progress saved, tests green.
- End of Day 2: daily reward, challenge, shop and settings real; no purchase wording; audio works.
- End of Day 3: ads (test IDs), consent, analytics, cleanup done; signed AAB built; handover files ready.
If time is short, cut in this order: native ad, app open ad, colorblind symbols, extra backgrounds. Do NOT cut: UMP consent, privacy link, Data safety correctness, rewarded-ad opt-in rules.
