import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/info_dialog.dart';

/// Every web address the app opens. The owner supplies the two policy pages.
abstract final class AppLinks {
  /// TODO(owner): the public Privacy Policy page. Empty until it exists; the
  /// app then says "coming soon" instead of opening a blank page.
  static const privacyPolicyUrl = '';

  /// TODO(owner): the public Terms of Service page. Same rule as above.
  static const termsUrl = '';

  /// The game's Google Play page.
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.gamezium.rainbowpour';

  /// Opens a link. Tests replace this with a fake.
  static Future<bool> Function(Uri url) launcher = (url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  /// Opens [url] in the browser (or the Play Store app for a store link).
  ///
  /// An empty [url] shows "coming soon" and never calls the launcher. A page
  /// that cannot be opened shows a short message. Never throws.
  static Future<bool> open(
    BuildContext context,
    String url, {
    required String title,
  }) async {
    final uri = url.isEmpty ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      await InfoDialog.show(
        context,
        icon: Icons.link_rounded,
        title: title,
        message: 'This page is coming soon.',
      );
      return false;
    }
    var opened = false;
    try {
      opened = await launcher(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      await InfoDialog.show(
        context,
        icon: Icons.link_off_rounded,
        title: title,
        message: 'The page could not be opened. Check your connection.',
      );
    }
    return opened;
  }
}
