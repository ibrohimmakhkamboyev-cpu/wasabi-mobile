import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/wasabi_opening/opening_timeline.dart';
import '../../theme/app_theme.dart';

class WessabiHomeOpeningScope extends InheritedWidget {
  const WessabiHomeOpeningScope({
    super.key,
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WessabiHomeOpeningScope>()
        ?.animation;
  }

  @override
  bool updateShouldNotify(WessabiHomeOpeningScope oldWidget) {
    return oldWidget.animation != animation;
  }
}

class WessabiEntrance extends StatelessWidget {
  const WessabiEntrance({super.key, required this.animation});

  static const duration = WasabiOpeningTimeline.duration;
  static const overlayKey = ValueKey('wessabi-entrance-overlay');
  static const logoKey = ValueKey('wessabi-entrance-logo');
  static const taglineKey = ValueKey('wessabi-entrance-brand');

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final logoFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(.58, .70, curve: Curves.easeOutCubic),
    );
    final logoScale = Tween<double>(begin: .82, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(.58, .72, curve: Curves.easeOutCubic),
      ),
    );
    final textFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(.64, .78, curve: Curves.easeOutCubic),
    );
    final exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(.965, 1, curve: Curves.easeInOutCubic),
      ),
    );

    return KeyedSubtree(
      key: WessabiEntrance.overlayKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _OpeningRevealClipper(animation),
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const RepaintBoundary(
                    child: CustomPaint(painter: _EntranceBackdropPainter()),
                  ),
                  CustomPaint(
                    painter: _EntrancePainter(animation),
                    willChange: true,
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final shortest = constraints.biggest.shortestSide;
                        final logoWidth = (shortest * .46).clamp(156.0, 232.0);
                        return FadeTransition(
                          opacity: exitFade,
                          child: RepaintBoundary(
                            child: Align(
                              alignment: const Alignment(0, -.04),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FadeTransition(
                                    opacity: logoFade,
                                    child: ScaleTransition(
                                      scale: logoScale,
                                      child: _LogoMark(
                                        key: WessabiEntrance.logoKey,
                                        width: logoWidth,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: (shortest * .035).clamp(12.0, 18.0),
                                  ),
                                  FadeTransition(
                                    opacity: textFade,
                                    child: RepaintBoundary(
                                      child: _BrandWordmark(
                                        key: WessabiEntrance.taglineKey,
                                        width: (shortest * .72)
                                            .clamp(250.0, 360.0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: _RevealEdgePainter(animation),
            willChange: true,
          ),
        ],
      ),
    );
  }
}

class _OpeningRevealClipper extends CustomClipper<Path> {
  _OpeningRevealClipper(this.animation) : super(reclip: animation);

  final Animation<double> animation;

  @override
  Path getClip(Size size) {
    final value = animation.value.clamp(0.0, 1.0);
    final progress =
        WasabiOpeningTimeline.homeReveal.transform(value.clamp(0.0, 1.0));
    final path = Path()
      ..addRect(Offset.zero & size)
      ..fillType = PathFillType.evenOdd;
    if (progress <= 0) return path;
    final center = Offset(-size.width * .08, size.height * 1.08);
    final farthestX = math.max(center.dx, size.width - center.dx);
    final farthestY = math.max(center.dy, size.height - center.dy);
    final maxRadius = math.sqrt(farthestX * farthestX + farthestY * farthestY);
    final radius = size.shortestSide * .34 + maxRadius * progress;
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(covariant _OpeningRevealClipper oldClipper) {
    return oldClipper.animation != animation;
  }
}

class _RevealEdgePainter extends CustomPainter {
  _RevealEdgePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final value = animation.value.clamp(0.0, 1.0);
    final progress =
        WasabiOpeningTimeline.homeReveal.transform(value.clamp(0.0, 1.0));
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(-size.width * .08, size.height * 1.08);
    final farthestX = math.max(center.dx, size.width - center.dx);
    final farthestY = math.max(center.dy, size.height - center.dy);
    final maxRadius = math.sqrt(farthestX * farthestX + farthestY * farthestY);
    final radius = size.shortestSide * .34 + maxRadius * progress;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * opacity
        ..color = const Color(0xFF94C719).withValues(alpha: .18 * opacity),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFD8FF5E).withValues(alpha: .62 * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _RevealEdgePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: WasabiColors.primary.withValues(alpha: .16),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * .30,
      child: RepaintBoundary(
        child: CustomPaint(painter: const _BrandWordmarkPainter()),
      ),
    );
  }
}

class _BrandWordmarkPainter extends CustomPainter {
  const _BrandWordmarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glowRect = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .46),
      width: size.width * .90,
      height: size.height * 1.15,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7FB80D).withValues(alpha: .28),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );
    _paintCenteredText(
      canvas,
      'WASABI',
      Offset(size.width * .5, size.height * .30),
      TextStyle(
        color: Colors.white,
        fontSize: size.height * .34,
        fontWeight: FontWeight.w900,
        letterSpacing: 7.5,
        height: 1,
        shadows: [
          Shadow(
            color: const Color(0xFF8AC414).withValues(alpha: .75),
            blurRadius: 8,
          ),
        ],
      ),
    );
    _paintCenteredText(
      canvas,
      'SUSHI',
      Offset(size.width * .5, size.height * .68),
      TextStyle(
        color: const Color(0xFF8AC414),
        fontSize: size.height * .26,
        fontWeight: FontWeight.w800,
        letterSpacing: 9,
        height: 1,
        shadows: [
          Shadow(
            color: const Color(0xFFBDF238).withValues(alpha: .70),
            blurRadius: 7,
          ),
        ],
      ),
    );
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width * .5, center.dy - painter.height * .5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EntrancePainter extends CustomPainter {
  _EntrancePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final value = animation.value.clamp(0.0, 1.0);
    final center = Offset(size.width * .5, size.height * .46);
    final shortest = size.shortestSide;

    _paintGreenGlow(canvas, size, center, value);
    _paintGreenMist(canvas, size, center, value);
    _paintDrop(canvas, center, size, value);
    _paintRipple(canvas, center, shortest, value);
    _paintIngredientSplash(canvas, center, shortest, value);
    _paintBrushCircle(canvas, center, size, shortest, value);
    _paintFloatingLeaves(canvas, center, shortest, value);
  }

  void _paintGreenGlow(Canvas canvas, Size size, Offset center, double value) {
    final reveal = WasabiOpeningTimeline.homeReveal.transform(value);
    final fade = 1 - reveal;
    if (fade <= 0) return;
    canvas.drawCircle(
      center,
      size.shortestSide * .62,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF8FB51A).withValues(alpha: .11 * fade),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: center,
          radius: size.shortestSide * .62,
        )),
    );
  }

  void _paintGreenMist(Canvas canvas, Size size, Offset center, double value) {
    final fade = (1 - _progress(value, .88, 1, Curves.easeOut)).clamp(0.0, 1.0);
    if (fade <= 0) return;
    final paint = Paint();
    for (var i = 0; i < 10; i++) {
      final a = i * 2.399 + value * 3.2;
      final d = size.shortestSide * (.08 + (i % 9) * .045);
      final p = center.translate(
        math.cos(a) * d * (1 + .16 * math.sin(value * 7 + i)),
        math.sin(a) * d * .92,
      );
      canvas.drawCircle(
        p,
        size.shortestSide * (.004 + (i % 4) * .002),
        paint
          ..color = const Color(0xFF7EA90D)
              .withValues(alpha: (.06 + (i % 5) * .02) * fade),
      );
    }
  }

  void _paintDrop(Canvas canvas, Offset impact, Size size, double value) {
    final drop = _progress(value, .056, .203, Curves.easeInCubic);
    final fade = _progress(value, .040, .070, Curves.easeOut) *
        (1 - _progress(value, .205, .285, Curves.easeIn));
    if (fade <= 0) return;
    final y = -size.height * .10 + (impact.dy + size.height * .045) * drop;
    final h = size.shortestSide * (.105 + .04 * drop);
    final rect = Rect.fromCenter(
      center: Offset(impact.dx, y),
      width: h * .62,
      height: h,
    );
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..cubicTo(rect.left, rect.top + rect.height * .34, rect.left,
          rect.bottom - rect.height * .18, rect.center.dx, rect.bottom)
      ..cubicTo(rect.right, rect.bottom - rect.height * .18, rect.right,
          rect.top + rect.height * .34, rect.center.dx, rect.top)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE7FF8A).withValues(alpha: fade),
            const Color(0xFF7FAE10).withValues(alpha: fade),
            const Color(0xFF375607).withValues(alpha: fade),
          ],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: rect.center.translate(-rect.width * .16, -rect.height * .1),
        width: rect.width * .2,
        height: rect.height * .32,
      ),
      Paint()..color = Colors.white.withValues(alpha: .35 * fade),
    );
  }

  void _paintRipple(
      Canvas canvas, Offset center, double shortest, double value) {
    final ripple = _progress(value, .175, .297, Curves.easeOutCubic);
    final fade = 1 - _progress(value, .300, .470, Curves.easeInOutCubic);
    if (ripple <= 0 || fade <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final radius = shortest * (.055 + ripple * (.24 + i * .10));
      canvas.drawCircle(
        center,
        radius,
        paint
          ..strokeWidth = 3 - i * .55
          ..color =
              WasabiColors.primary.withValues(alpha: (.48 - i * .11) * fade),
      );
    }
    final splash = _progress(value, .175, .297, Curves.easeOutBack) *
        (1 - _progress(value, .330, .470, Curves.easeIn));
    if (splash > 0) {
      final base = Rect.fromCenter(
        center: center.translate(0, shortest * .18),
        width: shortest * (.30 + splash * .55),
        height: shortest * (.08 + splash * .06),
      );
      canvas.drawOval(
        base,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFA5D91B).withValues(alpha: .70 * splash),
              const Color(0xFF365905).withValues(alpha: .22 * splash),
              Colors.transparent,
            ],
          ).createShader(base.inflate(shortest * .15)),
      );
      for (var i = 0; i < 9; i++) {
        final x = (i - 4) * shortest * .045;
        final h = shortest * (.10 + .05 * math.sin(i * 1.7));
        final path = Path()
          ..moveTo(center.dx + x, center.dy + shortest * .18)
          ..quadraticBezierTo(
              center.dx + x * 1.25,
              center.dy + shortest * (.08 - splash * .08),
              center.dx + x * 1.55,
              center.dy + shortest * .18 - h * splash);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = shortest * .010
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF93C915).withValues(alpha: .65 * splash),
        );
      }
    }
  }

  void _paintIngredientSplash(
      Canvas canvas, Offset center, double shortest, double value) {
    final explode = WasabiOpeningTimeline.ingredients.transform(value);
    final gather = WasabiOpeningTimeline.orbit.transform(value);
    final fade = _progress(value, .210, .300, Curves.easeOut) *
        (1 - _progress(value, .660, .780, Curves.easeInOutCubic));
    if (fade <= 0) return;

    final items = const [
      _FoodBit(kind: 0, angle: -.58, distance: .42, size: .108),
      _FoodBit(kind: 1, angle: .48, distance: .40, size: .105),
      _FoodBit(kind: 2, angle: 1.05, distance: .39, size: .090),
      _FoodBit(kind: 2, angle: 1.82, distance: .36, size: .080),
      _FoodBit(kind: 4, angle: 2.45, distance: .42, size: .060),
      _FoodBit(kind: 5, angle: 3.10, distance: .38, size: .046),
      _FoodBit(kind: 6, angle: 3.88, distance: .35, size: .060),
      _FoodBit(kind: 7, angle: 4.70, distance: .43, size: .038),
      _FoodBit(kind: 8, angle: 5.35, distance: .34, size: .046),
    ];

    for (final bit in items) {
      final orbit = bit.angle + value * math.pi * 1.8;
      final spread =
          shortest * bit.distance * (0.45 + explode) * (1 - gather * .88);
      final offset = Offset(math.cos(orbit), math.sin(orbit)) * spread;
      final bitCenter = center + offset;
      canvas.save();
      canvas.translate(bitCenter.dx, bitCenter.dy);
      canvas.rotate(orbit + gather * math.pi);
      _paintFoodBit(canvas, bit.kind, shortest * bit.size, fade);
      canvas.restore();
    }

    final sesamePaint = Paint()
      ..color = const Color(0xFFE8C56B).withValues(alpha: fade);
    for (var i = 0; i < 8; i++) {
      final a = i * .9 + value * 5;
      final d = shortest * (.05 + .28 * explode * (1 - gather));
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(math.cos(a), math.sin(a)) * d,
          width: shortest * .008,
          height: shortest * .017,
        ),
        sesamePaint,
      );
    }
  }

  void _paintFoodBit(Canvas canvas, int kind, double s, double opacity) {
    final paint = Paint()..isAntiAlias = true;
    switch (kind) {
      case 0:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, s * .16), width: s * 1.30, height: s * .62),
            Radius.circular(s * .18),
          ),
          paint..color = Colors.white.withValues(alpha: opacity),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, -s * .12), width: s * 1.55, height: s),
            Radius.circular(s * .18),
          ),
          paint..color = const Color(0xFFFF8F6F).withValues(alpha: opacity),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: s * 1.1, height: s * .62),
            Radius.circular(s * .14),
          ),
          paint..color = const Color(0xFFFFC9B2).withValues(alpha: opacity),
        );
      case 1:
        canvas.drawCircle(Offset.zero, s * .56,
            paint..color = const Color(0xFF202020).withValues(alpha: opacity));
        canvas.drawCircle(Offset.zero, s * .40,
            paint..color = Colors.white.withValues(alpha: opacity));
        canvas.drawCircle(Offset(s * .05, 0), s * .23,
            paint..color = const Color(0xFFFF7A63).withValues(alpha: opacity));
      case 2:
        final shrimp = Path()
          ..moveTo(-s * .52, 0)
          ..quadraticBezierTo(0, -s * .68, s * .52, -s * .1)
          ..quadraticBezierTo(s * .08, s * .48, -s * .52, 0)
          ..close();
        canvas.drawPath(shrimp,
            paint..color = const Color(0xFFFFA06F).withValues(alpha: opacity));
        canvas.drawCircle(Offset(s * .48, -s * .13), s * .12,
            paint..color = Colors.white.withValues(alpha: opacity));
      case 3:
        canvas.drawCircle(Offset.zero, s * .42,
            paint..color = Colors.white.withValues(alpha: opacity));
      case 4:
      case 6:
        final leaf = Path()
          ..moveTo(0, -s * .65)
          ..quadraticBezierTo(-s * .62, 0, 0, s * .68)
          ..quadraticBezierTo(s * .62, 0, 0, -s * .65)
          ..close();
        canvas.drawPath(leaf,
            paint..color = const Color(0xFF5B8E12).withValues(alpha: opacity));
      default:
        canvas.drawCircle(Offset.zero, s * .28,
            paint..color = const Color(0xFFB7D647).withValues(alpha: opacity));
    }
  }

  void _paintBrushCircle(
      Canvas canvas, Offset center, Size size, double shortest, double value) {
    final draw = WasabiOpeningTimeline.brush.transform(value);
    final expand = WasabiOpeningTimeline.homeReveal.transform(value);
    if (draw <= 0) return;
    final baseRadius = shortest * .34;
    final radius = baseRadius * (1 + expand * .28);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = shortest * (.032 + .022 * (1 - expand))
      ..color = const Color(0xFFBDF238).withValues(alpha: .24 * (1 - expand));
    canvas.drawArc(rect, -math.pi * .58, math.pi * 2 * draw, false, glow);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = shortest * (.013 + .016 * (1 - expand))
      ..shader = SweepGradient(
        startAngle: -math.pi * .55,
        endAngle: math.pi * 1.45,
        colors: [
          Colors.transparent,
          const Color(0xFFBDF238).withValues(alpha: .82 * (1 - expand * .45)),
          WasabiColors.primary.withValues(alpha: .95),
          const Color(0xFFBDF238).withValues(alpha: .62),
        ],
        stops: const [0, .16, .62, 1],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi * .58, math.pi * 2 * draw, false, paint);
    for (var i = 0; i < 3; i++) {
      final inset = shortest * (.018 + i * .028);
      canvas.drawArc(
        rect.deflate(inset),
        -math.pi * (.56 - i * .03),
        math.pi * 2 * draw * (.92 - i * .08),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = shortest * (.004 + i * .001)
          ..color = const Color(0xFFD8FF5E)
              .withValues(alpha: (.55 - i * .12) * (1 - expand)),
      );
    }
  }

  void _paintFloatingLeaves(
      Canvas canvas, Offset center, double shortest, double value) {
    final fade = _progress(value, .58, .74, Curves.easeOut) *
        (1 - _progress(value, .88, 1, Curves.easeInOut));
    if (fade <= 0) return;
    for (var i = 0; i < 4; i++) {
      final a = i * .92 + value * 1.2;
      final d = shortest * (.23 + (i % 3) * .05);
      final p = center + Offset(math.cos(a), math.sin(a)) * d;
      canvas.save();
      canvas.translate(p.dx, p.dy + math.sin(value * 8 + i) * 5);
      canvas.rotate(a);
      _paintFoodBit(canvas, 4, shortest * .025, fade * .65);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EntrancePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// The opening backdrop never changes. Keeping it out of the animated painter
/// lets Flutter cache it instead of rebuilding its full-screen gradient on
/// every animation frame.
class _EntranceBackdropPainter extends CustomPainter {
  const _EntranceBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.18),
          radius: .95,
          colors: [
            Color(0xFFFFF4BF),
            WasabiColors.background,
            Color(0xFFF3F8D7),
          ],
          stops: [0, .58, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _EntranceBackdropPainter oldDelegate) => false;
}

class _FoodBit {
  const _FoodBit({
    required this.kind,
    required this.angle,
    required this.distance,
    required this.size,
  });

  final int kind;
  final double angle;
  final double distance;
  final double size;
}

double _progress(double value, double begin, double end, Curve curve) {
  final normalized = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(normalized);
}
