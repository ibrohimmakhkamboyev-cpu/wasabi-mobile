import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/native_bridge.dart';
import '../services/push_notifications.dart';
import '../services/wasabi_api.dart';
import '../config/app_config.dart';
import '../utils/ordering_hours.dart';

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9а-яё]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _isLegacyPaymentTestItem(CartItem item) =>
    item.productId == 'payment_test_1000' ||
    item.productId == 'payment-test-1000' ||
    item.categoryId == 'payment_test';

List<String> _searchTextVariants(String value) {
  final lower = _normalizeSearchText(value);
  if (lower.isEmpty) return const [];
  final transliterated = transliterateRuToUz(lower).toLowerCase();
  return {
    lower,
    _normalizeSearchText(transliterated),
  }.where((variant) => variant.isNotEmpty).toList(growable: false);
}

class _ProductSearchEntry {
  const _ProductSearchEntry(this.product, this.haystack);

  final ProductModel product;
  final String haystack;
}

class AppState extends ChangeNotifier {
  AppState({WasabiApi? api, PushNotifications? pushNotifications})
      : _api = api ?? WasabiApi(),
        _pushNotifications = pushNotifications ?? PushNotifications();

  static const _cartKey = 'wasabi_mobile_cart_v1';
  static const _localeKey = 'wasabi_mobile_locale_v1';
  static const _themeModeKey = 'wasabi_mobile_theme_mode_v1';
  static const _onboardingKey = 'wasabi_mobile_onboarding_v1';
  static const _entranceSeenKey = 'wasabi_mobile_entrance_seen_v1';
  static const _addressesKey = 'wasabi_mobile_addresses_v1';
  static const _readMailingsKey = 'wasabi_mobile_read_mailings_v1';
  static const _savedProductsKey = 'wasabi_mobile_saved_products_v1';
  static const _profileKey = 'wasabi_mobile_profile_v1';
  static const _paymentUrlAttempts = 3;
  static const _paymentUrlRetryDelay = Duration(milliseconds: 350);

  final WasabiApi _api;
  final PushNotifications _pushNotifications;

  bool initialized = false;
  bool busy = false;
  bool _submittingOrder = false;
  bool catalogLoading = false;
  bool offlineCatalog = false;
  bool onboardingDone = false;
  bool entranceSeen = true;
  String locale = 'uz';
  ThemeMode themeMode = ThemeMode.light;
  String? error;
  int? lastOrderId;

  AppSettings settings = const AppSettings();
  List<CategoryModel> categories = [];
  List<ProductModel> products = [];
  List<String> popularProductIds = [];
  List<DiscountModel> checkoutPromotions = [];
  List<BannerModel> banners = [];
  List<BranchModel> branches = [];
  List<AddressModel> addresses = [];
  List<CartItem> cart = [];
  List<OrderModel> orders = [];
  List<MailingModel> mailings = [];
  UserProfile? user;
  Set<String> _readMailingIds = {};
  Set<String> _savedProductIds = {};
  List<_ProductSearchEntry>? _productSearchIndex;
  Future<void>? _mailingsRequest;
  final Map<String, Future<void>> _catalogRequests = {};

  String selectedCategoryId = '';
  bool showPopularCatalog = false;
  int? selectedPromotionId;
  bool _promotionAutoSelected = false;
  bool _promoCodeSelected = false;
  String promoCode = '';
  int _promoDiscount = 0;
  int _promoRefreshToken = 0;

  bool get isAuthenticated => user != null;
  OrderingHours get orderingHours => OrderingHours.fromSettings(
        workStart: settings.workStart,
        workEnd: settings.workEnd,
      );
  bool get isOrderingOpen => orderingHours.isOpenAt(DateTime.now());
  bool get isUzEnabled => settings.langUzEnabled;
  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => cart.fold(0, (sum, item) => sum + item.total);
  bool get hasMailings => mailings.isNotEmpty;
  bool get hasUnreadMailings =>
      mailings.any((item) => !_readMailingIds.contains(item.id));
  int get savedCount => _savedProductIds.length;
  List<ProductModel> get savedProducts => products
      .where((product) => _savedProductIds.contains(product.id))
      .toList(growable: false);

  bool get hasPromoCodeOption =>
      promoCode.trim().isNotEmpty && _promoDiscount > 0;

  bool get isPromoCodeSelected => _promoCodeSelected && hasPromoCodeOption;

  int get checkoutDiscountOptionCount =>
      checkoutPromotionIds.length + (hasPromoCodeOption ? 1 : 0);

  bool get requiresCheckoutDiscountChoice =>
      checkoutDiscountOptionCount > 1 &&
      selectedPromotionId == null &&
      !isPromoCodeSelected;

  bool get hasSelectedCheckoutDiscount =>
      selectedPromotionId != null || isPromoCodeSelected;

  int get promoDiscount => isPromoCodeSelected
      ? _promoDiscount.clamp(0, fullPriceSubtotal).toInt()
      : 0;

  /// The undiscounted price of the current cart. Order-wide promotions are
  /// deliberately shown once in the checkout bill rather than on every card.
  int get fullPriceSubtotal => cart.fold(0, (sum, item) {
        final product = products
            .where((candidate) => candidate.id == item.productId)
            .firstOrNull;
        return sum + (product?.price ?? item.price) * item.quantity;
      });

  int get checkoutPromotionDiscount {
    final promotionId = selectedPromotionId;
    if (promotionId == null) return 0;
    final discount = _discountForPromotion(promotionId);
    if (discount == null) return 0;
    return (fullPriceSubtotal - discount.apply(fullPriceSubtotal))
        .clamp(0, fullPriceSubtotal)
        .toInt();
  }

  int get checkoutDiscount => (checkoutPromotionDiscount + promoDiscount)
      .clamp(0, fullPriceSubtotal)
      .toInt();

  /// Product-specific offers already reflected in [subtotal]. Showing this
  /// separately makes the checkout bill reconcile with its final total.
  int get productDiscount =>
      (fullPriceSubtotal - subtotal).clamp(0, fullPriceSubtotal).toInt();

  int totalFor(DeliveryType type) {
    final delivery = type == DeliveryType.delivery ? settings.deliveryFee : 0;
    return (subtotal - checkoutDiscount + delivery).clamp(0, 1 << 31).toInt();
  }

  AddressModel? get primaryAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (address) => address.isPrimary,
      orElse: () => addresses.first,
    );
  }

  List<ProductModel> get discountedProducts => products
      .where((product) =>
          product.hasDiscount &&
          _isDiscountAvailableForUser(product.discount!) &&
          !_isOrderWideDiscount(product.discount!))
      .toList(growable: false);

  bool showsCatalogDiscount(ProductModel product) {
    final discount = product.discount;
    return discount != null &&
        product.hasDiscount &&
        _isDiscountAvailableForUser(discount) &&
        !_isOrderWideDiscount(discount);
  }

  int catalogPriceFor(ProductModel product) =>
      showsCatalogDiscount(product) ? product.effectivePrice : product.price;

  List<int> get checkoutPromotionIds {
    return checkoutPromotions
        .where(_isDiscountAvailableForUser)
        .map((discount) => discount.promotionId!)
        .toSet()
        .toList(growable: false);
  }

  DiscountModel? _discountForPromotion(int promotionId) {
    return checkoutPromotions
        .where(
          (discount) =>
              discount.promotionId == promotionId &&
              _isDiscountAvailableForUser(discount),
        )
        .firstOrNull;
  }

  String promotionLabel(int id, String locale) {
    const namesRu = {
      138: 'Счастливые часы',
      155: 'День рождения',
      157: 'Первый заказ',
      232: 'Сэндвич с курицей',
      233: 'Сэндвич с курицей и сыром',
    };
    const namesUz = {
      138: 'Baxtli soatlar',
      155: 'Tug‘ilgan kun',
      157: 'Birinchi buyurtma',
      232: 'Tovuqli sendvich',
      233: 'Tovuqli va pishloqli sendvich',
    };
    return (locale == 'uz' ? namesUz[id] : namesRu[id]) ??
        (locale == 'uz' ? 'Aksiya #$id' : 'Акция #$id');
  }

  bool get birthdayDiscountAvailable {
    final value = user?.birthday;
    if (value == null) return false;
    final parsed = DateTime.tryParse(value);
    final now = DateTime.now();
    return parsed != null && parsed.month == now.month && parsed.day == now.day;
  }

  bool _isDiscountAvailableForUser(DiscountModel discount) {
    return !discount.isBirthday || birthdayDiscountAvailable;
  }

  bool _isOrderWideDiscount(DiscountModel discount) {
    // The API is the source of truth for promotions enabled by the admin.
    // Do not hard-code Poster IDs here: a newly enabled checkout promotion
    // must immediately behave as an order-wide promotion in the app.
    return discount.isBirthday ||
        checkoutPromotions.any(
          (promotion) => promotion.promotionId == discount.promotionId,
        );
  }

  void selectPromotion(int? promotionId) {
    selectedPromotionId = promotionId;
    _promoCodeSelected = false;
    _promotionAutoSelected = false;
    _syncCartPrices();
    _persistCart();
    notifyListeners();
  }

  void _reconcilePromotionSelection() {
    final ids = checkoutPromotionIds;
    final hasPromoCode = hasPromoCodeOption;
    final optionCount = ids.length + (hasPromoCode ? 1 : 0);
    if (optionCount == 1) {
      selectedPromotionId = ids.isEmpty ? null : ids.single;
      _promoCodeSelected = hasPromoCode;
      _promotionAutoSelected = true;
    } else if (optionCount == 0 ||
        _promotionAutoSelected ||
        (!ids.contains(selectedPromotionId) && !isPromoCodeSelected)) {
      // Auto-selection is only correct while there is exactly one eligible
      // checkout promotion. When another option appears, clear that automatic
      // choice; an explicit customer selection is retained while valid.
      selectedPromotionId = null;
      _promoCodeSelected = false;
      _promotionAutoSelected = false;
    } else {
      _promotionAutoSelected = false;
    }
  }

  void _syncCartPrices() {
    for (var index = 0; index < cart.length; index++) {
      final item = cart[index];
      final product = products
          .where((candidate) => candidate.id == item.productId)
          .firstOrNull;
      if (product == null) continue;
      cart[index] = CartItem(
        productId: item.productId,
        name: item.name,
        price: _cartPriceFor(product),
        quantity: item.quantity,
        imageUrl: item.imageUrl,
        categoryId: item.categoryId,
      );
    }
  }

  int _cartPriceFor(ProductModel product) {
    final discount = product.discount;
    if (discount == null || !_isDiscountAvailableForUser(discount)) {
      return product.price;
    }
    // A selected checkout discount is calculated once from the full normal
    // cart total. Product offers remain in the cart but do not stack.
    if (hasSelectedCheckoutDiscount) return product.price;
    if (!_isOrderWideDiscount(discount)) return product.effectivePrice;
    return product.price;
  }

  List<ProductModel> get popularProducts {
    final byId = {for (final product in products) product.id: product};
    final ordered = popularProductIds
        .map((id) => byId[id])
        .whereType<ProductModel>()
        .take(10)
        .toList(growable: false);
    // A new installation has no completed orders to rank yet.
    return ordered.isEmpty
        ? products.take(10).toList(growable: false)
        : ordered;
  }

  /// Produces a varied, relevant product list for a product detail sheet.
  /// The catalog API has no recommendation endpoint, so this is deliberately
  /// based on real local signals instead of the raw catalog order.
  List<ProductModel> recommendationsFor(ProductModel product, {int limit = 6}) {
    if (limit <= 0) return const [];

    final cartProductIds = cart.map((item) => item.productId).toSet();
    final productById = {for (final item in products) item.id: item};
    final cartCategoryWeights = <String, int>{};
    for (final item in cart) {
      final categoryId = item.categoryId;
      if (categoryId == null || categoryId.isEmpty) continue;
      cartCategoryWeights.update(categoryId, (count) => count + 1,
          ifAbsent: () => 1);
    }

    final historyCategoryWeights = <String, int>{};
    for (final item in orders.expand((order) => order.items)) {
      final productId = item.productId;
      final categoryId =
          productId == null ? null : productById[productId]?.categoryId;
      if (categoryId == null || categoryId.isEmpty) continue;
      historyCategoryWeights.update(categoryId, (count) => count + 1,
          ifAbsent: () => 1);
    }

    final ranked = <(ProductModel product, int score, int order)>[];
    for (var index = 0; index < products.length; index++) {
      final candidate = products[index];
      if (candidate.id == product.id || cartProductIds.contains(candidate.id)) {
        continue;
      }
      final categoryId = candidate.categoryId;
      var score = candidate.hasDiscount ? 20 : 0;
      if (categoryId != null && categoryId.isNotEmpty) {
        if (categoryId == product.categoryId) score += 1000;
        score += (cartCategoryWeights[categoryId] ?? 0) * 240;
        score += (historyCategoryWeights[categoryId] ?? 0) * 180;
      }
      ranked.add((candidate, score, index));
    }
    ranked.sort((a, b) {
      final score = b.$2.compareTo(a.$2);
      return score != 0 ? score : a.$3.compareTo(b.$3);
    });

    final recommendations = <ProductModel>[];
    var sameCategoryCount = 0;
    for (final candidate in ranked) {
      final isSameCategory = candidate.$1.categoryId == product.categoryId &&
          product.categoryId != null &&
          product.categoryId!.isNotEmpty;
      // Two closely related options are useful; showing only one category is
      // not. Fill the rest from cart/history signals and other categories.
      if (isSameCategory && sameCategoryCount >= 2) continue;
      recommendations.add(candidate.$1);
      if (isSameCategory) sameCategoryCount++;
      if (recommendations.length == limit) break;
    }
    return recommendations;
  }

  List<ProductModel> get newProducts {
    if (products.length <= 10) return products.reversed.take(6).toList();
    return products.reversed.take(10).toList();
  }

  List<ProductModel> productsForCategory(String categoryId) {
    if (categoryId.isEmpty) return products;
    final category =
        categories.where((item) => item.id == categoryId).firstOrNull;
    if (category != null && _isPromoCategory(category)) {
      return discountedProducts;
    }
    return products
        .where((product) => product.categoryId == categoryId)
        .toList(growable: false);
  }

  List<ProductModel> searchProducts(String query, String categoryId) {
    final queryVariants = _searchTextVariants(query);
    final index = _searchIndex;
    return index
        .where((entry) {
          if (categoryId.isNotEmpty && entry.product.categoryId != categoryId) {
            return false;
          }
          if (queryVariants.isEmpty) return true;
          return queryVariants.any(entry.haystack.contains);
        })
        .map((entry) => entry.product)
        .toList(growable: false);
  }

  List<_ProductSearchEntry> get _searchIndex {
    return _productSearchIndex ??= products
        .map(
          (product) => _ProductSearchEntry(
            product,
            _searchTextVariants([
              product.nameRu,
              product.nameUz,
              product.descriptionRu,
              product.descriptionUz,
              product.categoryName,
            ].whereType<String>().join(' '))
                .join(' '),
          ),
        )
        .toList(growable: false);
  }

  int quantityFor(String productId) {
    for (final item in cart) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  bool isSaved(String productId) => _savedProductIds.contains(productId);

  Future<void> init() async {
    busy = true;
    notifyListeners();
    try {
      final localValues = await Future.wait<String?>([
        NativeBridge.getString(_localeKey),
        NativeBridge.getString(_themeModeKey),
        NativeBridge.getString(_onboardingKey),
        NativeBridge.getString(_entranceSeenKey),
        NativeBridge.getString(_cartKey),
        NativeBridge.getString(_addressesKey),
        NativeBridge.getString(_readMailingsKey),
        NativeBridge.getString(_savedProductsKey),
        NativeBridge.getString(_profileKey),
      ]);

      locale = localValues[0] ?? 'uz';
      themeMode = _decodeThemeMode(localValues[1]);
      onboardingDone = localValues[2] != '0';
      entranceSeen = localValues[3] == '1';
      cart = decodeCart(localValues[4] ?? '[]');
      final cartWithoutTestItems =
          cart.where((item) => !_isLegacyPaymentTestItem(item)).toList();
      if (cartWithoutTestItems.length != cart.length) {
        cart = cartWithoutTestItems;
        unawaited(_persistCart());
      }
      addresses = decodeAddresses(localValues[5] ?? '[]');
      _readMailingIds = _decodeReadMailings(
        localValues[6] ?? '[]',
      );
      _savedProductIds = _decodeStringSet(
        localValues[7] ?? '[]',
      );
      user = _decodeUserProfile(localValues[8]);

      await _api.init();
      final cachedCatalog = await _api.loadCachedBootstrap(locale);
      if (cachedCatalog != null) {
        _applyBootstrap(cachedCatalog);
      }
    } catch (exception) {
      offlineCatalog = true;
      error = exception.toString();
    } finally {
      initialized = true;
      busy = false;
      notifyListeners();
    }
    unawaited(_loadInitialRemoteData());
  }

  Future<void> _loadInitialRemoteData() async {
    // Show products as soon as the essential catalog arrives. The slower
    // marketing and delivery endpoints then update without blocking home.
    await _refreshCatalogFast();
    unawaited(refreshCatalog());
    unawaited(refreshSession());
    unawaited(refreshMailings());
    unawaited(_syncPushNotifications());
  }

  Future<void> refreshCatalog() {
    final requestedLocale = locale;
    return _catalogRequests[requestedLocale] ??=
        _refreshCatalog(requestedLocale).whenComplete(() {
      _catalogRequests.remove(requestedLocale);
    });
  }

  Future<void> _refreshCatalog(String requestedLocale) async {
    catalogLoading = true;
    notifyListeners();
    try {
      BootstrapData? data;
      Object? lastError;
      // Poster can briefly reject a cold connection. Keep the existing catalog
      // (or the loading state on first launch) and retry once before showing a
      // customer-facing failure.
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          data = await _api.loadBootstrap(requestedLocale);
          break;
        } catch (error) {
          lastError = error;
          if (attempt == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 700));
          }
        }
      }
      if (data == null) throw lastError ?? Exception('Catalog unavailable');
      if (locale != requestedLocale) return;
      _applyBootstrap(data);
      if (!settings.langUzEnabled && locale == 'uz') {
        await setLocale('ru');
      }
      error = null;
    } catch (exception) {
      if (locale != requestedLocale) return;
      offlineCatalog = true;
      error = exception.toString();
    } finally {
      if (locale == requestedLocale) {
        catalogLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _refreshCatalogFast() async {
    final requestedLocale = locale;
    catalogLoading = true;
    notifyListeners();
    try {
      final data = await _api.loadCatalogBootstrap(requestedLocale);
      if (locale != requestedLocale) return;
      _applyBootstrap(data);
      error = null;
    } catch (_) {
      // Keep cache/fallback visible. The full background request retains the
      // existing retry and error handling if the essential catalog is down.
    } finally {
      if (locale == requestedLocale) {
        catalogLoading = false;
        notifyListeners();
      }
    }
  }

  void _applyBootstrap(BootstrapData data) {
    settings = data.settings;
    categories = _orderCategories([
      ...data.categories,
    ]);
    products = _filterBirthdayDiscounts([
      ...data.products,
    ]);
    popularProductIds = data.popularProductIds;
    checkoutPromotions = data.checkoutPromotions;
    _reconcilePromotionSelection();
    _syncCartPrices();
    _productSearchIndex = null;
    banners = data.banners;
    branches = data.branches;
    offlineCatalog = false;
  }

  List<CategoryModel> _orderCategories(List<CategoryModel> source) {
    final categories = source.indexed.toList();
    categories.sort((a, b) {
      final promoCompare = (_isPromoCategory(b.$2) ? 1 : 0)
          .compareTo(_isPromoCategory(a.$2) ? 1 : 0);
      if (promoCompare != 0) return promoCompare;
      final sortA = a.$2.sortOrder ?? 1 << 20;
      final sortB = b.$2.sortOrder ?? 1 << 20;
      final sortCompare = sortA.compareTo(sortB);
      if (sortCompare != 0) return sortCompare;
      return a.$1.compareTo(b.$1);
    });
    return categories.map((entry) => entry.$2).toList(growable: false);
  }

  List<ProductModel> _filterBirthdayDiscounts(List<ProductModel> source) {
    return source
        .map(
          (product) =>
              product.discount?.isBirthday == true && !birthdayDiscountAvailable
                  ? product.withoutDiscount()
                  : product,
        )
        .toList(growable: false);
  }

  bool _isPromoCategory(CategoryModel category) {
    final title = '${category.nameRu} ${category.nameUz ?? ''}'.toLowerCase();
    return title.contains('акци') ||
        title.contains('aksi') ||
        title.contains('promo') ||
        title.contains('скид') ||
        title.contains('chegir');
  }

  Future<void> refreshSession() async {
    final hadBirthdayDiscount = birthdayDiscountAvailable;
    try {
      final remote = await _api.loadMe();
      final previous = user;
      // Poster can return an automatically generated client label. The name
      // entered and saved by this user must remain their profile name.
      user = remote != null &&
              previous != null &&
              previous.id == remote.id &&
              previous.name.trim().isNotEmpty
          ? remote.copyWith(name: previous.name)
          : remote;
      if (user != null) {
        await _persistProfile();
        try {
          addresses = await _api.loadAddresses();
          await _refreshAddressLocale(persist: false);
          await _persistAddresses();
        } catch (_) {
          // Keep the signed-in profile even when saved addresses fail to load.
        }
      }
    } on ApiException catch (exception) {
      if (exception.statusCode == 401 || exception.statusCode == 403) {
        user = null;
        await _persistProfile();
      }
    } catch (_) {
      // Retain the saved account during a timeout or temporary server outage.
    } finally {
      if (hadBirthdayDiscount != birthdayDiscountAvailable) {
        await refreshCatalog();
      }
      unawaited(_syncPushNotifications());
      notifyListeners();
    }
  }

  Future<void> refreshMailings() {
    // Inbox refreshes are triggered by startup, push notifications, the shell
    // timer, and the mailbox screen. Share one request instead of stacking
    // identical HTTP calls when those events arrive together.
    return _mailingsRequest ??= _refreshMailings().whenComplete(() {
      _mailingsRequest = null;
    });
  }

  Future<void> _refreshMailings() async {
    try {
      final latest = await _api.loadMailings();
      if (_sameMailings(mailings, latest)) return;
      mailings = latest;
    } catch (_) {
      // Do not erase an already visible inbox when the connection is briefly
      // unavailable. The next successful refresh will reconcile it.
      return;
    }
    notifyListeners();
  }

  bool _sameMailings(List<MailingModel> left, List<MailingModel> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      final a = left[index];
      final b = right[index];
      if (a.id != b.id ||
          a.titleRu != b.titleRu ||
          a.titleUz != b.titleUz ||
          a.textRu != b.textRu ||
          a.textUz != b.textUz ||
          a.imageUrl != b.imageUrl ||
          a.createdAt != b.createdAt) {
        return false;
      }
    }
    return true;
  }

  Future<void> markMailingsRead() async {
    if (mailings.isEmpty) return;
    _readMailingIds = {
      ..._readMailingIds,
      ...mailings.map((item) => item.id),
    };
    await NativeBridge.setString(
      _readMailingsKey,
      jsonEncode(_readMailingIds.toList()),
    );
    notifyListeners();
  }

  Future<void> setLocale(String value) async {
    if (value == 'uz' && !settings.langUzEnabled) return;
    final nextLocale = value == 'uz' ? 'uz' : 'ru';
    if (locale == nextLocale) return;
    locale = nextLocale;
    notifyListeners();
    // Redraw immediately; persistence and locale-dependent remote data may be slow.
    return _persistAndRefreshLocale(nextLocale);
  }

  Future<void> _persistAndRefreshLocale(String nextLocale) async {
    await NativeBridge.setString(_localeKey, nextLocale);
    try {
      await refreshCatalog();
      await _refreshAddressLocale();
    } catch (_) {
      // The already-selected local language must remain usable offline.
    }
    unawaited(_syncPushNotifications());
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (themeMode == value) return;
    themeMode = value;
    await NativeBridge.setString(_themeModeKey, _encodeThemeMode(themeMode));
    notifyListeners();
  }

  Future<void> toggleThemeMode() {
    return setThemeMode(
      themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> finishOnboarding() async {
    onboardingDone = true;
    await NativeBridge.setString(_onboardingKey, '1');
    notifyListeners();
  }

  Future<void> markEntranceSeen() async {
    entranceSeen = true;
    await NativeBridge.setString(_entranceSeenKey, '1');
  }

  void selectCategory(String id) {
    selectedCategoryId = id;
    showPopularCatalog = false;
    notifyListeners();
  }

  void selectPopularCatalog() {
    selectedCategoryId = '';
    showPopularCatalog = false;
    notifyListeners();
  }

  Future<String> sendRegisterCode(String phone) {
    return _api.sendRegisterCode(phone: phone, locale: locale);
  }

  Future<void> sendLoginCode(String phone) {
    return _api.sendLoginCode(phone: phone, locale: locale);
  }

  Future<void> register({
    required String name,
    required String phone,
    required String smsCode,
    String birthday = '',
  }) async {
    user = await _api.register(
      name: name,
      phone: phone,
      generatedPassword: _generatedPassword(phone),
      smsCode: smsCode,
      birthday: birthday,
    );
    await _persistProfile();
    // Saved-address refresh can include reverse geocoding. It must not delay
    // entering the app after the SMS code has already been confirmed.
    unawaited(_loadRemoteAddresses().whenComplete(notifyListeners));
    unawaited(_syncPushNotifications());
    notifyListeners();
  }

  Future<void> login({
    required String phone,
    required String smsCode,
  }) async {
    final remote = await _api.login(
      phone: phone,
      smsCode: smsCode,
    );
    user = remote;
    await _persistProfile();
    unawaited(_loadRemoteAddresses().whenComplete(notifyListeners));
    unawaited(_syncPushNotifications());
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final current = user;
    if (current == null) return;
    UserProfile updated;
    try {
      updated = await _api.updateProfile(name: name, phone: phone);
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      updated = current.copyWith(name: name.trim(), phone: phone);
    }
    user = updated.copyWith(
      name: name.trim().isEmpty ? updated.name : name.trim(),
      phone: phone,
    );
    await _persistProfile();
    unawaited(_syncPushNotifications());
    notifyListeners();
  }

  Future<void> sendProfilePhoneChangeCode(String phone) {
    return _api.sendProfilePhoneChangeCode(phone: phone, locale: locale);
  }

  Future<void> sendProfileCurrentPhoneCode(String phone) {
    return _api.sendLoginCode(phone: phone, locale: locale);
  }

  Future<void> verifyProfileCurrentPhone({
    required String phone,
    required String code,
  }) async {
    final current = user;
    await _api.login(phone: phone, smsCode: code);
    user = current;
    notifyListeners();
  }

  Future<void> verifyProfilePhoneChange({
    required String phone,
    required String code,
  }) async {
    final current = user;
    final updated =
        await _api.verifyProfilePhoneChange(phone: phone, code: code);
    user = updated.copyWith(
      name: current?.name.trim().isNotEmpty == true
          ? current!.name
          : updated.name,
      phone: phone,
    );
    await _persistProfile();
    unawaited(_syncPushNotifications());
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    user = null;
    orders = [];
    entranceSeen = false;
    await NativeBridge.remove(_entranceSeenKey);
    await NativeBridge.remove(_profileKey);
    unawaited(_syncPushNotifications());
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    final index = cart.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      cart[index] = cart[index].copyWith(
        quantity: cart[index].quantity + quantity,
      );
    } else {
      cart.add(CartItem.fromProduct(product, quantity: quantity));
    }
    _reconcilePromotionSelection();
    _syncCartPrices();
    _persistCart();
    _refreshPromoIfNeeded();
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      cart.removeWhere((item) => item.productId == productId);
    } else {
      final index = cart.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        cart[index] = cart[index].copyWith(quantity: quantity);
      }
    }
    _reconcilePromotionSelection();
    _syncCartPrices();
    _persistCart();
    _refreshPromoIfNeeded();
    notifyListeners();
  }

  Future<void> toggleSaved(String productId) async {
    if (_savedProductIds.contains(productId)) {
      _savedProductIds.remove(productId);
    } else {
      _savedProductIds.add(productId);
    }
    await NativeBridge.setString(
      _savedProductsKey,
      jsonEncode(_savedProductIds.toList()),
    );
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((item) => item.productId == productId);
    _reconcilePromotionSelection();
    _syncCartPrices();
    _persistCart();
    _refreshPromoIfNeeded();
    notifyListeners();
  }

  void clearCart() {
    cart = [];
    _clearPromo(notify: false);
    _persistCart();
    notifyListeners();
  }

  Future<void> applyPromo(String value) async {
    final code = value.trim().toUpperCase();
    if (code.isEmpty) {
      clearPromo();
      return;
    }
    final discount = await _api.validatePromoCode(
      code: code,
      subtotal: fullPriceSubtotal,
    );
    if (discount <= 0) {
      _clearPromo(notify: true);
      throw Exception('Промокод недействителен');
    }
    promoCode = code;
    _promoDiscount = discount;
    _reconcilePromotionSelection();
    _syncCartPrices();
    notifyListeners();
  }

  void selectPromoCode() {
    if (!hasPromoCodeOption) return;
    selectedPromotionId = null;
    _promoCodeSelected = true;
    _promotionAutoSelected = false;
    _syncCartPrices();
    _persistCart();
    notifyListeners();
  }

  void clearPromo() {
    _clearPromo(notify: true);
  }

  void _clearPromo({required bool notify}) {
    promoCode = '';
    _promoDiscount = 0;
    _promoCodeSelected = false;
    _promoRefreshToken += 1;
    _reconcilePromotionSelection();
    _syncCartPrices();
    if (notify) notifyListeners();
  }

  Future<void> _refreshPromoNow() async {
    final code = promoCode.trim();
    if (code.isEmpty) return;
    final discount = await _api.validatePromoCode(
      code: code,
      subtotal: fullPriceSubtotal,
    );
    if (discount <= 0) {
      _clearPromo(notify: true);
      throw Exception('Промокод недействителен');
    }
    promoCode = code.toUpperCase();
    _promoDiscount = discount;
    _reconcilePromotionSelection();
    _syncCartPrices();
    notifyListeners();
  }

  void _refreshPromoIfNeeded() {
    if (promoCode.trim().isEmpty) return;
    final token = ++_promoRefreshToken;
    unawaited(_api
        .validatePromoCode(code: promoCode, subtotal: fullPriceSubtotal)
        .then((discount) {
      if (token != _promoRefreshToken) return;
      if (discount <= 0) {
        _clearPromo(notify: true);
        return;
      }
      _promoDiscount = discount;
      _reconcilePromotionSelection();
      _syncCartPrices();
      notifyListeners();
    }).catchError((_) {
      if (token != _promoRefreshToken) return;
      _clearPromo(notify: true);
    }));
  }

  Future<void> upsertAddress(AddressModel address) async {
    final next = address.isPrimary
        ? addresses.map((item) => item.copyWith(isPrimary: false)).toList()
        : List<AddressModel>.from(addresses);
    final index = next.indexWhere((item) => item.id == address.id);
    if (index >= 0) {
      next[index] = address;
    } else {
      next.add(address);
    }
    addresses = _primaryFirst(_ensurePrimary(next));
    await _saveAddresses();
    notifyListeners();
  }

  Future<void> deleteAddress(String id) async {
    addresses = _primaryFirst(_ensurePrimary(
      addresses.where((address) => address.id != id).toList(),
    ));
    await _saveAddresses();
    notifyListeners();
  }

  Future<void> setPrimaryAddress(String id) async {
    addresses = addresses
        .map((address) => address.copyWith(isPrimary: address.id == id))
        .toList();
    addresses = _primaryFirst(addresses);
    await _saveAddresses();
    notifyListeners();
  }

  Future<int> submitOrder({
    required DeliveryType deliveryType,
    required PaymentMethod paymentMethod,
    AddressModel? address,
    BranchModel? branch,
    String comment = '',
    String deliveryTimeMode = 'today',
    String? deliveryDate,
    String? deliveryClock,
    int persons = 1,
    int bonusAmount = 0,
  }) async {
    if (_submittingOrder) {
      throw Exception(locale == 'uz'
          ? 'Buyurtma yuborilmoqda'
          : 'Заказ уже отправляется');
    }
    _submittingOrder = true;
    try {
      return await _submitOrder(
        deliveryType: deliveryType,
        paymentMethod: paymentMethod,
        address: address,
        branch: branch,
        comment: comment,
        deliveryTimeMode: deliveryTimeMode,
        deliveryDate: deliveryDate,
        deliveryClock: deliveryClock,
        persons: persons,
        bonusAmount: bonusAmount,
      );
    } finally {
      _submittingOrder = false;
    }
  }

  Future<int> _submitOrder({
    required DeliveryType deliveryType,
    required PaymentMethod paymentMethod,
    AddressModel? address,
    BranchModel? branch,
    String comment = '',
    String deliveryTimeMode = 'today',
    String? deliveryDate,
    String? deliveryClock,
    int persons = 1,
    int bonusAmount = 0,
  }) async {
    if (!settings.siteEnabled) {
      throw Exception(locale == 'uz' ? 'Texnik tanaffus' : 'Технический перерыв');
    }
    if (!isOrderingOpen) {
      final hours = orderingHours;
      throw Exception(locale == 'uz'
          ? 'Buyurtmalar ${hours.startLabel} dan ${hours.endLabel} gacha qabul qilinadi'
          : 'Заказы принимаются с ${hours.startLabel} до ${hours.endLabel}');
    }
    if (cart.isEmpty) throw Exception('Корзина пустая');
    if (user == null) throw Exception('Нужно войти в аккаунт');
    if (!paymentMethod.isCheckoutSupported) {
      throw Exception('Этот способ оплаты временно недоступен');
    }
    if (requiresCheckoutDiscountChoice) {
      throw Exception('Chegirmani tanlang');
    }
    if (isPromoCodeSelected) await _refreshPromoNow();
    final sourceBranch =
        deliveryType == DeliveryType.delivery && address != null
            ? nearestBranchFor(address)
            : branch;
    final request = CheckoutRequest(
      deliveryType: deliveryType,
      paymentMethod: paymentMethod,
      items: cart,
      customerPhone: user?.phone,
      customerName: user?.name,
      address: deliveryType == DeliveryType.delivery ? address?.address : null,
      lat: deliveryType == DeliveryType.delivery ? address?.lat : null,
      lng: deliveryType == DeliveryType.delivery ? address?.lng : null,
      spotId: sourceBranch?.spotId ?? sourceBranch?.id,
      persons: persons,
      promoCode: isPromoCodeSelected ? promoCode : null,
      checkoutPromotionId: selectedPromotionId,
      comment: comment.trim().isEmpty ? null : comment.trim(),
      deliveryTimeMode: deliveryTimeMode,
      deliveryDate: deliveryDate,
      deliveryClock: deliveryClock,
      bonusAmount: bonusAmount,
    );
    final result = await _api.placeOrder(request);
    final paymentUrl = result.paymentUrl?.trim().isNotEmpty == true
        ? result.paymentUrl
        : paymentMethod.requiresOnlinePayment
            ? await _loadPaymentUrlWithRetry(result.orderId)
            : null;
    final paymentOpened = await _openOnlinePaymentIfNeeded(
      paymentMethod: paymentMethod,
      orderId: result.orderId,
      amount: totalFor(deliveryType) - bonusAmount,
      paymentUrl: paymentUrl,
    );
    if (paymentMethod.requiresOnlinePayment && !paymentOpened) {
      throw Exception('Оплата временно недоступна. Попробуйте другой способ.');
    }
    lastOrderId = result.orderId;
    clearCart();
    unawaited(loadOrders().catchError((Object _) {
      // An unavailable history endpoint must not fail an accepted checkout.
      // Keep existing history; opening the orders screen can retry the request.
    }));
    return result.orderId;
  }

  Future<void> loadOrders() async {
    if (user == null) return;
    try {
      orders = await _api.loadOrders();
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        orders = [];
        return;
      }
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> cancelOrder(int id) async {
    await _api.cancelOrder(id);
    orders = orders
        .where((order) => order.id != id.toString() && order.id != 'local:$id')
        .toList(growable: false);
    notifyListeners();
  }

  Future<OrderModel?> loadOrderStatus(int id) async {
    try {
      return await _api.loadOrderStatus(id);
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadPaymentUrl(int id) async {
    try {
      return await _api.loadPaymentUrl(id);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadPaymentUrlWithRetry(int orderId) async {
    for (var attempt = 0; attempt < _paymentUrlAttempts; attempt++) {
      final url = await loadPaymentUrl(orderId);
      if (url?.trim().isNotEmpty == true) return url;
      if (attempt < _paymentUrlAttempts - 1) {
        await Future<void>.delayed(_paymentUrlRetryDelay);
      }
    }
    return null;
  }

  void repeatOrder(OrderModel order) {
    for (final item in order.items) {
      final product = products.firstWhere(
        (candidate) =>
            candidate.id == item.productId ||
            candidate.title(locale) == item.name ||
            candidate.nameRu == item.name,
        orElse: () => ProductModel(
          id: 'repeat-${item.name}',
          nameRu: item.name,
          price: ((item.totalMinor ?? 0) / 100).round(),
        ),
      );
      addToCart(product, quantity: item.quantity);
    }
  }

  Future<List<GeocodeResult>> geocodeAddress(String query) {
    return _api.geocodeAddress(query, locale);
  }

  Future<AddressModel?> addressFromCurrentLocation({
    AddressModel? existing,
  }) async {
    final point = await NativeBridge.getCurrentLocation();
    if (point == null) return null;
    final lat = point['lat']!;
    final lng = point['lng']!;
    final address = await _api.reverseGeocode(lat, lng, locale) ??
        (locale == 'uz' ? 'Joriy joylashuv' : 'Текущее местоположение');
    return AddressModel(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      address: address,
      lat: lat,
      lng: lng,
      entrance: existing?.entrance,
      floor: existing?.floor,
      apartment: existing?.apartment,
      intercom: existing?.intercom,
      isPrimary: existing?.isPrimary ?? addresses.isEmpty,
    );
  }

  Future<AddressModel> addressFromPoint(
    double lat,
    double lng, {
    AddressModel? existing,
  }) async {
    final address = await _api.reverseGeocode(lat, lng, locale) ??
        (locale == 'uz' ? 'Tanlangan manzil' : 'Выбранный адрес');
    return AddressModel(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      address: address,
      lat: lat,
      lng: lng,
      entrance: existing?.entrance,
      floor: existing?.floor,
      apartment: existing?.apartment,
      intercom: existing?.intercom,
      isPrimary: existing?.isPrimary ?? addresses.isEmpty,
    );
  }

  BranchModel? nearestBranchFor(AddressModel address) {
    BranchModel? best;
    var bestDistance = double.infinity;
    for (final branch in branches) {
      final lat = branch.lat;
      final lng = branch.lng;
      if (lat == null || lng == null) continue;
      final distance = distanceKm(address.lat, address.lng, lat, lng);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = branch;
      }
    }
    return best;
  }

  DeliveryEstimate? estimateDelivery(AddressModel? address) {
    if (address == null) return null;
    final branch = nearestBranchFor(address);
    if (branch?.lat == null || branch?.lng == null) return null;
    final distance =
        distanceKm(address.lat, address.lng, branch!.lat!, branch.lng!);
    final center = (22 + distance * 4).round().clamp(25, 90).toInt();
    return DeliveryEstimate(
      branch: branch,
      distanceKm: distance,
      minMinutes: (center - 5).clamp(20, 85).toInt(),
      maxMinutes: (center + 10).clamp(30, 100).toInt(),
    );
  }

  String _generatedPassword(String phone) {
    final digits = normalizePhone(phone);
    final suffix = digits.length >= 6
        ? digits.substring(digits.length - 6)
        : digits.padLeft(6, '0');
    return 'Wasabi$suffix!';
  }

  Future<void> _syncPushNotifications() async {
    try {
      await _pushNotifications.ensureConfigured(
        onToken: (token, platform, installationId) => _api.registerPushToken(
          token: token,
          platform: platform,
          installationId: installationId,
          locale: locale,
        ),
        onMessage: (_) => refreshMailings(),
      );
    } catch (_) {
      // Push setup should not block app startup or auth flows.
    }
  }

  Future<bool> _openOnlinePaymentIfNeeded({
    required PaymentMethod paymentMethod,
    required int orderId,
    required int amount,
    String? paymentUrl,
  }) async {
    if (paymentUrl != null && paymentUrl.trim().isNotEmpty) {
      await NativeBridge.openUrl(paymentUrl, throwOnFailure: true);
      return true;
    }
    final baseUrl = paymentMethod == PaymentMethod.click
        ? AppConfig.clickPaymentUrl
        : paymentMethod == PaymentMethod.payme
            ? AppConfig.paymePaymentUrl
            : '';
    if (baseUrl.trim().isEmpty) return false;
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      ...Uri.parse(baseUrl).queryParameters,
      'order_id': '$orderId',
      'amount': '${amount.clamp(0, 1 << 31)}',
    });
    await NativeBridge.openUrl(uri.toString(), throwOnFailure: true);
    return true;
  }

  Future<void> _loadRemoteAddresses() async {
    try {
      addresses = await _api.loadAddresses();
      await _refreshAddressLocale(persist: false);
      await _persistAddresses();
    } catch (_) {
      // Local addresses stay available if backend is temporarily unreachable.
    }
  }

  Future<void> _refreshAddressLocale({bool persist = true}) async {
    if (addresses.isEmpty) return;
    final refreshed = <AddressModel>[];
    var changed = false;
    for (final address in addresses) {
      final translated = await _api.reverseGeocode(
        address.lat,
        address.lng,
        locale,
      );
      if (translated == null || translated == address.address) {
        refreshed.add(address);
        continue;
      }
      refreshed.add(address.copyWith(address: translated));
      changed = true;
    }
    if (!changed) return;
    addresses = _primaryFirst(refreshed);
    if (persist) await _saveAddresses();
  }

  Future<void> _saveAddresses() async {
    await _persistAddresses();
    if (user == null) return;
    try {
      addresses = await _api.saveAddresses(addresses);
      await _persistAddresses();
    } catch (_) {
      // Keep local copy and retry on the next explicit save.
    }
  }

  List<AddressModel> _ensurePrimary(List<AddressModel> list) {
    if (list.isEmpty) return list;
    if (list.any((address) => address.isPrimary)) return list;
    final next = List<AddressModel>.from(list);
    next[0] = next[0].copyWith(isPrimary: true);
    return next;
  }

  List<AddressModel> _primaryFirst(List<AddressModel> list) {
    return [
      ...list.where((address) => address.isPrimary),
      ...list.where((address) => !address.isPrimary),
    ];
  }

  Future<void> _persistCart() async {
    await NativeBridge.setString(_cartKey, encodeCart(cart));
  }

  Future<void> _persistAddresses() async {
    await NativeBridge.setString(_addressesKey, encodeAddresses(addresses));
  }

  Future<void> _persistProfile() async {
    final current = user;
    if (current == null) {
      await NativeBridge.remove(_profileKey);
      return;
    }
    await NativeBridge.setString(_profileKey, _encodeUserProfile(current));
  }
}

String _encodeUserProfile(UserProfile profile) {
  return jsonEncode({
    'id': profile.id,
    'name': profile.name,
    'phone': profile.phone,
    'bonus': profile.bonus,
    'birthday': profile.birthday,
  });
}

UserProfile? _decodeUserProfile(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    return UserProfile.fromJson(readMap(jsonDecode(raw)));
  } catch (_) {
    return null;
  }
}

Set<String> _decodeReadMailings(String raw) {
  return _decodeStringSet(raw);
}

Set<String> _decodeStringSet(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return readList(decoded)
        .map(readString)
        .where((id) => id.isNotEmpty)
        .toSet();
  } catch (_) {
    return {};
  }
}

ThemeMode _decodeThemeMode(String? raw) {
  return raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
}

String _encodeThemeMode(ThemeMode mode) {
  return mode == ThemeMode.dark ? 'dark' : 'light';
}

String encodeAddresses(List<AddressModel> items) {
  return jsonEncode(items.map((item) => item.toJson()).toList());
}

List<AddressModel> decodeAddresses(String raw) {
  try {
    final decoded = readList(jsonDecode(raw));
    return decoded
        .map((item) => AddressModel.fromJson(readMap(item)))
        .where((address) => address.id.isNotEmpty && address.address.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthKm = 6371.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRadians(double value) => value * math.pi / 180;
