import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../animations/wasabi_motion.dart';
import '../widgets/common.dart';

String resolveCatalogVisibleCategoryId({
  required double scrollOffset,
  required List<({String id, double revealOffset})> sections,
  double topResetOffset = 24,
  double anchor = 120,
}) {
  if (scrollOffset < topResetOffset || sections.isEmpty) {
    return '';
  }

  var activeId = sections.first.id;
  for (final section in sections) {
    if (scrollOffset + anchor >= section.revealOffset) {
      activeId = section.id;
    } else {
      break;
    }
  }
  return activeId;
}

double resolveCatalogMenuScrollOffset({
  required double currentOffset,
  required double itemLeft,
  required double itemWidth,
  required double viewportWidth,
  required double maxScrollExtent,
}) {
  final itemCenter = itemLeft + itemWidth / 2;
  final viewportCenter = viewportWidth / 2;
  return (currentOffset + itemCenter - viewportCenter)
      .clamp(0.0, maxScrollExtent);
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with AutomaticKeepAliveClientMixin<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _menuScrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _pillKeys = {};
  final GlobalKey _menuViewportKey = GlobalKey();
  String _visibleCategoryId = '';
  bool _syncScheduled = false;
  String? _lastRevealedCategoryId;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  void _scheduleVisibleCategorySync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _syncVisibleCategory();
    });
  }

  void _syncVisibleCategory() {
    final state = AppScope.of(context, listen: false);
    if (state.selectedCategoryId.isNotEmpty || state.categories.isEmpty) {
      if (_visibleCategoryId.isNotEmpty) {
        setState(() => _visibleCategoryId = '');
      }
      return;
    }

    final sections = <({String id, double revealOffset})>[];

    for (final category in state.categories) {
      final sectionContext = _sectionKeys[category.id]?.currentContext;
      if (sectionContext == null) continue;
      final box = sectionContext.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final viewport = RenderAbstractViewport.of(box);
      sections.add((
        id: category.id,
        revealOffset: viewport.getOffsetToReveal(box, 0).offset,
      ));
    }

    final nextVisible = resolveCatalogVisibleCategoryId(
      scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
      sections: sections,
    );

    if (nextVisible != _visibleCategoryId) {
      setState(() => _visibleCategoryId = nextVisible);
    }
  }

  void _scheduleActivePillReveal(String activeCategoryId) {
    if (_lastRevealedCategoryId == activeCategoryId) return;
    _lastRevealedCategoryId = activeCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pillContext = _pillKeys[activeCategoryId]?.currentContext;
      final viewportContext = _menuViewportKey.currentContext;
      if (pillContext == null ||
          viewportContext == null ||
          !_menuScrollController.hasClients) {
        return;
      }

      final pillBox = pillContext.findRenderObject() as RenderBox?;
      final viewportBox = viewportContext.findRenderObject() as RenderBox?;
      if (pillBox == null || viewportBox == null) return;

      final pillLeft =
          pillBox.localToGlobal(Offset.zero, ancestor: viewportBox).dx;
      final clampedOffset = resolveCatalogMenuScrollOffset(
        currentOffset: _menuScrollController.offset,
        itemLeft: pillLeft,
        itemWidth: pillBox.size.width,
        viewportWidth: viewportBox.size.width,
        maxScrollExtent: _menuScrollController.position.maxScrollExtent,
      );
      if ((clampedOffset - _menuScrollController.offset).abs() < 1) return;
      unawaited(
        _menuScrollController.animateTo(
          clampedOffset,
          duration: WasabiMotion.duration(
            context,
            const Duration(milliseconds: 260),
          ),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final selected = state.selectedCategoryId;
    final activeCategoryId = selected.isEmpty ? _visibleCategoryId : selected;
    final products = state.productsForCategory(selected);
    final catalogUnavailable = state.offlineCatalog && state.products.isEmpty;

    _scheduleVisibleCategorySync();
    _scheduleActivePillReveal(
        activeCategoryId.isEmpty ? 'all' : activeCategoryId);

    if (catalogUnavailable) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title:
            isUz ? 'Poster menyusi yuklanmadi' : 'Меню Poster не загрузилось',
        text: isUz
            ? 'Server hozir mahsulot va bo‘limlarni qaytarmayapti.'
            : 'Сервер сейчас не возвращает товары и категории.',
        action: FilledButton.icon(
          onPressed: () => AppScope.of(context, listen: false).refreshCatalog(),
          icon: const Icon(Icons.refresh),
          label: Text(isUz ? 'Qayta urinish' : 'Повторить'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        SizedBox(
          key: _menuViewportKey,
          height: 46,
          child: ListView(
            key: const ValueKey('catalog-menu-list'),
            controller: _menuScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              WasabiFadeUp(
                child: _CatalogPill(
                  key: _pillKeys.putIfAbsent('all', GlobalKey.new),
                  active: selected.isEmpty && activeCategoryId.isEmpty,
                  label: isUz ? 'Hammasi' : 'Все',
                  onTap: () => state.selectCategory(''),
                ),
              ),
              for (var index = 0; index < state.categories.length; index++) ...[
                const SizedBox(width: 8),
                WasabiFadeUp(
                  delay: Duration(milliseconds: 35 * (index + 1)),
                  child: _CatalogPill(
                    key: _pillKeys.putIfAbsent(
                        state.categories[index].id, GlobalKey.new),
                    active: activeCategoryId == state.categories[index].id,
                    label: state.categories[index].title(state.locale),
                    onTap: () =>
                        state.selectCategory(state.categories[index].id),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: selected.isEmpty
              ? _AllCategoriesView(
                  controller: _scrollController,
                  categories: state.categories,
                  popularProducts: state.popularProducts,
                  locale: state.locale,
                  productsForCategory: state.productsForCategory,
                  sectionKeys: _sectionKeys,
                  onScroll: _scheduleVisibleCategorySync,
                )
              : products.isEmpty
                  ? EmptyState(
                      icon: Icons.restaurant_menu,
                      title: isUz ? 'Bo‘lim bo‘sh' : 'В категории пока пусто',
                      text: isUz
                          ? 'Tez orada bu yerda mahsulotlar paydo bo‘ladi.'
                          : 'Скоро здесь появятся товары.',
                    )
                  : _CatalogProductGrid(
                      key: PageStorageKey('catalog-selected-$selected'),
                      products: products,
                    ),
        ),
      ],
    );
  }
}

class _CatalogProductGrid extends StatelessWidget {
  const _CatalogProductGrid({super.key, required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 640 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: constraints.maxWidth > 640
                ? 0.88
                : compactProductCardAspectRatio(context),
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => WasabiFadeUp(
            delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
            child: ProductCard(
              key: ValueKey('catalog-product-${products[index].id}'),
              product: products[index],
              compact: true,
            ),
          ),
        );
      },
    );
  }
}

class _AllCategoriesView extends StatelessWidget {
  const _AllCategoriesView({
    required this.controller,
    required this.categories,
    required this.popularProducts,
    required this.locale,
    required this.productsForCategory,
    required this.sectionKeys,
    required this.onScroll,
  });

  final ScrollController controller;
  final List<CategoryModel> categories;
  final List<ProductModel> popularProducts;
  final String locale;
  final List<ProductModel> Function(String categoryId) productsForCategory;
  final Map<String, GlobalKey> sectionKeys;
  final VoidCallback onScroll;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories
        .where((category) => productsForCategory(category.id).isNotEmpty)
        .toList(growable: false);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          onScroll();
        }
        return false;
      },
      child: CustomScrollView(
        key: const PageStorageKey('catalog-all-list'),
        controller: controller,
        // Keep a short look-ahead buffer. Building full category grids ahead
        // of the viewport made catalog scrolling jank on larger menus.
        cacheExtent: 320,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (popularProducts.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _CategorySectionHeader(
                  title: locale == 'uz' ? 'Mashhur' : 'Популярное',
                  count: popularProducts.length,
                  locale: locale,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: compactProductCardAspectRatio(context),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    key: ValueKey(
                      'popular-menu-product-${popularProducts[index].id}',
                    ),
                    product: popularProducts[index],
                    compact: true,
                  ),
                  childCount: popularProducts.length,
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: false,
                ),
              ),
            ),
          ],
          for (final category in visibleCategories) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: KeyedSubtree(
                  // Scrollable.ensureVisible expects a RenderBox, not a
                  // RenderSliver. Keep the section anchor on this header.
                  key: sectionKeys.putIfAbsent(category.id, GlobalKey.new),
                  child: _CategorySectionHeader(
                    title: category.title(locale),
                    count: productsForCategory(category.id).length,
                    locale: locale,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: compactProductCardAspectRatio(context),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final products = productsForCategory(category.id);
                    return ProductCard(
                      key: ValueKey('category-product-${products[index].id}'),
                      product: products[index],
                      compact: true,
                    );
                  },
                  childCount: productsForCategory(category.id).length,
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: false,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({
    required this.title,
    required this.count,
    required this.locale,
  });

  final String title;
  final int count;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? WasabiColors.darkMuted : WasabiColors.muted;
    final divider = isDark ? WasabiColors.darkStroke : WasabiColors.stroke;
    final countLabel = locale == 'uz' ? '$count mahsulot' : '$count товаров';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: WasabiMotion.duration(
        context,
        const Duration(milliseconds: 320),
      ),
      curve: Curves.easeOutQuart,
      child: Semantics(
        header: true,
        label: '$title, $countLabel',
        child: Row(
          children: [
            Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: WasabiColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    countLabel,
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 34, height: 1, color: divider),
          ],
        ),
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: .96 + (.04 * value),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}

class _CatalogPill extends StatelessWidget {
  const _CatalogPill({
    super.key,
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF2F8E3) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? WasabiColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            // Inactive pills keep a white background in both themes.
            color: active ? WasabiColors.primary : WasabiColors.dark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
