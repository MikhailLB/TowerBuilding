import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/type_scale.dart';

enum BtnTone { ember, plank, moss }

/// A carved-wood signpost button. The look is built entirely from gradients,
/// borders and an engraved-text effect — no bitmap button asset and no shared
/// widget library, so it doesn't match any template skin.
class StorybookButton extends StatefulWidget {
  const StorybookButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tone = BtnTone.ember,
    this.icon,
    this.width,
    this.height = 64,
    this.fontSize = 19,
  });

  final String label;
  final VoidCallback? onTap;
  final BtnTone tone;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;

  @override
  State<StorybookButton> createState() => _StorybookButtonState();
}

class _StorybookButtonState extends State<StorybookButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final colors = _toneColors(widget.tone);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _down
                    ? [colors.$2, colors.$3]
                    : [colors.$1, colors.$2],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Hue.timberDeep, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _down ? 0.22 : 0.38),
                  blurRadius: _down ? 4 : 11,
                  offset: Offset(0, _down ? 2 : 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: widget.fontSize + 4),
                  const SizedBox(width: 9),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Lettering.caption(size: widget.fontSize).copyWith(
                      shadows: const [
                        Shadow(color: Hue.timberDeep, offset: Offset(0, 2)),
                        Shadow(color: Color(0x55000000), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _toneColors(BtnTone tone) {
    switch (tone) {
      case BtnTone.ember:
        return (const Color(0xFFF0975A), Hue.ember, const Color(0xFFB24E20));
      case BtnTone.plank:
        return (const Color(0xFFB07C4A), Hue.timber, Hue.timberDeep);
      case BtnTone.moss:
        return (const Color(0xFF8FAE68), Hue.moss, const Color(0xFF4E6834));
    }
  }
}
