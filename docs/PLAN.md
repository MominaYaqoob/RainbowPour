> UPDATE: game rules, economy, ads and release plan are now in `docs/BACKEND_THEORY.md`,
> `docs/RELEASE_AND_POLICY.md`, `docs/CURSOR_PROMPTS.md` (3-day work plan) and `docs/PRIVACY_POLICY_DRAFT.md`.
> Where this file disagrees (Spin wheel, Remove Ads, IAP gem packs, banner ads), the newer files win.

# Rainbow Pour: Water Sort — Planning Notes

Platform: Android only (Flutter). Single source of truth for features, screens, ads and build order.
Status legend: [ ] todo, [x] done.

## 1. Decisions locked

- App title: **Rainbow Pour: Water Sort** (27 chars, Play limit 30)
- Company / developer name: **Gamezium Studio** (shown on splash 1 and Play developer name)
- Package: `com.gamezium.rainbowpour` (set before first upload; cannot change later). Project currently still uses `com.rainbowpour.rainbow_pour` -> rename in M1.
- Currency: **Gems only** (no gems). Used for hints, +Bottle, skins, themes, spin/daily rewards.
- Bottle shape: **Cone beaker** (plain glass, NO cork on top, 4 liquid layers). Drawn with CustomPainter, no image assets.
- Visual style: glossy 3D glass, gradient backgrounds, glossy buttons.
- Backgrounds: 8 themes, change every 20 levels (Ocean glow, Galaxy night, Sunset peach, Magic forest, Frozen ice, Candy land, Desert dunes, Neon city).
- Liquid colors (8): #FF3B5C, #FF9F1C, #FFD60A, #5EE07A, #22D3EE, #3B82F6, #A855F7, #FF6FB5

## 2. Screen flow

```
Splash 1 (Gamezium Studio) -> Splash 2 (game loading) -> Consent (terms + privacy + ads)
  -> [first launch only] Onboarding 1..4 -> Welcome reward (100 gems) -> Nickname
  -> Home
Home -> Play -> Game -> Level complete -> (Next | Home)
                     -> Level failed (no moves) -> (Undo | +Bottle | Restart | Home)
                     -> Pause -> (Resume | Restart | Settings | Home)
Home -> Daily reward | Shop | Settings | Level map
```

### Full screen list (checklist)
1. Splash 1 — Gamezium Studio
2. Splash 2 — game loading
3. Consent (UMP + agree)
4. Onboarding 1-8 (5 gameplay + 3 feature pages)
5. Welcome reward (100 gems)
6. Nickname
7. Home
8. Game (play screen)
9. Pause popup
10. Level complete
11. Level failed / stuck popup
12. Level map (optional, v1.1)
13. Daily reward (7 days)
14. Shop (skins, themes, gem packs later)
17. Settings
18. Not-enough-gems popup (offers rewarded ad)
19. Rate-us popup (after level 10 once)
20. Exit-app confirm (optional)
21. Avatar picker (DP)
22. Profile
23. Score / stats
First-launch flags stored in local storage: `consent_done`, `onboarding_done`, `reward_claimed`, `nickname`, `avatarId`. Returning users go Splash -> Home directly.

### 2.1 Splash 1 — studio name
- Text only, no logo image: tiny crescent moon, **GAMEZIUM** in wide-tracked bold type with white-to-lavender-to-sky gradient and a shine sweep, gold lines either side of **STUDIO**, one twinkling sparkle. Dark navy bg, fade in/out, ~2.5 s. No ads.

### 2.2 Splash 2 — game splash / loading
- Game logo, animated bottle filling, progress bar. 2-3 s.
- Init here: local storage, audio preload, Mobile Ads SDK (after consent), Remote Config (optional).

### 2.3 Consent (the "agree" screen)
- Short text, links to Privacy Policy and Terms (in-app webview or browser).
- Button: "Agree and continue". Show once.
- If ads are used: use Google UMP (User Messaging Platform) to request consent where required (EEA/UK). Initialize ads only after consent state is known.
- Age line: "You must be 13 or older." Do NOT enable Designed for Families.

### 2.4 Onboarding (5 pages, Moonlit night theme, skippable, shown once)
Layout per page (modeled on Boxora's onboarding): top bar (small bottle + "Rainbow Pour" left, Skip pill right) -> 2-line title (white line + gold gradient line) -> 2-line description -> dark rounded illustration panel with looping animation -> pill dots (active dot stretches, gold glow) -> glossy gold button with arrow ("Let's Play!" on last, gentle pulse).
1. Tap & Lift / A Bottle
2. Pour Matching / Colors
3. Fill Every / Bottle! (stars)
4. Stuck? Use / Helpers (Undo, Hint 25 gems, +Bottle 40 gems)
5. Daily Rewards / & Streaks (flame, 5-day streak, week ticks, "Today: +40 gems")
- Page transition: slide (parallax later). Splash -> onboarding: fade + zoom.
- Moon in the theme is a thin crescent (about 4 days old), not a full moon.

### 2.5 Welcome reward
- "Welcome gift: 100 gems". Big chest/gem animation, button "Claim".
- Optional "Watch ad for 2x" (rewarded). Never forced.
- Currency: **Gems** only at first. Gems later only if a real second use exists (premium skins).

### 2.6 Nickname + avatar
- Text field, 3-12 chars, letters/numbers/space, profanity-safe (small blocklist), "Random" dice button, Continue.
- Same screen: pick an avatar (DP) from a grid; default random. Change later in Profile.
- Stored locally. Used in Home greeting and later leaderboards.

### 2.7 Home
- Top: nickname/avatar, gems, Settings, Daily reward badge.
- Center: logo + big **Play (Level N)** button, bottle animation.
- Bottom: Daily, Shop (skins/themes), Level map (optional).
- Banner ad slot at bottom (see ads).

### 2.8 Game
- Top bar: Pause, Level N, Hint(?)
- Bottles: auto-layout in 1-3 rows by bottle count, shelf under each row.
- Bottom bar: Undo, Restart, +Bottle, Hint (with gem cost and rewarded-ad alternative).
- Banner ad slot at bottom (reserved).

### 2.9 Level complete
- Stars (1-3 by moves), gem reward, Next, Home, "Watch ad for 2x gems".
- Interstitial shown here (not before).

### 2.10 Settings
- Sound, Music, Vibration, Colorblind mode (symbols on liquids), Language, Privacy Policy, Terms, Rate app, Restore purchases (later), Remove ads (later), Version, Ad privacy options (UMP re-open button).

### 2.11 Shop (v1.1 ok)
- Bottle skins (glass tint/cork styles), Themes, Remove ads (IAP, later).

### 2.12 Daily reward
- 7-day cycle, day 7 big prize, claim button, rewarded 2x option.
- Rewards (gems): D1 20, D2 30, D3 40, D4 50, D5 60, D6 80, D7 150 + skin chance.
- Missing a day: streak resets to day 1 (simple) — or pause-streak option later.
- Home shows red dot when claimable. Uses device date + stored last-claim date (v1, local only; note: clock cheating possible, acceptable).

### 2.13 Spin wheel
- Wheel with 8 slices: gems 10 / 20 / 30 / 50 / 100, a hint, a +Bottle, a skin-fragment (or bonus 200 gem jackpot, rare).
- 1 free spin per day; extra spins via rewarded ad (cap 3 per day).
- Spin animation with ease-out, tick sound, haptic on each peg, result popup with "Claim" and "2x (watch ad)".
- Weighted probabilities (e.g. 10:30%, 20:25%, 30:15%, 50:10%, 100:3%, hint 8%, +Bottle 8%, jackpot 1%).

### 2.14 Daily challenge
- One special puzzle per day (fixed seed from date, so same for everyone); harder than average, themed background.
- Reward: 50 gems + a calendar stamp. Month calendar view with completed days marked; completing the whole week gives bonus.
- Resume allowed same day; fail = retry free.

### 2.15 Level failed / stuck
- Detect no legal moves: popup "No moves left" with Undo, +Bottle (gems or ad), Restart.

### 2.16 Pause popup
- Resume, Restart, Sound/Music toggles, Home.

### 2.17 Not enough gems popup
- Shows price vs balance, button "Watch ad for 25 gems", Cancel.

### 2.18 Rate-us popup
- Once after level 10 (and again after 30 if not rated), in-app review API, never during play.

### 2.19 Avatar picker (DP)
- Grid of 12-16 built-in avatars (cute bottles, animals, gems, characters), drawn as vector/WebP assets bundled in the app. No camera or gallery upload in v1 (avoids permissions, moderation and privacy policy complexity).
- 6 free, rest unlocked by gems or levels (e.g. level 10, 25, 50) or from Spin/Daily rewards.
- Avatar frame (border) cosmetics later in Shop.

### 2.20 Profile
- Big avatar (tap to change), nickname (tap to edit), level reached, total gems, join date.
- Stats cards: levels completed, best streak, total stars, daily challenges done.
- Achievements row (badges, v1.1).
- Opened from the avatar on Home top-left.

### 2.21 Score / stats screen
- Per-level: stars (1-3), moves used, best moves, time (optional).
- Overall: total stars, levels completed, current and best daily streak, challenge calendar, total gems earned.
- Level complete screen shows this level's score vs best ("New best!").
- Score formula (v1): stars = 3 if moves <= par, 2 if <= par*1.5, else 1; score = 1000 + (par - moves)*50 clamped at min 100.
- Leaderboard (Google Play Games) is v2; scores stored locally in v1.

## 3. Ads plan (reserve space in layout from day 1)

| Slot | Where | Format | Rule |
|---|---|---|---|
| Banner | Bottom of Home and Game | Anchored adaptive banner | Fixed 50-60dp reserved area; NEVER overlaps bottles or buttons; do not place on Splash/Consent/Onboarding |
| Interstitial | Level complete, then continue | Interstitial | Every 2-3 levels, min 60-90 s gap, never during play, never on app open before first level |
| Rewarded | Hint, +Bottle, 2x gems, welcome/daily 2x | Rewarded | Always optional, clear label ("Watch video") |
| App open | skip in v1 | - | Avoid; hurts retention and policy risk |

Layout rule: build game screen as `Column[ TopBar, Expanded(Board), ActionBar, BannerSlot ]` with `BannerSlot` a fixed-height `SizedBox` that shows a placeholder when no ad loaded (no layout jump).
Use test ad unit IDs during development. Real IDs only in release build.
Policy: no fake close buttons, no ad too close to tap targets, no ads on loading, label rewarded clearly.

## 3a. Animation and transitions plan

### Screen transitions (one shared helper, used by all routes)
- Splash 1 -> Splash 2: cross-fade (600 ms).
- Splash 2 -> Consent / Home: fade + slight zoom-in (500 ms).
- Onboarding page -> page: slide left with parallax (illustration moves slower than text), 450 ms, easeOutCubic. Pager dots stretch to active (8 -> 18 px). Skip jumps to last page.
- Onboarding -> Welcome reward -> Nickname -> Home: fade + zoom.
- Home -> Game: bottle/curtain wipe or zoom-through (600 ms); Game -> Level complete: popup scales in from 0.8 with overshoot, dim backdrop.
- Popups (pause, failed, not-enough-gems): scale + fade 250 ms. Never hard cuts.
- Implementation: custom `PageRouteBuilder` + `FadeTransition`/`SlideTransition`/`ScaleTransition`; one `AppTransitions` class with `fade`, `slideX`, `zoom`, `rise`.

### Onboarding / help animations (looping, driven by one AnimationController per page)
1. Tap: bottle lifts 16 px and drops, tap ripple pulses on it (2.4 s loop).
2. Pour: source bottle tilts 75 deg, liquid stream appears, target bottle layer grows (3.4 s loop).
3. Win: three bottles fill, stars pop with scale overshoot, soft glow pulse (2.6 s loop).
4. Helpers: Undo / Hint / +Bottle buttons bounce one after another (2 s loop).
- Background bubbles drift slowly on all onboarding pages.
- Same animations reused in a "How to play" help popup from Settings and Pause.

### Other micro-animations
- Button press: scale 0.96 + haptic. Gem count: count-up tween. Daily/Spin: ease-out wheel, tick on each peg. Confetti on win. Bottle complete: sparkle + sparkle burst.
- Respect "reduce motion": if system animations off, shorten to fades.

## 4. Game rules / systems

- Move: tap source (bottle lifts), tap target; legal if target empty or top color equal and has space. Pours all consecutive same-color layers that fit.
- Bottle capacity: 4. Win: every non-empty bottle is full of one color.
- Level generation: N colors + 2 empty bottles; difficulty ramps (3 -> 12 colors, extra bottle fewer). Generate by reverse shuffling from solved state (guarantees solvable). Seeded by level number.
- Undo (unlimited or limited), Restart, +Bottle (once or twice per level), Hint (solver suggests a move).
- Save: current level, board state (resume), gems, settings, flags.

## 5. Tech choices

- Flutter + Dart, Android target only.
- State: Riverpod (or Provider; keep it simple).
- Storage: `shared_preferences` (v1).
- Ads: `google_mobile_ads` (AdMob) + UMP consent.
- Audio: `audioplayers` or `flame_audio`; haptics: `HapticFeedback`.
- Animation: AnimationController, CustomPainter for bottles, particles for confetti.
- Optional: `flutter_animate`, `confetti`.
- Min SDK 23+, target latest required SDK.
- Folder layout: `lib/core` (theme, constants), `lib/features/{splash,consent,onboarding,reward,nickname,home,game,shop,settings}`, `lib/game` (engine, level generator, painters), `lib/services` (ads, storage, audio).

## 6. Play Store policy checklist

- [ ] Privacy Policy URL (required, ads used)
- [ ] Data safety form matches AdMob/UMP data use
- [ ] Content rating questionnaire
- [ ] Target audience 13+ (not kids)
- [ ] Ads declaration: contains ads = yes
- [ ] Original icon/screenshots, no copied branding
- [ ] Trademark check for "Rainbow Pour"
- [ ] App bundle (.aab), signing key backed up
- [ ] Target API level meets current Play requirement
- [ ] Short desc <= 80 chars, title <= 30, no emoji/"free"/"best" in title

## 7. Build order (milestones)

1. **M1 Foundation**: theme, colors, routing, storage service, folder structure
2. **M2 Game core**: engine, level generator, cone beaker painter, tap/pour animation, win check
3. **M3 Game UI**: backgrounds (1 then 8), bars, undo/restart/+bottle, level complete
4. **M4 Onboarding flow**: splash 1+2, consent, onboarding, welcome reward, nickname
5. **M5 Home + Settings + Daily reward**
6. **M6 Ads**: UMP, banner slot, interstitial, rewarded (test IDs)
7. **M7 Polish**: sounds, haptics, colorblind mode, shop skins
8. **M8 Release**: icon, screenshots, signing, policy forms, internal testing track

## 8. Open questions

- Language: English only for v1?
- Monetization v1: ads only, or also Remove Ads IAP?

## Scope decision (2026-10)
- Removed: Spin wheel, Daily challenge. Kept: Daily reward (with streak) as the only daily feature.
- Onboarding is 5 pages (Tap, Pour, Fill, Helpers, Daily Rewards).
