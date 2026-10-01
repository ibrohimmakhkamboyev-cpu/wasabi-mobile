import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/models/app_models.dart';
import 'package:wasabi_mobile/services/native_bridge.dart';
import 'package:wasabi_mobile/services/wasabi_api.dart';
import 'package:wasabi_mobile/state/app_state.dart';

class _CancelApi extends WasabiApi {
  bool fail = true;
  @override
  Future<void> cancelOrder(int id) async {
    if (fail) throw Exception('offline');
  }
}

class _CheckoutApi extends WasabiApi {
  int calls = 0;
  final result = Completer<CheckoutResult>();
  @override
  Future<CheckoutResult> placeOrder(CheckoutRequest request) {
    calls++;
    return result.future;
  }

  @override
  Future<List<OrderModel>> loadOrders() async => throw Exception('offline');
}

class _OpenState extends AppState {
  _OpenState(WasabiApi api) : super(api: api);
  @override
  bool get isOrderingOpen => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('checkout rejects double taps and tolerates history refresh failure',
      () async {
    final api = _CheckoutApi();
    final state = _OpenState(api)
      ..user = const UserProfile(id: '1', name: 'Test', phone: '+998901234567')
      ..cart = [
        const CartItem(productId: '1', name: 'Roll', price: 10000, quantity: 1)
      ];
    final first = state.submitOrder(
        deliveryType: DeliveryType.pickup, paymentMethod: PaymentMethod.cash);
    await expectLater(
        state.submitOrder(
            deliveryType: DeliveryType.pickup,
            paymentMethod: PaymentMethod.cash),
        throwsException);
    expect(api.calls, 1);
    api.result.complete(CheckoutResult(orderId: 42));
    expect(await first, 42);
    await Future<void>.delayed(Duration.zero);
    expect(state.cart, isEmpty);
    expect(state.lastOrderId, 42);
  });

  test('failed cancellation preserves the order for retry', () async {
    final api = _CancelApi();
    final state = AppState(api: api)
      ..orders = [
        const OrderModel(id: '42', status: 'new', createdAt: null),
      ];
    await expectLater(state.cancelOrder(42), throwsException);
    expect(state.orders.single.id, '42');
    api.fail = false;
    await state.cancelOrder(42);
    expect(state.orders, isEmpty);
  });

  test('maintenance rejects submission before order processing', () async {
    final state = AppState()..settings = const AppSettings(siteEnabled: false);
    await expectLater(
      state.submitOrder(
          deliveryType: DeliveryType.pickup, paymentMethod: PaymentMethod.cash),
      throwsA(predicate((e) => e.toString().contains('Texnik tanaffus'))),
    );
  });

  test('payment link launch failure reaches checkout', () async {
    const channel = MethodChannel('uz.wasabi.mobile/native');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'OPEN_URL_FAILED');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await expectLater(
        NativeBridge.openUrl('https://example.com/payment',
            throwOnFailure: true),
        throwsA(isA<PlatformException>()));
  });
}
