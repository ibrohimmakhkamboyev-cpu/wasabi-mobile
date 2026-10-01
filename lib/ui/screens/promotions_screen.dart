import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _promo = TextEditingController();

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final discounted = state.discountedProducts;
    return Scaffold(
      appBar: AppBar(title: Text(isUz ? 'Aksiyalar' : 'Акции и промокоды')),
      body: RefreshIndicator(
        onRefresh: state.refreshCatalog,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Text(
              isUz ? 'Aksiyalar va promokodlar' : 'Акции и промокоды',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark ? Colors.white : WasabiColors.dark,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              isUz
                  ? 'Haqiqiy chegirmalar katalogdan olinadi'
                  : 'Актуальные скидки берутся из каталога',
              style: const TextStyle(
                color: Color(0x99141414),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promo,
                        decoration: InputDecoration(
                          hintText:
                              isUz ? 'Promokodni kiriting' : 'Введите промокод',
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          try {
                            await state.applyPromo(_promo.text);
                            if (!context.mounted) return;
                            showWasabiMessage(
                              context,
                              isUz
                                  ? 'Promokod savatga qo‘shildi'
                                  : 'Промокод добавлен в корзину',
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
                        child: Text(isUz ? 'Qo‘llash' : 'Применить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (state.banners.isNotEmpty) ...[
              for (final banner in state.banners.take(3)) ...[
                _BannerPromoCard(banner: banner),
                const SizedBox(height: 14),
              ],
            ],
            if (discounted.isEmpty)
              EmptyState(
                icon: Icons.local_offer_outlined,
                title: isUz ? 'Faol chegirmalar yo‘q' : 'Активных скидок нет',
                text: isUz
                    ? 'Katalog yangilanganda aksiyalar shu yerda chiqadi.'
                    : 'Когда в каталоге появятся скидки, они будут показаны здесь.',
              )
            else ...[
              Text(
                isUz ? 'Chegirmadagi mahsulotlar' : 'Товары со скидкой',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white : WasabiColors.dark,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              for (final product in discounted) ...[
                _DiscountProductCard(product: product),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerPromoCard extends StatelessWidget {
  const _BannerPromoCard({required this.banner});

  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: Image.network(
          banner.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFF9FAFB),
            child: Center(
              child: Icon(Icons.local_offer_outlined,
                  color: WasabiColors.primary, size: 42),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscountProductCard extends StatelessWidget {
  const _DiscountProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final locale = state.locale;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: ProductImage(
                url: product.imageUrl,
                fallbackUrl: designProductImageUrl(product),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.discount?.label() ??
                        (locale == 'uz' ? 'Chegirma' : 'Скидка'),
                    style: const TextStyle(
                      color: WasabiColors.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        money(product.effectivePrice, locale),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        money(product.price, locale),
                        style: const TextStyle(
                          color: WasabiColors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: () => state.addToCart(product),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
