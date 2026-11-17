# Rainbow Pour — 15 pending tasks

Status as of 2026-11-17: tasks 1-11 are done and committed (86437b8); Firebase Analytics + Crashlytics is added on top. Open: 13, 14, 15. See docs/PROJECT_GUIDE.md for the full picture and the audit findings.

- [x] **1. Level map real data** — 300 levels (not 30), real current/furthest level, real stars per level, scroll to current level, lock future levels.
- [x] **2. Profile/Stats real data** — show levels completed, total moves, total stars, best streak from `SaveData`.
- [x] **3. Daily Reward real logic** — 7-day state, one claim per local day (20/30/40/50/60/80/150), streak resets after a missed day, real streak banner.
- [x] **4. Clock protection** — remember last seen time; if the clock goes back, block claims and show `InfoDialog.clockChanged`.
- [x] **5. Daily Challenge level** — owner confirms bottles (25-28 vs 30), countdown vs count-up, time-up result; then challenge spec, 3 empty bottles, seed `yyyyMMdd`, 5-row layout.
- [x] **6. Daily Challenge timer and rewards** — timer chip, pause, time-up popup with retry, 30 gems + streak, weekly 40-gem bonus, real calendar.
- [x] **7. Ads setup and consent** — add `google_mobile_ads`, `AdConfig` with Google test IDs, AndroidManifest app id, UMP consent flow, Settings "Ad privacy options".
- [x] **8. Rewarded ads** — +10 gems (max 3/day), win 2x gems, +3 undos, free hint/+bottle, Daily Reward 2x, "not ready"/limit dialogs.
- [x] **9. Banner, native, interstitial** — banner on Home/Levels only, native ad in Daily Reward, interstitial rules (not first 3 levels, 1 per 3 levels, 90 s gap).
- [x] **10. Audio** — `AudioService`, sounds (pour, select, win, fail, tap) and music, Sound/Music switches, pause in background, placeholder assets.
- [x] **11. Colorblind mode** — distinct symbol on each liquid layer in `ConeBottle`; check the 20 colours on a phone.
- [x] **12. Review and links** — `in_app_review` after level 5 (max once per 30 days), `url_launcher` for Privacy Policy/Terms (needs URLs).
- [ ] **13. Phone testing** — Level Failed popup, extra-bottle flow, "Undo N moves" hint, 3-free-undos-then-ad popup, frame rate, haptics, hint speed.
- [ ] **14. Cleanup and docs** — (Settings demo section already removed) remove debug logs, update outdated docs, refresh `HANDOFF.md`.
- [ ] **15. Release** — keystore + `key.properties` (not committed), version, `flutter build appbundle --release`, universal APK, Play Console listing/Data safety/content rating/ads declaration.

**Only the owner can supply:** real AdMob IDs, Privacy Policy and Terms URLs, (optional) professional audio files, Play Console account.

**Later, optional:** difficulty plateau after level 100 (more scramble, honest `par`).

---

## Extra tasks from the audit (small steps)

### A. Manifest permissions (release relevant, about 45 min)
- [ ] A1 Build a release APK and read the RELEASE merged manifest (debug differs).
- [ ] A2 Find who adds each extra permission (`build/outputs/logs/manifest-merger-*.txt`): `WAKE_LOCK`, `FOREGROUND_SERVICE`, `BIND_GET_INSTALL_REFERRER_SERVICE`, `ACCESS_ADSERVICES_*`.
- [ ] A3 Decide per permission: keep (ads/Firebase need `AD_ID`, `ACCESS_ADSERVICES_*`, install referrer) or remove with `tools:node="remove"` (`WAKE_LOCK`, `FOREGROUND_SERVICE` if nothing needs them).
- [ ] A4 Add the removals, rebuild, verify the merged manifest, check audio and ads still work on a phone.
- [ ] A5 Update the permission list in `docs/RELEASE_AND_POLICY.md` and the Data safety / Advertising ID answers.

### B. Levels 100 to 300 feel the same, par too easy (about 3 to 4 hours)
- [ ] B1 Measure levels 100..300 (bottles, colours, capacity, par, par per full bottle) and write down what is constant.
- [ ] B2 Honest par: when the solver cannot finish (more than 14 colours), improve par with the beam search line instead of the reverse-shuffle length; verify it replays.
- [x] B3 DONE: owner chose the bottle wave (15 to 25 bottles).
- [x] B4 DONE: 10-level bottle wave from level 100 (`DifficultyCurve.waveBottles`), levels 1 to 99 unchanged.
- [x] B5 DONE: difficulty tests updated, generator test passes for all 300 levels.
- [ ] B6 Optional: mark hard levels on the level map.
- [ ] B7 Play 5 levels from each range in the browser and adjust.

### C. Colorblind symbols while a bottle is tilted (about 45 min)
- [ ] C1 Read `_paintTilted` in `cone_bottle.dart` (layer surfaces come from `_levelFor`, chord from `_chord`).
- [ ] C2 For each visible layer compute its band (its surface to the surface below) and the chord middle, and draw the symbol there upright.
- [ ] C3 Same skip rules as the upright case (band under 60% of a layer, symbol under 5.5 px).
- [ ] C4 Pixel test: tilted with symbols differs from tilted without; mode off stays identical.
- [ ] C5 Look at a tilted bottle in a temporary preview image and fix any overlap.

### D. Split `game_screen.dart` (about 1900 lines, about 5 to 6 hours, do after release)
Rule: one extraction at a time, analyze and all tests green after each, no behaviour change.
- [ ] D1 Safety net first: widget tests for select, pour, undo, hint cost, restart and the win popup path.
- [ ] D2 Move the painters and pose classes (`_FxPainter`, `_BottleLook`, `_PourPose`) to `game_fx.dart`.
- [ ] D3 Move the tutorial overlay and state to its own file.
- [ ] D4 Move the pour animation (`_pourPose`, `_pouringBottle`, `_pourDir`, controllers) to a `PourAnimator`.
- [ ] D5 Move the challenge logic (timer, clock tick, time up, retry, result dialogs) to a `ChallengeController`.
- [ ] D6 Move the popups (stuck, pause card) to `game_popups.dart`.
- [ ] D7 Move the ad and analytics helpers (`_watch`, `_doubleWin`, `_nextAfterAd`) to a helper.
- [ ] D8 Final browser walkthrough and update the file map in `docs/PROJECT_GUIDE.md`.
