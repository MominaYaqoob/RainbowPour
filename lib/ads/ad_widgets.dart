/// `BannerAdSlot` and `NativeAdCard`. Web builds get empty stand-ins, so the
/// ads plugin is never loaded there.
library;

export 'ad_widgets_stub.dart' if (dart.library.io) 'ad_widgets_io.dart';
