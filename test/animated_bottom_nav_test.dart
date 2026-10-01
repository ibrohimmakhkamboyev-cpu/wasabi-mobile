import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/theme/app_theme.dart';
import 'package:wasabi_mobile/ui/widgets/animated_bottom_nav.dart';

void main() {
  testWidgets('keeps the floating nav lifted above the bottom edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          bottomNavigationBar: AnimatedBottomNav(
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              AnimatedBottomNavItem(
                icon: Icons.home_rounded,
                label: 'Asosiy',
              ),
              AnimatedBottomNavItem(
                icon: Icons.restaurant_menu_rounded,
                label: 'Menyu',
              ),
              AnimatedBottomNavItem(
                icon: Icons.shopping_bag_rounded,
                label: 'Savat',
              ),
            ],
          ),
        ),
      ),
    );

    final padding = tester.widget<Padding>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding is EdgeInsets &&
            widget.padding == const EdgeInsets.fromLTRB(18, 0, 18, 16),
      ),
    );

    expect(padding.padding, const EdgeInsets.fromLTRB(18, 0, 18, 16));
  });

  testWidgets('renders floating nav items and selects a tab', (tester) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: AnimatedBottomNav(
                selectedIndex: selectedIndex,
                onSelected: (index) => setState(() => selectedIndex = index),
                items: const [
                  AnimatedBottomNavItem(
                    icon: Icons.home_rounded,
                    label: 'Asosiy',
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Menyu',
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Savat',
                    badge: 3,
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Buyurtmalar',
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(find.byType(AnimatedBottomNav), findsOneWidget);
    expect(find.text('Asosiy'), findsNothing);
    expect(find.text('Menyu'), findsNothing);
    expect(find.text('Savat'), findsNothing);
    expect(find.text('Buyurtmalar'), findsNothing);
    expect(find.text('Profil'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.home_rounded)).size, 30);

    await tester.tap(find.byIcon(Icons.shopping_bag_rounded));
    await tester.pumpAndSettle();

    expect(selectedIndex, 2);
  });

  testWidgets('cart badge pops when it first appears', (tester) async {
    var badgeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => setState(() => badgeCount = 4),
                  child: const Text('Add cart'),
                ),
              ),
              bottomNavigationBar: AnimatedBottomNav(
                selectedIndex: 0,
                onSelected: (_) {},
                items: [
                  const AnimatedBottomNavItem(
                    icon: Icons.home_rounded,
                    label: 'Asosiy',
                  ),
                  const AnimatedBottomNavItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Menyu',
                  ),
                  AnimatedBottomNavItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Savat',
                    badge: badgeCount,
                  ),
                  const AnimatedBottomNavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Buyurtmalar',
                  ),
                  const AnimatedBottomNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Add cart'));
    await tester.pump();

    final badgeScale = tester.widget<AnimatedScale>(
      find.ancestor(of: find.text('4'), matching: find.byType(AnimatedScale)),
    );
    expect(badgeScale.scale, greaterThan(1));
  });
}
