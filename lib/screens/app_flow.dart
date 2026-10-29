import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/app_prefs.dart';
import 'consent/consent_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'profile/nickname_screen.dart';
import 'welcome/welcome_reward_screen.dart';

/// Which screen to open after the splash screens.
///
/// First launch order: Consent, Onboarding, Welcome gift, Nickname, Home.
/// Debug builds always start from Consent so every screen can be reviewed.
Future<Widget> entryScreen() async {
  if (kDebugMode) return const ConsentScreen();
  if (!await AppPrefs.isConsentDone()) return const ConsentScreen();
  if (!await AppPrefs.isOnboardingDone()) return const OnboardingScreen();
  if (!await AppPrefs.isWelcomeClaimed()) return const WelcomeRewardScreen();
  if (!await AppPrefs.isProfileDone()) return const NicknameScreen();
  return const HomeScreen();
}
