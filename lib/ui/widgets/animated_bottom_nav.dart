import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedBottomNavItem {
  const AnimatedBottomNavItem({
    required this.icon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final int badge;
}

class AnimatedBottomNav extends StatelessWidget {
  const AnimatedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  }) : assert(items.length > 0);

  static const primaryGreen = Color(0xFF6B8E23);
  static const activePill = Color(0xFFE8F1E1);
  static const inactiveGray = Color(0xFF8F9690);

  final int selectedIndex;
  final List<AnimatedBottomNavItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final safeIndex = selectedIndex.clamp(0, items.length - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: RepaintBoundary(
        child: DecoratedBox(
          // A backdrop blur re-rasterizes the scrolling content behind the
          // navigation bar every frame. The opaque glass colour keeps the
          // same dark/light visual treatment without that GPU cost.
          decoration: BoxDecoration(
            color: isDark ? const Color(0xED1B2414) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .12)
                  : const Color(0xFFF1F4EE),
            ),
          ),
          child: _AnimatedBottomNavContent(
            safeIndex: safeIndex,
            items: items,
            onSelected: onSelected,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _AnimatedBottomNavContent extends StatelessWidget {
  const _AnimatedBottomNavContent({
    required this.safeIndex,
    required this.items,
    required this.onSelected,
    required this.isDark,
  });

  final int safeIndex;
  final List<AnimatedBottomNavItem> items;
  final ValueChanged<int> onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            final pillWidth = (itemWidth * .86).clamp(52.0, 76.0);
            final pillLeft =
                itemWidth * safeIndex + (itemWidth - pillWidth) / 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(left: pillLeft),
                  width: pillWidth,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF25370F)
                        : AnimatedBottomNav.activePill,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: itemWidth,
                          child: _AnimatedBottomNavButton(
                            item: items[i],
                            selected: safeIndex == i,
                            onTap: () => onSelected(i),
                            isDark: isDark,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedBottomNavButton extends StatelessWidget {
  const _AnimatedBottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final AnimatedBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? (isDark ? const Color(0xFFA8E536) : AnimatedBottomNav.primaryGreen)
        : (isDark
            ? Colors.white.withValues(alpha: .66)
            : AnimatedBottomNav.inactiveGray);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.1 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: color, size: selected ? 30 : 28),
                    ],
                  ),
                ),
                if (item.badge > 0)
                  Positioned(
                    right: 9,
                    top: 4,
                    child: _PoppingBadge(count: item.badge),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoppingBadge extends StatefulWidget {
  const _PoppingBadge({required this.count});

  final int count;

  @override
  State<_PoppingBadge> createState() => _PoppingBadgeState();
}

class _PoppingBadgeState extends State<_PoppingBadge> {
  Timer? _timer;
  double _scale = 1.28;

  @override
  void initState() {
    super.initState();
    _settle();
  }

  @override
  void didUpdateWidget(covariant _PoppingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _timer?.cancel();
      setState(() => _scale = 1.28);
      _settle();
    }
  }

  void _settle() {
    _timer = Timer(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _scale = 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: AnimatedBottomNav.primaryGreen,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.count > 99 ? '99+' : '${widget.count}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
