import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// A parchment-on-wood card used for menus, dialogs and HUD chips. Centralises
/// the storybook framing so every surface in the app shares one look.
class PlankPanel extends StatelessWidget {
  const PlankPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.tone = Hue.panel,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Hue.timberDeep, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// A small rounded chip for showing a labelled value (coins, stars, floors).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = Hue.gold,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Hue.panelDeep.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Hue.timberDeep, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 19),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Hue.parchment,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return GestureDetector(onTap: onTap, child: body);
  }
}

/// Circular icon button used for back / pause / settings.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tone = Hue.panelDeep,
    this.iconColor = Hue.parchment,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color tone;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      shape: const CircleBorder(side: BorderSide(color: Hue.timberDeep, width: 2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.52),
        ),
      ),
    );
  }
}
