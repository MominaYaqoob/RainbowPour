import 'ads_gateway.dart';
import 'mobile_ads_gateway_stub.dart'
    if (dart.library.io) 'mobile_ads_gateway.dart'
    as impl;

/// The real plugin on IO platforms, a throw-away stub on web.
AdsGateway loadAdsGateway() => impl.createMobileAdsGateway();
