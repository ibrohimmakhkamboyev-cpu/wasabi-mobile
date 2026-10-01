import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/native_bridge.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _orderPush = true;
  bool _promoPush = true;
  bool _newProductsPush = true;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isUz ? 'Aloqa' : 'Обратная связь'),
          bottom: TabBar(
            tabs: [
              Tab(text: isUz ? 'Aloqa' : 'Контакты'),
              Tab(text: isUz ? 'Push' : 'Push'),
            ],
          ),
        ),
        body: _SupportBackdrop(
          child: TabBarView(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                children: [
                  _SupportTile(
                    icon: Icons.call_outlined,
                    title:
                        isUz ? 'Restoranga qo‘ng‘iroq' : 'Позвонить в ресторан',
                    subtitle: state.settings.contactPhone.isEmpty
                        ? AppConfig.defaultPhone
                        : state.settings.contactPhone,
                    onTap: () => NativeBridge.openUrl(
                      'tel:${state.settings.contactPhone.isEmpty ? AppConfig.defaultPhone : state.settings.contactPhone}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SupportTile(
                    icon: Icons.send_outlined,
                    title: isUz ? 'Telegram' : 'Написать в Telegram',
                    subtitle: state.settings.telegram.isEmpty
                        ? AppConfig.supportTelegram
                        : state.settings.telegram,
                    onTap: () => NativeBridge.openUrl(
                      state.settings.telegram.isEmpty
                          ? AppConfig.supportTelegram
                          : state.settings.telegram,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SupportTile(
                    icon: Icons.rate_review_outlined,
                    title: isUz ? 'Fikr qoldirish' : 'Оставить отзыв',
                    subtitle: isUz
                        ? 'Xizmat sifati haqida yozing'
                        : 'Напишите, что можно улучшить',
                    onTap: () => _showReviewDialog(context),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                children: [
                  _SwitchCard(
                    icon: Icons.receipt_long_outlined,
                    title: isUz ? 'Buyurtma holati' : 'Статус заказа',
                    value: _orderPush,
                    onChanged: (value) => setState(() => _orderPush = value),
                  ),
                  const SizedBox(height: 10),
                  _SwitchCard(
                    icon: Icons.local_offer_outlined,
                    title: isUz ? 'Aksiyalar' : 'Акции и промокоды',
                    value: _promoPush,
                    onChanged: (value) => setState(() => _promoPush = value),
                  ),
                  const SizedBox(height: 10),
                  _SwitchCard(
                    icon: Icons.new_releases_outlined,
                    title: isUz ? 'Yangi mahsulotlar' : 'Новые товары',
                    value: _newProductsPush,
                    onChanged: (value) =>
                        setState(() => _newProductsPush = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportBackdrop extends StatelessWidget {
  const _SupportBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0A0D08), Color(0xFF10170B), Color(0xFF090909)]
              : const [Color(0xFFFFFBE3), Color(0xFFF3F9DF), Color(0xFFFFF9DD)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SupportPatternPainter(
                  primary: WasabiColors.primary
                      .withValues(alpha: isDark ? .14 : .10),
                  accent: WasabiColors.secondary
                      .withValues(alpha: isDark ? .08 : .09),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SupportPatternPainter extends CustomPainter {
  const _SupportPatternPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final wash = Paint()..color = primary;
    final accentPaint = Paint()..color = accent;

    canvas.drawCircle(Offset(size.width + 38, size.height * .28), 156, wash);
    canvas.drawCircle(Offset(-36, size.height * .78), 128, accentPaint);

    for (var offset = -150.0; offset < size.height; offset += 76) {
      final curve = Path()
        ..moveTo(-12, offset)
        ..cubicTo(
          size.width * .24,
          offset - 56,
          size.width * .72,
          offset + 56,
          size.width + 14,
          offset - 18,
        );
      canvas.drawPath(curve, line);
    }

    for (final point in [
      Offset(size.width * .16, size.height * .53),
      Offset(size.width * .79, size.height * .67),
      Offset(size.width * .51, size.height * .88),
    ]) {
      canvas.drawCircle(point, 3, accentPaint);
      canvas.drawCircle(point, 8, line);
    }
  }

  @override
  bool shouldRepaint(covariant _SupportPatternPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.accent != accent;
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: WasabiColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: WasabiColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        value: value,
        activeThumbColor: WasabiColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}

void _showReviewDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Отзыв'),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(hintText: 'Ваш отзыв'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть')),
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отправить')),
      ],
    ),
  ).whenComplete(controller.dispose);
}
