import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/animated_bottom_nav.dart';
import '../widgets/common.dart';
import '../widgets/wasabi_page_background.dart';
import '../widgets/wessabi_entrance.dart';
import 'branches_screen.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'home_screen.dart';
import 'mailings_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'promotions_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';
import 'support_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  late int _index = widget.initialIndex;
  int _lastCartCount = 0;
  bool _cartCountReady = false;
  bool _showExpandedQuickCart = false;
  bool _appIsActive = true;
  Timer? _quickCartTimer;
  Timer? _mailingRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mailingRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshMailingsIfActive(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    final cartCount = state.cartCount;
    if (!_cartCountReady) {
      _cartCountReady = true;
      _lastCartCount = cartCount;
      return;
    }
    if (cartCount > _lastCartCount) {
      _playQuickCartAnimation();
    } else if (cartCount <= 0) {
      _quickCartTimer?.cancel();
      _showExpandedQuickCart = false;
    }
    _lastCartCount = cartCount;
  }

  @override
  void dispose() {
    _quickCartTimer?.cancel();
    _mailingRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (_appIsActive != active && mounted) {
      setState(() => _appIsActive = active);
    } else {
      _appIsActive = active;
    }
    if (active) {
      _refreshMailingsIfActive();
    }
  }

  void _refreshMailingsIfActive() {
    if (!mounted || !_appIsActive) return;
    final state = AppScope.of(context, listen: false);
    // Mailings are account-specific. Avoid a background request every cycle
    // for guests, who cannot open the inbox anyway.
    if (!state.isAuthenticated) return;
    unawaited(state.refreshMailings());
  }

  void _playQuickCartAnimation() {
    _quickCartTimer?.cancel();
    setState(() => _showExpandedQuickCart = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showExpandedQuickCart = true);
      _quickCartTimer = Timer(const Duration(milliseconds: 1700), () {
        if (!mounted) return;
        setState(() => _showExpandedQuickCart = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final opening = WessabiHomeOpeningScope.maybeOf(context);
    final pages = [
      HomeScreen(
        onOpenCatalog: () => setState(() => _index = 1),
        isActive: _index == 0 && _appIsActive,
      ),
      const CatalogScreen(),
      CartScreen(
        onAddMore: () => setState(() => _index = 1),
      ),
      OrdersScreen(
        standalone: false,
      ),
      ProfileScreen(
        reserveBottomNavSpace: true,
      ),
    ];
    final scaffold = Scaffold(
      extendBody: true,
      appBar: _index == 4
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: _OpeningReveal(
                animation: opening,
                begin: .900,
                child: AppBar(
                  toolbarHeight: kToolbarHeight,
                  title: const _ShellTitle(),
                  actions: _index <= 2
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TopActionButton(
                              icon: Icons.search_rounded,
                              label: isUz ? 'Qidiruv' : 'Поиск',
                              onTap: () => _open(context, const SearchScreen()),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TopActionButton(
                              label: isUz ? 'Xabarlar' : 'Рассылки',
                              hasUnread: state.hasUnreadMailings,
                              customChild: Icon(
                                Icons.notifications_none_rounded,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : WasabiColors.dark,
                                size: 26,
                              ),
                              onTap: () =>
                                  _open(context, const MailingsScreen()),
                            ),
                          ),
                        ]
                      : const [],
                ),
              ),
            ),
      drawer: _AppDrawer(
        selectedIndex: _index,
        onTab: (index) {
          Navigator.pop(context);
          setState(() => _index = index);
        },
        onOpen: (screen) {
          Navigator.pop(context);
          _open(context, screen);
        },
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WasabiPageBackground()),
          _OpeningReveal(
            animation: opening,
            begin: .900,
            dy: 18,
            child: _AnimatedIndexedStack(index: _index, children: pages),
          ),
          if (state.cartCount > 0 && (_index == 0 || _index == 1))
            Positioned(
              left: 16,
              right: 16,
              bottom: 130,
              child: _OpeningReveal(
                animation: opening,
                begin: .945,
                dy: 16,
                child: _QuickCartBar(
                  total: money(state.subtotal, state.locale),
                  count: state.cartCount,
                  expanded: _showExpandedQuickCart,
                  onTap: () => setState(() => _index = 2),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _OpeningReveal(
        animation: opening,
        begin: .960,
        dy: 22,
        child: AnimatedBottomNav(
          selectedIndex: _index,
          onSelected: (value) => setState(() => _index = value),
          items: [
            AnimatedBottomNavItem(
              icon: Icons.home_rounded,
              label: isUz ? 'Bosh sahifa' : 'Главная',
            ),
            AnimatedBottomNavItem(
              icon: Icons.restaurant_menu_rounded,
              label: isUz ? 'Menyu' : 'Меню',
            ),
            AnimatedBottomNavItem(
              icon: Icons.shopping_bag_rounded,
              label: isUz ? 'Savatcha' : 'Корзина',
              badge: state.cartCount,
            ),
            AnimatedBottomNavItem(
              icon: Icons.receipt_long_rounded,
              label: isUz ? 'Buyurtmalar' : 'Заказы',
            ),
            AnimatedBottomNavItem(
              icon: Icons.person_rounded,
              label: isUz ? 'Profil' : 'Профиль',
            ),
          ],
        ),
      ),
    );
    return scaffold;
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ShellTitle extends StatelessWidget {
  const _ShellTitle();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 4),
            child: child,
          ),
        );
      },
      child: ClipOval(
        child: Image.asset(
          'assets/images/wasabi_brand_logo.png',
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _OpeningReveal extends StatelessWidget {
  const _OpeningReveal({
    required this.animation,
    required this.child,
    required this.begin,
    this.dy = 12,
  });

  final Animation<double>? animation;
  final Widget child;
  final double begin;
  final double dy;

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
              offset: Offset(0, dy * (1 - eased)),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedIndexedStack extends StatefulWidget {
  const _AnimatedIndexedStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<_AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(covariant _AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: RepaintBoundary(
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
      builder: (context, child) {
        final progress = _progress.value;
        return Opacity(
          opacity: progress,
          child: Transform.scale(
            scale: 0.96 + (progress * 0.04),
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(0, 42 * (1 - progress)),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.selectedIndex,
    required this.onTab,
    required this.onOpen,
  });

  final int selectedIndex;
  final ValueChanged<int> onTab;
  final ValueChanged<Widget> onOpen;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _DrawerEntry(
        icon: Icons.home_rounded,
        label: isUz ? 'Bosh sahifa' : 'Главная',
        onTap: () => onTab(0),
        active: selectedIndex == 0,
      ),
      _DrawerEntry(
        icon: Icons.restaurant_menu_rounded,
        label: isUz ? 'Menyu' : 'Каталог',
        onTap: () => onTab(1),
        active: selectedIndex == 1,
      ),
      _DrawerEntry(
        icon: Icons.shopping_bag_rounded,
        label: isUz ? 'Savatcha' : 'Корзина',
        onTap: () => onTab(2),
        active: selectedIndex == 2,
        badge: state.cartCount,
      ),
      _DrawerEntry(
        icon: Icons.favorite_rounded,
        label: isUz ? 'Saqlanganlar' : 'Сохраненные',
        onTap: () => onOpen(const SavedScreen()),
        badge: state.savedCount,
      ),
      _DrawerEntry(
        icon: Icons.receipt_long_rounded,
        label: isUz ? 'Buyurtmalar' : 'Мои заказы',
        onTap: () => onTab(3),
        active: selectedIndex == 3,
      ),
      _DrawerEntry(
        icon: state.themeMode == ThemeMode.dark
            ? Icons.light_mode_rounded
            : Icons.dark_mode_rounded,
        label: state.themeMode == ThemeMode.dark
            ? (isUz ? 'Oq rejim' : 'Светлый режим')
            : (isUz ? "Qorong'i rejim" : 'Темный режим'),
        onTap: state.toggleThemeMode,
      ),
      _DrawerEntry(
        icon: Icons.local_offer_rounded,
        label: isUz ? 'Aksiyalar' : 'Акции',
        onTap: () => onOpen(const PromotionsScreen()),
      ),
      _DrawerEntry(
        icon: Icons.storefront_rounded,
        label: isUz ? 'Filiallar' : 'Филиалы',
        onTap: () => onOpen(const BranchesScreen()),
      ),
      _DrawerEntry(
        icon: Icons.support_agent_rounded,
        label: isUz ? 'Aloqa' : 'Обратная связь',
        onTap: () => onOpen(const SupportScreen()),
      ),
    ];

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151B12) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? WasabiColors.primary.withValues(alpha: .45)
                        : const Color(0xFFE4EBD6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: .22)
                          : Colors.black.withValues(alpha: .08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      const AppLogo(compact: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'WASABI',
                          maxLines: 1,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFA8E536)
                                : WasabiColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 23,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                children: [
                  for (var i = 0; i < items.length; i++)
                    _AnimatedDrawerItem(entry: items[i], delay: i),
                  _AnimatedDrawerLanguageItem(
                    locale: state.locale,
                    isUzEnabled: state.isUzEnabled,
                    delay: items.length,
                    onChanged: state.setLocale,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerEntry {
  const _DrawerEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final int badge;
}

class _AnimatedDrawerItem extends StatelessWidget {
  const _AnimatedDrawerItem({
    required this.entry,
    required this.delay,
  });

  final _DrawerEntry entry;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: 1),
      duration: Duration(milliseconds: 300 + delay * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(22 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _DrawerItem(
        icon: entry.icon,
        label: entry.label,
        active: entry.active,
        badge: entry.badge,
        onTap: entry.onTap,
      ),
    );
  }
}

class _AnimatedDrawerLanguageItem extends StatelessWidget {
  const _AnimatedDrawerLanguageItem({
    required this.locale,
    required this.isUzEnabled,
    required this.delay,
    required this.onChanged,
  });

  final String locale;
  final bool isUzEnabled;
  final int delay;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: 1),
      duration: Duration(milliseconds: 300 + delay * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(22 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _DrawerLanguageCard(
        locale: locale,
        isUzEnabled: isUzEnabled,
        onChanged: onChanged,
      ),
    );
  }
}

class _DrawerLanguageCard extends StatelessWidget {
  const _DrawerLanguageCard({
    required this.locale,
    required this.isUzEnabled,
    required this.onChanged,
  });

  final String locale;
  final bool isUzEnabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isUz = locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10140D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .22)
              : const Color(0xFFE6E3D6),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .34)
                : const Color(0x14000000),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: WasabiColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.language_rounded,
                color: WasabiColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isUz ? 'Til' : 'Язык',
                style: TextStyle(
                  color: isDark ? Colors.white : WasabiColors.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _DrawerLanguageFlag(
              flag: '🇷🇺',
              selected: !isUz,
              onTap: () => onChanged('ru'),
            ),
            const SizedBox(width: 8),
            _DrawerLanguageFlag(
              flag: '🇺🇿',
              selected: isUz,
              onTap: isUzEnabled ? () => onChanged('uz') : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLanguageFlag extends StatelessWidget {
  const _DrawerLanguageFlag({
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? WasabiColors.primary
          : isDark
              ? Colors.white.withValues(alpha: .06)
              : const Color(0xFFF8F7F2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? WasabiColors.primary
                  : isDark
                      ? WasabiColors.primary.withValues(alpha: .16)
                      : const Color(0xFFEAE6D8),
            ),
          ),
          child: Text(flag, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.label,
    required this.onTap,
    this.hasUnread = false,
    this.icon,
    this.customChild,
  });

  final IconData? icon;
  final String label;
  final bool hasUnread;
  final Widget? customChild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: .09) : Colors.white,
            shape: BoxShape.circle,
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: .10))
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              customChild ??
                  Icon(
                    icon,
                    color: isDark ? Colors.white : WasabiColors.dark,
                    size: 27,
                  ),
              if (hasUnread)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE32626),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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

class _QuickCartBar extends StatelessWidget {
  const _QuickCartBar({
    required this.total,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final String total;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.bottomRight,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              end: expanded ? constraints.maxWidth : 68,
            ),
            duration: const Duration(milliseconds: 430),
            curve: Curves.easeInOutCubic,
            builder: (context, width, _) {
              final showDetails = expanded && width > 260;
              return SizedBox(
                width: width,
                height: 68,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(expanded ? 24 : 22),
                    child: Ink(
                      decoration: BoxDecoration(
                        color:
                            expanded ? WasabiColors.dark : WasabiColors.primary,
                        borderRadius: BorderRadius.circular(expanded ? 24 : 22),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(expanded ? 24 : 22),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: showDetails ? 14 : 0,
                            right: showDetails ? 11 : 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (showDetails) ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppScope.of(context).locale == 'uz'
                                            ? 'Buyurtma summasi'
                                            : 'Сумма заказа',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        total,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              _QuickCartIcon(
                                count: count,
                                active: expanded,
                                expanded: showDetails,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _QuickCartIcon extends StatelessWidget {
  const _QuickCartIcon({
    required this.count,
    required this.active,
    required this.expanded,
  });

  final int count;
  final bool active;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (expanded)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          AnimatedRotation(
            turns: active ? -0.035 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          Positioned(
            top: expanded ? 6 : 5,
            right: expanded ? 3 : 3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WasabiColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
    required this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : WasabiColors.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active ? WasabiColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active
                    ? WasabiColors.primary
                    : WasabiColors.primary.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: (active ? WasabiColors.primary : Colors.black)
                      .withValues(alpha: active ? 0.24 : 0.05),
                  blurRadius: active ? 18 : 10,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: active ? 1.08 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.18)
                          : WasabiColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: active ? Colors.white : WasabiColors.primary,
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : WasabiColors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? WasabiColors.primary : Colors.white,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (active)
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
