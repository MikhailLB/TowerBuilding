import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ButtonVariant { gold, slate }

class ButtonPalette {
  final Color innerStart;
  final Color innerEnd;
  final Color rimDark;
  final Color rimLight;
  final Color highlight;
  final Color glow;
  final Color textColor;
  final Color textStroke;

  const ButtonPalette({
    required this.innerStart,
    required this.innerEnd,
    required this.rimDark,
    required this.rimLight,
    required this.highlight,
    required this.glow,
    required this.textColor,
    required this.textStroke,
  });

  factory ButtonPalette.of(ButtonVariant v) {
    switch (v) {
      case ButtonVariant.gold:
        return const ButtonPalette(
          innerStart: Color(0xFFFFD24A),
          innerEnd: Color(0xFFE0681A),
          rimDark: Color(0xFF7A2A06),
          rimLight: Color(0xFFFFE7A0),
          highlight: Color(0xFFFFF6CC),
          glow: Color(0xFFFFB74D),
          textColor: Color(0xFFFFFFFF),
          textStroke: Color(0xFF6E1F00),
        );
      case ButtonVariant.slate:
        return const ButtonPalette(
          innerStart: Color(0xFF3C4860),
          innerEnd: Color(0xFF1F2738),
          rimDark: Color(0xFF0B0F1A),
          rimLight: Color(0xFFD5A24A),
          highlight: Color(0xFFB8C4DA),
          glow: Color(0xFF6B7B98),
          textColor: Color(0xFFFFEAB8),
          textStroke: Color(0xFF1A1208),
        );
    }
  }
}

class ActionPlate extends StatefulWidget {
  final double width;
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;
  final ButtonVariant variant;
  final AnimationController shimmer;
  final AnimationController pulse;
  final double aspectRatio;

  const ActionPlate({
    super.key,
    required this.width,
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
    required this.variant,
    required this.shimmer,
    required this.pulse,
    this.aspectRatio = 4.4,
  });

  @override
  State<ActionPlate> createState() => _ActionPlateState();
}

class _ActionPlateState extends State<ActionPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _interactive => widget.enabled && !widget.busy;

  Future<void> _onTap() async {
    if (!_interactive) return;
    await _press.forward();
    await _press.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ButtonPalette.of(widget.variant);
    final plateHeight = widget.width / widget.aspectRatio;
    final fontSize = (plateHeight * 0.46).clamp(14.0, 30.0);
    final isHero = widget.variant == ButtonVariant.gold;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, widget.shimmer, widget.pulse]),
        builder: (_, unused) {
          final scale = 1.0 - 0.04 * _press.value;
          final pulseT = isHero ? widget.pulse.value : 0.0;
          return Opacity(
            opacity: _interactive ? 1.0 : 0.55,
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.width,
                child: AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: CustomPaint(
                    painter: ActionPlatePainter(
                      palette: palette,
                      shimmer: widget.shimmer.value,
                      pulse: pulseT,
                      pressed: _press.value,
                      hero: isHero,
                    ),
                    child: Center(
                      child: widget.busy
                          ? SizedBox(
                              width: fontSize + 6,
                              height: fontSize + 6,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.textColor,
                                ),
                              ),
                            )
                          : StrokedLabel(
                              label: widget.label,
                              fontSize: fontSize,
                              color: palette.textColor,
                              stroke: palette.textStroke,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StrokedLabel extends StatelessWidget {
  final String label;
  final double fontSize;
  final Color color;
  final Color stroke;

  const StrokedLabel({
    super.key,
    required this.label,
    required this.fontSize,
    required this.color,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    final outlineWidth = math.max(2.0, fontSize * 0.12);
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: const [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActionPlatePainter extends CustomPainter {
  final ButtonPalette palette;
  final double shimmer;
  final double pulse;
  final double pressed;
  final bool hero;

  ActionPlatePainter({
    required this.palette,
    required this.shimmer,
    required this.pulse,
    required this.pressed,
    required this.hero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cornerRadius = h * 0.45;

    final outerRect = Rect.fromLTWH(0, 0, w, h);
    final outerRRect = RRect.fromRectAndRadius(
      outerRect.deflate(2),
      Radius.circular(cornerRadius),
    );
    final innerRRect = RRect.fromRectAndRadius(
      outerRect.deflate(h * 0.13),
      Radius.circular(cornerRadius * 0.85),
    );

    if (hero) {
      final glowAlpha = 0.30 + 0.25 * pulse;
      final glowPaint = Paint()
        ..color = palette.glow.withValues(alpha: glowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, 16 + 6 * pulse);
      canvas.drawRRect(outerRRect, glowPaint);
    }

    canvas.drawRRect(
      outerRRect.shift(Offset(0, h * 0.10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.rimLight, palette.rimDark],
        ).createShader(outerRect),
    );

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.innerStart, palette.innerEnd],
        ).createShader(outerRect),
    );

    canvas.save();
    canvas.clipRRect(innerRRect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.55),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.highlight.withValues(alpha: 0.55),
            palette.highlight.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.55)),
    );

    final shimmerPos = (shimmer * 1.6) - 0.3;
    final cx = w * shimmerPos;
    canvas.drawRect(
      Rect.fromLTWH(-w, -h, w * 3, h * 3),
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [
            Colors.transparent,
            palette.highlight.withValues(alpha: hero ? 0.40 : 0.18),
            Colors.transparent,
          ],
          stops: const [0.46, 0.5, 0.54],
        ).createShader(
          Rect.fromCenter(
            center: Offset(cx, h * 0.5),
            width: w * 1.4,
            height: h,
          ),
        ),
    );
    canvas.restore();

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, h * 0.025)
        ..color = palette.rimDark.withValues(alpha: 0.85),
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, h * 0.018)
        ..color = palette.rimLight.withValues(alpha: 0.75),
    );

    if (pressed > 0) {
      canvas.save();
      canvas.clipRRect(innerRRect);
      canvas.drawColor(
        Colors.black.withValues(alpha: 0.12 * pressed),
        BlendMode.srcOver,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ActionPlatePainter old) =>
      old.shimmer != shimmer ||
      old.pulse != pulse ||
      old.pressed != pressed ||
      old.hero != hero ||
      old.palette != palette;
}
