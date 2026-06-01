import 'package:flutter/widgets.dart';

import '../theme/asset_paths.dart';

/// Warms the Flutter image cache so the painted scene appears without a
/// first-frame flicker. Replaces the old Flame texture preloader — everything
/// now flows through the standard [AssetImage] pipeline.
class ImageBank {
  ImageBank._();

  static bool _warmed = false;

  static Future<void> warm(BuildContext context) async {
    if (_warmed) return;
    final paths = <String>[
      Art.sky,
      Art.street,
      Art.soil,
      Art.cloud,
      Art.crane,
      Art.foundation,
      Art.mark,
      Art.wordmark,
      ...Art.allHouses,
    ];
    for (final path in paths) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {
        // A missing optional asset must never block startup.
      }
    }
    _warmed = true;
  }
}
