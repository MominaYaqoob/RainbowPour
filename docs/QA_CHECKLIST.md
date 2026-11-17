# QA checklist (real phone)

Tick each line on a real Android phone. Write PASS or FAIL in the last column.
**Always test a RELEASE build** (`flutter build apk --release`): debug builds are
much slower and hide release-only crashes (R8). A debug build is fine for
reading the QA menu (Settings, bottom, debug only).

## 0. Install

```bash
flutter build apk --release
D:/AndroidSetup/AndroidSDK/platform-tools/adb.exe devices
D:/AndroidSetup/AndroidSDK/platform-tools/adb.exe install -r build/app/outputs/flutter-apk/app-release.apk
```

Watch the log while you test:

```bash
D:/AndroidSetup/AndroidSDK/platform-tools/adb.exe logcat -v time > phone.log
```

Then search the file for `FATAL EXCEPTION` and `ANR in`. Firebase events:
`adb shell setprop debug.firebase.analytics.app com.gamezium.rainbowpour` and open
DebugView in the Firebase console.

## 1. Start and first launch

| # | Step | Expected | Result |
|---|------|----------|--------|
| 1 | Install and open the app | Opens to Home (release) or Consent (debug), no crash | |
| 2 | First launch: Consent, UMP form (if shown), Onboarding, Welcome gift, Nickname | Every screen shows, buttons work | |
| 3 | Kill the app and open it again | Opens straight to Home with the same level and gems | |
| 4 | Splash | About 3 seconds in total | |

## 2. Playing a level

| # | Step | Expected | Result |
|---|------|----------|--------|
| 5 | Level 1 tutorial | A hand shows the taps, wrong taps are ignored | |
| 6 | Select a bottle, tap another | Pour animation, the bottle travels over its target | |
| 7 | Fill a bottle with one colour | Bounce, shine, sparkles, vibration, "ding" | |
| 8 | Undo (3 times, then a 4th) | 3 free undos, then "Need more undos?" with an ad button | |
| 9 | Hint (after a few wrong moves) | Costs 40 gems, highlights source and target; or "Undo N moves" (free) | |
| 10 | + Bottle | Costs 70 gems, one extra empty bottle, only once per level | |
| 11 | Get stuck on purpose | "No moves left" popup, sound, Undo / Restart / extra bottle | |
| 12 | Win a NEW level | Win popup, stars, +10/15/20 gems, "Watch an ad for 2x" | |
| 13 | Win an OLD level again | NO gems, text "Gems are paid on the first win only", no 2x button | |
| 14 | Android Back during play | Pause menu (Resume, Restart, Home); Back again closes it | |
| 15 | Kill the app in the middle of a level, reopen, tap Play | The same board and move count come back | |

## 3. Menus and progress

| # | Step | Expected | Result |
|---|------|----------|--------|
| 16 | Back to Home after playing | Level and gems are current (not the old ones) | |
| 17 | Level map | Current level pulses, stars show, locked levels are locked, smooth scroll | |
| 18 | Profile and Stats | Levels, stars, moves and best streak match what you played | |
| 19 | Shop: buy a bottle shape or background | Gems drop, item equips, Home bottles change | |
| 20 | Gem pill (the "+") in the game and on inner screens | Opens the Shop | |
| 21 | Settings switches: Sound, Music, Vibration, Colorblind | Each takes effect at once, and stays after a restart | |
| 22 | Privacy Policy / Terms rows | "Coming soon" until real URLs exist, then the page opens | |
| 23 | Rate Rainbow Pour: 5 stars / 2 stars | 5: review sheet or store; 2: "Thank you!" only | |

## 4. Daily features

| # | Step | Expected | Result |
|---|------|----------|--------|
| 24 | Daily Reward: Claim | Gems added, "Claimed", "Come back tomorrow", streak 1 | |
| 25 | Change the phone date to tomorrow, open the app | Day 2 can be claimed (QA menu can also do this) | |
| 26 | Change the phone date back one day | "Check Your Clock" dialog, claim blocked | |
| 27 | Daily Challenge: Play | 25 to 28 bottles in 5 rows, timer 5:00 counts down | |
| 28 | Pause or open a popup during the challenge | Timer stops; background the app: timer stops | |
| 29 | Let the timer reach 0 | "Time's up" with Retry (same board) and Exit | |
| 30 | Win the challenge | +30 gems, streak +1, calendar tick, Play shows "Done for today" | |

## 5. Ads (test ads)

| # | Step | Expected | Result |
|---|------|----------|--------|
| 31 | Home and Level map | A banner at the bottom; none on the game screen | |
| 32 | Daily Reward screen | Native ad card (or nothing if it did not load) | |
| 33 | Rewarded: Shop "Watch Ad: +10 gems" (3 per day) | Ad plays, closes, +10 gems; the 4th shows "Daily limit" | |
| 34 | Rewarded: win 2x, +3 undos, free extra bottle, daily 2x | Reward only after the ad completes | |
| 35 | Close a rewarded ad early | No reward | |
| 36 | Interstitial | Only after a win, tapping Next, from level 4, once per 3 levels, 90 s apart | |
| 37 | Settings "Ad privacy options" | UMP form (EEA) or "No privacy options needed" | |

## 6. Look and feel

| # | Step | Expected | Result |
|---|------|----------|--------|
| 38 | Colorblind mode on, play a level | A different symbol on every layer, readable, also while a bottle is poured | |
| 39 | Levels 100 to 109 (QA menu: jump to level) | Bottles 19, 21, 22, 23, 24, 25, 25, 25, 20, 15; all fit the screen | |
| 40 | Sounds | tap, select, pour, ding, win, fail all heard; music loops without a click | |
| 41 | Turn Sound and Music off | Silence at once, and after a restart | |
| 42 | Frame rate on the biggest board (28 bottles) | Smooth enough; note any stutter | |
| 43 | Low battery, low memory (open other apps first) | No crash, no ANR | |
| 44 | Rotate the phone | Stays portrait | |
| 45 | Switch to another app and back | Game and music resume | |

## 7. Frame timing (profile build)

```bash
flutter run --profile
```

Open DevTools (Performance), play the 28-bottle challenge and several pours.
Frames over 16 ms during the pour animation or the hint calculation are worth
a note. The hint search runs on a separate isolate, so the board should not
freeze when you tap Hint.

## 8. QA menu (debug builds only)

Settings, last section "QA (debug only)". It does not exist in release builds.
It can: add or reset gems, jump to any level, show the Level Failed, stuck and
extra-undo popups, push the stored clock one day ahead (to test the clock
check) and undo that, reset the daily reward, daily challenge, ad counters and
review record, complete today's challenge, and clear the whole save.
