import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../animations/wasabi_motion.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.standalone = false,
    this.onAddMore,
  });

  final bool standalone;
  final VoidCallback? onAddMore;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promo = TextEditingController();
  String _syncedPromoCode = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = AppScope.of(context).promoCode;
    if (code == _syncedPromoCode) return;
    _syncedPromoCode = code;
    _promo.text = code;
  }

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    if (!widget.standalone) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: content,
    );
  }

  Widget _content(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    if (state.cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: isUz ? 'Savat bo‘sh' : 'Корзина пустая',
        text: isUz
            ? 'Menyudan taom tanlang va buyurtmani rasmiylashtiring.'
            : 'Добавьте блюда из каталога и оформите заказ.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          isUz ? 'Savat' : 'Корзина',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        ...state.cart.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WasabiFadeUp(
                delay: Duration(milliseconds: entry.key * 35),
                child: _CartItemTile(item: entry.value),
              ),
            )),
        OutlinedButton.icon(
          onPressed: widget.onAddMore ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.add),
          label: Text(isUz ? 'Yana taom qo‘shish' : 'Добавить еще блюда'),
          style: OutlinedButton.styleFrom(
            foregroundColor: WasabiColors.primary,
            side: BorderSide(
              color: WasabiColors.primary.withValues(alpha: 0.30),
              width: 1.6,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WasabiColors.secondary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        color: WasabiColors.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isUz ? 'Promokod yoki chegirma' : 'Промокод или скидка',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackControls = constraints.maxWidth < 300;
                    final action = state.promoCode.isNotEmpty
                        ? IconButton.filledTonal(
                            onPressed: () {
                              state.clearPromo();
                              _promo.clear();
                              showWasabiMessage(
                                context,
                                isUz
                                    ? 'Promokod olib tashlandi'
                                    : 'Промокод убран',
                              );
                            },
                            icon: const Icon(Icons.close),
                            tooltip: isUz ? 'Olib tashlash' : 'Убрать',
                          )
                        : FilledButton(
                            onPressed: () async {
                              try {
                                await state.applyPromo(_promo.text);
                                if (!context.mounted) return;
                                showWasabiMessage(
                                  context,
                                  isUz
                                      ? 'Promokod qo‘llandi'
                                      : 'Промокод применен',
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                showWasabiMessage(
                                  context,
                                  error.toString(),
                                  isError: true,
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: WasabiColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: Size(
                                  stackControls ? double.infinity : 118, 52),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: Text(
                              isUz ? 'OK' : 'Применить',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                    final input = TextField(
                      controller: _promo,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: isUz ? 'Kodni kiriting' : 'Введите код',
                      ),
                    );

                    if (stackControls) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          input,
                          const SizedBox(height: 10),
                          action,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: input),
                        const SizedBox(width: 8),
                        SizedBox(width: 118, child: action),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (state.promoDiscount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              isUz ? 'Promokod qo‘llandi' : 'Промокод применен',
              style: const TextStyle(
                color: WasabiColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUz ? 'Buyurtma summasi' : 'Сумма заказа',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                TotalRow(
                  label: isUz ? 'Mahsulotlar narxi' : 'Стоимость товаров',
                  value: money(state.subtotal, state.locale),
                ),
                TotalRow(
                  label: isUz ? 'Soni' : 'Количество',
                  value: '${state.cartCount} ${isUz ? 'dona' : 'шт'}',
                ),
                if (state.promoDiscount > 0)
                  TotalRow(
                    label: isUz ? 'Chegirma' : 'Скидка',
                    value: '-${money(state.promoDiscount, state.locale)}',
                  ),
                const Divider(),
                TotalRow(
                  label: isUz ? 'To‘lash' : 'К оплате',
                  value:
                      money(state.totalFor(DeliveryType.pickup), state.locale),
                  strong: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () {
            if (!state.isAuthenticated) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            );
          },
          icon: const Icon(Icons.arrow_forward),
          label: Text(isUz ? 'Rasmiylashtirish' : 'Оформить заказ'),
        ),
        TextButton.icon(
          onPressed: state.clearCart,
          icon: const Icon(Icons.delete_outline),
          label: Text(isUz ? 'Savatni tozalash' : 'Очистить корзину'),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unitPrice = money(item.price, state.locale);
    final total = money(item.total, state.locale);
    final titleColor = isDark ? Colors.white : WasabiColors.dark;
    final mutedColor = isDark ? WasabiColors.darkMuted : WasabiColors.muted;

    return Card(
      color: isDark ? const Color(0xFF10150D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? WasabiColors.darkStroke : const Color(0xFFE8EEDC),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 136,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 96,
                          child: ProductImage(
                            url: item.imageUrl,
                            fallbackUrl: designCartItemImageUrl(item),
                            borderRadius: BorderRadius.circular(17),
                            fit: BoxFit.contain,
                            backgroundColor: isDark
                                ? const Color(0xFF1A2114)
                                : const Color(0xFFF6F8F1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            // Reserve the delete-action area. Text must never
                            // run under the top-right control on narrow phones.
                            padding: const EdgeInsets.only(right: 56),
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                height: 1.16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$unitPrice × ${item.quantity}',
                                        maxLines: 1,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        total,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _CartQuantityControl(
                                quantity: item.quantity,
                                onMinus: () => state.setQuantity(
                                    item.productId, item.quantity - 1),
                                onPlus: () => state.setQuantity(
                                    item.productId, item.quantity + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: WasabiColors.secondary.withValues(alpha: .10),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => state.removeFromCart(item.productId),
                  tooltip: state.locale == 'uz'
                      ? 'Savatdan olib tashlash'
                      : 'Убрать из корзины',
                  icon: const Icon(Icons.delete_outline_rounded),
                  iconSize: 19,
                  color: WasabiColors.secondary,
                  constraints:
                      const BoxConstraints.tightFor(width: 40, height: 40),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartQuantityControl extends StatelessWidget {
  const _CartQuantityControl({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C13) : const Color(0xFFF8FAF4),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: isDark ? WasabiColors.darkStroke : const Color(0xFFDCE8CE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onMinus,
            tooltip: 'Уменьшить',
            icon: const Icon(Icons.remove_rounded),
            color: isDark ? WasabiColors.darkMuted : WasabiColors.muted,
            iconSize: 18,
            constraints: const BoxConstraints.tightFor(width: 36, height: 44),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : WasabiColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Material(
            color: WasabiColors.primary,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onPlus,
              tooltip: 'Увеличить',
              icon: const Icon(Icons.add_rounded),
              color: Colors.white,
              iconSize: 21,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
