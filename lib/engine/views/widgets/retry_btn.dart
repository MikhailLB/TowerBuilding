import 'dart:math' as math;

import 'package:flutter/material.dart';

class RetryButton extends StatelessWidget {
  final double width;
  final bool busy;
  final AnimationController press;
  final VoidCallback onTap;

  const RetryButton({
    super.key,
    required this.width,
    required this.busy,
    required this.press,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: AnimatedBuilder(
        animation: press,
        builder: (_, child) {
          final scale = 1.0 - 0.05 * press.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 3.8,
            child: CustomPaint(
              painter: RetryButtonPainter(pressed: press.value),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2A150A),
                          ),
                        ),
                      )
                    : const RetryLabel(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RetryLabel extends StatelessWidget {
  const RetryLabel();

  @override
  Widget build(BuildContext context) {
    const fontSize = 18.0;
    const outlineWidth = 2.2;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'RETRY',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF6E1F00),
          ),
        ),
        const Text(
          'RETRY',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
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

class RetryButtonPainter extends CustomPainter {
  final double pressed;
  const RetryButtonPainter({required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cr = h * 0.45;

    final outerRect = Rect.fromLTWH(0, 0, w, h);
    final outerRRect = RRect.fromRectAndRadius(
      outerRect.deflate(2),
      Radius.circular(cr),
    );
    final innerRRect = RRect.fromRectAndRadius(
      outerRect.deflate(h * 0.13),
      Radius.circular(cr * 0.85),
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14),
    );

    canvas.drawRRect(
      outerRRect.shift(Offset(0, h * 0.10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE7A0), Color(0xFF7A2A06)],
        ).createShader(outerRect),
    );

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD24A), Color(0xFFE0681A)],
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
            const Color(0xFFFFF6CC).withValues(alpha: 0.55),
            const Color(0xFFFFF6CC).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.55)),
    );
    canvas.restore();

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, h * 0.025)
        ..color = const Color(0xFF7A2A06).withValues(alpha: 0.85),
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, h * 0.018)
        ..color = const Color(0xFFFFE7A0).withValues(alpha: 0.75),
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
  bool shouldRepaint(covariant RetryButtonPainter old) =>
      old.pressed != pressed;
}
