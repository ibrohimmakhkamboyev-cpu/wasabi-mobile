import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../services/native_bridge.dart';
import '../widgets/common.dart';
import '../widgets/wasabi_page_background.dart';
import 'auth_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.standalone = true});

  final bool standalone;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = false;
  String? _payingOrderId;
  String? _cancellingOrderId;
  final Set<String> _collapsingOrderIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = !state.isAuthenticated
        ? EmptyState(
            icon: Icons.receipt_long_outlined,
            title: isUz ? 'Kirish kerak' : 'Нужен вход',
            text: isUz
                ? 'Buyurtmalar tarixini ko‘rish uchun profilga kiring.'
                : 'Войдите, чтобы видеть историю заказов и повторять покупки.',
            action: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              ),
              icon: const Icon(Icons.login),
              label: Text(isUz ? 'Kirish' : 'Войти'),
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : state.orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 170),
                        children: [
                          EmptyState(
                            icon: Icons.history,
                            title: isUz
                                ? 'Hali buyurtma yo‘q'
                                : 'Заказов пока нет',
                            text: isUz
                                ? 'Birinchi buyurtmangiz shu yerda paydo bo‘ladi.'
                                : 'После оформления заказы появятся здесь.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 170),
                        itemBuilder: (context, index) {
                          final order = state.orders[index];
                          final isCancelling = _cancellingOrderId == order.id;
                          final isCollapsing =
                              _collapsingOrderIds.contains(order.id);
                          return AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            child: isCollapsing
                                ? const SizedBox.shrink()
                                : AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    opacity: isCancelling ? 0 : 1,
                                    child: Card(
                                      color: Colors.transparent,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24)),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          border: Border.all(
                                            color: isDark
                                                ? WasabiColors.primary
                                                    .withValues(alpha: .28)
                                                : Colors.white
                                                    .withValues(alpha: .76),
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isDark
                                                ? [
                                                    const Color(0xFF151B11)
                                                        .withValues(alpha: .96),
                                                    const Color(0xFF0D110B)
                                                        .withValues(alpha: .94),
                                                    const Color(0xFF1C2A10)
                                                        .withValues(alpha: .88),
                                                  ]
                                                : [
                                                    Colors.white
                                                        .withValues(alpha: .94),
                                                    Colors.white
                                                        .withValues(alpha: .76),
                                                    const Color(0xFFEAF6D2)
                                                        .withValues(alpha: .28),
                                                  ],
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            const Positioned.fill(
                                                child: _OrderCardDotPattern()),
                                            ExpansionTile(
                                              shape:
                                                  const RoundedRectangleBorder(
                                                side: BorderSide.none,
                                              ),
                                              collapsedShape:
                                                  const RoundedRectangleBorder(
                                                side: BorderSide.none,
                                              ),
                                              tilePadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14),
                                              leading: Container(
                                                width: 52,
                                                height: 52,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  color: WasabiColors.primary
                                                      .withValues(alpha: .10),
                                                ),
                                                child: const Icon(
                                                  Icons.fact_check_rounded,
                                                  color: WasabiColors.primary,
                                                ),
                                              ),
                                              title: Text(
                                                '${isUz ? 'Buyurtma' : 'Заказ'} №${order.id}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ).copyWith(
                                                  color: isDark
                                                      ? Colors.white
                                                      : WasabiColors.dark,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    orderStatusLabel(
                                                        order.status,
                                                        state.locale),
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.white
                                                              .withValues(
                                                                  alpha: .64)
                                                          : WasabiColors.muted,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    order.total == null
                                                        ? '—'
                                                        : money(order.total!,
                                                            state.locale),
                                                    style: const TextStyle(
                                                        color: WasabiColors
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.w900),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: WasabiColors.primary,
                                                  ),
                                                ],
                                              ),
                                              children: [
                                                if (order.items.isEmpty)
                                                  const Padding(
                                                    padding: EdgeInsets.all(14),
                                                    child: Text(
                                                      'Детализация недоступна',
                                                      style: TextStyle(
                                                          color: WasabiColors
                                                              .muted),
                                                    ),
                                                  )
                                                else
                                                  ...order.items.map(
                                                    (item) => ListTile(
                                                      dense: true,
                                                      title: Text(
                                                        item.name,
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : WasabiColors
                                                                  .dark,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      trailing: Text(
                                                        'x${item.quantity}',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          .72)
                                                              : WasabiColors
                                                                  .muted,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          14, 4, 14, 14),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                OutlinedButton
                                                                    .icon(
                                                              onPressed: () {
                                                                state
                                                                    .repeatOrder(
                                                                        order);
                                                                showWasabiMessage(
                                                                  context,
                                                                  isUz
                                                                      ? 'Savatga qo‘shildi'
                                                                      : 'Товары добавлены в корзину',
                                                                );
                                                              },
                                                              icon: const Icon(
                                                                  Icons.replay,
                                                                  size: 16),
                                                              label: Text(
                                                                isUz
                                                                    ? 'Takrorlash'
                                                                    : 'Повторить',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              style:
                                                                  OutlinedButton
                                                                      .styleFrom(
                                                                minimumSize:
                                                                    const Size(
                                                                        0, 38),
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8),
                                                                tapTargetSize:
                                                                    MaterialTapTargetSize
                                                                        .shrinkWrap,
                                                              ),
                                                            ),
                                                          ),
                                                          if (order.status ==
                                                              'pending_payment') ...[
                                                            const SizedBox(
                                                                width: 8),
                                                            Expanded(
                                                              child:
                                                                  FilledButton
                                                                      .icon(
                                                                onPressed: _payingOrderId ==
                                                                            order
                                                                                .id ||
                                                                        _cancellingOrderId ==
                                                                            order
                                                                                .id
                                                                    ? null
                                                                    : () =>
                                                                        _payOrder(
                                                                            order),
                                                                icon: _payingOrderId ==
                                                                        order.id
                                                                    ? const SizedBox(
                                                                        width:
                                                                            15,
                                                                        height:
                                                                            15,
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          strokeWidth:
                                                                              2,
                                                                        ),
                                                                      )
                                                                    : const Icon(
                                                                        Icons
                                                                            .payments_outlined,
                                                                        size:
                                                                            16,
                                                                      ),
                                                                label: Text(isUz
                                                                    ? 'To\'lash'
                                                                    : 'Оплатить'),
                                                                style: FilledButton
                                                                    .styleFrom(
                                                                  minimumSize:
                                                                      const Size(
                                                                          0,
                                                                          38),
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8),
                                                                  tapTargetSize:
                                                                      MaterialTapTargetSize
                                                                          .shrinkWrap,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      if (order.status ==
                                                          'pending_payment')
                                                        TextButton.icon(
                                                          onPressed:
                                                              _cancellingOrderId ==
                                                                      order.id
                                                                  ? null
                                                                  : () =>
                                                                      _cancelOrder(
                                                                          order),
                                                          icon: _cancellingOrderId ==
                                                                  order.id
                                                              ? const SizedBox(
                                                                  width: 15,
                                                                  height: 15,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                                )
                                                              : const Icon(
                                                                  Icons
                                                                      .close_rounded,
                                                                  size: 17,
                                                                ),
                                                          label: Text(isUz
                                                              ? 'Bekor qilish'
                                                              : 'Отменить заказ'),
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .error,
                                                            minimumSize:
                                                                const Size(
                                                                    0, 34),
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: state.orders.length,
                      ),
          );
    if (!widget.standalone) return content;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(isUz ? 'Buyurtmalar' : 'История заказов'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WasabiPageBackground(animate: true)),
          content,
        ],
      ),
    );
  }

  Future<void> _load() async {
    final state = AppScope.of(context, listen: false);
    if (!state.isAuthenticated) return;
    setState(() => _loading = true);
    try {
      await state.loadOrders();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payOrder(OrderModel order) async {
    final id = int.tryParse(order.id.replaceFirst('local:', ''));
    if (id == null) return;
    setState(() => _payingOrderId = order.id);
    try {
      final state = AppScope.of(context, listen: false);
      final url = order.paymentUrl?.isNotEmpty == true
          ? order.paymentUrl
          : await state.loadPaymentUrl(id);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(state.locale == 'uz'
                  ? 'To\'lov havolasi olinmadi'
                  : 'Не удалось открыть оплату')),
        );
        return;
      }
      await NativeBridge.openUrl(url);
    } finally {
      if (mounted) setState(() => _payingOrderId = null);
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final id = int.tryParse(order.id.replaceFirst('local:', ''));
    if (id == null) return;
    final state = AppScope.of(context, listen: false);
    setState(() => _cancellingOrderId = order.id);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _collapsingOrderIds.add(order.id));
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    try {
      await state.cancelOrder(id);
      if (!mounted) return;
      showWasabiMessage(
        context,
        state.locale == 'uz' ? 'Buyurtma bekor qilindi' : 'Заказ отменен',
      );
    } catch (_) {
      if (!mounted) return;
      showWasabiMessage(
        context,
        state.locale == 'uz'
            ? 'Buyurtmani bekor qilib bo‘lmadi'
            : 'Не удалось отменить заказ',
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingOrderId = null;
          _collapsingOrderIds.remove(order.id);
        });
      }
    }
  }
}

class _OrderCardDotPattern extends StatelessWidget {
  const _OrderCardDotPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OrderCardDotPainter());
  }
}

class _OrderCardDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = WasabiColors.primary.withValues(alpha: .050);
    for (var x = size.width * .74; x < size.width - 12; x += 8) {
      for (var y = 14.0; y < size.height - 14; y += 8) {
        final fade = ((x - size.width * .74) / (size.width * .26)).clamp(0, 1);
        canvas.drawCircle(Offset(x, y), 1.2 + fade * 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
