import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/address_display.dart';
import '../animations/wasabi_motion.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
      assert(scope != null, 'AppScope is missing');
      return scope!.notifier!;
    }
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    final scope = element?.widget as AppScope?;
    assert(scope != null, 'AppScope is missing');
    return scope!.notifier!;
  }
}

void showWasabiMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      content: _WasabiToast(message: message, isError: isError),
    ),
  );
}

class _WasabiToast extends StatelessWidget {
  const _WasabiToast({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? const Color(0xFFD43C33) : WasabiColors.primary;
    final background =
        isError ? const Color(0xFFFFF1EC) : const Color(0xFFF5F9E8);
    final border = isError ? const Color(0xFFFFD5CA) : const Color(0xFFDCE8B7);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: WasabiColors.dark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String money(int value, String locale) {
  final format =
      NumberFormat.decimalPattern(locale == 'uz' ? 'uz_UZ' : 'ru_RU');
  final suffix = locale == 'uz' ? "so'm" : 'сум';
  return '${format.format(value)} $suffix';
}

String orderStatusLabel(String status, String locale) {
  final normalized = status.toLowerCase();
  if (locale == 'uz') {
    switch (normalized) {
      case 'pending_payment':
        return 'To\'lov kutilmoqda';
      case 'paid':
      case 'paid_test':
        return 'To\'langan';
      case 'new':
      case 'accepted':
        return 'Qabul qilindi';
      case 'cooking':
      case 'processing':
        return 'Tayyorlanmoqda';
      case 'courier':
      case 'delivery':
        return 'Kuryerda';
      case 'closed':
      case 'delivered':
        return 'Yetkazildi';
      case 'cancelled':
      case 'canceled':
        return 'Bekor qilindi';
      default:
        return status;
    }
  }
  switch (normalized) {
    case 'pending_payment':
      return 'Ожидает оплаты';
    case 'paid':
    case 'paid_test':
      return 'Оплачено';
    case 'new':
      return 'Принят';
    case 'accepted':
      return 'Подтвержден';
    case 'cooking':
    case 'processing':
      return 'Готовится';
    case 'courier':
    case 'delivery':
      return 'Передан курьеру';
    case 'closed':
    case 'delivered':
      return 'Доставлен';
    case 'cancelled':
    case 'canceled':
      return 'Отменен';
    default:
      return status;
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'logo.png',
            width: compact ? 34 : 42,
            height: compact ? 34 : 42,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: compact ? 34 : 42,
              height: compact ? 34 : 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WasabiColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'W',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            'WASABI SUSHI',
            style: TextStyle(
              color: WasabiColors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
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
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C13) : const Color(0xFFF7F8F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? WasabiColors.darkStroke : const Color(0xFFE2E7D8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Уменьшить',
            onPressed: onMinus,
            icon: const Icon(Icons.remove),
            iconSize: 17,
            color: isDark ? WasabiColors.darkMuted : WasabiColors.muted,
            constraints: const BoxConstraints.tightFor(width: 38, height: 40),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : WasabiColors.dark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Увеличить',
            onPressed: onPlus,
            icon: const Icon(Icons.add),
            iconSize: 18,
            color: WasabiColors.primary,
            constraints: const BoxConstraints.tightFor(width: 38, height: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
  });

  final ProductModel product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final locale = state.locale;
    final quantity = state.quantityFor(product.id);
    final isSaved = state.isSaved(product.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preserveEntireProduct = _preserveEntireProductImage(product);
    final compactImageHeight = math.max(
      55.0,
      63.0 - math.max(0.0, MediaQuery.textScalerOf(context).scale(1) - 1) * 40,
    );
    final compactPriceHeight =
        state.showsCatalogDiscount(product) ? 38.0 : 26.0;
    final cardRadius = BorderRadius.circular(compact ? 16 : 28);
    final imageRadius = BorderRadius.circular(compact ? 12 : 24);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: isDark ? Colors.transparent : WasabiColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: quantity > 0 ? .9 : .55)
              : quantity > 0
                  ? const Color(0xFFEAF3CD)
                  : WasabiColors.primary.withValues(alpha: 0.95),
          width: 1.2,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF21320F),
                    Color(0xFF10180B),
                    Color(0xFF070907),
                  ],
                )
              : null,
        ),
        child: InkWell(
          borderRadius: cardRadius,
          onTap: () => showProductSheet(context, product),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 9 : 12,
              compact ? 9 : 12,
              compact ? 9 : 12,
              compact ? 8 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: compact ? compactImageHeight : 132,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ProductImage(
                          url: product.imageUrl,
                          fallbackUrl: designProductImageUrl(product),
                          borderRadius: imageRadius,
                          fit: preserveEntireProduct
                              ? BoxFit.contain
                              : BoxFit.cover,
                          edgeToEdge: !preserveEntireProduct,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.90),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: locale == 'uz' ? 'Saqlash' : 'Сохранить',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => state.toggleSaved(product.id),
                            icon: Icon(
                              isSaved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 19,
                              color: isSaved
                                  ? const Color(0xFFE32626)
                                  : isDark
                                      ? Colors.white.withValues(alpha: .72)
                                      : const Color(0x66141414),
                            ),
                          ),
                        ),
                      ),
                      if (state.showsCatalogDiscount(product))
                        Positioned(
                          top: 8,
                          left: 8,
                          child: BadgeLabel(
                            label: locale == 'uz' ? 'Chegirma' : 'Скидка',
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 5 : 10,
                      compact ? 3 : 8,
                      compact ? 5 : 10,
                      compact ? 0 : 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // The action always sits at the lower edge of the card.
                      // This prevents a large unused panel below the cart button.
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: compact ? 29 : 0,
                              ),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  product.title(locale),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: compact ? 14.2 : 16.5,
                                    height: compact ? 1.02 : 1.05,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 6),
                            compact
                                ? SizedBox(
                                    height: compactPriceHeight,
                                    child: _PriceLine(
                                      product: product,
                                      locale: locale,
                                      compact: true,
                                    ),
                                  )
                                : _PriceLine(
                                    product: product,
                                    locale: locale,
                                    compact: false,
                                  ),
                          ],
                        ),
                        if (quantity > 0) ...[
                          _ProductQtyBar(
                            quantity: quantity,
                            compact: compact,
                            onMinus: () =>
                                state.setQuantity(product.id, quantity - 1),
                            onPlus: () => state.addToCart(product),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: compact ? 28 : 34,
                            child: _ProductAddButton(
                              compact: compact,
                              onPressed: () => state.addToCart(product),
                              label: locale == 'uz' ? 'Savatga' : 'Добавить',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps compact product cards tall enough for two-line product names and the
/// action row on narrow Android devices or when the user increases text size.
double compactProductCardAspectRatio(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  if (textScale >= 1.3) return .68;
  if (textScale >= 1.1) return .78;
  return .90;
}

/// Drinks and packaged products are typically photographed vertically. They
/// must remain fully visible inside the same square media frame.
bool _preserveEntireProductImage(ProductModel product) {
  final value = '${product.categoryName ?? ''} ${product.nameRu}'.toLowerCase();
  return value.contains('напит') ||
      value.contains('ichimlik') ||
      value.contains('sok') ||
      value.contains('juice') ||
      value.contains('bliss') ||
      value.contains('voda') ||
      value.contains('water');
}

class _ProductAddButton extends StatelessWidget {
  const _ProductAddButton({
    required this.compact,
    required this.onPressed,
    required this.label,
  });

  final bool compact;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF9BDA19), Color(0xFF6B9305)],
              )
            : null,
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.shopping_cart_outlined, size: compact ? 15 : 16),
        style: FilledButton.styleFrom(
          foregroundColor: isDark ? Colors.white : WasabiColors.primary,
          backgroundColor: isDark ? Colors.transparent : Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          minimumSize: Size(0, compact ? 28 : 34),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 10.5 : 12,
          ),
        ),
        label: Text(label),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.product,
    required this.locale,
    this.compact = false,
  });

  final ProductModel product;
  final String locale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceColor = isDark ? const Color(0xFFA8E536) : Colors.white;
    final showDiscount = state.showsCatalogDiscount(product);
    final displayedPrice = state.catalogPriceFor(product);
    if (showDiscount) {
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              money(displayedPrice, locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: priceColor,
                fontSize: 15.5,
              ),
            ),
            Text(
              money(product.price, locale)
                  .replaceAll(' сум', '')
                  .replaceAll(" so'm", ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xC7E6EFD0),
                decoration: TextDecoration.lineThrough,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }
      return Row(
        children: [
          Flexible(
            child: Text(
              money(displayedPrice, locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: priceColor,
                fontSize: compact ? 15.5 : 15,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            money(product.price, locale)
                .replaceAll(' сум', '')
                .replaceAll(" so'm", ''),
            style: const TextStyle(
              color: Color(0xC7E6EFD0),
              decoration: TextDecoration.lineThrough,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return Text(
      money(displayedPrice, locale),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        color: priceColor,
        fontSize: compact ? 15.5 : 15,
      ),
    );
  }
}

class _ProductQtyBar extends StatelessWidget {
  const _ProductQtyBar({
    required this.quantity,
    this.compact = false,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final bool compact;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: compact ? 28 : 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: .96) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
      ),
      child: Row(
        children: [
          _QtyIconButton(
            icon: Icons.remove,
            onPressed: onMinus,
            inverted: true,
            compact: compact,
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFE6EEDC) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: WasabiAnimatedNumber(
                value: quantity,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDark ? const Color(0xFF315200) : WasabiColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 18 : 19,
                  height: 1,
                ),
              ),
            ),
          ),
          _QtyIconButton(
            icon: Icons.add,
            onPressed: onPlus,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  const _QtyIconButton({
    required this.icon,
    required this.onPressed,
    this.inverted = false,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool inverted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = inverted
        ? (isDark
            ? const Color(0xFFEFF5E8)
            : WasabiColors.primary.withValues(alpha: .10))
        : WasabiColors.primary;
    final foregroundColor = inverted ? const Color(0xFF315200) : Colors.white;
    final radius = BorderRadius.circular(compact ? 12 : 14);
    return SizedBox(
      width: compact ? 24 : 28,
      height: compact ? 24 : 28,
      child: Material(
        color: backgroundColor,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Icon(
            icon,
            size: compact ? 13 : 14,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class ProductImage extends StatefulWidget {
  const ProductImage({
    super.key,
    this.url,
    this.fallbackUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.contain,
    this.edgeToEdge = false,
    this.backgroundColor = Colors.white,
  });

  final String? url;
  final String? fallbackUrl;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final bool edgeToEdge;
  final Color? backgroundColor;

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  @override
  Widget build(BuildContext context) {
    final primaryUrl = widget.url?.trim() ?? '';
    final imageUrl =
        primaryUrl.isNotEmpty ? primaryUrl : (widget.fallbackUrl ?? '');
    final image = imageUrl.isEmpty
        ? const Center(
            child: Icon(
              Icons.ramen_dining,
              color: WasabiColors.primary,
              size: 42,
            ),
          )
        : widget.edgeToEdge
            ? _networkProductImage(imageUrl)
            : Padding(
                padding: const EdgeInsets.all(2),
                child: _networkProductImage(imageUrl),
              );
    // Keep image repaint work isolated while a long product grid scrolls.
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: widget.backgroundColor == null
            ? image
            : ColoredBox(color: widget.backgroundColor!, child: image),
      ),
    );
  }

  Widget _networkProductImage(String imageUrl) {
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: widget.fit,
      alignment: Alignment.center,
      // Product cards are small; avoid decoding oversized source images at full cost.
      cacheWidth: 512,
      // Product cards are small; medium quality is visually equivalent here
      // and avoids costly high-quality sampling while scrolling a grid.
      filterQuality: FilterQuality.medium,
      // A grid cell is reused while scrolling. Keeping the previous image painted
      // here makes another product temporarily (and sometimes persistently) show
      // the old product photo. Key each image by its URL and clear the old frame.
      key: ValueKey<String>('product-image:$imageUrl'),
      gaplessPlayback: false,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.ramen_dining,
          color: WasabiColors.primary,
          size: 42,
        ),
      ),
    );
  }
}

String designProductImageUrl(ProductModel product) {
  final title = product.nameRu.toLowerCase();
  final category =
      '${product.categoryName ?? ''} ${product.categoryId ?? ''}'.toLowerCase();
  if (title.contains('филадельф') || title.contains('philadelphia')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_58aa498d0d_6a3e691633a139af.png';
  }
  if (title.contains('калифор') || title.contains('california')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_8c735138c8_1f94fdd7a621ba34.png';
  }
  if (title.contains('запеч') ||
      title.contains('угр') ||
      title.contains('dragon')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_98f0ac469c_6825c1d6b6c1c91f.png';
  }
  if (title.contains('set') ||
      title.contains('сет') ||
      category.contains('set') ||
      category.contains('сет')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_3fe965ce0b_19a2594d1cd3045a.png';
  }
  if (title.contains('drink') ||
      title.contains('напит') ||
      category.contains('drink') ||
      category.contains('напит')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_3ee539f61d_f93a7f7c6febea2e.png';
  }
  if (title.contains('sushi') ||
      title.contains('суш') ||
      category.contains('sushi') ||
      category.contains('суш')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_2d4a357566_28ca302b7de13255.png';
  }
  return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_8c735138c8_1f94fdd7a621ba34.png';
}

String designCartItemImageUrl(CartItem item) {
  return designProductImageUrl(
    ProductModel(
      id: item.productId,
      nameRu: item.name,
      price: item.price,
      categoryId: item.categoryId,
    ),
  );
}

String designCategoryImageUrl(CategoryModel category) {
  final name = '${category.nameRu} ${category.id}'.toLowerCase();
  if (name.contains('сет') || name.contains('set')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_3fe965ce0b_19a2594d1cd3045a.png';
  }
  if (name.contains('суш') || name.contains('sushi')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_2d4a357566_28ca302b7de13255.png';
  }
  if (name.contains('wok') || name.contains('вок')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_971c5d6e51_2505d1f08f596b95.png';
  }
  if (name.contains('суп') || name.contains('soup')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_67dbc09263_99e477c9bb71a8ef.png';
  }
  if (name.contains('напит') || name.contains('drink')) {
    return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_3ee539f61d_f93a7f7c6febea2e.png';
  }
  return 'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_8e8174dce1_c9e2f7a166f74bd8.png';
}

class BadgeLabel extends StatelessWidget {
  const BadgeLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: WasabiColors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WasabiColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: WasabiColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class TotalRow extends StatelessWidget {
  const TotalRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      fontSize: strong ? 18 : 14,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.selected,
    this.onTap,
    this.trailing,
    this.premium = false,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    if (premium) {
      return Card(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: .76)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .94),
                Colors.white.withValues(alpha: .76),
                const Color(0xFFEAF6D2).withValues(alpha: .28),
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _AddressCardDotPattern()),
              ListTile(
                onTap: onTap,
                leading: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: WasabiColors.primary.withValues(alpha: .10),
                  ),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.location_on_outlined,
                    color: WasabiColors.primary,
                  ),
                ),
                title: Text(
                  displayAddressLabel(address.address),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  [
                    if (address.entrance != null) 'подъезд ${address.entrance}',
                    if (address.floor != null) 'этаж ${address.floor}',
                    if (address.apartment != null) address.apartment!,
                  ].join(', '),
                ),
                trailing: trailing,
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      color: selected
          ? WasabiColors.primary.withValues(alpha: 0.08)
          : Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.location_on_outlined,
          color: WasabiColors.primary,
        ),
        title: Text(
          displayAddressLabel(address.address),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            if (address.entrance != null) 'подъезд ${address.entrance}',
            if (address.floor != null) 'этаж ${address.floor}',
            if (address.apartment != null) address.apartment!,
          ].join(', '),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _AddressCardDotPattern extends StatelessWidget {
  const _AddressCardDotPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AddressCardDotPainter());
  }
}

class _AddressCardDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = WasabiColors.primary.withValues(alpha: .050);
    for (var x = size.width * .72; x < size.width - 12; x += 8) {
      for (var y = 14.0; y < size.height - 14; y += 8) {
        final fade = ((x - size.width * .72) / (size.width * .28)).clamp(0, 1);
        canvas.drawCircle(Offset(x, y), 1.2 + fade * 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    required this.selected,
    this.onTap,
  });

  final BranchModel branch;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 0 : null,
      color: selected
          ? WasabiColors.primary.withValues(alpha: isDark ? .16 : 0.08)
          : isDark
              ? const Color(0xFF11180D)
              : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? WasabiColors.primary.withValues(alpha: .72)
              : isDark
                  ? WasabiColors.primary.withValues(alpha: .18)
                  : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.storefront_outlined,
          color: WasabiColors.primary,
        ),
        title: Text(
          branch.name,
          style: TextStyle(
            color: isDark ? Colors.white : WasabiColors.dark,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          [
            branch.address,
            if (branch.workTime != null) branch.workTime!,
            if (branch.phone != null) branch.phone!,
          ].join('\n'),
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: .68)
                : WasabiColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class DeliveryRouteCard extends StatelessWidget {
  const DeliveryRouteCard({
    super.key,
    required this.address,
    this.compact = false,
    this.onOpenMap,
  });

  final AddressModel address;
  final bool compact;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final locale = state.locale;
    final isUz = locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estimate = state.estimateDelivery(address);
    final routeLabel =
        isUz ? 'Wasabi yetkazib berish nuqtasi' : 'Точка доставки Wasabi';

    return Card(
      color: isDark ? const Color(0xFF0F140C) : Colors.white,
      elevation: isDark ? 0 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .28)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: WasabiColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: WasabiColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUz ? 'Yetkazish xaritasi' : 'Карта доставки',
                        style: TextStyle(
                          color: isDark ? Colors.white : WasabiColors.dark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        estimate == null
                            ? (isUz
                                ? 'Filial aniqlanmoqda'
                                : 'Филиал определяется')
                            : '${estimate.timeText(locale)} • ${estimate.distanceText(locale)}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: .70)
                              : WasabiColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isUz ? 'Xaritani ochish' : 'Открыть карту',
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: compact ? 2.7 : 2.1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _RouteFallback(),
                    Container(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF11180D).withValues(alpha: .94)
                              : Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? WasabiColors.primary.withValues(alpha: .22)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RouteText(
                              icon: Icons.storefront_outlined,
                              text: routeLabel,
                            ),
                            const SizedBox(height: 5),
                            _RouteText(
                              icon: Icons.location_on_outlined,
                              text: displayAddressLabel(address.address),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteText extends StatelessWidget {
  const _RouteText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: WasabiColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : WasabiColors.dark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteFallback extends StatelessWidget {
  const _RouteFallback();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _RoutePainter(isDark: isDark),
      child: Stack(
        children: [
          const Positioned(
            left: 42,
            top: 34,
            child: Icon(Icons.storefront, color: WasabiColors.primary),
          ),
          const Positioned(
            right: 42,
            bottom: 34,
            child: Icon(Icons.location_pin, color: WasabiColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = isDark ? const Color(0xFF17210F) : const Color(0xFFEAF1E2);
    canvas.drawRect(Offset.zero & size, background);
    final road = Paint()
      ..color = isDark ? const Color(0xFF2B3721) : Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.28)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.48,
        size.height * 0.76,
        size.width * 0.82,
        size.height * 0.68,
      );
    canvas.drawPath(path, road);
    final line = Paint()
      ..color = WasabiColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

Future<void> showProductSheet(BuildContext context, ProductModel product) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: isDark ? const Color(0xFF111115) : WasabiColors.background,
    barrierColor: Colors.black.withValues(alpha: .35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => _ProductDetailSheet(product: product),
  );
}

class _ProductDetailSheet extends StatefulWidget {
  const _ProductDetailSheet({required this.product});

  final ProductModel product;

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet>
    with TickerProviderStateMixin {
  int _quantity = 1;
  AnimationController? _entranceController;
  Animation<double>? _imageEntrance;
  Animation<double>? _contentEntrance;
  Animation<double>? _bottomEntrance;

  @override
  void initState() {
    super.initState();
    _ensureEntranceAnimations();
  }

  void _ensureEntranceAnimations() {
    if (_entranceController != null) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _entranceController = controller;
    _imageEntrance = CurvedAnimation(
      parent: controller,
      curve: const Interval(0, .72, curve: Curves.easeOutCubic),
    );
    _contentEntrance = CurvedAnimation(
      parent: controller,
      curve: const Interval(.16, .88, curve: Curves.easeOutCubic),
    );
    _bottomEntrance = CurvedAnimation(
      parent: controller,
      curve: const Interval(.34, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entranceController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureEntranceAnimations();
    final state = AppScope.of(context);
    final locale = state.locale;
    final isUz = locale == 'uz';
    final product = widget.product;
    final description = product.description(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recommended = state.recommendationsFor(product);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .96,
      minChildSize: .74,
      maxChildSize: 1,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  // The sheet artwork is decorative, not interactive. Keeping
                  // it static avoids continuously rasterizing blurred waves
                  // behind a scrolling product sheet.
                  painter: _ProductSheetBackgroundPainter(
                    progress: .5,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _ProductEntrance(
                    animation: _imageEntrance!,
                    dy: 18,
                    child: _ProductTopImageSection(product: product),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ProductEntrance(
                    animation: _contentEntrance!,
                    dy: 24,
                    child: Container(
                      key: const Key('product-detail-info-panel'),
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xE61D211A)
                            : Colors.white.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: .08)
                              : Colors.white.withValues(alpha: .92),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? .22 : .08,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title(locale),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : WasabiColors.dark,
                              fontSize: 28,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: .64)
                                    : WasabiColors.dark.withValues(alpha: .58),
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _ProductDetailPrice(product: product, locale: locale),
                          const SizedBox(height: 28),
                          if (recommended.isNotEmpty) ...[
                            _RecommendedSectionHeader(isUz: isUz),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (recommended.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      118 + bottomPadding,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio:
                            compactProductCardAspectRatio(context),
                      ),
                      itemCount: recommended.length,
                      itemBuilder: (context, index) => _ProductEntrance(
                        animation: _contentEntrance!,
                        dy: 18 + index * 2,
                        child: ProductCard(
                          product: recommended[index],
                          compact: true,
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(height: 118 + bottomPadding),
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ProductEntrance(
                animation: _bottomEntrance!,
                dy: 34,
                child: _ProductDetailBottomBar(
                  quantity: _quantity,
                  locale: locale,
                  onMinus: () {
                    if (_quantity <= 1) return;
                    setState(() => _quantity--);
                  },
                  onPlus: () => setState(() => _quantity++),
                  onAdd: () {
                    state.addToCart(product, quantity: _quantity);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductEntrance extends StatelessWidget {
  const _ProductEntrance({
    required this.animation,
    required this.child,
    this.dy = 18,
  });

  final Animation<double> animation;
  final Widget child;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * dy),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProductSheetBackgroundPainter extends CustomPainter {
  const _ProductSheetBackgroundPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF101114),
                Color(0xFF15180F),
                Color(0xFF0D0E10),
              ]
            : const [
                Color(0xFFFFFBDE),
                Color(0xFFFFF8C8),
                Color(0xFFF4F9DA),
              ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = (isDark ? Colors.white : WasabiColors.primary).withValues(
        alpha: isDark ? .070 : .105,
      );
    for (var i = 0; i < 4; i++) {
      final y = size.height * (.20 + i * .18);
      final shift = (progress * size.width * (i.isEven ? 1 : -1)) % size.width;
      final path = Path()..moveTo(-size.width + shift, y);
      for (var x = -size.width; x <= size.width * 2; x += 84) {
        path.quadraticBezierTo(
          x + 42 + shift,
          y + (i.isEven ? 24 : -24),
          x + 84 + shift,
          y,
        );
      }
      canvas.drawPath(path, wavePaint);
    }

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34);
    for (var i = 0; i < 3; i++) {
      final angle = progress * 6.28318 + i * 2.1;
      final center = Offset(
        size.width * (.20 + .30 * i) + math.sin(angle) * 18,
        size.height * (.22 + .20 * i) + math.cos(angle) * 22,
      );
      glowPaint.color =
          (i == 1 ? const Color(0xFFC51F1A) : WasabiColors.primary)
              .withValues(alpha: isDark ? .050 : .070);
      canvas.drawCircle(center, 70 + i * 22, glowPaint);
    }

    final leafPaint = Paint()
      ..color = WasabiColors.primary.withValues(alpha: isDark ? .10 : .12);
    for (var i = 0; i < 7; i++) {
      final drift = math.sin(progress * 6.28318 + i) * 10;
      final center = Offset(
        size.width * (.12 + (i % 3) * .34) + drift,
        size.height * (.42 + i * .085),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-.70 + i * .22);
      final leaf = Path()
        ..moveTo(0, -12)
        ..quadraticBezierTo(18, -3, 0, 18)
        ..quadraticBezierTo(-13, -1, 0, -12);
      canvas.drawPath(leaf, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ProductSheetBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

class _RecommendedSectionHeader extends StatelessWidget {
  const _RecommendedSectionHeader({required this.isUz});

  final bool isUz;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      isUz ? 'Tavsiya etamiz' : 'Рекомендуем',
      style: TextStyle(
        color: isDark ? Colors.white : WasabiColors.dark,
        fontSize: 30,
        height: 1,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _ProductTopImageSection extends StatelessWidget {
  const _ProductTopImageSection({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      key: const Key('product-detail-image-section'),
      height: 308,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: 0,
            bottom: 10,
            child: Container(
              key: const Key('product-detail-image-frame'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242820) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: .09)
                      : const Color(0xFFF0F2EC),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .28 : .10),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ProductImage(
                url: product.imageUrl,
                fallbackUrl: designProductImageUrl(product),
                borderRadius: BorderRadius.circular(18),
                fit: BoxFit.contain,
                edgeToEdge: true,
                backgroundColor: null,
              ),
            ),
          ),
          Positioned(
            right: 28,
            top: 16,
            child: _ProductSaveButton(product: product),
          ),
        ],
      ),
    );
  }
}

class _ProductSaveButton extends StatelessWidget {
  const _ProductSaveButton({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isSaved = state.isSaved(product.id);
    return Semantics(
      key: const Key('product-detail-save-button'),
      button: true,
      label: 'Save product',
      child: _ProductSheetCircleButton(
        icon: isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isSaved ? const Color(0xFFFF5B68) : null,
        onPressed: () => state.toggleSaved(product.id),
      ),
    );
  }
}

class _ProductSheetCircleButton extends StatelessWidget {
  const _ProductSheetCircleButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF2A2A30) : Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: color ?? (isDark ? Colors.white : WasabiColors.dark),
        iconSize: 28,
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints.tightFor(width: 58, height: 58),
      ),
    );
  }
}

class _ProductDetailPrice extends StatelessWidget {
  const _ProductDetailPrice({
    required this.product,
    required this.locale,
  });

  final ProductModel product;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          money(state.catalogPriceFor(product), locale),
          style: TextStyle(
            color: isDark ? Colors.white : WasabiColors.dark,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (state.showsCatalogDiscount(product)) ...[
          const SizedBox(height: 4),
          Text(
            money(product.price, locale),
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: .44)
                  : WasabiColors.dark.withValues(alpha: .42),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

class _RecommendedProductTile extends StatefulWidget {
  const _RecommendedProductTile({required this.product});

  final ProductModel product;

  @override
  State<_RecommendedProductTile> createState() =>
      _RecommendedProductTileState();
}

class _RecommendedProductTileState extends State<_RecommendedProductTile> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final locale = state.locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final quantity = state.quantityFor(product.id);
    return Material(
      color: isDark ? const Color(0xFF1D1D23) : WasabiColors.primary,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) showProductSheet(context, product);
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(
                      url: product.imageUrl,
                      fallbackUrl: designProductImageUrl(product),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 10,
                    child: quantity > 0
                        ? SizedBox(
                            width: 122,
                            height: 34,
                            child: _ProductQtyBar(
                              quantity: quantity,
                              compact: true,
                              onMinus: () =>
                                  state.setQuantity(product.id, quantity - 1),
                              onPlus: _addProduct,
                            ),
                          )
                        : Semantics(
                            button: true,
                            label: locale == 'uz'
                                ? 'Savatga qo\'shish'
                                : 'Добавить в корзину',
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: isDark ? 0 : 5,
                              shadowColor: Colors.black.withValues(alpha: .18),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _addProduct,
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: Icon(
                                      _added
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      key: ValueKey(_added),
                                      color: _added
                                          ? WasabiColors.primary
                                          : WasabiColors.dark,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: isDark ? const Color(0xFF1B1B20) : WasabiColors.primary,
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    money(product.effectivePrice, locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.title(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: isDark ? .84 : .94),
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addProduct() {
    final state = AppScope.of(context, listen: false);
    state.addToCart(widget.product);
    setState(() => _added = true);
    showWasabiMessage(
      context,
      state.locale == 'uz' ? 'Savatga qo\'shildi' : 'Добавлено в корзину',
    );
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _added = false);
    });
  }
}

class _ProductDetailBottomBar extends StatelessWidget {
  const _ProductDetailBottomBar({
    required this.quantity,
    required this.locale,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  final int quantity;
  final String locale;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isUz = locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1D23) : WasabiColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .34 : .10),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          _QuantityCircleButton(icon: Icons.remove_rounded, onPressed: onMinus),
          SizedBox(
            width: 52,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : WasabiColors.dark,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _QuantityCircleButton(icon: Icons.add_rounded, onPressed: onPlus),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onAdd,
              child: Text(
                isUz ? 'Savatga' : 'В корзину',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 58),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor:
                    isDark ? Colors.transparent : WasabiColors.primary,
                foregroundColor: isDark ? WasabiColors.primary : Colors.white,
                side: isDark
                    ? const BorderSide(color: WasabiColors.primary, width: 1.5)
                    : BorderSide.none,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityCircleButton extends StatelessWidget {
  const _QuantityCircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: isDark ? Colors.black : WasabiColors.dark,
        iconSize: 32,
        constraints: const BoxConstraints.tightFor(width: 58, height: 58),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: WasabiColors.primary),
      ),
    );
  }
}
