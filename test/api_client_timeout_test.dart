import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wasabi_mobile/services/api_client.dart';

class _NeverRespondingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future;
}

void main() {
  test('catalog requests do not block startup for a minute', () async {
    final client = ApiClient(
      baseUrl: 'https://wasabisushi.uz',
      httpClient: _NeverRespondingClient(),
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
        client.getJson('/api/menu'), throwsA(isA<TimeoutException>()));
  });
}
