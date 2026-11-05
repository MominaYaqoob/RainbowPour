import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ads/ad_service.dart';
import 'core/app_prefs.dart';
import 'core/audio_service.dart';
import 'core/colorblind.dart';
import 'core/haptics.dart';
import 'screens/splash/studio_splash.dart';
import 'widgets/background_theme.dart';
import 'widgets/bottle_shape.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Device frames and screen sizes in debug/profile; off in release builds.
  await BottleSkin.load();
  await BackgroundSkin.load();
  await Haptics.load();
  await AudioService.instance.load();
  await ColorblindMode.load();
  // Remember this launch time. A backwards clock must not stop the app.
  unawaited(
    AppPrefs.touchClock(DateTime.now()).catchError((Object _) => false),
  );
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const RainbowPourApp(),
    ),
  );
  // Returning players already agreed. First launch waits for ConsentScreen.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initAdsForReturningUser());
  });
}

Future<void> _initAdsForReturningUser() async {
  try {
    if (!await AppPrefs.isConsentDone()) return;
    await AdService.instance.initialize();
  } catch (error) {
    if (kDebugMode) debugPrint('AdService: $error');
  }
}

class RainbowPourApp extends StatelessWidget {
  const RainbowPourApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return MaterialApp(
      title: 'Rainbow Pour',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: base.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      ),
      home: const StudioSplash(),
    );
  }
}
