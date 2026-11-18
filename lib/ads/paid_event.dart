import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_service.dart';

/// Reports an ad's revenue to Firebase as `ad_impression`. Android only (it
/// imports the ads plugin), so it is used by the IO gateway and widgets.
OnPaidEventCallback paidEventLogger({
  required String format,
  required String unit,
}) {
  return (ad, valueMicros, precision, currencyCode) {
    AnalyticsService.instance.adImpression(
      format: format,
      unit: unit,
      valueMicros: valueMicros,
      currency: currencyCode,
    );
  };
}
