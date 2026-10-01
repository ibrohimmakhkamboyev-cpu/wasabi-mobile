import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/models/app_models.dart';
import 'package:wasabi_mobile/state/app_state.dart';
import 'package:wasabi_mobile/theme/app_theme.dart';
import 'package:wasabi_mobile/ui/screens/cart_screen.dart';
import 'package:wasabi_mobile/ui/widgets/common.dart';

void main() {
  testWidgets('cart keeps product name and price readable on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.15;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    const productName = 'Ананас Кокос-Лайт 500 мл';
    final state = AppState()
      ..locale = 'ru'
      ..cart = const [
        CartItem(
          productId: 'ananas-kokos-light',
          name: productName,
          price: 12000,
          quantity: 1,
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: CartScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    final itemCard = find.ancestor(
      of: find.text(productName),
      matching: find.byType(Card),
    );
    final priceFinder = find.descendant(
      of: itemCard,
      matching: find.text(money(12000, 'ru')),
    );

    expect(itemCard, findsOneWidget);
    expect(priceFinder, findsOneWidget);

    final name = tester.widget<Text>(find.text(productName));
    final price = tester.widget<Text>(priceFinder);

    expect(name.maxLines, 2);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(price.maxLines, 1);
    expect(price.softWrap, isFalse);
    expect(tester.getSize(priceFinder).height, lessThan(30));
  });
}
