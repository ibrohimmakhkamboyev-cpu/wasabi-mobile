import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/wasabi_page_background.dart';
import 'map_picker_screen.dart';
import 'order_status_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryType _deliveryType = DeliveryType.delivery;
  PaymentMethod _payment = PaymentMethod.cash;
  AddressModel? _address;
  BranchModel? _branch;
  String _timeMode = 'today';
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  int _bonus = 0;
  bool _submitting = false;
  final _comment = TextEditingController();
  Timer? _orderingClock;

  @override
  void initState() {
    super.initState();
    // Refresh the checkout action at opening and closing time without forcing
    // the customer to leave the screen.
    _orderingClock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _orderingClock?.cancel();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    _address ??= state.primaryAddress;
    _branch ??= state.branches.isEmpty ? null : state.branches.first;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(isUz ? 'Buyurtma' : 'Оформление заказа'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WasabiPageBackground(animate: true)),
          ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 14,
              16,
              24,
            ),
            children: [
              _FulfillmentCard(
                deliveryType: _deliveryType,
                onDeliveryTypeChanged: (value) =>
                    setState(() => _deliveryType = value),
                selectedAddress: _address,
                onSelectAddress: (address) =>
                    setState(() => _address = address),
                selectedBranch: _branch,
                onSelectBranch: (branch) => setState(() => _branch = branch),
                onOpenMap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                  );
                  if (!mounted) return;
                  setState(() => _address = state.primaryAddress);
                },
              ),
              if (_deliveryType == DeliveryType.delivery &&
                  _address != null) ...[
                const SizedBox(height: 14),
                DeliveryRouteCard(
                  address: _address!,
                  onOpenMap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialAddress: _address,
                        ),
                      ),
                    );
                    if (mounted) {
                      setState(() => _address = state.primaryAddress);
                    }
                  },
                ),
              ],
              const SizedBox(height: 14),
              _DeliveryTimeCard(
                timeMode: _timeMode,
                scheduledDate: _scheduledDate,
                scheduledTime: _scheduledTime,
                onChanged: (value) => setState(() => _timeMode = value),
                onPickDate: _pickDate,
                onPickTime: _pickTime,
              ),
              const SizedBox(height: 16),
              _PaymentGrid(
                selected: _payment,
                onChanged: (method) => setState(() => _payment = method),
              ),
              const SizedBox(height: 16),
              _PremiumCommentField(controller: _comment),
              const SizedBox(height: 16),
              if ((state.user?.bonus ?? 0) > 0) ...[
                _QuantityCard(
                  label: isUz ? 'Bonus' : 'Бонусы',
                  icon: Icons.star_outline_rounded,
                  value: _bonus,
                  step: 5000,
                  onChanged: (value) => setState(
                    () =>
                        _bonus = value.clamp(0, state.user?.bonus ?? 0).toInt(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (state.checkoutDiscountOptionCount > 0) ...[
                _PromotionChoiceCard(
                  selectedId: state.selectedPromotionId,
                  promotionIds: state.checkoutPromotionIds,
                  promoCode: state.promoCode,
                  promoCodeSelected: state.isPromoCodeSelected,
                  labelFor: (id) => state.promotionLabel(id, state.locale),
                  onChanged: state.selectPromotion,
                  onPromoCodeSelected: state.selectPromoCode,
                ),
                const SizedBox(height: 16),
              ],
              _InvoiceCard(
                deliveryType: _deliveryType,
                bonus: _bonus,
              ),
              if (!state.isOrderingOpen) ...[
                const SizedBox(height: 14),
                _OrderingClosedNotice(
                  start: state.orderingHours.startLabel,
                  end: state.orderingHours.endLabel,
                ),
              ],
              const SizedBox(height: 18),
              _ConfirmOrderButton(
                onPressed:
                    _submitting || !state.isOrderingOpen ? null : _submit,
                submitting: _submitting,
                paymentMethod: _payment,
                orderingOpen: state.isOrderingOpen,
                start: state.orderingHours.startLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final state = AppScope.of(context, listen: false);
    if (_deliveryType == DeliveryType.delivery && _address == null) {
      showWasabiMessage(
        context,
        'Выберите адрес доставки',
        isError: true,
      );
      return;
    }
    if (_deliveryType == DeliveryType.pickup && _branch == null) {
      showWasabiMessage(
        context,
        'Выберите филиал',
        isError: true,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final id = await state.submitOrder(
        deliveryType: _deliveryType,
        paymentMethod: _payment,
        address: _address,
        branch: _branch,
        comment: _comment.text,
        bonusAmount: _bonus,
        deliveryTimeMode: _timeMode,
        deliveryDate: _scheduledDate?.toIso8601String().substring(0, 10),
        deliveryClock: _scheduledTime == null
            ? null
            : '${_scheduledTime!.hour.toString().padLeft(2, '0')}:'
                '${_scheduledTime!.minute.toString().padLeft(2, '0')}',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: id)),
      );
    } catch (error) {
      if (!mounted) return;
      showWasabiMessage(
        context,
        error.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _FulfillmentCard extends StatelessWidget {
  const _FulfillmentCard({
    required this.deliveryType,
    required this.onDeliveryTypeChanged,
    required this.selectedAddress,
    required this.onSelectAddress,
    required this.selectedBranch,
    required this.onSelectBranch,
    required this.onOpenMap,
  });

  final DeliveryType deliveryType;
  final ValueChanged<DeliveryType> onDeliveryTypeChanged;
  final AddressModel? selectedAddress;
  final ValueChanged<AddressModel> onSelectAddress;
  final BranchModel? selectedBranch;
  final ValueChanged<BranchModel> onSelectBranch;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF0F140C) : Colors.white,
      elevation: isDark ? 0 : 8,
      shadowColor: isDark ? Colors.transparent : const Color(0x1A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .28)
              : const Color(0xFFF2F2EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeliveryTypeSwitch(
              value: deliveryType,
              onChanged: onDeliveryTypeChanged,
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .98, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: deliveryType == DeliveryType.delivery
                  ? _DeliveryAddressList(
                      key: const ValueKey('delivery-addresses'),
                      selected: selectedAddress,
                      onSelect: onSelectAddress,
                      onOpenMap: onOpenMap,
                    )
                  : _PickupBlock(
                      key: const ValueKey('pickup-branches'),
                      selected: selectedBranch,
                      onSelect: onSelectBranch,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryTypeSwitch extends StatelessWidget {
  const _DeliveryTypeSwitch({required this.value, required this.onChanged});

  final DeliveryType value;
  final ValueChanged<DeliveryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isUz = AppScope.of(context).locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF080B07) : const Color(0xFFF8F8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .24)
              : const Color(0xFFE7E7DC),
        ),
      ),
      child: Row(
        children: [
          _DeliveryTypeOption(
            active: value == DeliveryType.delivery,
            icon: Icons.delivery_dining,
            label: isUz ? 'Yetkazish' : 'Доставка',
            onTap: () => onChanged(DeliveryType.delivery),
          ),
          _DeliveryTypeOption(
            active: value == DeliveryType.pickup,
            icon: Icons.local_mall_outlined,
            label: isUz ? 'Olib ketish' : 'Самовывоз',
            onTap: () => onChanged(DeliveryType.pickup),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTypeOption extends StatelessWidget {
  const _DeliveryTypeOption({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? WasabiColors.primary.withValues(alpha: isDark ? .20 : .12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active
                  ? WasabiColors.primary.withValues(alpha: .55)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? WasabiColors.primary : WasabiColors.muted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? WasabiColors.primary
                        : isDark
                            ? Colors.white
                            : WasabiColors.dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressList extends StatelessWidget {
  const _DeliveryAddressList({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onOpenMap,
  });

  final AddressModel? selected;
  final ValueChanged<AddressModel> onSelect;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    return Column(
      children: [
        if (state.addresses.isEmpty)
          InkWell(
            onTap: onOpenMap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E9E2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: WasabiColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isUz
                          ? 'Saqlangan manzil yo‘q'
                          : 'Сохраненных адресов нет',
                      style: const TextStyle(
                        color: WasabiColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ModernAddressRow(
                address: address,
                selected: selected?.id == address.id,
                onTap: () => onSelect(address),
              ),
            ),
          ),
        const SizedBox(height: 2),
        InkWell(
          onTap: onOpenMap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: WasabiColors.primary, width: 1.6),
                  ),
                  child: const Icon(Icons.add,
                      color: WasabiColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isUz ? "Yangi manzil qo'shish" : 'Добавить новый адрес',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WasabiColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernAddressRow extends StatelessWidget {
  const _ModernAddressRow({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (address.entrance != null) 'pod ${address.entrance}',
      if (address.floor != null) '${address.floor}-qavat',
      if (address.apartment != null) address.apartment!,
    ].join(' • ');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? WasabiColors.primary.withValues(alpha: isDark ? .16 : .09)
              : isDark
                  ? const Color(0xFF11180D)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? WasabiColors.primary.withValues(alpha: .72)
                : isDark
                    ? WasabiColors.primary.withValues(alpha: .18)
                    : const Color(0xFFEDEDED),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? .08 : .04),
              blurRadius: selected ? 20 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: selected ? 1.04 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? WasabiColors.primary : WasabiColors.muted,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.storefront_outlined,
              color: WasabiColors.primary,
              size: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : WasabiColors.dark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    details.isEmpty ? address.address : details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: .68)
                          : WasabiColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: isDark ? WasabiColors.primary : WasabiColors.dark,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupBlock extends StatelessWidget {
  const _PickupBlock(
      {super.key, required this.selected, required this.onSelect});

  final BranchModel? selected;
  final ValueChanged<BranchModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      children: state.branches
          .map(
            (branch) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BranchCard(
                branch: branch,
                selected: selected?.id == branch.id,
                onTap: () => onSelect(branch),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PremiumSectionCard extends StatelessWidget {
  const _PremiumSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF0F140C) : Colors.white,
      elevation: isDark ? 0 : 8,
      shadowColor: isDark ? Colors.transparent : const Color(0x12000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .28)
              : const Color(0xFFF0F0EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _DeliveryTimeCard extends StatelessWidget {
  const _DeliveryTimeCard({
    required this.timeMode,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.onChanged,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String timeMode;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final isUz = AppScope.of(context).locale == 'uz';
    return _PremiumSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUz ? 'Yetkazish vaqti' : 'Время доставки',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SelectableOptionCard(
                  active: timeMode == 'today',
                  icon: Icons.schedule_rounded,
                  title: isUz ? 'Hozir' : 'Сейчас',
                  subtitle: isUz ? '30-40 daqiqa' : '30-40 минут',
                  onTap: () => onChanged('today'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectableOptionCard(
                  active: timeMode == 'other',
                  icon: Icons.calendar_month_outlined,
                  title: isUz ? 'Vaqt tanlash' : 'Ко времени',
                  subtitle: isUz ? 'Keyinroq' : 'Позже',
                  onTap: () => onChanged('other'),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: timeMode == 'other'
                ? Padding(
                    key: const ValueKey('schedule-pickers'),
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.calendar_month_outlined,
                            label: scheduledDate == null
                                ? (isUz ? 'Sana' : 'Дата')
                                : scheduledDate!
                                    .toIso8601String()
                                    .substring(0, 10),
                            onTap: onPickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.access_time,
                            label: scheduledTime == null
                                ? (isUz ? 'Vaqt' : 'Время')
                                : scheduledTime!.format(context),
                            onTap: onPickTime,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PaymentGrid extends StatelessWidget {
  const _PaymentGrid({required this.selected, required this.onChanged});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    return _PremiumSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUz ? 'To‘lov usuli' : 'Способ оплаты',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Row(
            key: const Key('payment-options-row'),
            children: [
              for (var index = 0;
                  index < checkoutPaymentMethods.length;
                  index++) ...[
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: _SelectableOptionCard(
                      active: selected == checkoutPaymentMethods[index],
                      icon: _paymentIcon(checkoutPaymentMethods[index]),
                      brand: _paymentBrand(checkoutPaymentMethods[index]),
                      brandOnly:
                          checkoutPaymentMethods[index] != PaymentMethod.cash,
                      title: checkoutPaymentMethods[index] == PaymentMethod.cash
                          ? checkoutPaymentMethods[index].label(state.locale)
                          : '',
                      compact: true,
                      onTap: () => onChanged(checkoutPaymentMethods[index]),
                    ),
                  ),
                ),
                if (index != checkoutPaymentMethods.length - 1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.click:
        return Icons.radio_button_checked;
      case PaymentMethod.payme:
        return Icons.payments_outlined;
    }
  }

  Widget? _paymentBrand(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.click:
        return Container(
          key: const Key('payment-logo-click'),
          width: 64,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/images/click_logo.png',
            fit: BoxFit.contain,
          ),
        );
      case PaymentMethod.payme:
        return ClipRRect(
          key: const Key('payment-logo-payme'),
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            'assets/images/payme_logo.png',
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
        );
      case PaymentMethod.cash:
      case PaymentMethod.card:
        return null;
    }
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.active,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.compact = false,
    this.brand,
    this.brandOnly = false,
  });

  final bool active;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool compact;
  final Widget? brand;
  final bool brandOnly;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 13,
        ),
        decoration: BoxDecoration(
          color: active
              ? WasabiColors.primary.withValues(alpha: isDark ? .18 : .09)
              : isDark
                  ? const Color(0xFF11180D)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? WasabiColors.primary.withValues(alpha: .72)
                : isDark
                    ? WasabiColors.primary.withValues(alpha: .18)
                    : const Color(0xFFE8E8E2),
            width: active ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: active ? .07 : .035),
              blurRadius: active ? 18 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: brandOnly
            ? Stack(
                children: [
                  Center(
                    child: AnimatedScale(
                      scale: active ? 1.06 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: brand!,
                    ),
                  ),
                  if (active)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_circle,
                        color: WasabiColors.primary,
                        size: 17,
                      ),
                    ),
                ],
              )
            : Row(
                children: [
                  AnimatedScale(
                    scale: active ? 1.06 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: brand ??
                        Icon(
                          icon,
                          color: active
                              ? WasabiColors.primary
                              : isDark
                                  ? Colors.white
                                  : WasabiColors.dark,
                          size: compact ? 24 : 30,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: TextStyle(
                              color: active
                                  ? WasabiColors.primary
                                  : isDark
                                      ? Colors.white
                                      : WasabiColors.dark,
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 14 : 15,
                            ),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: .66)
                                  : WasabiColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (active)
                    const Icon(Icons.check_circle,
                        color: WasabiColors.primary, size: 20),
                ],
              ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _PremiumCommentField extends StatelessWidget {
  const _PremiumCommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isUz = AppScope.of(context).locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : WasabiColors.dark,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: WasabiColors.primary,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: isUz ? 'Izoh (ixtiyoriy)' : 'Комментарий (необязательно)',
        hintStyle: TextStyle(
          color:
              isDark ? Colors.white.withValues(alpha: .58) : WasabiColors.muted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.chat_bubble_outline,
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .78)
              : WasabiColors.muted,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF11180D) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark
                ? WasabiColors.primary.withValues(alpha: .28)
                : const Color(0xFFE8E8E2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: WasabiColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final IconData icon;
  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF0F140C) : Colors.white,
      elevation: isDark ? 0 : 7,
      shadowColor: isDark ? Colors.transparent : const Color(0x12000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .28)
              : const Color(0xFFF0F0EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: WasabiColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: .62)
                    : WasabiColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : WasabiColors.dark,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                _RoundStepButton(
                  icon: Icons.remove,
                  onTap: () => onChanged(value - step),
                ),
                const SizedBox(width: 8),
                _RoundStepButton(
                  icon: Icons.add,
                  onTap: () => onChanged(value + step),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white : const Color(0xFFF3F4F0),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: WasabiColors.dark),
        ),
      ),
    );
  }
}

class _PromotionChoiceCard extends StatelessWidget {
  const _PromotionChoiceCard({
    required this.selectedId,
    required this.promotionIds,
    required this.promoCode,
    required this.promoCodeSelected,
    required this.labelFor,
    required this.onChanged,
    required this.onPromoCodeSelected,
  });

  final int? selectedId;
  final List<int> promotionIds;
  final String promoCode;
  final bool promoCodeSelected;
  final String Function(int id) labelFor;
  final ValueChanged<int?> onChanged;
  final VoidCallback onPromoCodeSelected;

  @override
  Widget build(BuildContext context) {
    final isUz = AppScope.of(context).locale == 'uz';
    final hasPromoCode = promoCode.trim().isNotEmpty;
    final optionCount = promotionIds.length + (hasPromoCode ? 1 : 0);
    final isSingleOption = optionCount == 1;
    return _PremiumSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSingleOption
                ? (isUz ? 'Aksiya qo‘llandi' : 'Акция применена')
                : (isUz ? 'Aksiyani tanlang' : 'Выберите акцию'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            isSingleOption
                ? (isUz
                    ? 'Savatga mos aksiya avtomatik qo‘llandi'
                    : 'Подходящая акция применена автоматически')
                : (isUz
                    ? 'Buyurtma uchun faqat bitta chegirmani tanlang'
                    : 'Выберите только одну скидку для заказа'),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: .66)
                  : WasabiColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final id in promotionIds) ...[
            _PromotionOptionTile(
              active: selectedId == id,
              icon:
                  id == 155 ? Icons.cake_outlined : Icons.local_offer_outlined,
              title: labelFor(id),
              subtitle: isSingleOption
                  ? (isUz ? 'Avtomatik qo‘llanildi' : 'Применена автоматически')
                  : (isUz ? 'Ushbu aksiyani tanlash' : 'Выбрать эту акцию'),
              onTap: isSingleOption ? null : () => onChanged(id),
            ),
            if (id != promotionIds.last || hasPromoCode)
              const SizedBox(height: 8),
          ],
          if (hasPromoCode)
            _PromotionOptionTile(
              active: promoCodeSelected,
              icon: Icons.confirmation_number_outlined,
              title: promoCode.toUpperCase(),
              subtitle: isSingleOption
                  ? (isUz
                      ? 'Promokod avtomatik qo‘llanildi'
                      : 'Промокод применён автоматически')
                  : (isUz
                      ? 'Promokoddan foydalanish'
                      : 'Использовать промокод'),
              onTap: isSingleOption ? null : onPromoCodeSelected,
            ),
        ],
      ),
    );
  }
}

class _PromotionOptionTile extends StatelessWidget {
  const _PromotionOptionTile({
    required this.active,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: onTap != null,
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? WasabiColors.primary.withValues(alpha: dark ? .25 : .10)
                : (dark
                    ? Colors.white.withValues(alpha: .06)
                    : Colors.white.withValues(alpha: .62)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? WasabiColors.primary
                  : (dark
                      ? Colors.white.withValues(alpha: .12)
                      : WasabiColors.primary.withValues(alpha: .16)),
              width: active ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WasabiColors.primary
                      .withValues(alpha: active ? .18 : .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: WasabiColors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? Colors.white.withValues(alpha: .62)
                                : WasabiColors.muted)),
                  ],
                ),
              ),
              Icon(
                  active
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: active
                      ? WasabiColors.primary
                      : (dark
                          ? Colors.white.withValues(alpha: .38)
                          : WasabiColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.deliveryType, required this.bonus});

  final DeliveryType deliveryType;
  final int bonus;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final total =
        (state.totalFor(deliveryType) - bonus).clamp(0, 1 << 31).toInt();
    return _PremiumSectionCard(
      child: Column(
        children: [
          _InvoiceRow(
            label: isUz ? 'Mahsulotlar' : 'Товары',
            value: money(state.fullPriceSubtotal, state.locale),
          ),
          if (deliveryType == DeliveryType.delivery)
            _InvoiceRow(
              label: isUz ? 'Yetkazish' : 'Доставка',
              value: money(state.settings.deliveryFee, state.locale),
            ),
          if (state.productDiscount > 0)
            _InvoiceRow(
              label: isUz ? 'Mahsulot aksiyasi' : 'Акция на товары',
              value: '-${money(state.productDiscount, state.locale)}',
            ),
          if (state.checkoutPromotionDiscount > 0)
            _InvoiceRow(
              label: state.promotionLabel(
                  state.selectedPromotionId!, state.locale),
              value: '-${money(state.checkoutPromotionDiscount, state.locale)}',
            ),
          if (state.promoDiscount > 0)
            _InvoiceRow(
              label: isUz ? 'Chegirma' : 'Скидка',
              value: '-${money(state.promoDiscount, state.locale)}',
            ),
          if (bonus > 0)
            _InvoiceRow(
              label: isUz ? 'Bonus' : 'Бонусы',
              value: '-${money(bonus, state.locale)}',
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  isUz ? 'To‘lash' : 'К оплате',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : WasabiColors.dark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (state.checkoutDiscount > 0)
                    Text(
                      money(
                        state.fullPriceSubtotal +
                            (deliveryType == DeliveryType.delivery
                                ? state.settings.deliveryFee
                                : 0),
                        state.locale,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: .48)
                            : WasabiColors.muted,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    money(total, state.locale),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: WasabiColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: .58)
                    : WasabiColors.dark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: .72)
                  : WasabiColors.dark,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderingClosedNotice extends StatelessWidget {
  const _OrderingClosedNotice({required this.start, required this.end});

  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    final isUz = AppScope.of(context).locale == 'uz';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7C66F)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: WasabiColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUz
                    ? 'Buyurtmalar $start dan $end gacha qabul qilinadi'
                    : 'Заказы принимаются с $start до $end',
                style: const TextStyle(
                  color: WasabiColors.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmOrderButton extends StatefulWidget {
  const _ConfirmOrderButton({
    required this.onPressed,
    required this.submitting,
    required this.paymentMethod,
    required this.orderingOpen,
    required this.start,
  });

  final VoidCallback? onPressed;
  final bool submitting;
  final PaymentMethod paymentMethod;
  final bool orderingOpen;
  final String start;

  @override
  State<_ConfirmOrderButton> createState() => _ConfirmOrderButtonState();
}

class _ConfirmOrderButtonState extends State<_ConfirmOrderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isUz = AppScope.of(context).locale == 'uz';
    final enabled = widget.onPressed != null;
    final label = !widget.orderingOpen
        ? (isUz
            ? 'Buyurtma ${widget.start} da ochiladi'
            : 'Заказы с ${widget.start}')
        : widget.paymentMethod.requiresOnlinePayment
            ? (isUz ? "To'lovga o'tish" : 'Перейти к оплате')
            : (isUz ? 'Tasdiqlash' : 'Подтвердить заказ');
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? .98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? WasabiColors.primary
                : WasabiColors.primary.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
