import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/models/app_models.dart';
import 'package:wasabi_mobile/services/api_client.dart';
import 'package:wasabi_mobile/services/wasabi_api.dart';
import 'package:wasabi_mobile/state/app_state.dart';

class _ControlledApi extends WasabiApi {
  final requests = <String, Completer<BootstrapData>>{};
  int calls = 0;
  Object sessionError = TimeoutException('offline');

  @override
  Future<BootstrapData> loadBootstrap(String locale) {
    calls++;
    return (requests[locale] ??= Completer<BootstrapData>()).future;
  }

  @override
  Future<UserProfile?> loadMe() async => throw sessionError;
}

BootstrapData _catalog(String locale) => BootstrapData(
      settings: const AppSettings(),
      categories: const [],
      products: [ProductModel(id: locale, nameRu: locale, price: 1000)],
      banners: const [],
      branches: const [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old language completion keeps the current catalog loading', () async {
    final api = _ControlledApi();
    final state = AppState(api: api)..locale = 'ru';
    final old = state.refreshCatalog();
    state.locale = 'uz';
    final current = state.refreshCatalog();
    api.requests['ru']!.complete(_catalog('ru'));
    await old;
    expect(state.catalogLoading, isTrue);
    api.requests['uz']!.complete(_catalog('uz'));
    await current;
    expect(state.catalogLoading, isFalse);
  });

  test('concurrent catalog refreshes share a request and ignore old language',
      () async {
    final api = _ControlledApi();
    final state = AppState(api: api)..locale = 'ru';
    final first = state.refreshCatalog();
    final duplicate = state.refreshCatalog();
    expect(api.calls, 1);
    state.locale = 'uz';
    final next = state.refreshCatalog();
    api.requests['uz']!.complete(_catalog('uz'));
    await next;
    api.requests['ru']!.complete(_catalog('ru'));
    await Future.wait([first, duplicate]);
    expect(state.products.first.id, 'uz');
    expect(api.calls, 2);
  });

  test('temporary session failure preserves profile; unauthorized clears it',
      () async {
    final api = _ControlledApi();
    final state = AppState(api: api)
      ..user = const UserProfile(
          id: '1', name: 'Saved name', phone: '+998901234567');
    await state.refreshSession();
    expect(state.user?.name, 'Saved name');
    api.sessionError = ApiException('Unauthorized', statusCode: 401);
    await state.refreshSession();
    expect(state.user, isNull);
  });
}
