import 'dart:convert';

import 'package:http/http.dart' as http;

import 'native_bridge.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    Duration? requestTimeout,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _httpClient = httpClient ?? http.Client(),
        _requestTimeout = requestTimeout ?? const Duration(seconds: 8);

  static const _cookieKey = 'wasabi_client_cookie_v1';
  final String _baseUrl;
  final http.Client _httpClient;
  final Duration _requestTimeout;
  String? _cookieHeader;

  Future<void> init() async {
    _cookieHeader = await NativeBridge.getString(_cookieKey);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query,
    });
  }

  Map<String, String> _headers({bool json = true}) {
    return {
      'accept': 'application/json',
      if (json) 'content-type': 'application/json',
      if (_cookieHeader != null && _cookieHeader!.isNotEmpty)
        'cookie': _cookieHeader!,
    };
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _httpClient
        .get(
          _uri(path, query),
          headers: _headers(json: false),
        )
        .timeout(_requestTimeout);
    return _decode(response);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final response = await _httpClient
        .post(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(_stripNulls(body)),
        )
        .timeout(_requestTimeout);
    return _decode(response);
  }

  Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final response = await _httpClient
        .patch(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(_stripNulls(body)),
        )
        .timeout(_requestTimeout);
    return _decode(response);
  }

  Future<void> clearSession() async {
    _cookieHeader = null;
    await NativeBridge.remove(_cookieKey);
  }

  dynamic _decode(http.Response response) {
    _captureCookie(response);
    final raw = response.body.trim();
    dynamic json;
    if (raw.isNotEmpty) {
      try {
        json = jsonDecode(raw);
      } catch (_) {
        json = raw;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final map = json is Map ? json : const {};
      final code = map['error']?.toString();
      throw ApiException(
        _humanError(code) ?? response.reasonPhrase ?? 'Ошибка запроса',
        statusCode: response.statusCode,
        code: code,
      );
    }
    return json;
  }

  void _captureCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return;

    final parts = setCookie
        .split(RegExp(r',(?=[^;,]+=)'))
        .map((cookie) => cookie.split(';').first.trim())
        .where((cookie) => cookie.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;

    final current = <String, String>{};
    if (_cookieHeader != null && _cookieHeader!.isNotEmpty) {
      for (final cookie in _cookieHeader!.split(';')) {
        final idx = cookie.indexOf('=');
        if (idx <= 0) continue;
        current[cookie.substring(0, idx).trim()] = cookie.substring(idx + 1);
      }
    }
    for (final cookie in parts) {
      final idx = cookie.indexOf('=');
      if (idx <= 0) continue;
      current[cookie.substring(0, idx).trim()] = cookie.substring(idx + 1);
    }
    _cookieHeader =
        current.entries.map((e) => '${e.key}=${e.value}').join('; ');
    NativeBridge.setString(_cookieKey, _cookieHeader!);
  }

  Map<String, dynamic> _stripNulls(Map<String, dynamic> value) {
    final result = <String, dynamic>{};
    value.forEach((key, item) {
      if (item == null) return;
      if (item is Map<String, dynamic>) {
        result[key] = _stripNulls(item);
      } else if (item is List) {
        result[key] = item
            .map((entry) =>
                entry is Map<String, dynamic> ? _stripNulls(entry) : entry)
            .toList();
      } else {
        result[key] = item;
      }
    });
    return result;
  }

  String? _humanError(String? code) {
    switch (code) {
      case 'UNAUTHORIZED':
        return 'Нужно войти в аккаунт';
      case 'INVALID_PHONE':
        return 'Некорректный номер телефона';
      case 'CLIENT_ALREADY_REGISTERED':
        return 'Этот номер уже зарегистрирован';
      case 'CLIENT_NOT_FOUND':
        return 'Клиент не найден';
      case 'INVALID_CREDENTIALS':
        return 'Неверный телефон или SMS-код';
      case 'PASSWORD_TOO_SHORT':
        return 'Неверный телефон или SMS-код';
      case 'SMS_CODE_INVALID':
        return 'Неверный SMS-код';
      case 'SMS_CODE_EXPIRED':
        return 'Срок действия SMS-кода истек';
      case 'SMS_RESEND_TOO_EARLY':
        return 'Подождите перед повторной отправкой SMS';
      case 'AUTH_CONFIG_ERROR':
        return 'Ошибка настройки авторизации на сервере';
      case 'POSTER_CONFIG_ERROR':
        return 'Ошибка настройки сервиса клиентов на сервере';
      case 'POSTER_UNAVAILABLE':
        return 'Сервис клиентов временно недоступен';
      case 'AUTH_INTERNAL_ERROR':
        return 'Внутренняя ошибка авторизации';
      case 'CLIENT_SYNC_FAILED':
        return 'Не удалось синхронизировать аккаунт';
      case 'CLIENT_SAVE_FAILED':
        return 'Не удалось сохранить аккаунт';
      case 'CLIENT_CREATE_FAILED':
        return 'Не удалось создать аккаунт';
      case 'INVALID_PROMO':
        return 'Промокод недействителен';
      case 'ADDRESS_REQUIRED':
        return 'Укажите адрес доставки';
      case 'LOCATION_REQUIRED':
        return 'Укажите точку доставки';
      case 'SPOT_REQUIRED':
        return 'Выберите филиал';
      case 'CLOSED':
        return 'Ресторан сейчас не принимает заказы';
      case 'MAINTENANCE':
        return 'Приложение временно находится на техническом обслуживании';
      case 'PAYME_NOT_CONFIGURED':
        return 'Оплата Payme пока не настроена';
      default:
        return null;
    }
  }
}
