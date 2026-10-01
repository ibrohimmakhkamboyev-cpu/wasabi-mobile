import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/config/app_config.dart';
import 'package:wasabi_mobile/models/app_models.dart';
import 'package:wasabi_mobile/services/api_client.dart';
import 'package:wasabi_mobile/services/wasabi_api.dart';
import 'package:wasabi_mobile/state/app_state.dart';
import 'package:wasabi_mobile/theme/app_theme.dart';
import 'package:wasabi_mobile/ui/screens/auth_screen.dart';
import 'package:wasabi_mobile/ui/screens/addresses_screen.dart';
import 'package:wasabi_mobile/ui/screens/cart_screen.dart';
import 'package:wasabi_mobile/ui/screens/catalog_screen.dart';
import 'package:wasabi_mobile/ui/screens/checkout_screen.dart';
import 'package:wasabi_mobile/ui/screens/home_screen.dart';
import 'package:wasabi_mobile/ui/screens/profile_screen.dart';
import 'package:wasabi_mobile/ui/screens/saved_screen.dart';
import 'package:wasabi_mobile/ui/screens/search_screen.dart';
import 'package:wasabi_mobile/ui/screens/shell_screen.dart';
import 'package:wasabi_mobile/ui/screens/welcome_screen.dart';
import 'package:wasabi_mobile/ui/widgets/common.dart';
import 'package:wasabi_mobile/ui/widgets/wasabi_page_background.dart';

void main() {
  testWidgets('renders Wasabi logo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AppLogo()),
        ),
      ),
    );

    expect(find.text('WASABI SUSHI'), findsOneWidget);
  });

  testWidgets('welcome hero does not overlay marketing text', (tester) async {
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WelcomeScreen(),
        ),
      ),
    );

    expect(find.text('WASABI SUSHI'), findsNothing);
    expect(find.text('Premium Sushi'), findsNothing);
    expect(find.text('Ta’m san’ati'), findsNothing);
    expect(
      find.text(
          'Eng yangi ingredientlar va mualliflik retseptlari eshigingizgacha.'),
      findsNothing,
    );
  });

  testWidgets('auth screen uses light text in dark mode', (tester) async {
    final state = AppState()..themeMode = ThemeMode.dark;

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const AuthScreen(),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Profil'));
    expect(title.style?.color, Colors.white);
  });

  testWidgets('drawer hides search profile and guest card', (tester) async {
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ShellScreen(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    final drawer = find.byType(Drawer);

    expect(find.descendant(of: drawer, matching: find.text('Qidiruv')),
        findsNothing);
    expect(find.descendant(of: drawer, matching: find.text('Profil')),
        findsNothing);
    expect(find.descendant(of: drawer, matching: find.text('Mehmon')),
        findsNothing);
    expect(
      find.descendant(of: drawer, matching: find.text(AppConfig.defaultPhone)),
      findsNothing,
    );
  });

  testWidgets('product card keeps price close to title', (tester) async {
    const product = ProductModel(
      id: 'california',
      nameRu: 'Kaliforniya',
      nameUz: 'Kaliforniya',
      price: 59000,
    );

    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 172,
                height: 344,
                child: ProductCard(product: product),
              ),
            ),
          ),
        ),
      ),
    );

    final titleBottom = tester.getBottomLeft(find.text('Kaliforniya')).dy;
    final priceTop = tester.getTopLeft(find.text(money(59000, 'uz'))).dy;

    expect(priceTop - titleBottom, lessThan(24));
  });

  testWidgets('product detail keeps the image in a frame and groups its info',
      (tester) async {
    const product = ProductModel(
      id: 'cola-detail',
      nameRu: 'Кола 1,5L',
      nameUz: 'Kola 1,5L',
      price: 22000,
    );

    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showProductSheet(context, product),
                  child: const Text('Open product'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open product'));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byKey(const Key('product-detail-image-frame')), findsOneWidget);
    expect(find.byKey(const Key('product-detail-info-panel')), findsOneWidget);
    expect(find.byKey(const Key('product-detail-save-button')), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('Kola 1,5L'), findsOneWidget);
    expect(find.textContaining("so'm"), findsOneWidget);

    final imageSection = tester.getSize(
      find.byKey(const Key('product-detail-image-section')),
    );
    final imageFrame = tester.getRect(
      find.byKey(const Key('product-detail-image-frame')),
    );
    final infoPanel = tester.getRect(
      find.byKey(const Key('product-detail-info-panel')),
    );
    expect(imageSection.height, lessThanOrEqualTo(320));
    expect(infoPanel.top - imageFrame.bottom, lessThan(24));
  });

  testWidgets('search result shows readable product price', (tester) async {
    final state = AppState()
      ..products = const [
        ProductModel(
          id: 'ananas-kokos-layt',
          nameRu: 'Ananas Kokos-Layt 500 ml',
          nameUz: 'Ananas Kokos-Layt 500 ml',
          price: 1200000,
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SearchScreen(),
        ),
      ),
    );

    await tester.pump();

    final priceText = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data?.replaceAll('\u00A0', ' ') == '12 000 UZS',
    );

    expect(priceText, findsOneWidget);
    expect(tester.widget<Text>(priceText).style?.color, WasabiColors.primary);
    expect(find.text('1 200 000 UZS'), findsNothing);
    final imageSize = tester.getSize(find.byType(ProductImage));
    expect(imageSize.width / imageSize.height, greaterThan(1.4));
  });

  test('search finds Cyrillic products from Latin query', () {
    final state = AppState()
      ..products = const [
        ProductModel(
          id: 'apelsin-bliss',
          nameRu: 'Апельсин сок 200 мл Bliss',
          price: 7000,
        ),
        ProductModel(
          id: 'california',
          nameRu: 'Калифорния',
          price: 59000,
        ),
      ];

    expect(state.searchProducts('apelsin', '').map((p) => p.id),
        contains('apelsin-bliss'));
    expect(state.searchProducts('kaliforniya', '').map((p) => p.id),
        contains('california'));
  });

  testWidgets('product card quantity controls stay aligned', (tester) async {
    const discounted = ProductModel(
      id: 'philadelphia',
      nameRu: 'Filadelfiya klassik',
      nameUz: 'Filadelfiya klassik',
      price: 69000,
      discount: DiscountModel(discountValue: 15, resultType: 3),
    );
    const regular = ProductModel(
      id: 'california',
      nameRu: 'Kaliforniya',
      nameUz: 'Kaliforniya',
      price: 59000,
    );
    final state = AppState()
      ..cart = [
        CartItem.fromProduct(discounted, quantity: 3),
        CartItem.fromProduct(regular, quantity: 3),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Row(
              children: [
                SizedBox(
                    width: 150,
                    height: 344,
                    child: ProductCard(product: discounted)),
                SizedBox(
                    width: 150,
                    height: 344,
                    child: ProductCard(product: regular)),
              ],
            ),
          ),
        ),
      ),
    );

    final removeButtons = find.byIcon(Icons.remove);
    final leftY = tester.getCenter(removeButtons.at(0)).dy;
    final rightY = tester.getCenter(removeButtons.at(1)).dy;

    expect((leftY - rightY).abs(), lessThanOrEqualTo(1));
    expect(leftY, greaterThan(220));
    expect(rightY, greaterThan(220));
  });

  testWidgets('compact product card keeps the cart button close to the price',
      (tester) async {
    const product = ProductModel(
      id: 'ananas-kokos',
      nameRu: 'Ananas Kokos-Layt 500 ml',
      nameUz: 'Ananas Kokos-Layt 500 ml',
      price: 1200000,
    );
    final state = AppState();

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 172,
                height: 220,
                child: ProductCard(product: product, compact: true),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final buttonBottom = tester
        .getBottomLeft(
          find.ancestor(
            of: find.text('Savatga'),
            matching: find.byType(FilledButton),
          ),
        )
        .dy;

    final cardBottom = tester.getBottomLeft(find.byType(ProductCard)).dy;
    expect(cardBottom - buttonBottom, lessThanOrEqualTo(12));
  });

  testWidgets('compact promotion card does not overflow at home-grid height',
      (tester) async {
    const product = ProductModel(
      id: 'sandwich-promo',
      nameRu: 'Sendvich tovuq va pishloq bilan',
      nameUz: 'Sendvich tovuq va pishloq bilan',
      price: 22000,
      discount: DiscountModel(discountValue: 15, resultType: 3),
    );
    final state = AppState()
      ..cart = [CartItem.fromProduct(product, quantity: 1)];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 172,
                height: 200,
                child: ProductCard(product: product, compact: true),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('compact product card quantity buttons update cart',
      (tester) async {
    const product = ProductModel(
      id: 'ananas-kokos',
      nameRu: 'Ananas Kokos-Layt 500 ml',
      nameUz: 'Ananas Kokos-Layt 500 ml',
      price: 1200000,
    );
    final state = AppState()
      ..cart = [
        CartItem.fromProduct(product, quantity: 2),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 172,
                height: 220,
                child: ProductCard(product: product, compact: true),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(state.quantityFor(product.id), 3);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(state.quantityFor(product.id), 2);
  });

  testWidgets('saved cards do not overflow on an Android-sized screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    const products = [
      ProductModel(
        id: 'ananas-kokos',
        nameRu: 'Ананас Кокос-Лайт 500 мл',
        price: 12000,
      ),
      ProductModel(
        id: 'apelsin-bliss',
        nameRu: 'Апельсин сок 200 мл Bliss',
        price: 7000,
      ),
    ];
    final state = _SavedProductsState(products);

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SavedScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final cards = tester
        .widgetList<ProductCard>(find.byType(ProductCard))
        .toList(growable: false);
    expect(cards, hasLength(2));
    expect(cards.every((card) => card.compact), isTrue);
    final savedGrid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate =
        savedGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(delegate.childAspectRatio, .68);

    for (var index = 0; index < cards.length; index++) {
      final card = find.byType(ProductCard).at(index);
      final button = find.descendant(
        of: card,
        matching: find.byType(FilledButton),
      );
      expect(tester.getBottomLeft(button).dy,
          lessThan(tester.getBottomLeft(card).dy));
    }
  });

  testWidgets('saved grid keeps the home two-column layout on wide screens',
      (tester) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const product = ProductModel(
      id: 'saved-wide',
      nameRu: 'Сохраненный товар',
      price: 12000,
    );

    await tester.pumpWidget(
      AppScope(
        state: _SavedProductsState(const [product]),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SavedScreen(),
        ),
      ),
    );

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(delegate.childAspectRatio, .90);
  });

  testWidgets('cart uses design image fallback when item image is missing',
      (tester) async {
    final state = AppState()
      ..cart = const [
        CartItem(
          productId: 'california',
          name: 'Калифорния',
          price: 59000,
          quantity: 2,
          categoryId: 'sushi',
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CartScreen(standalone: true),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final resized = image.image as ResizeImage;
    final provider = resized.imageProvider as NetworkImage;

    expect(
      provider.url,
      designProductImageUrl(
        const ProductModel(
          id: 'california',
          nameRu: 'Калифорния',
          price: 59000,
          categoryId: 'sushi',
        ),
      ),
    );
  });

  testWidgets('home category tile filters products without opening catalog',
      (tester) async {
    var openedCatalog = false;
    final state = AppState()
      ..categories = const [
        CategoryModel(id: 'rolls', nameRu: 'Роллы', nameUz: 'Rollar'),
        CategoryModel(id: 'drinks', nameRu: 'Напитки', nameUz: 'Ichimliklar'),
      ]
      ..products = const [
        ProductModel(
          id: 'roll-1',
          nameRu: 'Филадельфия',
          nameUz: 'Filadelfiya',
          price: 69000,
          categoryId: 'rolls',
        ),
        ProductModel(
          id: 'drink-1',
          nameRu: 'Апельсин сок',
          nameUz: 'Apelsin sok',
          price: 7000,
          categoryId: 'drinks',
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: HomeScreen(onOpenMenu: () => openedCatalog = true),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ichimliklar'));
    await tester.pumpAndSettle();

    expect(openedCatalog, isFalse);
    expect(state.selectedCategoryId, 'drinks');
    expect(find.text('Apelsin sok'), findsOneWidget);
    expect(find.text('Filadelfiya'), findsNothing);
  });

  testWidgets('home category shows every product instead of four',
      (tester) async {
    final state = AppState()
      ..categories = const [
        CategoryModel(id: 'rolls', nameRu: 'Роллы', nameUz: 'Rollar'),
      ]
      ..selectedCategoryId = 'rolls'
      ..products = [
        for (var index = 0; index < 5; index += 1)
          ProductModel(
            id: 'roll-$index',
            nameRu: 'Ролл $index',
            nameUz: 'Roll $index',
            price: 10000 + index,
            categoryId: 'rolls',
          ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('home-product-roll-4')), findsOneWidget);
  });

  testWidgets('all catalog view renders category sections in all mode',
      (tester) async {
    final state = AppState()
      ..categories = const [
        CategoryModel(id: 'rolls', nameRu: 'Роллы', nameUz: 'Rollar'),
        CategoryModel(id: 'drinks', nameRu: 'Напитки', nameUz: 'Ichimliklar'),
      ]
      ..products = [
        for (var index = 0; index < 8; index += 1)
          ProductModel(
            id: 'roll-$index',
            nameRu: 'Ролл $index',
            nameUz: 'Roll $index',
            price: 10000 + index,
            categoryId: 'rolls',
          ),
        for (var index = 0; index < 8; index += 1)
          ProductModel(
            id: 'drink-$index',
            nameRu: 'Напиток $index',
            nameUz: 'Ichimlik $index',
            price: 5000 + index,
            categoryId: 'drinks',
          ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: CatalogScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rollar'), findsAtLeastNWidgets(1));
    expect(find.text('Ichimliklar'), findsAtLeastNWidgets(1));
    expect(find.text('Roll 0'), findsOneWidget);
  });

  test('design cart image fallback recognizes names without category', () {
    expect(
      designCartItemImageUrl(
        const CartItem(
          productId: 'set-1',
          name: 'Wasabi сет',
          price: 219000,
          quantity: 1,
        ),
      ),
      'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_3fe965ce0b_19a2594d1cd3045a.png',
    );
    expect(
      designCartItemImageUrl(
        const CartItem(
          productId: 'sushi-1',
          name: 'Суши лосось',
          price: 28000,
          quantity: 1,
        ),
      ),
      'https://storage.googleapis.com/uxpilot-auth.appspot.com/gen_2d4a357566_28ca302b7de13255.png',
    );
  });

  test('catalog visible category resolver keeps all at top and tracks sections',
      () {
    const sections = [
      (id: 'rolls', revealOffset: 0.0),
      (id: 'drinks', revealOffset: 820.0),
      (id: 'salads', revealOffset: 1540.0),
    ];

    expect(
      resolveCatalogVisibleCategoryId(scrollOffset: 0, sections: sections),
      '',
    );
    expect(
      resolveCatalogVisibleCategoryId(scrollOffset: 140, sections: sections),
      'rolls',
    );
    expect(
      resolveCatalogVisibleCategoryId(scrollOffset: 760, sections: sections),
      'drinks',
    );
    expect(
      resolveCatalogVisibleCategoryId(scrollOffset: 1600, sections: sections),
      'salads',
    );
  });

  test('catalog menu scroll resolver centers the active chip', () {
    expect(
      resolveCatalogMenuScrollOffset(
        currentOffset: 0,
        itemLeft: 250,
        itemWidth: 90,
        viewportWidth: 280,
        maxScrollExtent: 400,
      ),
      155,
    );
    expect(
      resolveCatalogMenuScrollOffset(
        currentOffset: 120,
        itemLeft: -10,
        itemWidth: 90,
        viewportWidth: 280,
        maxScrollExtent: 400,
      ),
      15,
    );
    expect(
      resolveCatalogMenuScrollOffset(
        currentOffset: 120,
        itemLeft: 30,
        itemWidth: 90,
        viewportWidth: 280,
        maxScrollExtent: 400,
      ),
      55,
    );
  });

  testWidgets('registration form uses branded field icons', (tester) async {
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );

    await tester.tap(find.text("Ro'yxatdan o'tish"));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-field-icon')), findsNWidgets(4));
    expect(tester.getCenter(find.text('Ism')).dx, lessThan(250));
    expect(tester.getCenter(find.text('Telefon')).dx, lessThan(250));
    expect(tester.getCenter(find.text("Tug'ilgan sana")).dx, lessThan(250));
  });

  testWidgets('registration shows full SMS verification screen after code send',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeApi = _FakeWasabiApi();
    final state = AppState(api: fakeApi);

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );

    await tester.tap(find.text("Ro'yxatdan o'tish"));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Ism'), 'Ali');
    await tester.enterText(
        find.widgetWithText(TextField, 'Telefon'), '901234567');
    await tester.tap(find.text('Kod yuborish'));
    await tester.pumpAndSettle();

    expect(find.text('SMS kodi yuborildi'), findsOneWidget);
    expect(find.text('Xavfsiz tasdiqlash'), findsOneWidget);
    expect(find.text('+998 90 123 45 67'), findsOneWidget);
    expect(find.text('Tasdiqlash'), findsNothing);
    expect(fakeApi.registerCodeSends, 1);

    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Kodni qayta yuborish'), findsOneWidget);

    await tester.tap(find.text('Kodni qayta yuborish'));
    await tester.pump();
    expect(fakeApi.registerCodeSends, 2);
    expect(find.text('Kodni qayta yuborish'), findsNothing);
    expect(find.textContaining('01:00'), findsOneWidget);
  });

  testWidgets('login uses SMS verification without password', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeApi = _FakeWasabiApi();
    final state = AppState(api: fakeApi);

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'Telefon'), '971112233');
    expect(find.text('Parol'), findsNothing);
    expect(find.text('Parolni unutdingizmi?'), findsNothing);

    await tester.tap(find.textContaining('SMS').last);
    await tester.pumpAndSettle();

    expect(find.text('SMS kodi yuborildi'), findsOneWidget);
    expect(find.text('+998 97 111 22 33'), findsOneWidget);
    expect(find.text('Kodni qayta yuborish'), findsNothing);
    expect(fakeApi.registerCodeSends, 1);

    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Kodni qayta yuborish'), findsOneWidget);

    await tester.tap(find.text('Kodni qayta yuborish'));
    await tester.pump();
    expect(fakeApi.registerCodeSends, 2);
    expect(find.text('Kodni qayta yuborish'), findsNothing);
    expect(find.textContaining('01:00'), findsOneWidget);
  });

  testWidgets('SMS auth completes after six digit code', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeApi = _FakeWasabiApi();
    final state = AppState(api: fakeApi);

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'Telefon'), '971112233');
    await tester.tap(find.textContaining('SMS').last);
    await tester.pumpAndSettle();

    expect(find.text('SMS kodi yuborildi'), findsOneWidget);
    expect(find.text('Yangi parol'), findsNothing);
    expect(find.text('Tasdiqlash'), findsNothing);

    final codeField = find.byType(TextField).first;
    await tester.enterText(codeField, '123456');

    await tester.pumpAndSettle();
    expect(fakeApi.lastRegisterSmsCode, '123456');
  });

  testWidgets('auth phone fields show only country code prefix',
      (tester) async {
    final state = AppState(api: _FakeWasabiApi());

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );

    final phoneField = tester.widget<TextField>(find.byType(TextField).first);
    expect(phoneField.decoration?.prefixText, '+998 ');
  });

  testWidgets('profile screen matches reference section copy', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibbb',
        phone: '+998 97 772 22 79',
        bonus: 0,
      )
      ..addresses = const [
        AddressModel(
          id: 'address-1',
          address: 'Tashkent',
          lat: 41.311081,
          lng: 69.240562,
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );

    expect(find.text('Profil'), findsNothing);
    expect(find.text('Shaxsiy ma’lumotlaringizni boshqaring'), findsNothing);
    expect(find.text('1 manzil saqlangan'), findsOneWidget);
    expect(find.text('Avvalgi buyurtmalar va holati'), findsOneWidget);
    expect(find.text('Admin paneldan yuborilgan xabarlar'), findsOneWidget);
    expect(find.text('Chiqish'), findsOneWidget);
    expect(find.text('Til / Language'), findsNothing);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Uzbek'), findsOneWidget);
    expect(find.byIcon(Icons.language), findsNothing);
    expect(find.textContaining('Bonuslar'), findsNothing);
    expect(find.text('Tahrirlash'), findsNothing);
    expect(find.text('Parol'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('profile-hero-card'))).dy,
      lessThan(78),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('profile-hero-card'))).height,
      lessThanOrEqualTo(124),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('profile-hero-card'))).width,
      greaterThan(315),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('profile-tile-addresses')))
          .height,
      greaterThanOrEqualTo(78),
    );

    final heroTop =
        tester.getTopLeft(find.byKey(const ValueKey('profile-hero-card'))).dy;
    await tester.drag(find.byType(Scrollable), const Offset(0, -120));
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('profile-hero-card'))).dy,
      lessThan(heroTop),
    );

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(8));
    expect(scrollable.position.maxScrollExtent, lessThan(230));
  });

  testWidgets('profile content stays centered on wide screens', (tester) async {
    tester.view.physicalSize = const Size(900, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibrohim',
        phone: '+998 97 722 22 79',
        bonus: 0,
      );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );

    final card = find.byKey(const ValueKey('profile-hero-card'));
    final width = tester.getSize(card).width;
    final left = tester.getTopLeft(card).dx;

    expect(width, lessThanOrEqualTo(640));
    expect(left, moreOrLessEquals((900 - width) / 2, epsilon: 1));
  });

  testWidgets('profile tab omits the shared header', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibbb',
        phone: '+998 97 772 22 79',
        bonus: 0,
      );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ShellScreen(initialIndex: 4),
        ),
      ),
    );

    expect(find.text('WASABI'), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.text('Bosh sahifa'), findsNothing);
    expect(find.text('Savatcha'), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('profile-hero-card'))).dy,
      lessThan(118),
    );
  });

  testWidgets('profile screen lets authenticated users change language',
      (tester) async {
    final fakeApi = _FakeWasabiApi();
    final state = AppState(api: fakeApi)
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibrohim',
        phone: '+998 97 722 22 79',
        bonus: 0,
      );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Русский'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();

    expect(state.locale, 'ru');
  });

  test('profile name still updates when deployed profile endpoint is missing',
      () async {
    final state = AppState(api: _FakeWasabiApi(profileUpdateStatusCode: 404))
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibrohim',
        phone: '+998 97 722 22 79',
      );

    await state.updateProfile(name: 'Sanjar', phone: '+998 97 722 22 79');

    expect(state.user?.name, 'Sanjar');
  });

  test('profile refresh keeps the locally chosen name over a Poster label',
      () async {
    final state = AppState(
      api: _ProfileRefreshFakeWasabiApi(
        const UserProfile(
          id: 'user-1',
          name: 'Old Backend Name',
          phone: '+998 97 722 22 79',
        ),
      ),
    )..user = const UserProfile(
        id: 'user-1',
        name: 'Sanjar',
        phone: '+998 97 722 22 79',
      );

    await state.updateProfile(name: 'Sanjar', phone: '+998 97 722 22 79');
    await state.refreshSession();

    expect(state.user?.name, 'Sanjar');
  });

  test('profile login uses the name returned by the server', () async {
    final state = AppState(api: _FakeWasabiApi())
      ..user = const UserProfile(
        id: 'user-1',
        name: 'рри',
        phone: '+998 97 722 22 79',
      );

    await state.updateProfile(name: 'Sanjar', phone: '+998 97 722 22 79');
    await state.logout();
    await state.login(phone: '+998 97 722 22 79', smsCode: '123456');

    expect(state.user?.name, 'Ali');
  });

  test('startup opens before the catalog request finishes', () async {
    final api = _SlowBootstrapWasabiApi();
    final state = AppState(api: api);

    unawaited(state.init());
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(state.initialized, isTrue);
    expect(api.catalogRequested, isTrue);
    api.finishCatalog();
  });

  testWidgets('profile edit saves name and opens phone verification flow',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeApi = _FakeWasabiApi();
    final state = AppState(api: fakeApi)
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibbb',
        phone: '+998 97 772 22 79',
        bonus: 0,
      );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-hero-card')));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Ism'), 'Ali');
    await tester.tap(find.text('Saqlash'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(fakeApi.updatedName, 'Ali');
    expect(state.user?.name, 'Ali');

    await tester.tap(find.text('Telefon raqamini o‘zgartirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('SMS').last);
    await tester.pump(const Duration(milliseconds: 400));

    expect(fakeApi.registerCodeSends, 1);
    expect(fakeApi.profilePhoneCodeSends, 0);
    expect(find.text('Telefon tasdiqlash'), findsOneWidget);
    expect(find.text('Tasdiqlash'), findsNothing);

    final codeFields = find.byType(TextField);
    await tester.enterText(codeFields.first, '123456');
    await tester.pump(const Duration(seconds: 1));

    expect(fakeApi.lastRegisterSmsCode, '123456');
    expect(fakeApi.lastProfilePhoneCode, isNull);
    expect(fakeApi.lastProfilePhone, isNull);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '901234567');
    final newPhoneSend = find.byKey(const ValueKey('phone-change-send-code'));
    await tester.ensureVisible(newPhoneSend);
    await tester.tap(newPhoneSend);
    await tester.pump(const Duration(milliseconds: 400));

    expect(fakeApi.profilePhoneCodeSends, 1);
    expect(fakeApi.profilePhoneCodePhones.last, '+998901234567');

    final newCodeFields = find.byType(TextField);
    await tester.enterText(newCodeFields.first, '123456');
    await tester.pump(const Duration(seconds: 1));

    expect(fakeApi.lastProfilePhoneCode, '123456');
    expect(fakeApi.lastProfilePhone, '+998901234567');
  });

  testWidgets('profile edit does not show password actions', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibbb',
        phone: '+998 97 772 22 79',
        bonus: 0,
      );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );

    expect(find.text('Tahrirlash'), findsNothing);
    expect(find.text('Parol'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profile-hero-card')));
    await tester.pumpAndSettle();

    expect(find.text('Profilni tahrirlash'), findsOneWidget);
    expect(find.text('Saqlash'), findsOneWidget);
    expect(find.text('Parolni o‘zgartirish'), findsNothing);
    expect(find.text('Изменить пароль'), findsNothing);
  });

  testWidgets('profile edit hides password and security-only content',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..user = const UserProfile(
        id: 'user-1',
        name: 'Ibbb',
        phone: '+998 97 722 22 79',
        bonus: 0,
      );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProfileEditScreen(),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-edit-leaf-art')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-edit-promo-art')), findsNothing);
    expect(find.text('Ma’lumotlaringizni yangilang'), findsOneWidget);
    expect(find.text('Tasdiqlangan'), findsOneWidget);
    expect(find.text('Изменить пароль'), findsNothing);
    expect(find.text('Hisobingiz xavfsizligi'), findsNothing);
    expect(find.text('Ma’lumotlaringiz himoyalangan va\nxavfsiz saqlanadi.'),
        findsNothing);
    expect(find.text('Wasabi Sushi bilan tez va oson buyurtma qiling!'),
        findsOneWidget);
  });

  testWidgets('address form uses named location and map select action',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi());

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AddressesScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Qo‘shish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.widgetWithText(TextField, 'Joy nomi'), findsOneWidget);
    expect(find.text('Lokatsiyani tanlash'), findsOneWidget);
    expect(find.text('Mening joyim'), findsNothing);
    expect(find.widgetWithText(TextField, 'Lat'), findsNothing);
    expect(find.widgetWithText(TextField, 'Lng'), findsNothing);
    expect(find.textContaining('xarita'), findsWidgets);
  });

  testWidgets('address form saves without framework error', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi());

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AddressesScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Qo‘shish'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.widgetWithText(TextField, 'Joy nomi'), 'uy');
    await tester.tap(find.text('Saqlash'));
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.takeException(), isNull);
    expect(state.addresses.single.address, 'uy');
  });

  testWidgets('primary address is shown first on addresses screen',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..addresses = const [
        AddressModel(
          id: 'work',
          address: 'Ish',
          lat: 41.3,
          lng: 69.2,
        ),
        AddressModel(
          id: 'home',
          address: 'Uy',
          lat: 41.31,
          lng: 69.24,
          isPrimary: true,
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AddressesScreen(),
        ),
      ),
    );

    final homeTop = tester.getTopLeft(find.text('Uy')).dy;
    final workTop = tester.getTopLeft(find.text('Ish')).dy;
    expect(homeTop, lessThan(workTop));
  });

  testWidgets('address screen can choose primary edit and delete addresses',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..addresses = const [
        AddressModel(id: 'home', address: 'Uy', lat: 41.31, lng: 69.24),
        AddressModel(
          id: 'work',
          address: 'Ish',
          lat: 41.3,
          lng: 69.2,
          isPrimary: true,
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AddressesScreen(),
        ),
      ),
    );

    expect(find.text('Tahrirlash'), findsWidgets);
    expect(find.text('O‘chirish'), findsWidgets);
    expect(find.text('Asosiy qilish'), findsOneWidget);

    await tester.tap(find.text('Asosiy qilish'));
    await tester.pump();
    expect(state.primaryAddress?.id, 'home');

    await tester.tap(find.text('Tahrirlash').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(TextField, 'Joy nomi'), findsOneWidget);
    await tester.tap(find.text('Saqlash'));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.ensureVisible(find.text('O‘chirish').last);
    await tester.tap(find.text('O‘chirish').last);
    await tester.pump();
    expect(state.addresses.length, 1);
  });

  testWidgets('checkout uses primary saved address automatically',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(api: _FakeWasabiApi())
      ..addresses = const [
        AddressModel(id: 'home', address: 'Uy', lat: 41.31, lng: 69.24),
        AddressModel(
          id: 'work',
          address: 'Ish',
          lat: 41.3,
          lng: 69.2,
          isPrimary: true,
        ),
      ];

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CheckoutScreen(),
        ),
      ),
    );

    expect(find.text('Ish'), findsWidgets);
    expect(find.byIcon(Icons.radio_button_checked), findsWidgets);
  });

  testWidgets('checkout shows order promotions as selectable cards',
      (tester) async {
    final today = DateTime.now();
    const birthdayProduct = ProductModel(
      id: 'roll',
      nameRu: 'Roll',
      price: 50000,
      discount: DiscountModel(
        promotionId: 155,
        discountValue: 20,
        resultType: 3,
        isBirthday: true,
      ),
    );
    const firstOrderProduct = ProductModel(
      id: 'sushi',
      nameRu: 'Sushi',
      price: 50000,
      discount: DiscountModel(
        promotionId: 157,
        discountValue: 15,
        resultType: 3,
      ),
    );
    final state = AppState(api: _FakeWasabiApi())
      ..locale = 'uz'
      ..user = UserProfile(
        id: '1',
        name: 'Ali',
        phone: '+998901234567',
        birthday: '2000-${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}',
      )
      ..products = const [birthdayProduct, firstOrderProduct]
      ..checkoutPromotions = const [
        DiscountModel(
          promotionId: 155,
          discountValue: 20,
          resultType: 3,
          isBirthday: true,
        ),
        DiscountModel(
          promotionId: 157,
          discountValue: 15,
          resultType: 3,
        ),
      ];
    state
      ..addToCart(birthdayProduct)
      ..addToCart(firstOrderProduct);

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CheckoutScreen(),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Birinchi buyurtma'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(find.text('Tug‘ilgan kun'), findsOneWidget);
    expect(find.text('Birinchi buyurtma'), findsOneWidget);
  });

  testWidgets('checkout shows only backend-supported payment methods',
      (tester) async {
    final state = AppState(api: _FakeWasabiApi())..locale = 'uz';

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CheckoutScreen(),
        ),
      ),
    );

    expect(find.text('Naqd'), findsOneWidget);
    expect(find.text('Click'), findsNothing);
    expect(find.text('Payme'), findsNothing);
    expect(find.byKey(const Key('payment-logo-click')), findsOneWidget);
    expect(find.byKey(const Key('payment-logo-payme')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('payment-logo-click'))).width,
      64,
    );
    final paymentRow = tester.widget<Row>(
      find.byKey(const Key('payment-options-row')),
    );
    expect(paymentRow.children, hasLength(5));
    expect(find.byType(WasabiPageBackground), findsOneWidget);
    expect(find.text('Karta orqali'), findsNothing);
  });

  testWidgets('checkout keeps the Wasabi background in dark mode',
      (tester) async {
    final state = AppState(api: _FakeWasabiApi())..themeMode = ThemeMode.dark;

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const CheckoutScreen(),
        ),
      ),
    );

    expect(find.byType(WasabiPageBackground), findsOneWidget);
  });

  testWidgets('delivery map hides raw branch operation text', (tester) async {
    const rawBranchName = 'ТРЦ Атриум, 2 этаж. Режим работы: ежедневно';
    final state = AppState()
      ..locale = 'uz'
      ..branches = const [
        BranchModel(
          id: '1',
          name: rawBranchName,
          address: 'Toshkent',
          lat: 41.31,
          lng: 69.28,
        ),
      ];
    const address = AddressModel(
      id: 'home',
      address: 'Toshkent, Yashnobod',
      lat: 41.30,
      lng: 69.27,
    );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: DeliveryRouteCard(address: address)),
        ),
      ),
    );

    expect(find.text('Yetkazish xaritasi'), findsOneWidget);
    expect(find.text('Wasabi yetkazib berish nuqtasi'), findsOneWidget);
    expect(find.text(rawBranchName), findsNothing);
  });

  testWidgets('checkout hides person count and empty bonus control',
      (tester) async {
    final state = AppState(api: _FakeWasabiApi())
      ..locale = 'uz'
      ..user = const UserProfile(
        id: '1',
        name: 'Ali',
        phone: '+998901234567',
        bonus: 0,
      );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CheckoutScreen(),
        ),
      ),
    );

    expect(find.text('Personalar', skipOffstage: false), findsNothing);
    expect(find.text('Bonus', skipOffstage: false), findsNothing);
  });

  test('catalog fallback translates Russian menu names into Uzbek', () {
    const hotCategory = CategoryModel(id: '15', nameRu: 'Горячка');
    const gunkanCategory = CategoryModel(id: '18', nameRu: 'Гунканы');
    const dessertCategory = CategoryModel(id: '22', nameRu: 'Десерты');
    const smokedSalmonGunkan = ProductModel(
      id: '35',
      nameRu: 'Гункан копченный лосось острый',
      price: 1600000,
    );
    const crabGunkan = ProductModel(
      id: '37',
      nameRu: 'Гункан краб острый',
      price: 600000,
    );

    expect(hotCategory.title('uz'), 'Issiq taomlar');
    expect(gunkanCategory.title('uz'), 'Gunkanlar');
    expect(dessertCategory.title('uz'), 'Shirinliklar');
    expect(
      smokedSalmonGunkan.title('uz'),
      'Gunkan dudlangan losos achchiq',
    );
    expect(crabGunkan.title('uz'), 'Gunkan qisqichbaqa achchiq');
  });
}

class _FakeWasabiApi extends WasabiApi {
  _FakeWasabiApi({this.profileUpdateStatusCode});

  final int? profileUpdateStatusCode;
  int registerCodeSends = 0;
  int profilePhoneCodeSends = 0;
  final List<String> profilePhoneCodePhones = [];
  String? lastBootstrapLocale;
  String? lastRegisterSmsCode;
  String? lastProfilePhoneCode;
  String? lastProfilePhone;
  String? updatedName;

  @override
  Future<BootstrapData> loadBootstrap(String locale) async {
    lastBootstrapLocale = locale;
    return const BootstrapData(
      settings: AppSettings(langRuEnabled: true, langUzEnabled: true),
      categories: [],
      products: [],
      banners: [],
      branches: [],
    );
  }

  @override
  Future<String> sendRegisterCode({
    required String phone,
    required String locale,
  }) async {
    registerCodeSends += 1;
    return 'register';
  }

  @override
  Future<void> sendLoginCode({
    required String phone,
    required String locale,
  }) async {
    registerCodeSends += 1;
  }

  @override
  Future<void> sendProfilePhoneChangeCode({
    required String phone,
    required String locale,
  }) async {
    profilePhoneCodeSends += 1;
    profilePhoneCodePhones.add(phone);
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (profileUpdateStatusCode != null) {
      throw ApiException(
        'Not Found',
        statusCode: profileUpdateStatusCode,
      );
    }
    updatedName = name;
    return UserProfile(
      id: 'user-1',
      name: name,
      phone: phone,
    );
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String phone,
    required String generatedPassword,
    required String smsCode,
    String birthday = '',
  }) async {
    lastRegisterSmsCode = smsCode;
    return UserProfile(
      id: 'user-1',
      name: name.isEmpty ? 'Ali' : name,
      phone: phone,
    );
  }

  @override
  Future<UserProfile> login({
    required String phone,
    required String smsCode,
  }) async {
    lastRegisterSmsCode = smsCode;
    return UserProfile(
      id: 'user-1',
      name: 'Ali',
      phone: phone,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserProfile> verifyProfilePhoneChange({
    required String phone,
    required String code,
  }) async {
    lastProfilePhoneCode = code;
    lastProfilePhone = phone;
    return UserProfile(
      id: 'user-1',
      name: 'Ali',
      phone: phone,
    );
  }

  @override
  Future<List<OrderModel>> loadOrders() async {
    return const [];
  }
}

class _SavedProductsState extends AppState {
  _SavedProductsState(this._savedProducts) {
    locale = 'ru';
    products = _savedProducts;
  }

  final List<ProductModel> _savedProducts;

  @override
  List<ProductModel> get savedProducts => _savedProducts;

  @override
  bool isSaved(String productId) =>
      _savedProducts.any((product) => product.id == productId);
}

class _ProfileRefreshFakeWasabiApi extends _FakeWasabiApi {
  _ProfileRefreshFakeWasabiApi(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile?> loadMe() async => profile;
}

class _SlowBootstrapWasabiApi extends _FakeWasabiApi {
  final _catalog = Completer<BootstrapData>();
  bool catalogRequested = false;

  @override
  Future<BootstrapData> loadBootstrap(String locale) {
    catalogRequested = true;
    return _catalog.future;
  }

  @override
  Future<UserProfile?> loadMe() async => null;

  @override
  Future<List<MailingModel>> loadMailings() async => const [];

  void finishCatalog() {
    _catalog.complete(
      const BootstrapData(
        settings: AppSettings(langRuEnabled: true, langUzEnabled: true),
        categories: [],
        products: [],
        banners: [],
        branches: [],
      ),
    );
  }
}
