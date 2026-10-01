import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/wasabi_page_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _query.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _query.text.trim();
    final products = query.isEmpty
        ? state.popularProducts
        : state.searchProducts(query, '').take(40).toList(growable: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: _SearchBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF11150D).withValues(alpha: .88)
                            : Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? WasabiColors.primary.withValues(alpha: .26)
                              : const Color(0xFFE8E8E8),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: isDark ? Colors.white : WasabiColors.dark,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _query,
                              focusNode: _focusNode,
                              onChanged: (_) => setState(() {}),
                              cursorColor: WasabiColors.primary,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark ? Colors.white : WasabiColors.dark,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                hintText: isUz
                                    ? 'Sushi, roll, ichimlik qidiring...'
                                    : 'Search sushi, rolls, drinks...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: .54)
                                      : const Color(0xFF777777),
                                  fontWeight: FontWeight.w700,
                                ),
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _query.clear();
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: isDark
                                              ? Colors.white
                                              : WasabiColors.dark,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: isUz ? 'Topilmadi' : 'Ничего не найдено',
                          text: isUz
                              ? 'Boshqa nom bilan qidirib ko‘ring.'
                              : 'Попробуйте другое название блюда.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                          itemBuilder: (context, index) => _MealSearchCard(
                            product: products[index],
                          ),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemCount: products.length,
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

class _SearchBackground extends StatelessWidget {
  const _SearchBackground();

  @override
  Widget build(BuildContext context) {
    return const WasabiPageBackground(animate: true);
  }
}

class _MealSearchCard extends StatelessWidget {
  const _MealSearchCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final qty = state.quantityFor(product.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF10140D) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => showProductSheet(context, product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? WasabiColors.primary.withValues(alpha: .35)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: .34)
                    : const Color(0x0D000000),
                blurRadius: isDark ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth =
                  (constraints.maxWidth * .26).clamp(72.0, 104.0).toDouble();
              return Row(
                children: [
                  SizedBox(
                    width: imageWidth,
                    height: imageWidth / 1.6,
                    child: ProductImage(
                      url: product.imageUrl,
                      fallbackUrl: designProductImageUrl(product),
                      borderRadius: BorderRadius.circular(14),
                      fit: BoxFit.contain,
                      edgeToEdge: true,
                      backgroundColor: isDark
                          ? const Color(0xFF182112)
                          : const Color(0xFFF7F8F4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.title(state.locale),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : WasabiColors.dark,
                            fontSize: 16,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchPriceText(
                            state.catalogPriceFor(product),
                            state.locale,
                          ),
                          style: TextStyle(
                            color: WasabiColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SearchQuantityStepper(
                    quantity: qty,
                    onMinus: qty == 0
                        ? null
                        : () => state.setQuantity(product.id, qty - 1),
                    onPlus: () => state.addToCart(product),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String _searchPriceText(int price, String locale) {
  return money(_searchDisplayPrice(price), locale)
      .replaceAll('сум', 'UZS')
      .replaceAll("so'm", 'UZS');
}

int _searchDisplayPrice(int price) {
  if (price >= 100000 && price % 100 == 0) return price ~/ 100;
  return price;
}

class _SearchQuantityStepper extends StatelessWidget {
  const _SearchQuantityStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: .94)
            : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onPressed: onMinus,
            background: isDark ? const Color(0xFFE6EEDC) : Colors.white,
            foreground: isDark ? const Color(0xFF315200) : WasabiColors.dark,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFF315200) : WasabiColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onPressed: onPlus,
            background: WasabiColors.primary,
            foreground: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: onPressed == null
              ? Colors.white.withValues(alpha: 0.7)
              : background,
          foregroundColor:
              onPressed == null ? const Color(0xFFB8B8B8) : foreground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
