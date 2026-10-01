import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final products = state.savedProducts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _SavedBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 22, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: isDark ? Colors.white : WasabiColors.dark,
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Text(
                          isUz ? 'Saqlanganlar' : 'Сохраненные',
                          style: const TextStyle(
                            color: WasabiColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF11180D) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? WasabiColors.primary.withValues(alpha: .24)
                                : Colors.transparent,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A678F07),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.favorite_border_rounded,
                              color: WasabiColors.primary,
                              size: 32,
                            ),
                            Positioned(
                              right: -3,
                              top: -7,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: WasabiColors.secondary,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? _SavedEmpty(isUz: isUz)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Saved products intentionally mirror the home grid.
                            const columns = 2;
                            return CustomScrollView(
                              slivers: [
                                SliverPadding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio:
                                          compactProductCardAspectRatio(
                                              context),
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => ProductCard(
                                        key: ValueKey(
                                            'saved-product-${products[index].id}'),
                                        product: products[index],
                                        compact: true,
                                      ),
                                      childCount: products.length,
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        36, 28, 36, 24),
                                    child: _SavedBenefits(isUz: isUz),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        46, 0, 36, 58),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.auto_awesome_rounded,
                                            color: Colors.white, size: 32),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Text(
                                            isUz
                                                ? 'Sevimli mahsulotlaringiz\nbir joyda saqlanadi'
                                                : 'Любимые продукты\nсохраняются в одном месте',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              height: 1.35,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.favorite_rounded,
                                            color: Colors.white, size: 32),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedBenefits extends StatelessWidget {
  const _SavedBenefits({required this.isUz});

  final bool isUz;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.verified_user_rounded,
        isUz ? 'Ishonchli\nsifat' : 'Надежное\nкачество'
      ),
      (
        Icons.star_rounded,
        isUz ? 'Sevimlilaringiz\nhar doim qo‘lda' : 'Любимые\nвсегда рядом'
      ),
      (
        Icons.shopping_bag_rounded,
        isUz ? 'Tez va oson\nbuyurtma' : 'Быстрый\nзаказ'
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: WasabiColors.primary.withValues(alpha: 0.10),
                  child:
                      Icon(items[i].$1, color: WasabiColors.primary, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  items[i].$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: WasabiColors.primary,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (i != items.length - 1)
            Container(
              width: 1,
              height: 58,
              color: const Color(0x1F678F07),
            ),
        ],
      ],
    );
  }
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty({required this.isUz});

  final bool isUz;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 0, 36, 180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 66,
              backgroundColor:
                  WasabiColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              child: const Icon(
                Icons.favorite_rounded,
                color: WasabiColors.primary,
                size: 66,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isUz ? 'Saqlanganlar bo‘sh' : 'Список пуст',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WasabiColors.primary,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedBackground extends StatefulWidget {
  const _SavedBackground();

  @override
  State<_SavedBackground> createState() => _SavedBackgroundState();
}

class _SavedBackgroundState extends State<_SavedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
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
                painter: _SavedBackgroundPainter(progress: .5, isDark: isDark),
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
                  _FloatingIcon(
                    icon: Icons.eco_rounded,
                    left: 0.80,
                    top: 0.20,
                    size: 20,
                    opacity: 0.34,
                    progress: progress,
                  ),
                  _FloatingIcon(
                    icon: Icons.eco_rounded,
                    left: 0.63,
                    top: 0.38,
                    size: 15,
                    opacity: 0.22,
                    progress: 1 - progress,
                  ),
                  _FloatingIcon(
                    icon: Icons.eco_rounded,
                    left: 0.84,
                    top: 0.55,
                    size: 18,
                    opacity: 0.24,
                    progress: progress,
                  ),
                  _FloatingIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: 0.88,
                    top: 0.13,
                    size: 15,
                    opacity: sparkle * 0.65,
                    progress: 0,
                  ),
                  _FloatingIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: 0.52,
                    top: 0.52,
                    size: 10,
                    opacity: sparkle * 0.30,
                    progress: 0,
                  ),
                  _FloatingDot(left: 0.72, top: 0.30, progress: progress),
                  _FloatingDot(left: 0.50, top: 0.58, progress: 1 - progress),
                  _FloatingDot(left: 0.86, top: 0.72, progress: progress),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SavedBackgroundPainter extends CustomPainter {
  const _SavedBackgroundPainter({
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
                Color(0xFF0D120A),
                Color(0xFF10180D),
              ]
            : const [
                Color(0xFFFFF9DA),
                Color(0xFFF9F8D8),
                Color(0xFFEFF6D7),
              ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    _drawLargeCircles(canvas, size);
    _drawProductGlow(canvas, size);
    _drawCurvedLine(canvas, size);
    _drawHeartWatermark(canvas, size);
    _drawWave(canvas, size);
    _drawShoppingBag(canvas, size);
  }

  void _drawLargeCircles(Canvas canvas, Size size) {
    final scale = 1 + progress * 0.03;
    final circles = [
      (Offset(size.width * .82, size.height * .30), size.width * .22, 0.045),
      (Offset(size.width * .52, size.height * .67), size.width * .18, 0.035),
      (Offset(size.width * .17, size.height * .72), size.width * .20, 0.040),
      (Offset(size.width * .86, size.height * .68), size.width * .21, 0.032),
    ];
    for (final circle in circles) {
      canvas.drawCircle(
        circle.$1,
        circle.$2 * scale,
        Paint()
          ..color = WasabiColors.primary.withValues(alpha: circle.$3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _drawProductGlow(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width * .26, size.height * .27),
      radius: size.width * .28,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.52),
            WasabiColors.primary.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  void _drawCurvedLine(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-size.width * .08, size.height * .58)
      ..cubicTo(size.width * .22, size.height * .50, size.width * .38,
          size.height * .64, size.width * .58, size.height * .46)
      ..cubicTo(size.width * .74, size.height * .31, size.width * .86,
          size.height * .42, size.width * 1.08, size.height * .36);
    canvas.drawPath(
      path,
      Paint()
        ..color = (isDark ? WasabiColors.primary : Colors.white).withValues(
          alpha: isDark ? 0.16 : 0.62,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
    );
  }

  void _drawHeartWatermark(Canvas canvas, Size size) {
    final center = Offset(
      size.width * .82,
      size.height * (.25 + (progress - .5) * .012),
    );
    final radius = size.width * (.165 + progress * .006);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = (isDark ? WasabiColors.primary : Colors.white).withValues(
          alpha: isDark ? 0.07 : 0.18,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      center,
      radius * .68,
      Paint()
        ..color = WasabiColors.primary.withValues(alpha: 0.035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(
      _heartPath(center, size.width * (.20 + progress * .01)),
      Paint()
        ..color = WasabiColors.primary.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  void _drawWave(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .89)
      ..cubicTo(size.width * .25, size.height * .86, size.width * .52,
          size.height * .94, size.width, size.height * .89)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = WasabiColors.primary.withValues(alpha: 0.055),
    );
  }

  void _drawShoppingBag(Canvas canvas, Size size) {
    final left = size.width * .68;
    final top = size.height * .72;
    final width = size.width * .25;
    final height = size.height * .12;
    final basketPaint = Paint()
      ..color = WasabiColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.3);
    final linePaint = Paint()
      ..color = WasabiColors.primary.withValues(alpha: 0.145)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    final body = Path()
      ..moveTo(left + width * .07, top + height * .30)
      ..lineTo(left + width * .93, top + height * .30)
      ..lineTo(left + width * .82, top + height)
      ..lineTo(left + width * .18, top + height)
      ..close();
    canvas.drawPath(body, basketPaint);
    canvas.drawPath(body, linePaint);

    final rim = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top + height * .18, width, height * .22),
      const Radius.circular(12),
    );
    canvas.drawRRect(rim, basketPaint);
    canvas.drawRRect(rim, linePaint);

    final handleRect = Rect.fromLTWH(
      left + width * .22,
      top - height * .30,
      width * .56,
      height * .62,
    );
    canvas.drawArc(
        handleRect, math.pi, math.pi, false, linePaint..strokeWidth = 7);

    for (final x in [.28, .44, .60, .76]) {
      canvas.drawLine(
        Offset(left + width * x, top + height * .42),
        Offset(left + width * (x - .04), top + height * .88),
        linePaint..strokeWidth = 4,
      );
    }

    final heartCenter = Offset(left + width * .50, top + height * .68);
    canvas.drawPath(
      _heartPath(heartCenter, width * .18),
      Paint()
        ..color = (isDark ? WasabiColors.primary : Colors.white).withValues(
          alpha: isDark ? 0.08 : 0.16,
        ),
    );
  }

  Path _heartPath(Offset center, double size) {
    final path = Path();
    final scale = size / 32;
    for (double t = 0; t <= math.pi * 2; t += 0.08) {
      final x = 16 * math.pow(math.sin(t), 3).toDouble();
      final y = -(13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t));
      if (t == 0) {
        path.moveTo(center.dx + x * scale, center.dy + y * scale);
      } else {
        path.lineTo(center.dx + x * scale, center.dy + y * scale);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _SavedBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
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
        offset: Offset(0, (progress - 0.5) * 12),
        child: Icon(
          icon,
          size: size,
          color: color.withValues(alpha: opacity),
          shadows: [
            Shadow(
              color: color.withValues(alpha: opacity * 0.20),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({
    required this.left,
    required this.top,
    required this.progress,
  });

  final double left;
  final double top;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Positioned(
      left: screen.width * left,
      top: screen.height * top,
      child: Transform.translate(
        offset: Offset(0, (progress - 0.5) * 8),
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: WasabiColors.primary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: WasabiColors.primary.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
