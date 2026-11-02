# UI complete: notes for the logic step (Cursor)

All screens are built. What is demo-only and must be replaced or removed:

- `lib/screens/game/sample_board.dart`: fake board per level. Replace with the generator/solver.
- `GameScreen`: Level pill opens Level Complete, Undo opens Level Failed, Hint shows a 2 s glow on the first filled and last empty bottle, "Preparing level" overlay is a fixed 900 ms. Wire to the real engine, then remove the demo triggers.
- `ConeBottle` takes `capacity` (4 to 6); layer colours: 12 ids in `AppColors.liquid`.
- Backgrounds: `BackgroundTheme` (6 themes, new one every 20 levels in Auto) and `BackgroundSkin` (pref `bg_mode`, -1 = Auto). Home and Game use `BackgroundSkin.themeFor(level)`. Shop buy/own state is not saved yet (only price 0 is "owned").
- Shop Gems tab: "Watch ad +10 gems, 3/day" uses a local counter. Replace with the Ad service + daily counter in the save data.
- `InfoDialog` (`lib/widgets/info_dialog.dart`): adNotReady, dailyLimit, clockChanged, extraUndo. Settings "UI PREVIEW (DEMO ONLY)" section opens them; delete that section before release.
- `NativeAdPlaceholder` on Daily Reward: replace with the AdMob native ad (keep the "Ad" label).
- No real-money purchases or Remove Ads anywhere in the UI.
