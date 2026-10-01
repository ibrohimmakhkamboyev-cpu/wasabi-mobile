import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/app_models.dart';
import '../../services/native_bridge.dart';
import '../../theme/app_theme.dart';
import '../../utils/address_display.dart';
import '../widgets/common.dart';
import '../widgets/wessabi_entrance.dart';
import 'map_picker_screen.dart';
import 'promotions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenCatalog,
    this.onOpenMenu,
    this.isActive = true,
  });

  final VoidCallback? onOpenCatalog;

  /// Backwards-compatible alias for older callers.
  final VoidCallback? onOpenMenu;

  /// The shell keeps tabs alive. Stop carousel work while this tab is hidden.
  final bool isActive;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _bannerController;
  Timer? _bannerTimer;
  int _bannerIndex = 0;
  bool _bannerPaused = false;
  final Set<String> _preloadedBannerUrls = {};

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final state = AppScope.of(context, listen: false);
      final count = state.banners.isEmpty ? 1 : state.banners.length;
      if (!mounted ||
          !widget.isActive ||
          _bannerPaused ||
          count <= 1 ||
          !_bannerController.hasClients ||
          _bannerController.positions.length != 1) {
        return;
      }
      // The page view is unbounded, so moving from the last banner to the
      // first continues into the next virtual page without a visible reset.
      final next = (_bannerController.page ?? 0).round() + 1;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _handleBannerChanged(int page) {
    final count = AppScope.of(context, listen: false).banners.length;
    if (count <= 1) {
      setState(() => _bannerIndex = 0);
      return;
    }

    final logicalPage = page % count;
    setState(() => _bannerIndex = logicalPage);
    _precacheBannerImages(
      AppScope.of(context, listen: false).banners,
      startAt: logicalPage,
    );
  }

  void _setBannerScrollActive(bool active) {
    if (_bannerPaused == active) return;
    setState(() => _bannerPaused = active);
  }

  void _precacheBannerImages(List<BannerModel> banners, {int? startAt}) {
    if (!mounted || banners.isEmpty) return;
    final first = (startAt ?? _bannerIndex) % banners.length;
    for (final offset in const [0, 1]) {
      final url = banners[(first + offset) % banners.length].imageUrl;
      if (!_preloadedBannerUrls.add(url)) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          precacheImage(NetworkImage(url), context).catchError((_) {});
        }
      });
    }
  }

  Future<void> _openBanner(BannerModel banner) async {
    final href = banner.href?.trim() ?? '';
    // A banner without a configured destination is visual-only. It must not
    // unexpectedly redirect the customer to an unrelated section.
    if (href.isEmpty) {
      return;
    }
    final parsedUri = Uri.tryParse(href);
    final uri = parsedUri != null && !parsedUri.hasScheme
        ? Uri.tryParse('${AppConfig.apiBaseUrl}$href')
        : parsedUri;
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return;
    }

    final state = AppScope.of(context, listen: false);
    final fragment = Uri.decodeComponent(uri.fragment).trim();
    final target = fragment.toLowerCase();
    if (target.isEmpty || target == 'products' || target == 'popular') {
      state.selectPopularCatalog();
      _openCatalog();
      return;
    }
    if (target.startsWith('cat-')) {
      final categoryTarget = _bannerTargetKey(fragment.substring(4));
      final category = state.categories.cast<CategoryModel?>().firstWhere(
            (item) =>
                item != null &&
                (_bannerTargetKey(item.id) == categoryTarget ||
                    _bannerTargetKey(item.nameRu) == categoryTarget ||
                    _bannerTargetKey(item.title(state.locale)) ==
                        categoryTarget),
            orElse: () => null,
          );
      if (category != null) {
        state.selectCategory(category.id);
        _openCatalog();
        return;
      }
      // A category that exists only on the website must keep working instead
      // of opening an unrelated mobile category.
      await NativeBridge.openUrl(uri.toString());
      return;
    }
    if (target == 'promotions' || target == 'promotion') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PromotionsScreen()),
      );
      return;
    }
    if (target.startsWith('product-')) {
      final productId = fragment.substring('product-'.length);
      final product = state.products.cast<ProductModel?>().firstWhere(
            (item) => item?.id == productId,
            orElse: () => null,
          );
      if (product != null && mounted) {
        await showProductSheet(context, product);
        return;
      }
    }
    await NativeBridge.openUrl(uri.toString());
  }

  void _openCatalog() {
    (widget.onOpenCatalog ?? widget.onOpenMenu)?.call();
  }

  String _bannerTargetKey(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9а-яё]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _precacheBannerImages(state.banners);
    final opening = WessabiHomeOpeningScope.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUz = state.locale == 'uz';
    final selectedCategory = state.selectedCategoryId.isEmpty
        ? null
        : state.categories.firstWhere(
            (category) => category.id == state.selectedCategoryId,
            orElse: () => const CategoryModel(id: '', nameRu: ''),
          );
    final selectedProducts =
        selectedCategory == null || selectedCategory.id.isEmpty
            ? null
            : state.productsForCategory(selectedCategory.id);
    final popular = selectedProducts ?? state.popularProducts;
    final productTitle = selectedCategory == null || selectedCategory.id.isEmpty
        ? (isUz ? 'Mashhur' : 'Популярное')
        : selectedCategory.title(state.locale);
    final catalogUnavailable =
        state.offlineCatalog && state.products.isEmpty && !state.catalogLoading;
    final catalogLoading = state.catalogLoading && state.products.isEmpty;
    return RefreshIndicator(
      onRefresh: () => AppScope.of(context, listen: false).refreshCatalog(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
        children: [
          _HomeOpeningReveal(
            animation: opening,
            begin: .900,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _AddressPill(
                title: isUz ? 'Yetkazish manzili' : 'Доставка по адресу',
                address: state.primaryAddress == null
                    ? (isUz ? 'Manzilni tanlang' : 'Выберите адрес доставки')
                    : displayAddressLabel(state.primaryAddress!.address),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                ),
              ),
            ),
          ),
          _HomeOpeningReveal(
            animation: opening,
            begin: .920,
            child: _BannerCarousel(
              controller: _bannerController,
              currentIndex: _bannerIndex,
              onChanged: _handleBannerChanged,
              onScrollActiveChanged: _setBannerScrollActive,
              onBannerTap: _openBanner,
            ),
          ),
          _HomeOpeningReveal(
            animation: opening,
            begin: .940,
            child: catalogUnavailable
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: isUz
                        ? 'Poster menyusi yuklanmadi'
                        : 'Меню Poster не загрузилось',
                    text: isUz
                        ? 'Server hozir mahsulot va bo‘limlarni qaytarmayapti.'
                        : 'Сервер сейчас не возвращает товары и категории.',
                    action: FilledButton.icon(
                      onPressed: () =>
                          AppScope.of(context, listen: false).refreshCatalog(),
                      icon: const Icon(Icons.refresh),
                      label: Text(isUz ? 'Qayta urinish' : 'Повторить'),
                    ),
                  )
                : catalogLoading
                    ? _CatalogLoading(isUz: isUz)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeSectionTitle(
                            title: isUz ? 'Menyu' : 'Меню',
                          ),
                          SizedBox(
                            height: 112,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) => _CategoryTile(
                                category: state.categories[index],
                              ),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemCount: state.categories.length,
                            ),
                          ),
                        ],
                      ),
          ),
          if (!catalogUnavailable)
            _HomeOpeningReveal(
              animation: opening,
              begin: .960,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      productTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: isDark ? 30 : null,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio:
                            compactProductCardAspectRatio(context),
                      ),
                      itemCount: popular.length,
                      itemBuilder: (context, index) => ProductCard(
                        key: ValueKey('home-product-${popular[index].id}'),
                        product: popular[index],
                        compact: true,
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

class _HomeOpeningReveal extends StatelessWidget {
  const _HomeOpeningReveal({
    required this.animation,
    required this.begin,
    required this.child,
  });

  final Animation<double>? animation;
  final double begin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final source = animation;
    if (source == null || source.value >= 1) return child;
    return AnimatedBuilder(
      animation: source,
      child: child,
      builder: (context, child) {
        final t = ((source.value - begin) / (1 - begin)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: RepaintBoundary(
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - eased)),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.controller,
    required this.currentIndex,
    required this.onChanged,
    required this.onScrollActiveChanged,
    required this.onBannerTap,
  });

  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final ValueChanged<bool> onScrollActiveChanged;
  final ValueChanged<BannerModel> onBannerTap;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final banners = state.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    final count = banners.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  onScrollActiveChanged(true);
                } else if (notification is ScrollEndNotification) {
                  onScrollActiveChanged(false);
                }
                return false;
              },
              child: PageView.builder(
                controller: controller,
                itemCount: count > 1 ? null : count,
                physics: const BouncingScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                onPageChanged: onChanged,
                itemBuilder: (context, index) {
                  final bannerIndex = count == 0 ? 0 : index % count;
                  final banner = banners.isEmpty ? null : banners[bannerIndex];
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      var scale = 1.0;
                      var opacity = 1.0;
                      if (controller.hasClients &&
                          controller.positions.length == 1 &&
                          controller.position.haveDimensions) {
                        final page = controller.page ?? currentIndex.toDouble();
                        final distance = (page - index).abs().clamp(0.0, 1.0);
                        scale = (1 - (distance * 0.035))
                            .clamp(0.965, 1.0)
                            .toDouble();
                        opacity =
                            (1 - (distance * 0.12)).clamp(0.88, 1.0).toDouble();
                      }
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: _BannerCard(
                      imageUrl: banner?.imageUrl ?? '',
                      onTap: banner == null ? null : () => onBannerTap(banner),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentIndex == i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: currentIndex == i
                        ? WasabiColors.primary
                        : WasabiColors.primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.title,
    required this.address,
    required this.onTap,
  });

  final String title;
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF151D10) : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? WasabiColors.primary.withValues(alpha: .24)
                  : Colors.transparent,
            ),
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF192511),
                      Color(0xFF11170D),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? WasabiColors.primary.withValues(alpha: .20)
                      : WasabiColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: WasabiColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: .72)
                            : const Color(0x80141414),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : WasabiColors.dark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? WasabiColors.primary.withValues(alpha: .78)
                    : const Color(0x4D141414),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.imageUrl,
    required this.onTap,
  });

  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasRealImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: isDark
                ? Border.all(
                    color: WasabiColors.primary.withValues(alpha: .28),
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasRealImage)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const _BannerLoading(),
                    errorBuilder: (_, __, ___) => const _BannerFallback(),
                  )
                else
                  const _BannerFallback(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerLoading extends StatelessWidget {
  const _BannerLoading();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WasabiColors.primary.withValues(alpha: .18),
            WasabiColors.primary.withValues(alpha: .07),
          ],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading({required this.isUz});

  final bool isUz;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 118),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: WasabiColors.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: WasabiColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isUz ? 'Menyu yuklanmoqda' : 'Загружаем меню',
            style: const TextStyle(
              color: WasabiColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isUz ? 'Bir oz kuting' : 'Пожалуйста, подождите',
            style: TextStyle(
              color: WasabiColors.dark.withValues(alpha: .62),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WasabiColors.primary, WasabiColors.secondary],
        ),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 22),
          child: Icon(Icons.ramen_dining, color: Colors.white, size: 74),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final active = state.selectedCategoryId == category.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        state.selectCategory(category.id);
      },
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 108,
        width: 82,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .07)
                    : Colors.white.withValues(alpha: .88),
                shape: BoxShape.circle,
                border: Border.all(
                  color: active
                      ? const Color(0xFFA8E536)
                      : isDark
                          ? Colors.white.withValues(alpha: .12)
                          : WasabiColors.primary.withValues(alpha: .35),
                  width: 1.2,
                ),
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                scale: active ? 1.06 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Image.network(
                    category.photo?.isNotEmpty == true
                        ? category.photo!
                        : designCategoryImageUrl(category),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(category.emoji ?? '🍣',
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.title(state.locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active
                    ? const Color(0xFFA8E536)
                    : isDark
                        ? Colors.white.withValues(alpha: .88)
                        : colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.white : WasabiColors.dark,
                    fontSize: isDark ? 28 : null,
                    fontWeight: FontWeight.w900,
                    shadows: isDark
                        ? [
                            Shadow(
                              color:
                                  WasabiColors.primary.withValues(alpha: .22),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
