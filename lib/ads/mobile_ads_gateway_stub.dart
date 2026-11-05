import 'ads_gateway.dart';

/// Web builds never load the ads plugin.
AdsGateway createMobileAdsGateway() =>
    throw UnsupportedError('Ads run on Android only.');
