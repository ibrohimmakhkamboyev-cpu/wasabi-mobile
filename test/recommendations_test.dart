import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/models/app_models.dart';
import 'package:wasabi_mobile/state/app_state.dart';

void main() {
  const drink = ProductModel(
    id: 'drink-1',
    nameRu: 'Напиток 1',
    price: 10000,
    categoryId: 'drinks',
  );
  const drinkTwo = ProductModel(
    id: 'drink-2',
    nameRu: 'Напиток 2',
    price: 10000,
    categoryId: 'drinks',
  );
  const drinkThree = ProductModel(
    id: 'drink-3',
    nameRu: 'Напиток 3',
    price: 10000,
    categoryId: 'drinks',
  );
  const roll = ProductModel(
    id: 'roll-1',
    nameRu: 'Ролл',
    price: 40000,
    categoryId: 'rolls',
  );
  const rollTwo = ProductModel(
    id: 'roll-2',
    nameRu: 'Ролл 2',
    price: 45000,
    categoryId: 'rolls',
  );
  const salad = ProductModel(
    id: 'salad-1',
    nameRu: 'Салат',
    price: 30000,
    categoryId: 'salads',
  );

  test(
      'recommendations prioritize relevant products without only showing drinks',
      () {
    final state = AppState()
      ..products = [drink, drinkTwo, drinkThree, roll, rollTwo, salad];

    final recommendations = state.recommendationsFor(drink, limit: 5);

    expect(recommendations.take(2).every((item) => item.categoryId == 'drinks'),
        isTrue);
    expect(recommendations.any((item) => item.categoryId == 'rolls'), isTrue);
    expect(recommendations, isNot(contains(drink)));
  });

  test('recommendations use cart and previous-order category signals', () {
    final state = AppState()
      ..products = [drink, drinkTwo, roll, rollTwo, salad]
      ..cart = [CartItem.fromProduct(roll)]
      ..orders = const [
        OrderModel(
          id: 'order-1',
          status: 'done',
          createdAt: null,
          items: [
            OrderItemModel(
              productId: 'salad-1',
              name: 'Салат',
              quantity: 1,
            ),
          ],
        ),
      ];

    final recommendations = state.recommendationsFor(drink, limit: 4);

    expect(recommendations.first.id, 'drink-2');
    expect(recommendations.map((item) => item.id),
        containsAll(['roll-2', 'salad-1']));
  });
}
