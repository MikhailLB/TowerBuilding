import 'package:flutter/material.dart';

import 'palette.dart';

/// Typography helpers. Deliberately built on the platform default font family
/// (no `google_fonts` runtime download) — weight, spacing and layered shadows
/// carry the storybook personality instead of a bespoke typeface.
class Lettering {
  Lettering._();

  static const _shadow = [
    Shadow(blurRadius: 0, color: Hue.timberDeep, offset: Offset(0, 2)),
    Shadow(blurRadius: 6, color: Color(0x66000000), offset: Offset(0, 3)),
  ];

  /// Big headline used for screen titles and the game-over banner.
  static TextStyle banner({double size = 34, Color color = Hue.parchment}) {
    return TextStyle(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.6,
      height: 1.05,
      shadows: _shadow,
    );
  }

  /// Medium heading for cards and section labels.
  static TextStyle heading({double size = 22, Color color = Hue.ink}) {
    return TextStyle(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    );
  }

  /// Button caption.
  static TextStyle caption({double size = 20, Color color = Colors.white}) {
    return TextStyle(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
  }

  /// Running text / descriptions.
  static TextStyle body({double size = 15, Color color = Hue.inkSoft}) {
    return TextStyle(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
  }

  /// Numeric readouts (population, floors) — tabular feel.
  static TextStyle figure({double size = 26, Color color = Hue.parchment}) {
    return TextStyle(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      shadows: const [
        Shadow(blurRadius: 5, color: Color(0x88000000), offset: Offset(0, 2)),
      ],
    );
  }
}
