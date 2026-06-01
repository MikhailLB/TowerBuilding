import 'package:flutter/widgets.dart';

/// Gray-gate full-screen artwork paths (portrait / landscape).
abstract final class GateAssets {
  static String noWifi(Orientation orientation) =>
      orientation == Orientation.landscape
          ? 'assets/additional_assets/no_wifi/16x9_no_wifi_screen.webp'
          : 'assets/additional_assets/no_wifi/9x16_no_wifi_screen.webp';

  static String notification(Orientation orientation) =>
      orientation == Orientation.landscape
          ? 'assets/additional_assets/notifications/16x9_notification.png'
          : 'assets/additional_assets/notifications/9x16_notification.png';
}
