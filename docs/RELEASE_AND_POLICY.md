# Release and Google Play Policy Checklist (Rainbow Pour: Water Sort)

Account: **company developer account, handled by sir**. We deliver the files and texts below; sir uploads in Play Console.
Policies change often. Re-read the live Google Play Developer Policy Center before submitting. Nothing here is legal advice.

## 1. What we hand over to sir
1. `app-release.aab` (signed Android App Bundle) + the SHA-256 of the upload key (if sir enrols in Play App Signing, he uploads our AAB signed with the upload key).
2. App icon 512x512 PNG (32-bit, no transparency issues), feature graphic 1024x500 PNG/JPG.
3. 4-8 phone screenshots (portrait, min 320 px, max 3840 px, 16:9 or 9:16). Use real device captures.
4. Texts: title, short description, full description (draft in section 5).
5. Privacy Policy URL (sir's website) and the Terms URL if any. Draft text: `docs/PRIVACY_POLICY_DRAFT.md`.
6. Answers for: Content rating, Data safety, Ads declaration, Target audience (section 3).
7. AdMob app ID + ad unit IDs and Firebase `google-services.json` come FROM sir's company accounts (we then build the final AAB).

## 2. Technical requirements before building the AAB
- `applicationId` = `com.gamezium.rainbowpour` (cannot change after the first upload).
- `targetSdk`/`compileSdk`: must meet Google's current requirement at submission time (check Play Console "App content" and Policy Center; recent years required targeting the latest-but-one Android API level within a year of its release).
- 64-bit: Flutter release builds include arm64; AAB handles splits.
- Versioning: `version: 1.0.0+1` in pubspec -> every upload needs a higher `versionCode` (the number after `+`).
- Signing: create an **upload keystore** (`keytool -genkey ... -keystore upload-keystore.jks`), store it OUTSIDE git with its passwords in 2 safe places. Losing it blocks updates (Play App Signing can reset it, but do not rely on it). Reference it from `android/key.properties` (git-ignored) in `android/app/build.gradle.kts`.
- Build: `flutter build appbundle --release`. Test the same code with `flutter build apk --release --split-per-abi` on real phones.
- Permissions allowed in manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, `com.google.android.gms.permission.AD_ID`. Remove everything else. No storage/camera/location/contacts.
- Remove: Device Preview, debug banners, demo triggers (Level pill / Undo shortcuts), `kDebugMode` shortcuts, test ad IDs, `web/` folder.
- Replace runtime Google Fonts download with bundled Outfit font (offline first launch).
- Obfuscation optional: `--obfuscate --split-debug-info=build/symbols` (keep symbols for Crashlytics).
- Size target: under 40 MB AAB.

## 3. Play Console forms (answers for this app)
**App category:** Game > Puzzle. **Free app.** **Contains ads: Yes.** **No in-app purchases** (no billing). No subscriptions.
**Target audience and content:** Age groups **13+** (select 13-15, 16-17, 18+; do NOT select under 13). Not designed for children, no Families program.
**Content rating (IARC questionnaire):** no violence, no sexual content, no profanity, no gambling (the spin wheel was removed, gems are not money and cannot be bought), no user-generated content shared with others (nickname stays on device), no location sharing. Expect "Everyone"/PEGI 3 class results.
**News app / COVID / government / financial / health:** No.
**Data safety (draft):**
- Collected data: **Device or other IDs** (Advertising ID, via AdMob) - purpose: Advertising, Analytics; **App activity / diagnostics**: crash logs and performance (Firebase Crashlytics), app interactions (Firebase Analytics) - purpose: Analytics, App functionality.
- Shared with third parties: advertising ID with Google AdMob (ads).
- Data encrypted in transit: Yes. Users can request deletion: no account exists; data on device only (uninstall deletes). Say so.
- No personal info (name, email, phone, location, photos) is collected. Nickname/avatar are stored only on the device.
**Advertising ID declaration:** Yes, used for advertising (keep the AD_ID permission).
**Government apps / financial features / health:** none.

## 4. Policy rules that affect this app (and how we comply)
| Policy | What we do |
|---|---|
| **Ads: disruptive / misleading** | No ads on splash, consent, onboarding. No interstitial during gameplay. No fake close buttons, no ads shaped like game buttons. Native ad labelled "Ad" and separated from Claim button. |
| **Interstitial on launch** | None. First interstitial only after level 3. App Open ad only on return (>=4 h), never first session. |
| **Rewarded ads** | Always opt-in, text says exactly what you get ("Watch ad: +10 gems"), reward granted only after completion, daily cap 3 for gems. |
| **User consent / privacy** | Google UMP consent (EEA/UK/CH), privacy policy link in app (Settings) and in Play Console, Data safety accurate. |
| **Families / children** | Not applicable (13+). `tagForChildDirectedTreatment=false`, `tagForUnderAgeOfConsent=false`, `maxAdContentRating=T`. |
| **Simulated gambling** | No gambling-like mechanics (wheel removed). Gems have no cash value and cannot be bought. |
| **Intellectual property** | Original artwork and code. Do not copy competitor icons/screens/names. Check trademark for "Rainbow Pour" before submission. CC0 audio only, keep a credits list. Fonts: Outfit is OFL (ok). |
| **Deceptive behaviour / metadata** | Title (max 30 chars) without emojis/"best/#1/free"; screenshots show real gameplay; description matches features. |
| **Permissions** | Only INTERNET, ACCESS_NETWORK_STATE, AD_ID. |
| **User data** | No accounts. Firebase Analytics/Crashlytics are anonymous. Do not log nickname. |
| **Minimum functionality / stability** | No crashes on start; ANR free; test on low-end device; offline mode must still play. |
| **Payments** | No Google Play Billing used, no external payment links. |
| **Target API / 64-bit / AAB** | See section 2. |
| **Account (company)** | Organization account (D-U-N-S verified) is exempt from the 12-tester/14-day closed test rule that applies to new personal accounts; still run an internal test first. |

## 5. Store listing draft (English)
**Title (<=30):** `Rainbow Pour: Water Sort`
**Short description (<=80):** `Pour colorful liquids, sort the bottles and relax with a satisfying puzzle.`
**Full description:**
```
Rainbow Pour: Water Sort is a relaxing color sorting puzzle. Tap a bottle, pour the liquid into another one,
and sort every color until each bottle holds just one shade.

HOW TO PLAY
- Tap a bottle to lift its top color
- Pour it onto the same color or into an empty bottle
- Fill every bottle with a single color to win

FEATURES
- 500 levels that start easy and get more challenging
- Smooth pouring animations and calm sounds
- Undo, Hint and extra bottle helpers
- Daily Reward and a new Daily Challenge every day
- Collect gems and unlock new bottle shapes and backgrounds
- Works offline (ads need internet)
- Colorblind mode

The game contains ads. Watching optional rewarded ads gives you free gems.
```
Do not claim features that are not in the build (check against the final APK).

## 6. Release steps (order)
1. Finish Cursor prompts 1-13 (`docs/CURSOR_PROMPTS.md`). `flutter analyze` and tests green.
2. Replace test IDs with real AdMob/Firebase IDs (from sir). Set release flags.
3. Build AAB, install the APK variant on 3 real devices; run the manual checklist (BACKEND_THEORY section 7).
4. Sir: Play Console > Create app > fill forms (section 3) > upload privacy URL > Store listing > Upload AAB to **Internal testing** > add testers > verify install via Play.
5. Check **Pre-launch report** (crashes, accessibility, security warnings). Fix.
6. Promote to **Production**, countries chosen by sir, **staged rollout 10% -> 50% -> 100%**.
7. After launch: watch Crashlytics + Play Console vitals daily for a week, reply to reviews, plan updates (new levels, backgrounds, sounds).
8. Every update: bump versionCode, update "What's new", re-check Data safety if SDKs change.

## 7. Policy red flags to avoid
- Showing an ad before the consent form is answered.
- Ad right after app start, or an ad that appears when the user taps a game button.
- Claiming "no ads" anywhere (we removed Remove Ads).
- Using AdMob test ads in production or clicking own live ads.
- Copying another game's name/art. Using music without a licence.
- Missing privacy policy URL, wrong Data safety answers, unused permissions.
