# Rainbow Pour: plan for Update 1 (Firebase + AdMob test ads) and Update 2 (mediation + real ads)

Written 2026-11-17 for the owner (Momina, Roman Urdu) and for any new Claude/Cursor session on another laptop.
Read in this order: this file -> `docs/PROJECT_GUIDE.md` -> `docs/RELEASE_AND_POLICY.md` -> `docs/HANDOFF.md`.
Reference for the same process done on another game: `GAME_PLAYBOOK_ADS_FIREBASE.md` (in the Arrow Drift repo; a copy is in Boxora/docs).
Rules: never ask for or store passwords/keystores; never click real ads; the owner pushes to GitHub (do not run `git push` here).

## 0. Roman Urdu khulasa (short)
- Rainbow Pour mein **Firebase Analytics + Crashlytics, UMP consent, rewarded/banner/native/interstitial (test IDs)** pehle se bane hue hain. `flutter analyze` saaf, **194 tests pass**.
- **Update 1:** Firebase poora attach (Play + AdMob link) + AdMob (abhi test ads) + release ki taiyari (signing, icon, privacy, Data safety). **Update 2:** Unity, Liftoff, InMobi (aur chahein to AppLovin/Mintegral/Pangle) + real ads.
- Sab se zaroori khatre: (1) release build phone par chala kar dekhna (R8 crash pehle aa chuka), (2) release abhi **debug key** se sign hoti hai, (3) default Flutter icon, (4) privacy policy URL khali, (5) test ads ko Production mein daalna (Section 2).
- Is file mein har task ki checklist hai, kaun karega (sir ya aap), aur Arrow Drift mein jo masle aaye wo yahan kaise bachein.

## 1. Verified status (2026-11-17)
| Item | State |
|---|---|
| Package / Firebase project | `com.gamezium.rainbowpour`, project `rainbow-pour` (Spark), `android/app/google-services.json` package matches |
| `google_mobile_ads` | ^9.2.0 (newer than Arrow Drift's 8.0.0, so the NEWEST mediation adapters fit: dry-run OK for unity 1.12.0, liftoff 1.5.7, inmobi 2.4.1, applovin 2.7.0, mintegral 2.1.6, pangle 4.3.0; nothing installed) |
| Firebase | `firebase_core`, `firebase_analytics`, `firebase_crashlytics`; collection OFF in manifest until consent; crash reports release-only |
| Ads | `lib/ads/`: rewarded, banner (Home/Levels only), native (Daily Reward), interstitial gate; **Google test IDs** (`AdConfig.useTestIds = true`) |
| Consent | UMP before `MobileAds.initialize`; Settings "Ad privacy options" |
| Quality | `flutter analyze`: no issues. `flutter test`: 194 pass |
| Release signing | **debug key** (TODO). No `key.properties`/keystore yet |
| R8 | `proguard-rules.pro` keeps WorkManager Room constructor (fixes a launch crash found on a phone) |
| Not done | real icon, privacy/terms URLs (`lib/core/app_links.dart` empty), audio placeholders silent, real AdMob IDs, phone test of the Task 13 flows |
| Uncommitted | Many files are modified (run `git status`), including the Firebase work: the owner must commit and push |

## 2. Decisions to confirm with sir (before Update 1)
1. **Test ads in the first Production release?** The plan says Update 1 ships AdMob test ads and Update 2 real ads. Risks: Google sample ad units earn nothing; `docs/RELEASE_AND_POLICY.md` lists "test ads in production" as a red flag; I could not confirm it is a formal violation (read AdMob Help / Policy Center). **Safer option B:** create the AdMob app now, put the REAL IDs in Update 1, register the dev phone as an AdMob test device (AdMob > Settings > Test devices; sir adds the Advertising ID), and accept 24-48 h of "No fill" on a new app. Option A (test IDs) is fine for Internal/Closed testing, not as the public release. Write the decision here: ______
2. **applicationId** `com.gamezium.rainbowpour` cannot change after the first upload. Confirm the Play app name and the developer account (company account, handled by sir).
3. **Events for Google Ads:** Firebase events use standard names (`level_start`, `level_end`). If Google Ads should optimise for specific levels add named events (e.g. `level_win_5`, `level_win_10`) only for a few milestone levels (Firebase allows 500 distinct event names; Google Ads imports names, not parameters).
4. Remove Ads / in-app purchase: **not planned** (docs say no Remove Ads, no billing). If added later follow the Arrow Drift playbook section 5 and update Data safety.
5. Privacy Policy and Terms: sir provides the URLs; we update the text (Section 6).

## 3. Accounts, roles and emails (do once; same method as Arrow Drift)
Placeholders: SIR = team lead Gmail with owner rights, DEV = Momina's Gmail.
**Firebase** (project `rainbow-pour`):
1. Console > Project settings > Users and permissions: SIR = Owner (needed once for linking), DEV = Editor/Admin.
2. Android app registered with `com.gamezium.rainbowpour`. (Add the SHA-256 of the upload key only if Google sign-in/App Check is ever added; not needed now.)
3. Project settings > **Integrations**: link **Google Analytics**, **Google Play**, **AdMob**, **Google Ads** (the link needs one account with Firebase Owner + Play admin + AdMob access; SIR does it, or adds DEV as admin in those products).
**AdMob** (company account; never create another account):
1. SIR: Settings > Access and authorization > Invite DEV with role **Manager** (not Administrator, no payments access).
2. Apps > Add app > Android > Rainbow Pour. If the app is not on Play yet choose "No" and link later (app settings > link to store) after the first upload.
3. Create ad units: **Banner, Interstitial, Rewarded, Native** (no App Open in this game). Note the App ID (`ca-app-pub-...~...`) and each unit ID. Banner refresh 60 s.
4. App settings > **Linked services**: link the Firebase project `rainbow-pour`.
5. Privacy & messaging: create the **European regulations** message (and **US state regulations**), add the privacy policy URL, choose the ad partners (add Unity/Liftoff/InMobi before Update 2). The UMP code is already in the app; publish the message BEFORE the release.
6. app-ads.txt: Apps > app-ads.txt shows the AdMob line `google.com, pub-9551737622916377, DIRECT, f08c47fec0942fa0`. It must be served from the root of the website in the Play listing "Website" field (Blogger cannot host a root file).
**Google Play Console** (SIR):
1. Create the app (name "Rainbow Pour: Water Sort", game, free, package id as above); Play App Signing on.
2. Internal testing: add DEV's Gmail as tester.
3. After the first upload: link AdMob (AdMob > app > link to the Play listing) and Firebase.
**Google Ads** (optional now): link in Firebase Integrations; mark key events and import them as conversions after ~24 h of data.

## 4. UPDATE 1: Firebase complete + AdMob (test or real, per Section 2)
### 4A. Consoles (owner or sir): checklist
- [ ] Firebase: roles set, Integrations linked (Analytics, Play, AdMob, Google Ads).
- [ ] AdMob: app + 4 ad units created; Firebase linked; UMP messages published; Play listing linked after the first upload.
- [ ] Play Console: app created, store listing, content rating (IARC), target audience **13+**, Ads = Yes, Advertising ID = Yes, **Data safety** (Section 6B), privacy policy URL, 512 px icon, 1024x500 feature graphic, 4-8 screenshots.
- [ ] Privacy Policy and Terms published (same URL forever); URLs given to the dev for `lib/core/app_links.dart`.
### 4B. Code tasks (dev), in this order
1. **Release signing:** create the upload keystore (`keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`), `android/key.properties` (git-ignored), add `signingConfigs.release` in `android/app/build.gradle.kts` plus a guard that FAILS a release build when `key.properties` is missing (same pattern as Arrow Drift). Never ship the debug key. Keep the keystore and passwords OUTSIDE git, two private backups (Drive/USB), never on GitHub.
2. **Version:** `pubspec.yaml` `version: 1.0.0+1` for the first upload, then +2, +3...
3. **App icon:** replace the default Flutter icon (adaptive icon).
4. **Ad IDs:** per Section 2. If real IDs: fill `AdConfig.real*`, set `useTestIds=false` and set the manifest `APPLICATION_ID` to the same real App ID IN THE SAME COMMIT. **Banner/native widgets read `AdConfig.bannerId/nativeId` without try/catch (`lib/ads/ad_widgets_io.dart`, lines ~45 and ~117) and `AdConfig.resolve` THROWS in release when a real ID is empty: fill all 4 IDs or guard those reads, otherwise the screen crashes.**
5. **ad_impression event:** in `lib/ads/mobile_ads_gateway.dart` set `onPaidEvent` on rewarded/interstitial and on the banner/native listeners, and call `AnalyticsService.log('ad_impression', {value, currency, ad_format, ad_unit_name, ad_platform: 'AdMob'})` (as in Arrow Drift). Add a test in `test/analytics/`.
6. Optional: milestone level events (Section 2.3).
7. **Fonts:** bundle Outfit (OFL) as an asset and disable runtime fetching (`GoogleFonts.config.allowRuntimeFetching = false`); otherwise an offline first launch uses a fallback font and contacts Google servers (mention in the policy).
8. **Manifest permissions:** build a RELEASE APK and run `aapt dump permissions`. The merged manifest has extras (`WAKE_LOCK`, `FOREGROUND_SERVICE`, `ACCESS_ADSERVICES_*`, install referrer). Keep AD_ID/ADSERVICES; justify or remove the others with `tools:node="remove"`. Check `aapt dump badging` for `uses-feature` and make sure no location permission appears (ad SDKs may add it later; remove it or declare it in Data safety).
9. **16 KB alignment:** `zipalign -c -P 16 -v 4 app-release.apk` (every native lib must say OK).
10. **Audio:** replace the silent placeholder files with real CC0/licensed sounds and keep a credits list.
11. Remove debug logs; keep the `kDebugMode` guards. Confirm Settings has no demo section (already removed).
12. `flutter analyze` and `flutter test` must stay green. Commit; the owner pushes.
### 4C. Build and test (on a REAL phone, release build)
- `flutter build apk --release` and `flutter build appbundle --release`. **Install and open the RELEASE build before any upload** (the debug build hid a launch crash caused by R8: the WorkDatabase constructor).
- Task 13 checklist: Level Failed popup, extra-bottle flow, "Undo N moves" hint, 3-free-undos-then-ad popup, frame rate, haptics, hint speed, offline start, rewarded ad (reward only after completion), interstitial timing (not before level 4, every 3 levels, 90 s gap), banner only on Home/Levels, native on Daily Reward, consent form (EEA test), Settings > Ad privacy options, rate dialog.
- Firebase: `adb shell setprop debug.firebase.analytics.app com.gamezium.rainbowpour` then DebugView must show `level_start`, `level_end`, `ad_rewarded`, `ad_impression`; collection must stay OFF before consent; reset with `.none.`. Crashlytics: force a test crash in a release build once to confirm the dashboard (remove it afterwards); reports appear after the next launch.
- Upload the AAB to **Internal testing** first, install from Play, then Production at 20%, then 100%.
### 4D. After upload
- AdMob: link the Play listing; wait 24-48 h for ads; Firebase Events appear after ~24 h; watch Play Android vitals and Crashlytics daily for a week.

## 5. UPDATE 2: Unity, Liftoff, InMobi (+ real ads if Update 1 used test IDs)
Follow `GAME_PLAYBOOK_ADS_FIREBASE.md` section 4. Order:
1. **Accounts (sir):** Unity Ads, Liftoff Monetize, InMobi (and AppLovin/Mintegral/Pangle if wanted). Add the app and placements in each dashboard; keep each network's **test mode ON** until step 7.
2. **AdMob (sir/dev):** Mediation > Bidding sources: set up each network and map every AdMob ad unit to the network placement; add the sources to the Mediation groups per format (Unity: banner, interstitial, rewarded; Liftoff: all; InMobi: banner, interstitial, rewarded, native; none supports App Open, which this game does not use). Privacy & messaging: add the new ad partners to the GDPR partner list.
3. **Code (dev):** `flutter pub add gma_mediation_unity gma_mediation_liftoffmonetize gma_mediation_inmobi` (these versions fit google_mobile_ads 9.2). Before `MobileAds.initialize`: Unity `GmaMediationUnity().setGDPRConsent / setCCPAConsent`, Liftoff `GmaMediationLiftoffmonetize().setGDPRStatus / setCCPAStatus` (InMobi has no consent API). Feed them from the UMP result (`canRequestAds`).
4. **Test:** a debug build with the real units on a phone registered as an AdMob test device; Ad Inspector > Adapters (no "Failure") > Single ad source test per network > force-stop and reopen. Never click ads.
5. **Policy docs:** Privacy Policy names AdMob + partners (Unity Ads, Liftoff Monetize, InMobi); Data safety: Device or other IDs, approximate location, app interactions, diagnostics (Crashlytics) all Collected + Shared; app-ads.txt lines from every network; check the merged manifest for new permissions (in Arrow Drift the ad SDKs added precise location and wifi permissions and Play flagged "Precise location not declared": declare it or remove it with `tools:node="remove"`).
6. **Rewarded rules:** keep rewarded ads user-initiated (button text like "Watch ad: +10 gems"). Never auto-open a rewarded ad (AdMob policy; account risk).
7. Before Production: each network's test mode OFF (dashboard setting, not code), UMP published with the partners, version bumped, release APK tested again, then Internal testing, then Production 20%.

## 6. Policy and store checklist (avoid rejection)
A. **Privacy Policy** (public URL): must list AdMob (and later the partners), Firebase Analytics, Crashlytics, the data (Advertising ID, IP/approximate location, device info, events, crash logs), UMP consent, age 13+, contact email, no accounts, data stays on the device. Draft: `docs/PRIVACY_POLICY_DRAFT.md` (already mentions Firebase and Crashlytics; add the partners in Update 2).
B. **Data safety (Play):** Device or other IDs (Advertising + Analytics: AdMob), App info and performance > Crash logs and Diagnostics (Crashlytics), App activity > App interactions (Firebase), Approximate location (ad SDKs). Collected AND shared with Google/ad partners; encrypted in transit; no account, so deletion = uninstall. It MUST match the policy and the AAB: Play scans the AAB, and undeclared data blocks "send changes for review" (View details shows the missing type).
C. **Other forms:** content rating (no gambling: the spin wheel was removed and gems have no cash value), target audience 13+ (not Families), Ads = Yes, Advertising ID = Yes, news/health/finance = No.
D. **Ad behaviour rules (already designed):** no ads at launch/splash/consent/game screen; interstitial only after a win and from level 4; rewarded opt-in with clear text; reward only after completion; ads clearly labelled; no misleading buttons; consent before any ad request.
E. **Metadata:** title max 30 characters, no "best/free/#1"; screenshots from the real build; the description may only list features that exist (the draft says 500 levels but the game has 300: FIX the text).
F. **IP:** original art/code; check the "Rainbow Pour" trademark; credit audio/fonts (Outfit is OFL).
G. **Test ads in Production:** see Section 2.1.
H. **Target API / 64-bit / AAB:** Flutter defaults meet them; re-read Play Console warnings at upload. "Drop in support" lists are informational.

## 7. Crash and issue register (what can go wrong and how to prevent it)
| Risk | Why | Prevention / fix |
|---|---|---|
| Release crashes at launch (WorkDatabase) | R8 removed a Room constructor (found on a real phone) | Keep `proguard-rules.pro`; ALWAYS test the release build on a phone; re-test after adding SDKs/mediation (new libraries can add R8 problems) |
| Ad screen crash after enabling real IDs | `AdConfig.resolve` throws when a real ID is empty; banner/native read it unguarded | Fill all IDs together; guard the widget reads; test the release build |
| Release signed with the debug key | `signingConfig = debug` | Real signing + guard (4B.1); Play rejects a debug-signed AAB |
| Lost keystore/passwords | not in git by design | Two private backups |
| `google-services.json` missing on a new laptop | it is git-ignored | Download it again from Firebase > Project settings > Your apps into `android/app/` |
| Firebase init fails | missing file/plugin mismatch | `AnalyticsService.init` is try/caught; the game keeps working |
| ANR / app killed during a rewarded ad on a low-RAM phone | the game keeps animating behind the ad (seen on a debug build) | Test release on a low-RAM phone; if it stutters stop the tickers (`TickerMode`) while an ad shows |
| Rewarded "Ad not ready" on first tap | cold load; the wait is only 1 s (`rewardedReadyWait`) | Preload exists; keep preloading after each ad; the "not ready" dialog is the fallback |
| Ads/consent never start | UMP unfinished or `canRequestAds` false, offline first launch | 30 s consent timeout exists; retry on the next launch; test offline |
| Ad closes into the Play Store | the user tapped the ad (Install/end card); network behaviour | Cannot be fixed in code; lower the priority of the network that shows it |
| Data safety / permission rejection | SDK permissions (location, wifi) | Check the merged manifest with `aapt` before every upload |
| Fonts shift offline | runtime Google Fonts | Bundle Outfit |
| Hint is slow on a phone | beam search runs on the UI thread (~1 s) | Move it to an isolate |
| Gem-ad daily cap bypass by moving the clock | uses the raw local date | Reuse the clock check (`recordClock`) |
| `game_screen.dart` is ~1900 lines | hard to change safely | Split later (docs/TODO.md section D), one extraction at a time with tests |
| Docs out of date | older docs mention 500 levels / 12 colours | Treat `PROJECT_GUIDE.md` as the truth; update or delete `BACKEND_THEORY.md` and `CURSOR_*` |
| Colorblind symbols missing on a tilted bottle | not implemented | Optional (docs/TODO.md section C) |
| Store text says 500 levels | draft | Change to 300 |

## 8. Features not yet clicked through on a real phone
Level Failed popup; extra-bottle flow; "Undo N moves" hint; 3 free undos then a rewarded ad (+3); win popup "2x gems" (rewarded); Daily Reward claim + 2x; Daily Challenge timer/pause/time-up/retry; shop buy/equip; colorblind mode; sound/music switches; resume after killing the app; clock moved backwards; offline play (no ads, no crash); Back button inside a level opens the pause menu; in-app review (only appears on Play installs); first launch consent + onboarding; performance on 25-bottle levels.

## 9. New laptop setup (to continue the work)
1. Install Flutter (Dart SDK ^3.12.1, as in `pubspec.yaml`), the Android SDK (`adb`, build-tools with `aapt` and `zipalign`) and Java 17.
2. `git clone https://github.com/MominaYaqoob/RainbowPour.git`, then `flutter pub get`.
3. Copy privately (NOT from GitHub): `android/app/google-services.json` (or download it again) and later `android/upload-keystore.jks` + `android/key.properties`.
4. `flutter analyze` and `flutter test`, then `flutter run` on a phone (USB debugging on, screen unlocked).
5. Tell Claude: "Read `docs/UPDATE_PLAN_FIREBASE_ADS.md` first, then continue with Update 1, step 4B."
6. The owner commits and pushes: check `git status`, `git add -A`, `git commit -m "..."`, `git push origin main`.

## 11. Where every ad is placed and how test ads work (checked in the code, 2026-11-18)
**Test ads today:** `lib/ads/ad_config.dart` has `useTestIds = true`, so EVERY build (debug AND release) uses Google sample IDs: App ID `ca-app-pub-3940256099942544~3347511713` (also in `AndroidManifest.xml`), banner `.../9214589741`, interstitial `.../1033173712`, rewarded `.../5224354917`, native `.../2247696110`. Test ads show a "Test Ad" label and pay nothing. Real IDs go in `AdConfig.real*` (all empty now); to switch set `useTestIds = false` and put the real App ID in the manifest in the same commit. There is NO App Open ad and NO Remove Ads in this game.

| Ad | Where it shows (file) | Rule / how it works |
|---|---|---|
| **Banner** (320x50, `BannerAdSlot`) | Home screen (`lib/screens/home/home_screen.dart` line ~199) and Level map (`lib/screens/levels/level_map_screen.dart` line ~307) | Never on the game screen, splash, consent, onboarding or popups. Collapses if it fails. Widget code: `lib/ads/ad_widgets_io.dart` |
| **Native** (`NativeAdCard`) | Bottom of the Daily Reward screen (`lib/screens/daily/daily_reward_screen.dart` line ~277) | Labelled "Ad", separated from the Claim button; nothing is shown if it fails to load |
| **Interstitial** | After a win, when the player taps "Next level" (`lib/screens/game/game_screen.dart` lines ~378 and ~609, via `AdService.maybeShowInterstitial` and `onLevelCompleted`) | Rules in `lib/ads/interstitial_gate.dart`: never in levels 1-3 (`firstLevel = 4`), only after every 3rd completed level (`levelsPerAd = 3`), at least 90 s apart (`minGap`), not within 60 s of a rewarded ad (`afterRewardedGap`), never at launch, never in the daily challenge. Preloaded; shows only a ready ad |
| **Rewarded** (+ placement names for Firebase) | Shop gems `shop_gems` (`shop_screen.dart` ~228, +10 gems, max 3/day); in a level: `gems_game`, `extra_undo` (+3 undos), `extra_bottle` (free bottle) (`game_screen.dart` ~660/682/803); win popup 2x gems `win_double` (`game_screen.dart` ~866); Daily Reward 2x `daily_double` (`daily_reward_screen.dart` ~119) | Always a button the player taps. `lib/ads/rewarded_flow.dart` grants the reward ONLY when Google's user-earned callback fires (closing early gives nothing). Preloaded in `AdService` (`_preloadRewarded`); if still loading, a tap waits 1 s then shows "Ad not ready" |

**Order at startup:** consent screen / returning user -> `AdService.initialize()` (UMP form if required, then `MobileAds.initialize` only when `canRequestAds`) -> `adsReady` turns true -> banner/native widgets load, rewarded and interstitial preload -> `AnalyticsService.setConsent(true)` (Firebase + Crashlytics start). Web and non-Android skip all of it.

**How to test with test ads (Update 1, safe):** `flutter run` (or a release APK) on a phone: banner on Home and Level map, native on Daily Reward, rewarded from Shop > Gems, win popup 2x, extra undo/bottle; interstitial: finish levels 4, 5, 6 (shows when you tap Next level after the 3rd, then not again for 90 s). The unit tests are `test/ads/` (`ad_config_test`, `ad_service_test`, `interstitial_gate_test`, `rewarded_flow_test`).

**Real ads later:** same placements, only the IDs change. Update 2 adds mediation networks behind the same units (no change in where ads show).

## 12. Timing of every ad, and how to add the App Open ad (design, NOT built yet)
### 12.1 Timing summary (what exists in the code today)
| Ad | Preload | Shows when | Limits |
|---|---|---|---|
| Banner / Native | loads when `adsReady` turns true and the screen is visible | while the player is on Home / Level map (banner) or Daily Reward (native) | none; collapses on failure |
| Interstitial | preloaded after ads start and again after each show | only after a win, when the player taps "Next level" | level >= 4, every 3rd completed level, >= 90 s since the last interstitial, >= 60 s since the last rewarded, never at launch, never in the daily challenge |
| Rewarded | preloaded after ads start and again after each show (`_preloadRewarded`) | only when the player taps a "Watch ad" button | a tap waits 1 s for a still-loading ad, then "Ad not ready"; gem ads max 3 per local day |
| App Open | **not in this game yet** | see 12.2 | see 12.2 |
Note: Google rewarded/interstitial ads expire about 1 hour after loading. Arrow Drift discards a rewarded ad older than 50 minutes before showing it (`_discardStaleRewarded`); check that Rainbow Pour does the same, or an old preloaded ad may fail to show.

### 12.2 App Open ad: when to show (recommended rules, from Arrow Drift + `docs/RELEASE_AND_POLICY.md`)
- Show ONLY when the player comes BACK to the app from the background, never on the first launch of a session and never during the very first session after install.
- Minimum gap: **4 hours** since the last App Open ad (RELEASE_AND_POLICY says "only on return, >= 4 h"). Arrow Drift shows it on every resume; that earns more but irritates players, so Rainbow Pour should stay at 4 h.
- NEVER: before the consent step is finished, while another fullscreen ad (interstitial/rewarded) is showing or was closed in the last ~4 s (that "resume" is our own ad closing and causes an App Open loop), inside a level or the daily challenge (the challenge clock must not run behind an ad), or on splash/consent/onboarding.
- Preload: when the app goes to the background (`AppLifecycleState.paused`) and the player is not in a level; drop an ad older than 3 h 50 m; after a failed load wait 60 s before trying again.
- If no ad is cached on return, just continue (no loading dialog; a spinner pop-up annoys players).
### 12.3 App Open ad: how to add it (steps)
1. AdMob (sir/dev): Apps > Rainbow Pour > Ad units > Add ad unit > **App open**; note the ID. (Test ID for development: `ca-app-pub-3940256099942544/9257395921`.)
2. `lib/ads/ad_config.dart`: add `testAppOpenId` and `realAppOpenId` and an `appOpenId` getter with the same `resolve` rule (empty real ID must not fall back to a test ID).
3. `lib/ads/ads_gateway.dart` and `mobile_ads_gateway.dart`: add `loadAppOpen(String adUnitId)` and `showLoadedAppOpen()` (use `AppOpenAd.load` / `show`, set `fullScreenContentCallback`, `onPaidEvent`), plus a stub in `mobile_ads_gateway_stub.dart` for web.
4. `lib/ads/ad_service.dart`: add `_appOpenReady`, `_lastAppOpenShown`, a `WidgetsBindingObserver` for `paused` (preload) and `resumed` (show if the rules in 12.2 allow), and a flag `AdService.gameplayActive` that `game_screen.dart` sets (true while a level or the challenge is open).
5. `game_screen.dart`: set `gameplayActive` in `initState`/`dispose` so the ad never shows mid-level.
6. Ignore the resume that follows our own interstitial/rewarded for ~4 s.
7. Tests: extend `test/ads/ad_service_test.dart` with a fake gateway (first launch never shows, 4 h gap, not while gameplay is active, not right after another ad, not before consent).
8. Test on a phone with test IDs: open the app, press Home, wait, reopen (it should NOT show before 4 h; temporarily lower the gap in a debug build to check it), then confirm it never shows inside a level.
9. Policy: App Open is full-screen: keep it away from launch; no new Data safety type (same Advertising ID data). Liftoff supports App Open in mediation (Unity and InMobi do not), so in Update 2 add the Liftoff App Open source to the new App Open unit.
10. Where to schedule it: Update 1 only if sir wants it now; otherwise Update 2 together with Liftoff (fewer releases, one test round).

## 10. Quick order of work
Update 1: Section 2 decisions, then 4A consoles, then 4B code (1 signing, 3 icon, 4 IDs, 5 ad_impression, 7 fonts, 8 permissions), then 4C release test on a phone, Internal testing, Production 20%, 4D checks.
Update 2: Section 5, steps 1-7.
