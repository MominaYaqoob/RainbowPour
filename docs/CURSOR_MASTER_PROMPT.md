# Master prompt for Cursor (paste everything below the line)

---

## Role
You are a senior Flutter/Dart engineer finishing **Rainbow Pour: Water Sort** (Android only, package `com.gamezium.rainbowpour`, studio Gamezium Studio). All UI screens are already built and working. Your job is the **game logic and services behind them**, without changing how the screens look.

## Read first (do not skip)
1. `docs/BACKEND_THEORY.md` – rules, difficulty tables, generator/solver, economy, daily logic, save schema, tests. This is the source of truth.
2. `docs/UI_DONE_NOTES.md` – which parts of the UI are demo-only and must be replaced.
3. `docs/RELEASE_AND_POLICY.md` – Play Store policy rules (ads, consent, data safety).
4. Skim `lib/screens/game/game_screen.dart`, `lib/screens/game/sample_board.dart`, `lib/widgets/cone_bottle.dart`, `lib/core/app_prefs.dart`.

If anything in these docs contradicts this prompt, stop and ask instead of guessing.

## Hard rules
- **Do not redesign or restyle any screen.** Only change UI code where it must call real logic. Keep widget names, layout and animations.
- Game rules live in **pure Dart** (`lib/game/`, no Flutter imports) so they can be unit-tested.
- Keep the existing style: small files, `abstract final class` for static services, comments only where the reason is not obvious.
- Android only. No real-money purchases, no "Remove Ads", no login, no cloud save.
- Never commit secrets: keystore, `key.properties`, `google-services.json` (already in `.gitignore`).
- Work in the order below. After each step: run `flutter analyze` (must be clean) and `flutter test`, then summarise what changed and what is still missing. **Stop and wait for my review after each step.**
- Prefer the simplest correct solution. Do not add packages that are not listed here without asking.

## Current state (already done, do not redo)
- All screens, popups, themes (6 backgrounds, Auto per 20 levels), bottle shapes.
- `AppPrefs`: gems (`addGems`/`spendGems`), level (`setLevel`), flags (`flag`/`setFlag`), owned shop items (`owned`/`addOwned`), daily ad counter (`adsToday`/`addAdToday`), `bg_mode`, bottle skin.
- Game screen has demo triggers (level pill = complete popup, Undo = failed popup), fake board from `SampleBoard.forLevel`, fake hint.
- `Haptics` helper (follows the Vibration switch). Settings switches are saved but have no effect on audio yet.

## Step 1 – Game engine (`lib/game/`)
Models: `Bottle` (layers bottom→top as colour ids, capacity), `Board`, `Move(from,to,count)`, `GameState` (board, moves, undo stack).
Rules (see BACKEND_THEORY):
- A pour is legal if source is not empty, target is not full, and target is empty or its top colour equals the source top colour.
- Pour moves **all consecutive top layers of the same colour** that fit in the target's free space.
- Level is won when every non-empty bottle is full and single-coloured.
- No-moves-left detection (for the Level Failed popup).
- Undo stack with history of moves; `undo()` restores exactly.
Tests: legal/illegal pours, partial pour when target lacks space, win detection, dead-end detection, undo restores state.

## Step 2 – Level generator and solver
- `LevelGenerator.forLevel(n)` → deterministic board (seed from level). Colours/capacity/empty bottles follow the difficulty tables in BACKEND_THEORY (replace `sample_board.dart`; 500 levels, max 14 bottles, max 12 colours, capacity 4–6).
- Generate by reverse-shuffling from a solved board so every level is solvable, then verify with `Solver` (BFS/DFS with visited set, depth/time cap).
- `Solver.hint(board)` returns the next best move (from, to).
Tests: every level 1–500 is solvable; generation is deterministic; generation of any level takes well under 200 ms.

## Step 3 – Wire the game screen
Replace the demo with the real engine, keeping the existing visuals:
- Tap a bottle to select (it lifts, existing animation), tap another to pour. Illegal tap → deselect with a small shake/haptic.
- Animate the pour using the existing tilt support in `ConeBottle` (volume-conserving tilt) and a short stream; board updates when the animation ends. Block input while animating.
- Win → Level Complete popup with **real** stars (by moves vs par) and **real** gem reward added with `addGems`; save level progress (`setLevel`) only if it is the furthest level.
- No moves → Level Failed popup (Undo / Extra bottle / Restart / Home).
- **Undo**: pops the stack; limit and "extra undos" via rewarded ad (`InfoDialog.extraUndo`).
- **Hint** (25 gems): `Solver.hint`, glow source/target (existing glow), spend gems only after a hint exists.
- **Extra bottle** (40 gems, once per level): adds one empty bottle; layout already supports up to 14 bottles, show an `InfoDialog` if the board is already at the maximum.
- Restart / Next / Replay already work; make them reset the real engine.
- Remove the demo triggers (level pill and Undo opening dialogs).

## Step 4 – Economy, daily systems, save data
- Single `SaveData` model persisted as JSON under key `save_v1` (migrate existing `AppPrefs` values on first launch; keep `AppPrefs` as a thin facade or replace its callers).
- **Daily Reward**: 7-day streak, one claim per day, streak resets after a missed day, day 7 bonus, optional 2× via rewarded ad. Replace the demo "day 3 is today".
- **Daily Challenge**: deterministic level from the date, one reward per day, completion state saved.
- **Clock-rollback protection**: store the last seen time; if the device time goes backwards, block daily claims and show `InfoDialog.clockChanged`.
- Shop: gem prices already in `shop_screen.dart`; keep ownership in `SaveData`.
- Stats on the Profile/Stats screens come from real counters (levels completed, total moves, best streak).
Tests: streak logic across midnight, missed day, clock rollback, economy never goes negative.

## Step 5 – Ads and consent (AdMob)
- `google_mobile_ads` + UMP consent. Use **Google test ad unit IDs only** until I provide real ones. Keep IDs in one `AdConfig` file.
- Consent: the existing Consent screen must trigger the UMP form where required; Settings → "Ad privacy options" reopens it.
- Rewarded ad: +10 gems, max 3 per day (counter already saved), "Ad not ready" and "limit reached" use the existing `InfoDialog`s.
- Banner on the Home/Levels area only where the UI already reserves space; **no banner on the Game screen**. Native ad replaces `NativeAdPlaceholder` on Daily Reward and must keep the "Ad" label.
- Interstitial: never at app launch, never in the first 3 levels, at most once every 3 completed levels and 90 seconds apart.
- Do not load ads before consent is resolved. Children: app is rated for 13+, no personalised ads for under-age users.

## Step 6 – Audio, settings effects, polish
- `AudioService`: pour, select, win, fail, button tap and background music; honours Sound and Music switches; pauses on app background. Use short compressed assets under `assets/audio/` (ask me for files if missing; use silent placeholders so the app still runs).
- Vibration already follows its switch; add calls on pour, win, fail.
- **Colorblind mode**: draw a distinct symbol on each liquid layer in `ConeBottle` when enabled.
- `in_app_review`: ask after level 5 completion, at most once per 30 days, never on a failed level.
- Privacy Policy / Terms rows open the URLs I will provide (`url_launcher`).
- Firebase Analytics/Crashlytics: **skip for now** (optional later).

## Step 7 – Release readiness
- Remove Settings → "UI PREVIEW (DEMO ONLY)" section and any leftover demo triggers.
- Release signing via `android/key.properties` (not committed), `versionCode`/`versionName` in `pubspec.yaml`, AAB build (`flutter build appbundle --release`), minify/shrink check, no debug logs.
- Final checklist from `docs/RELEASE_AND_POLICY.md`.

## Quality bar for every step
- `flutter analyze` clean, tests green, no overflow on a 360×640 screen and a 412×915 screen.
- No frame drops while pouring on a mid-range phone (avoid rebuilding the whole screen per frame; use the existing `AnimatedBuilder` pattern).
- Everything saved survives an app restart and an app kill.
- If you are unsure about a game rule, a number or a policy detail, **ask me** instead of inventing it.

## How to report after each step
1. Files created/changed (list).
2. What now works, how I can verify it (exact taps or test command).
3. What you did **not** do or are unsure about.
Then stop and wait.
