# Rainbow Pour — 15 pending tasks

Status as of commit 179cc5e. Mark `[x]` when done. Do one task at a time.

- [ ] **1. Level map real data** — 300 levels (not 30), real current/furthest level, real stars per level, scroll to current level, lock future levels.
- [ ] **2. Profile/Stats real data** — show levels completed, total moves, total stars, best streak from `SaveData`.
- [ ] **3. Daily Reward real logic** — 7-day state, one claim per local day (20/30/40/50/60/80/150), streak resets after a missed day, real streak banner.
- [ ] **4. Clock protection** — remember last seen time; if the clock goes back, block claims and show `InfoDialog.clockChanged`.
- [ ] **5. Daily Challenge level** — owner confirms bottles (25-28 vs 30), countdown vs count-up, time-up result; then challenge spec, 3 empty bottles, seed `yyyyMMdd`, 5-row layout.
- [ ] **6. Daily Challenge timer and rewards** — timer chip, pause, time-up popup with retry, 30 gems + streak, weekly 40-gem bonus, real calendar.
- [ ] **7. Ads setup and consent** — add `google_mobile_ads`, `AdConfig` with Google test IDs, AndroidManifest app id, UMP consent flow, Settings "Ad privacy options".
- [ ] **8. Rewarded ads** — +10 gems (max 3/day), win 2x gems, +3 undos, free hint/+bottle, Daily Reward 2x, "not ready"/limit dialogs.
- [ ] **9. Banner, native, interstitial** — banner on Home/Levels only, native ad in Daily Reward, interstitial rules (not first 3 levels, 1 per 3 levels, 90 s gap).
- [ ] **10. Audio** — `AudioService`, sounds (pour, select, win, fail, tap) and music, Sound/Music switches, pause in background, placeholder assets.
- [ ] **11. Colorblind mode** — distinct symbol on each liquid layer in `ConeBottle`; check the 20 colours on a phone.
- [ ] **12. Review and links** — `in_app_review` after level 5 (max once per 30 days), `url_launcher` for Privacy Policy/Terms (needs URLs).
- [ ] **13. Phone testing** — Level Failed popup, extra-bottle flow, "Undo N moves" hint, 3-free-undos-then-ad popup, frame rate, haptics, hint speed.
- [ ] **14. Cleanup and docs** — delete Settings "UI PREVIEW (DEMO ONLY)", remove debug logs, update outdated docs, refresh `HANDOFF.md`.
- [ ] **15. Release** — keystore + `key.properties` (not committed), version, `flutter build appbundle --release`, universal APK, Play Console listing/Data safety/content rating/ads declaration.

**Only the owner can supply:** real AdMob IDs, Privacy Policy and Terms URLs, audio files, Play Console account.

**Later, optional:** difficulty plateau after level 100 (more scramble, honest `par`).
