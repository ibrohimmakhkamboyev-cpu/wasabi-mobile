import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'native_bridge.dart';

class BootstrapData {
  const BootstrapData({
    required this.settings,
    required this.categories,
    required this.products,
    this.popularProductIds = const [],
    this.checkoutPromotions = const [],
    required this.banners,
    required this.branches,
  });

  final AppSettings settings;
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<String> popularProductIds;
  final List<DiscountModel> checkoutPromotions;
  final List<BannerModel> banners;
  final List<BranchModel> branches;
}

class WasabiApi {
  WasabiApi({ApiClient? client, String? baseUrl})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? ApiClient(baseUrl: baseUrl ?? AppConfig.apiBaseUrl);

  final String _baseUrl;
  final ApiClient _client;

  String _bootstrapCacheKey(String locale) {
    final host = Uri.tryParse(_baseUrl)
            ?.host
            .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_') ??
        'default';
    return 'wasabi_mobile_bootstrap_v1_${host}_$locale';
  }

  String _bannerCacheKey(String locale) {
    final host = Uri.tryParse(_baseUrl)
            ?.host
            .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_') ??
        'default';
    return 'wasabi_mobile_banners_v1_${host}_$locale';
  }

  Future<void> init() => _client.init();

  /// Fast startup path: only the data needed to render the menu. Banners,
  /// promotions and branch metadata are refreshed after products are visible.
  Future<BootstrapData> loadCatalogBootstrap(String locale) async {
    final responses = await Future.wait<dynamic>([
      _safeGet('/api/menu', retry: false),
      _safeGet('/api/poster/categories', retry: false),
      _safeGet(
        '/api/poster/products',
        query: const {'compact': '1'},
        retry: false,
      ),
    ]);
    return _decodeBootstrap(
      locale,
      [
        responses[0],
        responses[1],
        const [],
        const <String, dynamic>{},
        const <String, dynamic>{},
        const [],
        responses[2],
      ],
      allowNetworkProductFallback: false,
    );
  }

  Future<BootstrapData> loadBootstrap(String locale) async {
    final responses = await Future.wait<dynamic>([
      _safeGet('/api/menu', retry: false),
      _safeGet('/api/poster/categories', retry: false),
      _safeGet('/api/banners', query: {'locale': locale}, retry: false),
      _safeGet('/api/poster/promotions', retry: false),
      _safeGet('/api/locations', retry: false),
      _safeGet('/api/poster/spots', retry: false),
      _safeGet(
        '/api/poster/products',
        query: const {'compact': '1'},
        retry: false,
      ),
    ]);
    // An unavailable banner request must not erase the last usable carousel.
    // An empty list, however, is a deliberate admin choice and stays empty.
    if (responses[2] == null) {
      final cachedBanners = await _loadCachedBanners(locale);
      if (cachedBanners != null) responses[2] = cachedBanners;
    } else {
      await NativeBridge.setString(
        _bannerCacheKey(locale),
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'banners': responses[2]
        }),
      );
    }

    final data = await _decodeBootstrap(
      locale,
      responses,
      allowNetworkProductFallback: true,
    );
    await NativeBridge.setString(
      _bootstrapCacheKey(locale),
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'responses': responses,
      }),
    );
    return data;
  }

  Future<List<dynamic>?> _loadCachedBanners(String locale) async {
    try {
      final raw = await NativeBridge.getString(_bannerCacheKey(locale));
      if (raw == null || raw.isEmpty) return null;
      final cache = readMap(jsonDecode(raw));
      final savedAt = readInt(cache['savedAt']);
      if (savedAt == 0 ||
          DateTime.now().millisecondsSinceEpoch - savedAt >
              const Duration(days: 7).inMilliseconds) {
        return null;
      }
      return readList(cache['banners']);
    } catch (_) {
      return null;
    }
  }

  /// Returns the last complete catalog without waiting for the network.
  /// A fresh version is always loaded in the background by [AppState].
  Future<BootstrapData?> loadCachedBootstrap(String locale) async {
    try {
      final raw = await NativeBridge.getString(_bootstrapCacheKey(locale));
      if (raw == null || raw.isEmpty) return null;
      final cached = readMap(jsonDecode(raw));
      final savedAt = readInt(cached['savedAt']);
      if (savedAt == 0 ||
          DateTime.now().millisecondsSinceEpoch - savedAt >
              const Duration(hours: 24).inMilliseconds) {
        return null;
      }
      final responses = readList(cached['responses']);
      if (responses.length != 7) return null;
      return _decodeBootstrap(
        locale,
        responses,
        allowNetworkProductFallback: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<BootstrapData> _decodeBootstrap(
    String locale,
    List<dynamic> responses, {
    required bool allowNetworkProductFallback,
  }) async {
    final menuResponse = responses[0];
    final categoriesResponse = responses[1];
    final bannersResponse = responses[2];
    final promotionsResponse = responses[3];
    final locationsResponse = responses[4];
    final spotsResponse = responses[5];
    final productsResponse = responses[6];

    final menu = readMap(menuResponse);
    final settings = AppSettings.fromJson(readMap(menu['settings']));
    final categoryTranslations =
        _normalizeLookupMap(menu['categoryTranslations']);
    final productTranslations =
        _normalizeLookupMap(menu['productTranslations']);
    final emojiMap = _normalizeLookupMap(menu['categoryEmoji']);
    final popularProductIds = readList(menu['popularProductIds'])
        .map(readString)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final discountsJson = readMap(readMap(promotionsResponse)['discounts']);
    final discounts = discountsJson.map(
      (key, value) => MapEntry(
        key,
        DiscountModel.fromJson(readMap(value)),
      ),
    );
    final checkoutPromotions = readList(
      readMap(promotionsResponse)['checkoutPromotions'],
    )
        .map((item) => DiscountModel.fromJson(readMap(item)))
        .where((discount) => discount.promotionId != null)
        .toList(growable: false);

    final menuCategories = readList(menu['categories']);
    final posterCategoryItems = readList(categoriesResponse);
    if (menuCategories.isEmpty && posterCategoryItems.isEmpty) {
      throw ApiException('Poster categories unavailable');
    }
    final posterCategories =
        posterCategoryItems.isNotEmpty ? posterCategoryItems : menuCategories;
    final categories = posterCategories
        .map((item) {
          final json = readMap(item);
          final id = readString(json['category_id'] ?? json['id']);
          return CategoryModel.fromJson(
            json,
            translation: readMap(categoryTranslations[id]),
            emoji: readString(emojiMap[id]).isEmpty
                ? null
                : readString(emojiMap[id]),
          );
        })
        .where((category) => category.id.isNotEmpty)
        .toList();
    categories.sort((a, b) {
      final left = a.sortOrder ?? 9999;
      final right = b.sortOrder ?? 9999;
      return left == right
          ? a.nameRu.compareTo(b.nameRu)
          : left.compareTo(right);
    });

    final menuProducts = readList(menu['products']);
    final productItems = readList(productsResponse);
    final posterProductItems = productItems.isNotEmpty
        ? productItems
        : allowNetworkProductFallback
            ? await _loadProductsByCategory(categoriesResponse)
            : const <dynamic>[];
    if (menuProducts.isEmpty && posterProductItems.isEmpty) {
      throw ApiException('Poster products unavailable');
    }
    // The direct Poster endpoint is the source of truth for live products.
    // /api/menu may contain a partial or cached product list used by the website.
    final posterProducts =
        posterProductItems.isNotEmpty ? posterProductItems : menuProducts;
    final products = posterProducts
        .map((item) {
          final json = readMap(item);
          final id = readString(json['product_id'] ?? json['id']);
          return ProductModel.fromJson(
            {
              ...json,
              'photo': _absoluteUrl(readString(json['photo'])),
              'photo_origin': _absoluteUrl(readString(json['photo_origin'])),
            },
            translation: readMap(productTranslations[id]),
            discount: discounts[id],
          );
        })
        .where((product) => product.id.isNotEmpty && product.price > 0)
        .toList();

    final banners = readList(bannersResponse)
        .map((item) {
          final json = readMap(item);
          return BannerModel.fromJson({
            ...json,
            'imageUrl':
                _absoluteUrl(readString(json['imageUrl'] ?? json['image'])),
          });
        })
        .where((banner) => _isUsableBannerImageUrl(banner.imageUrl))
        .toList();
    banners.sort((left, right) {
      final byOrder = left.sortOrder.compareTo(right.sortOrder);
      return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
    });

    final aboutLocations = readList(readMap(locationsResponse)['locations']);
    final spots = readList(spotsResponse);
    final branchSource = aboutLocations.isNotEmpty ? aboutLocations : spots;
    final branches = branchSource
        .map((item) => BranchModel.fromJson(readMap(item), locale))
        .where((branch) => branch.id.isNotEmpty || branch.spotId != null)
        .toList();

    return BootstrapData(
      settings: settings,
      categories: categories,
      products: products,
      popularProductIds: popularProductIds,
      checkoutPromotions: checkoutPromotions,
      // No active banner is a valid admin state. Never replace it with a demo.
      banners: banners,
      branches: branches.isEmpty ? _demoBranches(locale) : branches,
    );
  }

  Future<UserProfile?> loadMe() async {
    final data = readMap(await _client.getJson('/api/auth/client/me'));
    final client = data['client'];
    if (client == null) return null;
    return UserProfile.fromJson(readMap(client));
  }

  Future<String> sendRegisterCode({
    required String phone,
    required String locale,
  }) async {
    final data =
        readMap(await _client.postJson('/api/auth/client/register/send-code', {
      'phone': phone,
      'locale': locale,
    }));
    return readString(data['mode']).isEmpty
        ? 'register'
        : readString(data['mode']);
  }

  Future<UserProfile> register({
    required String name,
    required String phone,
    required String generatedPassword,
    required String smsCode,
    String birthday = '',
  }) async {
    final data = readMap(await _client.postJson('/api/auth/client/register', {
      'name': name,
      'phone': phone,
      'password': generatedPassword,
      'smsCode': smsCode,
      'birthday': birthday,
    }));
    return UserProfile.fromJson(readMap(data['client']));
  }

  Future<void> sendLoginCode({
    required String phone,
    required String locale,
  }) async {
    await _client.postJson('/api/auth/client/login/send-code', {
      'phone': phone,
      'locale': locale,
    });
  }

  Future<UserProfile> login({
    required String phone,
    required String smsCode,
  }) async {
    final data = readMap(await _client.postJson('/api/auth/client/login', {
      'phone': phone,
      'smsCode': smsCode,
    }));
    return UserProfile.fromJson(readMap(data['client']));
  }

  Future<List<GeocodeResult>> geocodeAddress(
      String query, String locale) async {
    final data = readMap(await _client.getJson('/api/geocode', query: {
      'q': query,
      'lang': locale == 'uz' ? 'uz_UZ' : 'ru_RU',
    }));
    return readList(data['results'])
        .map((item) => GeocodeResult.fromJson(readMap(item)))
        .where((item) => item.address.isNotEmpty)
        .toList();
  }

  Future<String?> reverseGeocode(
    double lat,
    double lng,
    String locale,
  ) async {
    final data = readMap(await _client.getJson('/api/geocode', query: {
      'lat': lat.toStringAsFixed(7),
      'lng': lng.toStringAsFixed(7),
      'lang': locale == 'uz' ? 'uz_UZ' : 'ru_RU',
    }));
    final address = readString(data['address']);
    return address.isEmpty ? null : address;
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
  }) async {
    final data = readMap(await _client.patchJson('/api/auth/client/profile', {
      'name': name,
      'phone': phone,
    }));
    return UserProfile.fromJson(readMap(data['client']));
  }

  Future<void> sendProfilePhoneChangeCode({
    required String phone,
    required String locale,
  }) async {
    await _client.postJson('/api/auth/client/profile/change-phone/send-code', {
      'phone': phone,
      'locale': locale,
    });
  }

  Future<UserProfile> verifyProfilePhoneChange({
    required String phone,
    required String code,
  }) async {
    final data = readMap(
        await _client.patchJson('/api/auth/client/profile/change-phone', {
      'phone': phone,
      'code': code,
    }));
    return UserProfile.fromJson(readMap(data['client']));
  }

  Future<void> logout() async {
    await _client.postJson('/api/auth/client/logout', const {});
    await _client.clearSession();
  }

  Future<List<AddressModel>> loadAddresses() async {
    final data = readMap(await _client.getJson('/api/auth/client/locations'));
    return readList(data['locations'])
        .map((item) => AddressModel.fromJson(readMap(item)))
        .where((address) => address.id.isNotEmpty && address.address.isNotEmpty)
        .toList();
  }

  Future<List<AddressModel>> saveAddresses(List<AddressModel> addresses) async {
    final data = readMap(await _client.postJson('/api/auth/client/locations', {
      'locations': addresses.map((address) => address.toJson()).toList(),
    }));
    return readList(data['locations'])
        .map((item) => AddressModel.fromJson(readMap(item)))
        .toList();
  }

  Future<int> validatePromoCode({
    required String code,
    required int subtotal,
  }) async {
    final data = readMap(await _client.postJson('/api/promo-codes/validate', {
      'code': code,
      'subtotal': subtotal,
    }));
    if (data['ok'] != true) return 0;
    return readInt(data['discount']);
  }

  Future<CheckoutResult> placeOrder(CheckoutRequest request) async {
    final data =
        readMap(await _client.postJson('/api/orders', request.toJson()));
    return CheckoutResult.fromJson(data);
  }

  Future<OrderModel> loadOrderStatus(int id) async {
    final data = readMap(await _client.getJson('/api/orders/$id'));
    return OrderModel.fromJson(data);
  }

  Future<String?> loadPaymentUrl(int id) async {
    final data = readMap(await _client.getJson(
      '/api/orders/$id/payment',
      query: const {'format': 'json'},
    ));
    final url = readString(data['paymentUrl']).trim();
    return url.isEmpty ? null : url;
  }

  Future<List<OrderModel>> loadOrders() async {
    final data = readMap(await _client.getJson('/api/account/orders'));
    return readList(data['orders'])
        .map((item) => OrderModel.fromJson(readMap(item)))
        .where((order) => order.id.isNotEmpty)
        .toList();
  }

  Future<void> cancelOrder(int id) async {
    await _client.postJson('/api/orders/$id/cancel', const {});
  }

  Future<List<MailingModel>> loadMailings() async {
    final data = await _safeGet('/api/account/mailings');
    final items = data is List ? data : readList(readMap(data)['mailings']);
    return items
        .map((item) {
          final json = readMap(item);
          return MailingModel.fromJson({
            ...json,
            'imageUrl':
                _absoluteUrl(readString(json['imageUrl'] ?? json['image_url'])),
          });
        })
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> registerPushToken({
    required String token,
    required String platform,
    required String installationId,
    required String locale,
  }) async {
    await _client.postJson('/api/push/device-token', {
      'token': token,
      'platform': platform,
      'installationId': installationId,
      'locale': locale,
      'language': locale,
    });
  }

  Future<dynamic> _safeGet(
    String path, {
    Map<String, String>? query,
    bool retry = true,
  }) async {
    try {
      return await _client.getJson(path, query: query);
    } catch (error, stackTrace) {
      debugPrint('safeGet failed path=$path error=$error');
      if (!retry) return null;
      // A transient Poster/network timeout should not leave the catalog empty.
      try {
        return await _client.getJson(path, query: query);
      } catch (retryError) {
        debugPrint('safeGet retry failed path=$path error=$retryError');
        debugPrintStack(stackTrace: stackTrace);
        return null;
      }
    }
  }

  Future<List<dynamic>> _loadProductsByCategory(
      dynamic categoriesResponse) async {
    // Poster returns the complete live catalog without a category filter.
    // Loading one response avoids dropping products when many category
    // requests run concurrently and one of them times out.
    final allProducts = await _safeGet(
      '/api/poster/products',
      query: const {'compact': '1'},
    );
    final completeProducts = readList(allProducts);
    if (completeProducts.isNotEmpty) return completeProducts;

    final categoryIds = readList(categoriesResponse)
        .map((item) {
          final json = readMap(item);
          return readString(json['category_id'] ?? json['id']);
        })
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (categoryIds.isEmpty) return const [];
    final responses = await Future.wait(
      categoryIds.map(
        (id) => _safeGet(
          '/api/poster/products',
          query: {'category_id': id, 'compact': '1'},
        ),
      ),
    );
    return responses.expand((response) => readList(response)).toList();
  }

  String _absoluteUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:') ||
        trimmed.startsWith('blob:')) {
      return trimmed;
    }
    final origin = Uri.tryParse(_baseUrl)?.origin ?? _baseUrl;
    if (trimmed.startsWith('/')) return '$origin$trimmed';
    return '$origin/$trimmed';
  }

  bool _isUsableBannerImageUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  List<BranchModel> _demoBranches(String locale) {
    return [
      BranchModel(
        id: 'demo-branch',
        spotId: '1',
        name: 'Wasabi Sushi',
        address: locale == 'uz'
            ? 'Toshkent, Amir Temur kochasi, 14'
            : 'Ташкент, ул. Амира Темура, 14',
        lat: 41.311081,
        lng: 69.240562,
        phone: AppConfig.defaultPhone,
        workTime: '10:00 - 23:00',
      ),
    ];
  }
}

Map<String, dynamic> _normalizeLookupMap(Object? value) {
  final raw = readMap(value);
  if (raw.isEmpty) return const {};
  return {
    for (final entry in raw.entries) readString(entry.key): entry.value,
  };
}
