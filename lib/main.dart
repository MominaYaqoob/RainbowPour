import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash/studio_splash.dart';
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
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const RainbowPourApp(),
    ),
  );
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
