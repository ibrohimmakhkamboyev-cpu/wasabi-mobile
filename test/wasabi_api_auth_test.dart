import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wasabi_mobile/models/app_models.dart';
import 'package:wasabi_mobile/services/api_client.dart';
import 'package:wasabi_mobile/services/wasabi_api.dart';
import 'package:wasabi_mobile/state/app_state.dart';

void main() {
  test('reports unavailable catalog when Poster menu is empty', () async {
    Uri? productsRequest;
    final api = WasabiApi(
      client: ApiClient(
        baseUrl: 'https://example.test',
        httpClient: MockClient((request) async {
          switch (request.url.path) {
            case '/api/menu':
              return http.Response('{"settings":{}}', 200);
            case '/api/poster/categories':
              return http.Response('[]', 200);
            case '/api/poster/products':
              productsRequest = request.url;
              return http.Response('[]', 200);
            case '/api/banners':
              return http.Response('[]', 200);
            case '/api/poster/promotions':
              return http.Response('{"discounts":{}}', 200);
            case '/api/locations':
              return http.Response('{"locations":[]}', 200);
            case '/api/poster/spots':
              return http.Response('[]', 200);
          }
          return http.Response('Not found', 404);
        }),
      ),
    );

    await expectLater(
      api.loadBootstrap('ru'),
      throwsA(isA<ApiException>()),
    );
    expect(productsRequest?.queryParameters['compact'], '1');
  });

  test('setLocale updates immediately and refreshes in the background',
      () async {
    final api = _FakeWasabiApi();
    final state = AppState(api: api)..locale = 'ru';

    await state.refreshCatalog();
    expect(state.products.single.title(state.locale), 'Bonito ru');

    final switching = state.setLocale('uz');

    expect(state.locale, 'uz');
    await switching;
    for (var attempt = 0;
        attempt < 20 && !api.requestedLocales.contains('uz');
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(api.requestedLocales, ['ru', 'uz']);
    expect(state.products.single.title(state.locale), 'Bonito uz');
  });

  test(
      'falls back to transliterated Uzbek titles when explicit translation is missing',
      () {
    const product = ProductModel(
      id: '1',
      nameRu: 'Апельсин сок 1л',
      price: 25000,
    );
    const category = CategoryModel(
      id: '2',
      nameRu: 'Горячие роллы',
    );

    expect(product.title('uz'), 'Apelsin sok 1l');
    expect(category.title('uz'), 'Goryachie rolly');
  });
}

class _FakeWasabiApi extends WasabiApi {
  final List<String> requestedLocales = [];

  @override
  Future<BootstrapData> loadBootstrap(String locale) async {
    requestedLocales.add(locale);
    return BootstrapData(
      settings: const AppSettings(),
      categories: [
        CategoryModel(
          id: '1',
          nameRu: 'Соусы',
          nameUz: locale == 'uz' ? 'Souslar' : null,
        ),
      ],
      products: [
        ProductModel(
          id: '101',
          nameRu: 'Bonito ru',
          nameUz: locale == 'uz' ? 'Bonito uz' : null,
          price: 39000,
          categoryId: '1',
        ),
      ],
      banners: const [],
      branches: const [],
    );
  }
}
