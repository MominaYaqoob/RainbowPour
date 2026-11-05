# Cursor prompt — Task 1: Level map with 300 levels, real progress and stars

Paste everything below the line into Cursor. Read `docs/HANDOFF.md` first.

---

## Goal
`lib/screens/levels/level_map_screen.dart` is still a UI demo: 30 nodes, a fixed "current level 8" and fake stars (`_stars` = `1 + level*7%3`). Make it use the **real saved progress** for all **300 levels**.

## Rules
- Change only `level_map_screen.dart` (and a new test file). Do not touch other screens, `AppPrefs`, `SaveData`, game logic or the look of the nodes (colours, sizes, gold path, PLAY badge, pulse). Keep the moon-night style.
- Do not run `git push` or destructive git commands.
- Reply in Roman Urdu, short. At the end say what you checked and what you did not.

## Data you must use (already exist)
- `AppPrefs.level()` -> `Future<int>`: the **furthest level the player can open** (starts at 1; after winning level N it becomes `N+1`, capped at 300 by `recordWin`).
- `AppPrefs.stars()` -> `Future<Map<int,int>>`: best stars 1..3 per won level. A level never won is missing from the map.
- `DifficultyCurve.maxLevel` (in `lib/game/difficulty.dart`) = 300. Use it, do not hardcode 300.

## Required changes
1. **Level count:** replace `static const _count = 30` with `DifficultyCurve.maxLevel`.
2. **Real progress:** remove `_current = 8`. Keep `int _current = 1` and `Map<int,int> _stars = {}` as state. Load both in `initState` via `AppPrefs.level()` and `AppPrefs.stars()`; call `setState` when loaded (check `mounted`). Show a node only after the data is loaded (a loader or an empty shell is fine, avoid a flash of level 1).
3. **Node states** (same as now, but from real data):
   - `level < _current` -> done (gold, shows its real stars; if a done level has no entry in the stars map show 0 filled stars, never crash).
   - `level == _current` -> current (blue, pulsing, PLAY badge).
   - `level > _current` -> locked.
   - Special case: if the player has beaten level 300 (`_current` is capped at 300 and `stars[300]` exists) show 300 as done, not current.
4. **Path colour:** `_PathPainter(points, _current - 1)` already colours the walked part gold; keep it. Make `shouldRepaint` return true when `doneUntil` changes (now it always returns false).
5. **Scroll to current level:** after the data loads, jump so the current level is visible near the middle. The list is `reverse: true` and level 1 is at the bottom, so the offset from the bottom is about `(_current - 3) * _gap`. Clamp to `0..maxScrollExtent`. Do it in a post-frame callback **after** `setState` with the loaded data (the current code runs it before the data exists). With 300 levels the content height is `300 * 96 + 140` = 28 940 px; this must scroll smoothly. Use `Stack` children only for nodes near the viewport if scrolling is janky; otherwise keep it simple.
6. **Tap rules:**
   - done or current -> open `GameScreen(level: level)` exactly as now.
   - locked -> keep `showSoon(context, 'Level $level')`, or better a small message "Finish level $_current first" using the existing `InfoDialog` style if it fits easily. Locked levels must **never** open the game.
7. **Refresh after playing:** `await Navigator.push(...)` on the game route, then reload `AppPrefs.level()` and `AppPrefs.stars()` and `setState`, so winning a level and coming back shows the new stars and the new current level without reopening the map.
8. Update the class doc comment (remove "UI only / sample data").

## Tests (add `test/screens/level_map_screen_test.dart`)
Use `SharedPreferences.setMockInitialValues({})` and `AppPrefs.resetForTest()` in `setUp`. Build the save with `SaveData` (see `lib/core/save_data.dart` and `test/core/*` for how), or call `AppPrefs.recordWin(...)` to set progress.
- Fresh save: level 1 is current, level 2 is locked, no stars shown.
- Save with level 5 furthest and stars {1:3, 2:2, 3:1, 4:3}: levels 1-4 done with the right star counts, level 5 current, level 6 locked.
- Tapping a locked level does not push `GameScreen`.
- The map builds 300 nodes (scroll to the top, find level 300).
Keep the test light (no real animations that never settle: use `pump(Duration)` not `pumpAndSettle` because the pulse repeats forever).

## Checks to run before you say done
```bash
flutter analyze
flutter test
```
Both must be clean. Then tell me: what changed, which files, test results, and anything you did not verify (for example real phone scrolling speed).
