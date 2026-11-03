# Rainbow Pour: Water Sort — hand-over notes

Read this first when you continue in a new chat. It says what is built, what state the code is in, what is left, and how the owner likes to work.

- Game: **Rainbow Pour: Water Sort**, Android only, Flutter, package `com.gamezium.rainbowpour`, studio **Gamezium Studio**.
- Owner talks Roman Urdu (Urdu in Latin letters). **Reply in Roman Urdu**, keep technical words in English. Short, clear answers.
- Repo: `https://github.com/MominaYaqoob/RainbowPour.git` (branch `main`). **The owner pushes; never run `git push`, `git checkout --` or other destructive git. Give the commands instead.**
- Windows machine, project at `D:\rainbow_pour`, Android SDK at `D:\AndroidSetup\AndroidSDK`.

---

## 1. Current state (what works)

### UI (all 21 screens done)
Splash x2, consent, onboarding (5 slides), welcome reward, nickname, profile, stats, home, level map, game, daily reward, daily challenge, settings (+rate dialog), shop (gems / bottles / backgrounds), plus popups (level complete, level failed, not enough gems, exit, generic `InfoDialog`).
Look: moonlit night theme, crescent moon on the left, water-style buttons, bottle *shapes* (not colours) are shop skins, 6 backgrounds (`BackgroundTheme`), **Auto** background changes every 20 levels.

### Game logic (done, in `lib/game/`, pure Dart)
- `models.dart` Bottle / Board / Move (immutable).
- `engine.dart` pour rules (top run pours, partial pour if the target has less space), `isWon` (every bottle empty or **full** of one colour), `isStuck` (no *useful* move; sliding a one-colour bottle into an empty bottle is not useful), undo stack in `GameState` (an undo counts as a move).
- `difficulty.dart` `DifficultyCurve` → `LevelSpec` for levels 1..300 (see section 3).
- `generator.dart` seeded reverse-shuffle generator, seed `level*7919+13`. Level 1 is a fixed tutorial board. Colour ids are shuffled over the 20-colour palette per level.
- `solver.dart` best-first search + `Solver.hint` (searched move for small boards, greedy fallback). **See "known problems".**
- `rewards.dart` hint 40 gems, +bottle 70 gems (once per level), 3 free undos then a rewarded ad (+3), win gems 10/15/20 for 1/2/3 stars. `paidHint(board)`.
- `level_repository.dart` builds levels in an isolate (falls back to the caller on web), caches, prefetches the next 2.

### Game screen (done, `lib/screens/game/game_screen.dart`)
Real tap → select → pour with animation: the bottle lifts, **travels over its target**, tilts with the lip held above the target's mouth, a stream falls in, then it goes home (never toward a screen edge). Bottle-full effect (bounce, shine, sparkles, haptic). Hint glow, undo, +bottle, level complete / failed popups, restart, next level. **Level 1 is a guided tutorial** (hand + one-line text, wrong taps ignored, shown once; pref `opt_tutorial`). Board layout: rows = 1 (≤4 bottles), 2 (≤12), 3 (≤18), 4 (≤25); slim bottles; small Undo/Hint/+Bottle buttons.

### Small backend features done
Settings switches saved (`opt_sound`, `opt_music`, `opt_vibration`, `opt_colorblind`), `Haptics` helper follows the vibration switch, gems add/spend (`AppPrefs.addGems/spendGems`), daily rewarded-ad counter saved (`ads_day`, `ads_count`), shop buy/equip with saved ownership (`owned`), level + furthest-level save (`level`), `bg_mode`, `bottle_skin`.

### Prices (already in the UI)
Bottle skins: cone 0, flask 0, tube 700, potion 1500, jar 3000, diamond 6000. Backgrounds: Night free, Sunset 200, Lavender 200, Turquoise 300, Aurora 400, Dunes 400. Rewarded ad = +10 gems, max 3 per day. No real-money purchases and no "Remove Ads" anywhere.

---

## 2. Known problems (fix these first)

### 2.0 Solver file is in a half-edited state — FIX FIRST
`lib/game/solver.dart`:
- The constants at the top were switched back to **4 bits** (`_bits = 4`, `_mask = 15`, `_lenShift = 24`) because the 5-bit version (copy saved by the previous session; not in the repo) broke the search (capacity-4 boards returned null).
- But `Solver.solve` still has the **5-bit era guard** `if (ids.length > 30 || board.capacity > _maxLayers) return null;` with `_maxLayers = 5`, and the doc comment still says five bits.
- With 4-bit packing the guard MUST be `ids.length > 14 || board.capacity > 6` (colour id + 1 must fit in 4 bits; capacity 6 = 24 bits). With colours > 14 it must return null and the greedy hint is used. Set `_maxLayers = 6` and fix the comments.
- `solve` renumbers the board's colours to 0, 1, 2 ... before packing (that part is good and needed, colour ids go up to 19).
- After the fix run `flutter analyze` and `flutter test` (all 37 should pass).

### 2.1 Hint is unreliable on big boards
The solver cannot solve boards with more than 14 colours (and most big boards run out of nodes). Then `Solver.hint` uses `_greedy` (picks the pour that minimises a "potential": 3 per extra bottle a colour is spread over + 1 per unit sitting above a different colour). Simulation (follow the hint until the board is won):
- With ≤ 14 colours it won 28/28 sample levels at about par moves.
- With 20 colours it won only ~9/23: it loops (300 moves) or walks into a dead end (no useful move).
Needed: a better hint for big boards. Ideas: beam search / weighted search over unpacked boards using the potential as heuristic; or a 2-ply lookahead; avoid returning a move that undoes the previous one; detect dead ends. The solver's own heuristic (`changes + mixed`) is the original one; a "potential"-style heuristic with weight 3 made small boards worse, so do not just swap it in. Always re-run the simulation (follow hints on levels 13, 26, … 299) and require ~100% wins.
`paidHint` returns null only when `GameEngine.isStuck`; then the game says "Undo a few moves".

### 2.2 Difficulty plateau and par
After level ~100 par stays around 44–62; levels 100–300 feel alike (bottles and colours are at the maximum). The generator stops when no more reverse peels are possible. `par` for big boards is the length of the reverse-shuffle line (not the true minimum), so 3 stars are easy there. Improve later (more scramble, mixed capacities, fewer duplicate colours).

### 2.3 Other
- **Level map shows only 30 nodes** (sample data, `_count = 30` in `level_map_screen.dart`). Needs 300 levels from real progress, scrolling, stars per level.
- `docs/BACKEND_THEORY.md`, `docs/CURSOR_PROMPTS.md`, `docs/CURSOR_MASTER_PROMPT.md` are **outdated** (they say 500 levels, 12 colours, 2 empty bottles always, etc.). Treat this file as the truth and update those docs.
- Settings still has the "UI PREVIEW (DEMO ONLY)" section (opens test popups). Delete before release.
- Level Failed popup, extra-bottle flow, "Undo a few moves" hint and the 3-free-undos-then-ad popup were never clicked through in a running app.
- Colour readability: with 20 colours some pairs may look close (cream/lime/mint, maroon/brown/red, sky/cyan). Check on a phone; colorblind mode (symbols) is not built yet.
- Win popup says "Watch an ad for 2x gems": it is a stub (ads not wired).

---

## 3. Level design (implemented in `difficulty.dart`)

- 300 levels (`DifficultyCurve.maxLevel`). Max 25 bottles (`maxBottles`), max 20 colours (`maxColors`).
- **Every non-empty bottle starts full.** Levels 1–2 have 1 empty bottle, levels 3+ have exactly **2 empty** bottles.
- A colour fills one bottle, or **two bottles** (`duplicates`) so a level can have more full bottles than colours. Win rule is unchanged: all non-empty bottles full of one colour.
- Bottles: L1 = 3 (tutorial), L2 = 4, L3 = 6, L4 = 7, L5 = 8, then 13 at L10, 19 at L40, **25 at L100**, 25 after.
- Colours: L1 = 2, L2 = 3, then up to 8 at L10, 13 at L30, 17 at L60, **20 at L100**.
- Every 5th level after level 5 is a **breather** (2 fewer colours, 3 fewer bottles).
- Capacity: 4 up to level 60, then 4 or 5 (`n % 3 == 0 ? 4 : 5`).
- `scrambleSteps` and `parFloor` control how hard the generator scrambles and the shortest par it accepts (about 1.6 pours per full bottle).
- Background index = `((level-1) ~/ 20) % 6`.
- All 300 levels generate (avg ~10 ms, max ~70 ms on a PC) and each is replay-verified in tests.

---

## 4. Remaining work, in order

### Step 0 – Solver fix and better hint (section 2.0 and 2.1)

### Step 1 – Save data and progress
- One `SaveData` model as JSON (key `save_v1`), migrate the existing `AppPrefs` values on first launch.
- **Resume the board after every move** (app killed → same board, moves, undo credits, extra-bottle flag, hint state not needed).
- Level map from real data (current level, stars per level). Profile/Stats screens from real counters (levels completed, total moves, best streak).

### Step 2 – Daily Reward and Daily Challenge
- Daily Reward: 7-day streak (20, 30, 40, 50, 60, 80, 150 gems), one claim per local day, streak resets after a missed day, optional 2x via rewarded ad. The UI currently shows a fake "day 3 is today".
- **Clock protection:** remember the last seen time; if the device time goes backwards block claims and show `InfoDialog.clockChanged`.
- **Daily Challenge (new spec from the owner):** a special level with **25 to 30 bottles** (my recommendation: 25 to 28, because 30 bottles need 5 rows and very small bottles), **2 to 3 empty bottles**, and a **timer**. Recommended: countdown of about 5 minutes, pause stops it, time up → Level Failed style popup with retry. Seed = `yyyyMMdd` (same level for everyone each day). Reward 30 gems + streak +1; weekly bonus 40 gems for 7 of 7 days. Needs: a challenge spec in `DifficultyCurve` (bottles up to 30 means > `maxBottles`), generator support for 3 empties, layout for 5 rows (`_layoutFor` in `game_screen.dart`), a timer chip in the top bar. Ask the owner to confirm: max bottles (25–28 vs 30), countdown vs count-up, what happens at time up.

### Step 3 – Ads and consent (AdMob + UMP)
- `google_mobile_ads` with Google **test ad IDs only** until the owner gives real ones; keep IDs in one `AdConfig` file.
- UMP consent first (the Consent screen triggers it; Settings → "Ad privacy options" reopens it). No ad loads before consent.
- Rewarded: +10 gems (max 3/day, counter already saved), 2x win reward, extra undos (+3), free hint / +bottle options. "Ad not ready" / daily-limit use the existing `InfoDialog`s.
- Banner only where the UI reserves space (Home/Levels), **never on the game screen**. Native ad replaces `NativeAdPlaceholder` on Daily Reward and keeps the "Ad" label.
- Interstitial: never at launch, not in the first 3 levels, at most once per 3 completed levels and 90 s apart.
- App is 13+, no personalised ads for under-age users. See `docs/RELEASE_AND_POLICY.md`.

### Step 4 – Audio, polish
- `AudioService`: pour, select, win, fail, tap, background music; honour Sound and Music switches; pause when the app goes to the background. Short compressed assets in `assets/audio/` (the owner has to supply files; use silent placeholders so the app still runs).
- Colorblind mode: draw a distinct symbol on each liquid layer in `ConeBottle`.
- `in_app_review` after level 5 completion, at most once per 30 days, never after a failed level.
- Privacy Policy / Terms rows open URLs from the owner (`url_launcher`).
- Firebase Analytics/Crashlytics: **skipped for now** (owner leaned toward local-only). Optional later.
- Extra polish ideas: pour stream sits slightly beside the target in some cases; Level 100+ variety; empty-bottle rule experiments.

### Step 5 – Release
- Remove Settings "UI PREVIEW (DEMO ONLY)" and any demo triggers.
- Release keystore + `android/key.properties` (never commit), `versionCode/versionName` in `pubspec.yaml`, `flutter build appbundle --release`, no debug logs.
- Play Console: listing, Data safety form, privacy policy URL, content rating, ads declaration. See `docs/RELEASE_AND_POLICY.md`.
- Items only the owner/sir can supply: real AdMob IDs, Privacy Policy and Terms URLs, audio files, Play Console account.

### Time estimate
About 2.5 to 3 working days of coding, plus 2–5 days for Play review.

---

## 5. How to work here

### Owner's style
- One screen/feature at a time, **show a screenshot after each UI change**, do not disturb other screens.
- Plan first when a design is unclear, ask a few clear questions with options and a recommendation, then implement.
- Crisp, professional look, no blur, water-style buttons, moon on the left.
- The APK is shown to "sir" (company owner). WhatsApp blocks `.apk` (use Drive / Telegram / email / USB). **One universal APK, not split per ABI.**
- After finishing, say what was checked and what was not.

### Commands (run from `D:\rainbow_pour`)
```bash
flutter analyze
flutter test
flutter build web --release          # for browser testing
flutter build apk --release          # universal APK → build/app/outputs/flutter-apk/app-release.apk
cp build/app/outputs/flutter-apk/app-release.apk release/RainbowPour.apk
D:/AndroidSetup/AndroidSDK/platform-tools/adb.exe devices
D:/AndroidSetup/AndroidSDK/platform-tools/adb.exe install -r release/RainbowPour.apk
```
Phone: enable Developer options → USB debugging, data cable, allow the prompt. `adb install` earlier worked when file transfer apps failed.

### Browser testing (built-in browser pane)
- Serve `build/web` with `python -m http.server 8765` (it dies if the working directory changes; restart it), open `http://localhost:8765`.
- Emulate a phone with `resize_window` 360x740 and **repeat it** if screenshots look 800x600 (coordinates then break). Screenshot frame is 360x740.
- The app takes ~40 s to reach Home in the pane (splash is slow). Skip onboarding by setting `localStorage` keys in the page: `flutter.consent_done`, `flutter.onboarding_done`, `flutter.welcome_claimed`, `flutter.profile_done` = `true`; `flutter.nickname` = `"Name"`; `flutter.avatar`, `flutter.gems`, `flutter.level` = numbers; `flutter.opt_tutorial` = `true` to skip the tutorial; then reload.
- Home "Play" is at about (180, 572). On the game screen bottle positions depend on the layout; take a screenshot first.
- Screenshots are slower than animations. To see a pour, temporarily set `timeDilation = 6` in the game screen (remove it afterwards).
- Haptics and the real frame rate only show on a phone.

### Tests
`test/game/*` covers engine, difficulty, generator (all 300 levels generate, solve/replay, timing), solver, rewards, repository. Keep temporary test files out of the repo (delete them after use).

### Files worth knowing
`lib/game/*` (logic), `lib/screens/game/game_screen.dart` (board, pour animation, tutorial, popups; ~1100 lines), `lib/widgets/cone_bottle.dart` (bottle painter with `capacity`, tilt, extra layer), `lib/widgets/background_theme.dart`, `lib/widgets/info_dialog.dart` (all simple popups), `lib/core/app_prefs.dart` (all saved values), `lib/core/app_colors.dart` (`liquid` = 20 colours), `docs/` (older planning docs, partly outdated), `release/` (APKs, ignored by git).

### Git
`.gitignore` already ignores APKs/AAB, keystores, `key.properties`, `google-services.json`, `build/`. Never commit secrets. Commit messages should end with the attribution lines the session asks for.
