import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';

/// An adaptive banner. It asks for an ad only when ads are allowed, takes no
/// space until then, keeps its height while the ad loads, and collapses if
/// the load fails. The ad is disposed with the widget.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _failed = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.adsReady.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (_ad != null || _starting || _failed) return;
    if (!AdService.instance.adsReady.value) return;
    _starting = true;
    // Standard 320x50 banner: a fixed, small height keeps Home and the level
    // map layouts stable (the adaptive sizes are taller).
    const size = AdSize.banner;
    final ad = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          if (kDebugMode) debugPrint('Banner: ${error.code} ${error.message}');
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
              _failed = true;
            });
          }
        },
      ),
    );
    setState(() {
      _ad = ad;
      _size = size;
    });
    await ad.load();
  }

  @override
  void dispose() {
    AdService.instance.adsReady.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final size = _size;
    if (_failed || ad == null || size == null) return const SizedBox.shrink();
    return SizedBox(
      width: size.width.toDouble(),
      height: size.height.toDouble(),
      child: _loaded ? AdWidget(ad: ad) : null,
    );
  }
}

/// One small native ad in a moon-night card. Shows nothing until the ad has
/// loaded and nothing at all if it fails (never an empty or fake card).
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key, required this.width});

  final double width;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdService.instance.adsReady.addListener(_maybeLoad);
    _maybeLoad();
  }

  void _maybeLoad() {
    if (_ad != null || !AdService.instance.adsReady.value) return;
    final ad = NativeAd(
      adUnitId: AdConfig.nativeId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: const Color(0xFF141B66),
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF3A2400),
          backgroundColor: const Color(0xFFFFC107),
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xCCFFFFFF),
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xCCFFFFFF),
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          if (kDebugMode) debugPrint('Native: ${error.code} ${error.message}');
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    AdService.instance.adsReady.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.width,
        maxWidth: widget.width,
        minHeight: 90,
        maxHeight: 120,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
