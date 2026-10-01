import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/native_bridge.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/wasabi_page_background.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  OrderModel? _order;
  bool _loading = true;
  bool _paying = false;
  bool _loadingOrder = false;
  bool _appIsActive = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_appIsActive) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    if (_appIsActive) _load();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final status = _order?.status;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(isUz ? 'Buyurtma holati' : 'Статус заказа'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WasabiPageBackground(animate: true)),
          ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
              16,
              24,
            ),
            children: [
              if (_loading && _order == null)
                const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _order == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          isUz
                              ? 'Holatni yuklab bo‘lmadi'
                              : 'Не удалось загрузить статус',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(isUz ? 'Qayta urinish' : 'Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '№${widget.orderId}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          orderStatusLabel(status!, state.locale),
                          style: const TextStyle(
                            color: WasabiColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (status.toLowerCase() == 'pending_payment') ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _paying
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _paying = true);
                            try {
                              final url = _order?.paymentUrl?.isNotEmpty == true
                                  ? _order!.paymentUrl
                                  : await state.loadPaymentUrl(widget.orderId);
                              if (url == null || url.isEmpty) {
                                throw Exception('payment');
                              }
                              await NativeBridge.openUrl(url);
                            } catch (_) {
                              if (!mounted) return;
                              messenger
                                ..clearSnackBars()
                                ..showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      isUz
                                          ? 'To‘lov havolasi olinmadi'
                                          : 'Не удалось открыть оплату',
                                    ),
                                  ),
                                );
                            } finally {
                              if (mounted) setState(() => _paying = false);
                            }
                          },
                    icon: _paying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_outlined),
                    label: Text(isUz ? 'To\'lash' : 'Оплатить'),
                  ),
                ],
                const SizedBox(height: 14),
                _Timeline(status: status),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(isUz ? 'Yangilash' : 'Обновить'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    // Polling may overlap on a slow connection. One request is enough and
    // avoids an older response replacing newer order state.
    if (_loadingOrder) return;
    _loadingOrder = true;
    final state = AppScope.of(context, listen: false);
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final order = await state.loadOrderStatus(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _error = order == null ? 'load_failed' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load_failed';
      });
    } finally {
      _loadingOrder = false;
    }
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final steps = state.locale == 'uz'
        ? const ['Qabul qilindi', 'Tayyorlanmoqda', 'Kuryerda', 'Yetkazildi']
        : const ['Принят', 'Готовится', 'Передан курьеру', 'Доставлен'];
    final active = _activeIndex(status);
    final canceled = status.toLowerCase().contains('cancel');
    if (canceled) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.cancel_outlined, color: WasabiColors.secondary),
          title: Text('Заказ отменен',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              _StepRow(
                label: steps[i],
                active: i <= active,
                last: i == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  int _activeIndex(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'pending_payment') return -1;
    if (normalized.contains('closed') || normalized.contains('delivered')) {
      return 3;
    }
    if (normalized.contains('courier') || normalized.contains('delivery')) {
      return 2;
    }
    if (normalized.contains('cook') || normalized.contains('process')) return 1;
    return 0;
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.active,
    required this.last,
  });

  final String label;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: active ? WasabiColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: active ? WasabiColors.primary : WasabiColors.stroke),
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: active ? Colors.white : WasabiColors.stroke,
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 34,
                color: active ? WasabiColors.primary : WasabiColors.stroke,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: active
                  ? Theme.of(context).colorScheme.onSurface
                  : WasabiColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
