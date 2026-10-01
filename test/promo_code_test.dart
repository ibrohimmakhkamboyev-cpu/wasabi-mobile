import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/models/app_models.dart';
import 'package:wasabi_mobile/services/wasabi_api.dart';
import 'package:wasabi_mobile/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('uz.wasabi.mobile/native'),
    (_) async => null,
  );

  test('invalid promo clears code and discount', () async {
    final api = _PromoApi({'BAD': 0});
    final state = AppState(api: api)
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    await expectLater(state.applyPromo('bad'), throwsException);

    expect(state.promoCode, isEmpty);
    expect(state.promoDiscount, 0);
  });

  test('promo discount refreshes after cart subtotal changes', () async {
    final api = _PromoApi({'SALE': 10000});
    final state = AppState(api: api)
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    await state.applyPromo('sale');
    expect(state.promoDiscount, 10000);

    api.discounts['SALE'] = 15000;
    state.addToCart(
      const ProductModel(id: 'soup', nameRu: 'Soup', price: 30000),
    );
    await Future<void>.delayed(Duration.zero);

    expect(state.promoCode, 'SALE');
    expect(state.promoDiscount, 15000);
  });

  test('submit revalidates promo before placing order', () async {
    final api = _PromoApi({'SALE': 10000});
    final state = AppState(api: api)
      ..user = const UserProfile(id: '1', name: 'Ali', phone: '+998901234567')
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    await state.applyPromo('sale');
    api.discounts['SALE'] = 0;

    await expectLater(
      state.submitOrder(
        deliveryType: DeliveryType.pickup,
        paymentMethod: PaymentMethod.cash,
        branch: const BranchModel(
          id: '1',
          name: 'Branch',
          address: 'Tashkent',
          spotId: '1',
        ),
      ),
      throwsException,
    );

    expect(api.ordersPlaced, 0);
    expect(state.promoCode, isEmpty);
    expect(state.promoDiscount, 0);
  });

  test('submit rejects unsupported card payment before placing order',
      () async {
    final api = _PromoApi({});
    final state = AppState(api: api)
      ..user = const UserProfile(id: '1', name: 'Ali', phone: '+998901234567')
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    await expectLater(
      state.submitOrder(
        deliveryType: DeliveryType.pickup,
        paymentMethod: PaymentMethod.card,
        branch: const BranchModel(
          id: '1',
          name: 'Branch',
          address: 'Tashkent',
          spotId: '1',
        ),
      ),
      throwsException,
    );

    expect(api.ordersPlaced, 0);
  });

  test('selected checkout promotion discounts the full normal cart total', () {
    const productDiscount = ProductModel(
      id: 'sandwich',
      nameRu: 'Sandwich',
      price: 100000,
      discount: DiscountModel(
        promotionId: 232,
        discountValue: 10,
        resultType: 3,
      ),
    );
    const birthdayPromotion = ProductModel(
      id: 'roll',
      nameRu: 'Roll',
      price: 100000,
      discount: DiscountModel(
        promotionId: 155,
        discountValue: 20,
        resultType: 3,
        isBirthday: true,
      ),
    );
    const firstOrderPromotion = ProductModel(
      id: 'sushi',
      nameRu: 'Sushi',
      price: 100000,
      discount: DiscountModel(
        promotionId: 157,
        discountValue: 15,
        resultType: 3,
      ),
    );
    final today = DateTime.now();
    final state = AppState()
      ..user = UserProfile(
        id: '1',
        name: 'Ali',
        phone: '+998901234567',
        birthday: '2000-${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}',
      )
      ..products = const [
        productDiscount,
        birthdayPromotion,
        firstOrderPromotion,
      ]
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
      ..addToCart(productDiscount)
      ..addToCart(birthdayPromotion)
      ..addToCart(firstOrderPromotion);

    expect(state.checkoutPromotionIds, orderedEquals([155, 157]));
    expect(state.cart.map((item) => item.price),
        orderedEquals([90000, 100000, 100000]));
    expect(state.requiresCheckoutDiscountChoice, isTrue);

    state.selectPromotion(155);
    expect(state.cart.map((item) => item.price),
        orderedEquals([100000, 100000, 100000]));
    expect(state.checkoutPromotionDiscount, 60000);
    expect(state.totalFor(DeliveryType.pickup), 240000);

    state.selectPromotion(157);
    expect(state.cart.map((item) => item.price),
        orderedEquals([100000, 100000, 100000]));
    expect(state.checkoutPromotionDiscount, 45000);
    expect(state.totalFor(DeliveryType.pickup), 255000);
  });

  test(
      'fixed product promotion deducts its value and checkout includes delivery',
      () {
    const fixedDiscountProduct = ProductModel(
      id: 'sandwich-with-cheese',
      nameRu: 'Sandwich with cheese',
      price: 35000,
      discount: DiscountModel(discountValue: 5000, resultType: 2),
    );
    const specialPriceProduct = ProductModel(
      id: 'sandwich',
      nameRu: 'Sandwich',
      price: 29000,
      discount: DiscountModel(
        discountValue: 0,
        resultType: 4,
        discountPrices: [
          {'type': '2', 'id': 'sandwich', 'price': 2200000},
        ],
      ),
    );
    final state = AppState()
      ..settings = const AppSettings(deliveryFee: 20000)
      ..products = const [fixedDiscountProduct, specialPriceProduct]
      ..addToCart(fixedDiscountProduct)
      ..addToCart(specialPriceProduct);

    expect(state.cart.map((item) => item.price), orderedEquals([30000, 22000]));
    expect(state.fullPriceSubtotal, 64000);
    expect(state.subtotal, 52000);
    expect(state.productDiscount, 12000);
    expect(state.totalFor(DeliveryType.delivery), 72000);
  });

  test('Poster fixed promotion amount is normalized before it is deducted', () {
    final discount = DiscountModel.fromJson(const {
      'discount_value': 500000,
      'result_type': 2,
    });

    expect(discount.discountValue, 5000);
    expect(discount.apply(35000), 30000);
  });

  test('a newly enabled checkout promotion does not depend on a hard-coded ID',
      () {
    const promotion = DiscountModel(
      promotionId: 901,
      discountValue: 20,
      resultType: 3,
    );
    const product = ProductModel(
      id: 'new-promotion-product',
      nameRu: 'New promotion product',
      price: 100000,
      discount: promotion,
    );
    final state = AppState()
      ..products = const [product]
      ..checkoutPromotions = const [promotion];

    state.addToCart(product);
    state.selectPromotion(901);

    expect(state.cart.single.price, 100000);
    expect(state.selectedPromotionId, 901);
    expect(state.checkoutPromotionDiscount, 20000);
    expect(state.totalFor(DeliveryType.pickup), 80000);
  });

  test('three checkout promotions require one explicit selection at a time',
      () {
    const first = DiscountModel(
      promotionId: 701,
      discountValue: 10,
      resultType: 3,
    );
    const second = DiscountModel(
      promotionId: 702,
      discountValue: 15,
      resultType: 3,
    );
    const third = DiscountModel(
      promotionId: 703,
      discountValue: 20,
      resultType: 3,
    );
    const product = ProductModel(id: 'roll', nameRu: 'Roll', price: 100000);
    final state = AppState()
      ..products = const [product]
      ..checkoutPromotions = const [first, second, third]
      ..addToCart(product);

    expect(state.requiresCheckoutDiscountChoice, isTrue);
    expect(state.selectedPromotionId, isNull);
    expect(state.totalFor(DeliveryType.pickup), 100000);

    state.selectPromotion(702);
    expect(state.selectedPromotionId, 702);
    expect(state.checkoutPromotionDiscount, 15000);
    expect(state.totalFor(DeliveryType.pickup), 85000);

    state.selectPromotion(703);
    expect(state.selectedPromotionId, 703);
    expect(state.checkoutPromotionDiscount, 20000);
    expect(state.totalFor(DeliveryType.pickup), 80000);
  });

  test('promo code is a checkout option beside an order promotion', () async {
    const orderPromotion = ProductModel(
      id: 'roll',
      nameRu: 'Roll',
      price: 100000,
      discount: DiscountModel(
        promotionId: 157,
        discountValue: 15,
        resultType: 3,
      ),
    );
    final state = AppState(api: _PromoApi({'SALE': 20000}))
      ..products = const [orderPromotion]
      ..checkoutPromotions = const [
        DiscountModel(
          promotionId: 157,
          discountValue: 15,
          resultType: 3,
        ),
      ];

    state.addToCart(orderPromotion);
    expect(state.selectedPromotionId, 157);

    await state.applyPromo('sale');
    expect(state.requiresCheckoutDiscountChoice, isTrue);
    expect(state.selectedPromotionId, isNull);
    expect(state.promoDiscount, 0);

    state.selectPromoCode();
    expect(state.isPromoCodeSelected, isTrue);
    expect(state.promoDiscount, 20000);
    expect(state.totalFor(DeliveryType.pickup), 80000);
  });

  test('click payment without payment URL does not complete checkout',
      () async {
    final api = _PromoApi({});
    final state = AppState(api: api)
      ..user = const UserProfile(id: '1', name: 'Ali', phone: '+998901234567')
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    await expectLater(
      state.submitOrder(
        deliveryType: DeliveryType.pickup,
        paymentMethod: PaymentMethod.click,
        branch: const BranchModel(
          id: '1',
          name: 'Branch',
          address: 'Tashkent',
          spotId: '1',
        ),
      ),
      throwsException,
    );

    expect(api.ordersPlaced, 1);
    expect(state.cart, isNotEmpty);
    expect(state.lastOrderId, isNull);
  });

  test('click payment with payment URL completes checkout', () async {
    final api = _PromoApi({})..paymentUrl = 'https://my.click.uz/pay';
    final state = AppState(api: api)
      ..user = const UserProfile(id: '1', name: 'Ali', phone: '+998901234567')
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    final orderId = await state.submitOrder(
      deliveryType: DeliveryType.pickup,
      paymentMethod: PaymentMethod.click,
      branch: const BranchModel(
        id: '1',
        name: 'Branch',
        address: 'Tashkent',
        spotId: '1',
      ),
    );

    expect(orderId, 123);
    expect(state.cart, isEmpty);
    expect(state.lastOrderId, 123);
  });

  test('payme payment without payment URL does not complete checkout',
      () async {
    final api = _PromoApi({});
    final state = AppState(api: api)
      ..user = const UserProfile(id: '1', name: 'Ali', phone: '+998901234567')
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    await expectLater(
      state.submitOrder(
        deliveryType: DeliveryType.pickup,
        paymentMethod: PaymentMethod.payme,
        branch: const BranchModel(
          id: '1',
          name: 'Branch',
          address: 'Tashkent',
          spotId: '1',
        ),
      ),
      throwsException,
    );

    expect(api.ordersPlaced, 1);
    expect(state.cart, isNotEmpty);
    expect(state.lastOrderId, isNull);
  });

  test('payme payment with payment URL completes checkout', () async {
    final api = _PromoApi({})..paymentUrl = 'https://checkout.paycom.uz/test';
    final state = AppState(api: api)
      ..user = const UserProfile(id: '1', name: 'Ali', phone: '+998901234567')
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    final orderId = await state.submitOrder(
      deliveryType: DeliveryType.pickup,
      paymentMethod: PaymentMethod.payme,
      branch: const BranchModel(
        id: '1',
        name: 'Branch',
        address: 'Tashkent',
        spotId: '1',
      ),
    );

    expect(orderId, 123);
    expect(state.cart, isEmpty);
    expect(state.lastOrderId, 123);
  });

  test('payme payment retries the order payment endpoint when URL is delayed',
      () async {
    final api = _PromoApi({})
      ..deferredPaymentUrls = [
        null,
        null,
        'https://checkout.paycom.uz/deferred',
      ];
    final state = AppState(api: api)
      ..user = const UserProfile(id: '1', name: 'Ali', phone: '+998901234567')
      ..cart = [
        const CartItem(
          productId: 'roll',
          name: 'Roll',
          price: 50000,
          quantity: 1,
        ),
      ];

    final orderId = await state.submitOrder(
      deliveryType: DeliveryType.pickup,
      paymentMethod: PaymentMethod.payme,
      branch: const BranchModel(
        id: '1',
        name: 'Branch',
        address: 'Tashkent',
        spotId: '1',
      ),
    );

    expect(orderId, 123);
    expect(state.cart, isEmpty);
    expect(state.lastOrderId, 123);
    expect(api.paymentUrlRequests, 3);
  });

  test('checkout result accepts snake case API fields', () {
    final result = CheckoutResult.fromJson({
      'order_id': 321,
      'payment_url': 'https://checkout.paycom.uz/test',
    });

    expect(result.orderId, 321);
    expect(result.paymentUrl, 'https://checkout.paycom.uz/test');
  });
}

class _PromoApi extends WasabiApi {
  _PromoApi(this.discounts);

  final Map<String, int> discounts;
  String? paymentUrl;
  String? deferredPaymentUrl;
  List<String?> deferredPaymentUrls = [];
  int paymentUrlRequests = 0;
  int ordersPlaced = 0;

  @override
  Future<int> validatePromoCode({
    required String code,
    required int subtotal,
  }) async {
    return discounts[code.toUpperCase()] ?? 0;
  }

  @override
  Future<CheckoutResult> placeOrder(CheckoutRequest request) async {
    ordersPlaced += 1;
    return CheckoutResult(orderId: 123, paymentUrl: paymentUrl);
  }

  @override
  Future<String?> loadPaymentUrl(int id) async {
    paymentUrlRequests += 1;
    if (deferredPaymentUrls.isNotEmpty) {
      return deferredPaymentUrls.removeAt(0);
    }
    return deferredPaymentUrl;
  }

  @override
  Future<List<OrderModel>> loadOrders() async {
    return const [];
  }
}
