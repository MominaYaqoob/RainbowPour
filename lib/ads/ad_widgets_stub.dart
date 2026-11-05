import 'package:flutter/widgets.dart';

/// Web builds show no banner.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Web builds show no native ad.
class NativeAdCard extends StatelessWidget {
  const NativeAdCard({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
