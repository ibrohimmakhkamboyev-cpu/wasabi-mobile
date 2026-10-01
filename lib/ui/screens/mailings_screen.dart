import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class MailingsScreen extends StatefulWidget {
  const MailingsScreen({super.key});

  @override
  State<MailingsScreen> createState() => _MailingsScreenState();
}

class _MailingsScreenState extends State<MailingsScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refresh();
      if (mounted) await AppScope.of(context, listen: false).markMailingsRead();
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await AppScope.of(context, listen: false).refreshMailings();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final items = state.mailings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _MailingsBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: _MailingsHeader(
                    title: isUz ? 'Xabarlar' : 'Рассылки',
                    refreshTooltip: isUz ? 'Yangilash' : 'Обновить',
                    loading: _loading,
                    onBack: () => Navigator.of(context).pop(),
                    onRefresh: _refresh,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: items.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.fromLTRB(18, 70, 18, 120),
                            children: [
                              EmptyState(
                                icon: Icons.mark_email_unread_outlined,
                                title: isUz
                                    ? 'Hozircha xabar yo‘q'
                                    : 'Пока нет рассылок',
                                text: isUz
                                    ? 'Admin paneldan yuborilgan xabarlar shu yerda chiqadi.'
                                    : 'Здесь появятся сообщения, отправленные из админ-панели.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                            itemBuilder: (context, index) => _MailingCard(
                              item: items[index],
                              locale: state.locale,
                            ),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: items.length,
                          ),
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

class _MailingsHeader extends StatelessWidget {
  const _MailingsHeader({
    required this.title,
    required this.refreshTooltip,
    required this.loading,
    required this.onBack,
    required this.onRefresh,
  });

  final String title;
  final String refreshTooltip;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF11150D).withValues(alpha: .92)
            : Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .26)
              : const Color(0xFFE8E8E8),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .48)
                : Colors.black.withValues(alpha: .08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          if (isDark)
            BoxShadow(
              color: WasabiColors.primary.withValues(alpha: .08),
              blurRadius: 30,
            ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : WasabiColors.dark,
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WasabiColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: refreshTooltip,
            onPressed: loading ? null : onRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: loading
                  ? (isDark
                      ? Colors.white.withValues(alpha: .28)
                      : WasabiColors.muted)
                  : (isDark ? Colors.white : WasabiColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _MailingCard extends StatelessWidget {
  const _MailingCard({required this.item, required this.locale});

  final MailingModel item;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = item.createdAt == null
        ? ''
        : DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt!.toLocal());
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? WasabiColors.primary.withValues(alpha: .36)
                : Colors.white.withValues(alpha: 0.72),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF1A250E),
                    Color(0xFF10140D),
                    Color(0xFF070907),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.92),
                    Colors.white.withValues(alpha: 0.72),
                    const Color(0xFFEFF6D7).withValues(alpha: 0.28),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: WasabiColors.primary.withValues(
                alpha: isDark ? .18 : 0.09,
              ),
              blurRadius: isDark ? 24 : 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: .35)
                  : Colors.white.withValues(alpha: 0.55),
              blurRadius: 16,
              offset: const Offset(-6, -8),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _CardDotPattern()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColoredBox(
                        color: isDark
                            ? const Color(0xFF11150D)
                            : const Color(0xFFF4F4EC),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF76A90A), Color(0xFF4E8204)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26678F07),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (date.isNotEmpty)
                              Text(
                                date,
                                style: const TextStyle(
                                  color: WasabiColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            Text(
                              item.title(locale),
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white : WasabiColors.dark,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (item.text(locale).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.text(locale),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: .72)
                                      : const Color(0xB3141414),
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MailingsBackground extends StatefulWidget {
  const _MailingsBackground();

  @override
  State<_MailingsBackground> createState() => _MailingsBackgroundState();
}

class _MailingsBackgroundState extends State<_MailingsBackground>
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
                painter:
                    _MailingsBackgroundPainter(progress: .5, isDark: isDark),
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
                  _FloatingMailingIcon(
                    icon: Icons.eco_rounded,
                    left: .72,
                    top: .14,
                    size: 18,
                    opacity: .30,
                    progress: progress,
                  ),
                  _FloatingMailingIcon(
                    icon: Icons.eco_rounded,
                    left: .54,
                    top: .70,
                    size: 18,
                    opacity: .22,
                    progress: 1 - progress,
                  ),
                  _FloatingMailingIcon(
                    icon: Icons.eco_rounded,
                    left: .83,
                    top: .50,
                    size: 22,
                    opacity: .28,
                    progress: progress,
                  ),
                  _FloatingMailingIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: .35,
                    top: .52,
                    size: 18,
                    opacity: sparkle * .55,
                    progress: 0,
                  ),
                  _FloatingMailingIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: .84,
                    top: .63,
                    size: 20,
                    opacity: sparkle * .48,
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

class _MailingsBackgroundPainter extends CustomPainter {
  const _MailingsBackgroundPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
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
                Color(0xFFF9F7D6),
                Color(0xFFEAF6D4),
              ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _drawGlows(canvas, size);
    _drawCurve(canvas, size);
    _drawBell(canvas, size);
    _drawPlant(canvas, size);
  }

  void _drawGlows(Canvas canvas, Size size) {
    final circles = [
      (Offset(size.width * .82, size.height * .14), size.width * .23, .055),
      (Offset(size.width * .12, size.height * .38), size.width * .28, .045),
      (Offset(size.width * .80, size.height * .70), size.width * .30, .038),
    ];
    for (final c in circles) {
      final rect = Rect.fromCircle(
        center: c.$1,
        radius: c.$2 * (1 + progress * .025),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              WasabiColors.primary.withValues(alpha: c.$3),
              Colors.transparent,
            ],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  void _drawCurve(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-size.width * .05, size.height * .18)
      ..cubicTo(size.width * .20, size.height * .06, size.width * .43,
          size.height * .26, size.width * .67, size.height * .11)
      ..cubicTo(size.width * .84, size.height * .02, size.width * .94,
          size.height * .15, size.width * 1.05, size.height * .07);
    canvas.drawPath(
      path,
      Paint()
        ..color = (isDark ? WasabiColors.primary : Colors.white)
            .withValues(alpha: isDark ? .045 : .70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    final lower = Path()
      ..moveTo(size.width * .15, size.height * .68)
      ..cubicTo(size.width * .34, size.height * .54, size.width * .55,
          size.height * .72, size.width * .66, size.height * .54)
      ..cubicTo(size.width * .77, size.height * .34, size.width * .92,
          size.height * .55, size.width * 1.04, size.height * .40);
    canvas.drawPath(
      lower,
      Paint()
        ..color = (isDark ? WasabiColors.primary : Colors.white)
            .withValues(alpha: isDark ? .05 : .56)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBell(Canvas canvas, Size size) {
    final opacityScale = isDark ? .46 : 1.0;
    final center = Offset(size.width * .82, size.height * .82);
    final paint = Paint()
      ..color = WasabiColors.primary.withValues(alpha: .055 * opacityScale)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final stroke = Paint()
      ..color = WasabiColors.primary.withValues(alpha: .060 * opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path()
      ..moveTo(center.dx - 70, center.dy + 46)
      ..quadraticBezierTo(
          center.dx - 46, center.dy + 28, center.dx - 42, center.dy - 36)
      ..quadraticBezierTo(
          center.dx - 38, center.dy - 76, center.dx, center.dy - 76)
      ..quadraticBezierTo(
          center.dx + 38, center.dy - 76, center.dx + 42, center.dy - 36)
      ..quadraticBezierTo(
          center.dx + 46, center.dy + 28, center.dx + 70, center.dy + 46)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(
      Offset(center.dx, center.dy + 58),
      14,
      Paint()
        ..color = WasabiColors.primary.withValues(alpha: .045 * opacityScale),
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - 88),
      14,
      Paint()
        ..color = WasabiColors.primary.withValues(alpha: .045 * opacityScale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  void _drawPlant(Canvas canvas, Size size) {
    final opacityScale = isDark ? .46 : 1.0;
    final base = Offset(size.width * .060, size.height * .94);
    final stem = Paint()
      ..color = WasabiColors.primary.withValues(alpha: .110 * opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final mainStem = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(size.width * .075, size.height * .89, size.width * .112,
          size.height * .84, size.width * .165, size.height * .78);
    canvas.drawPath(mainStem, stem);

    final branchA = Path()
      ..moveTo(size.width * .090, size.height * .870)
      ..quadraticBezierTo(size.width * .058, size.height * .842,
          size.width * .030, size.height * .810);
    canvas.drawPath(
      branchA,
      stem..color = WasabiColors.primary.withValues(alpha: .085 * opacityScale),
    );

    final branchB = Path()
      ..moveTo(size.width * .112, size.height * .840)
      ..quadraticBezierTo(size.width * .162, size.height * .810,
          size.width * .210, size.height * .795);
    canvas.drawPath(
      branchB,
      stem..color = WasabiColors.primary.withValues(alpha: .095 * opacityScale),
    );

    for (final leaf in [
      (Offset(size.width * .160, size.height * .795), .20, .050, .130),
      (Offset(size.width * .210, size.height * .795), 1.05, .055, .100),
      (Offset(size.width * .035, size.height * .815), -.70, .060, .095),
      (Offset(size.width * .075, size.height * .895), -.38, .057, .078),
      (Offset(size.width * .127, size.height * .840), .55, .050, .085),
    ]) {
      _drawLeaf(
        canvas,
        leaf.$1,
        leaf.$2,
        size.width * leaf.$3,
        leaf.$4 * opacityScale,
      );
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double rotation,
    double radius,
    double opacity,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -radius)
      ..cubicTo(
          radius * 1.15, -radius * .45, radius * 1.05, radius * .70, 0, radius)
      ..cubicTo(-radius * 1.05, radius * .70, -radius * 1.15, -radius * .45, 0,
          -radius);
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius * 1.2);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFA8C95A).withValues(alpha: opacity),
            WasabiColors.primary.withValues(alpha: opacity * .72),
          ],
        ).createShader(bounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -radius * .64)
        ..lineTo(0, radius * .58),
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * .40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MailingsBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

class _FloatingMailingIcon extends StatelessWidget {
  const _FloatingMailingIcon({
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

class _CardDotPattern extends StatelessWidget {
  const _CardDotPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CardDotPainter());
  }
}

class _CardDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = WasabiColors.primary.withValues(alpha: .045);
    for (var x = size.width * .72; x < size.width - 10; x += 8) {
      for (var y = 14.0; y < size.height - 14; y += 8) {
        final fade = ((x - size.width * .72) / (size.width * .28)).clamp(0, 1);
        canvas.drawCircle(
          Offset(x, y),
          1.2 + fade * 1.4,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
