import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class WasabiPageBackground extends StatefulWidget {
  const WasabiPageBackground({super.key, this.animate = false});

  final bool animate;

  @override
  State<WasabiPageBackground> createState() => _WasabiPageBackgroundState();
}

class _WasabiPageBackgroundState extends State<WasabiPageBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = .5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WasabiPageBackgroundPainter(
                  // Large blurred artwork is intentionally static. Repainting
                  // it at 60fps was the main source of scroll and transition
                  // stutter on lower-powered devices.
                  progress: .5,
                  isDark: isDark,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeInOut.transform(_controller.value);
              final sparkle = 0.3 +
                  0.7 * (0.5 + 0.5 * math.sin(_controller.value * math.pi * 4));
              return Stack(
                children: [
                  _FloatingBackgroundIcon(
                    icon: Icons.eco_rounded,
                    left: .76,
                    top: .14,
                    size: 21,
                    opacity: .30,
                    progress: progress,
                  ),
                  _FloatingBackgroundIcon(
                    icon: Icons.eco_rounded,
                    left: .27,
                    top: .40,
                    size: 20,
                    opacity: .26,
                    progress: 1 - progress,
                  ),
                  _FloatingBackgroundIcon(
                    icon: Icons.eco_rounded,
                    left: .74,
                    top: .65,
                    size: 22,
                    opacity: .27,
                    progress: progress,
                  ),
                  _FloatingBackgroundIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: .82,
                    top: .11,
                    size: 15,
                    opacity: sparkle * .42,
                    progress: 0,
                  ),
                  _FloatingBackgroundIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: .66,
                    top: .56,
                    size: 17,
                    opacity: sparkle * .50,
                    progress: 0,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WasabiPageBackgroundPainter extends CustomPainter {
  const _WasabiPageBackgroundPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF090909),
                Color(0xFF0B0D09),
                Color(0xFF0E140A),
              ]
            : const [
                Color(0xFFFFF9DA),
                Color(0xFFF8F7D5),
                Color(0xFFE9F6D2),
              ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    _drawGlows(canvas, size);
    _drawCurves(canvas, size);
    _drawPlant(canvas, size);
    _drawWaves(canvas, size);
  }

  void _drawGlows(Canvas canvas, Size size) {
    final circles = [
      (Offset(size.width * .78, size.height * .18), size.width * .25, .048),
      (Offset(size.width * .18, size.height * .45), size.width * .28, .038),
      (Offset(size.width * .78, size.height * .76), size.width * .36, .045),
    ];
    for (final circle in circles) {
      final rect = Rect.fromCircle(
        center: circle.$1,
        radius: circle.$2 * (1 + progress * .025),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              WasabiColors.primary.withValues(alpha: circle.$3),
              Colors.transparent,
            ],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  void _drawCurves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? WasabiColors.primary : Colors.white)
          .withValues(alpha: isDark ? .075 : .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final first = Path()
      ..moveTo(-size.width * .05, size.height * .28)
      ..cubicTo(
        size.width * .16,
        size.height * .48,
        size.width * .34,
        size.height * .30,
        size.width * .45,
        size.height * .58,
      )
      ..cubicTo(
        size.width * .56,
        size.height * .84,
        size.width * .82,
        size.height * .46,
        size.width * 1.06,
        size.height * .54,
      );
    canvas.drawPath(first, paint);

    final second = Path()
      ..moveTo(-size.width * .08, size.height * .86)
      ..cubicTo(
        size.width * .30,
        size.height * .75,
        size.width * .45,
        size.height * .96,
        size.width * .68,
        size.height * .90,
      )
      ..cubicTo(
        size.width * .86,
        size.height * .85,
        size.width * .86,
        size.height * .78,
        size.width * 1.08,
        size.height * .76,
      );
    canvas.drawPath(
      second,
      paint
        ..color = (isDark ? WasabiColors.primary : Colors.white)
            .withValues(alpha: isDark ? .060 : .45),
    );
  }

  void _drawPlant(Canvas canvas, Size size) {
    final opacityScale = isDark ? .45 : 1.0;
    final trunkPaint = Paint()
      ..color = WasabiColors.primary.withValues(alpha: .17 * opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final twigPaint = Paint()
      ..color = WasabiColors.primary.withValues(alpha: .14 * opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trunk = Path()
      ..moveTo(-size.width * .02, size.height * .96)
      ..cubicTo(
        size.width * .02,
        size.height * .91,
        size.width * .035,
        size.height * .84,
        size.width * .075,
        size.height * .78,
      )
      ..cubicTo(
        size.width * .105,
        size.height * .72,
        size.width * .13,
        size.height * .68,
        size.width * .16,
        size.height * .63,
      );
    canvas.drawPath(trunk, trunkPaint);

    final lowerLeftTwig = Path()
      ..moveTo(size.width * .052, size.height * .83)
      ..cubicTo(
        size.width * .03,
        size.height * .815,
        size.width * .01,
        size.height * .805,
        0,
        size.height * .79,
      );
    final middleRightTwig = Path()
      ..moveTo(size.width * .075, size.height * .78)
      ..cubicTo(
        size.width * .11,
        size.height * .775,
        size.width * .145,
        size.height * .76,
        size.width * .18,
        size.height * .75,
      );
    final upperLeftTwig = Path()
      ..moveTo(size.width * .115, size.height * .70)
      ..cubicTo(
        size.width * .095,
        size.height * .69,
        size.width * .07,
        size.height * .68,
        size.width * .055,
        size.height * .67,
      );
    final upperRightTwig = Path()
      ..moveTo(size.width * .135, size.height * .675)
      ..cubicTo(
        size.width * .16,
        size.height * .675,
        size.width * .185,
        size.height * .665,
        size.width * .205,
        size.height * .66,
      );
    canvas
      ..drawPath(lowerLeftTwig, twigPaint)
      ..drawPath(middleRightTwig, twigPaint)
      ..drawPath(upperLeftTwig, twigPaint)
      ..drawPath(upperRightTwig, twigPaint);

    _drawLeaf(
      canvas,
      Offset(0, size.height * .79),
      -.78,
      size.width * .068,
      opacity: .14,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * .18, size.height * .75),
      .82,
      size.width * .072,
      opacity: .17,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * .055, size.height * .67),
      -.58,
      size.width * .058,
      opacity: .15,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * .205, size.height * .66),
      .68,
      size.width * .056,
      opacity: .16,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * .16, size.height * .63),
      .08,
      size.width * .064,
      opacity: .18,
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Offset base,
    double rotation,
    double length, {
    required double opacity,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        length * .28,
        -length * .18,
        length * .42,
        -length * .60,
        0,
        -length,
      )
      ..cubicTo(
        -length * .42,
        -length * .60,
        -length * .28,
        -length * .18,
        0,
        0,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = WasabiColors.primary.withValues(
          alpha: opacity * (isDark ? .45 : 1.0),
        ),
    );
    canvas.drawLine(
      Offset(0, -length * .08),
      Offset(0, -length * .82),
      Paint()
        ..color = WasabiColors.primary.withValues(
          alpha: .08 * (isDark ? .45 : 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawWaves(Canvas canvas, Size size) {
    final opacityScale = isDark ? .55 : 1.0;
    final first = Path()
      ..moveTo(0, size.height * .86)
      ..cubicTo(
        size.width * .26,
        size.height * .79,
        size.width * .50,
        size.height * .94,
        size.width,
        size.height * .83,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      first,
      Paint()
        ..color = WasabiColors.primary.withValues(alpha: .070 * opacityScale),
    );
    final second = Path()
      ..moveTo(0, size.height * .92)
      ..cubicTo(
        size.width * .30,
        size.height * .84,
        size.width * .55,
        size.height * 1.02,
        size.width,
        size.height * .94,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      second,
      Paint()
        ..color = WasabiColors.primary.withValues(alpha: .085 * opacityScale),
    );
  }

  @override
  bool shouldRepaint(covariant _WasabiPageBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

class _FloatingBackgroundIcon extends StatelessWidget {
  const _FloatingBackgroundIcon({
    required this.icon,
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
    required this.progress,
  });

  final IconData icon;
  final double left;
  final double top;
  final double size;
  final double opacity;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final color = icon == Icons.auto_awesome_rounded
        ? WasabiColors.secondary
        : WasabiColors.primary;
    return Positioned(
      left: screen.width * left,
      top: screen.height * top,
      child: Transform.translate(
        offset: Offset(0, (progress - .5) * 12),
        child: Icon(
          icon,
          color: color.withValues(alpha: opacity),
          size: size,
          shadows: [
            Shadow(
              color: color.withValues(alpha: opacity * .25),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
