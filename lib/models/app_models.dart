import 'dart:convert';

String readString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString().trim();
}

int readInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final normalized = value
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9\.-]'), '');
    final parsed = num.tryParse(normalized);
    if (parsed != null) return parsed.round();
  }
  return fallback;
}

int normalizePosterPrice(Object? value, [int fallback = 0]) {
  final raw = readInt(value, fallback);
  if (raw <= 0) return raw;
  // Poster product prices in this project arrive in minor units.
  if (raw >= 1000 && raw % 100 == 0) {
    return (raw / 100).round();
  }
  return raw;
}

double? readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.'));
  }
  return null;
}

Map<String, dynamic> readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<dynamic> readList(Object? value) {
  if (value is List) return value;
  return const [];
}

String normalizePhone(String value) => value.replaceAll(RegExp(r'\D'), '');

String formatPhone(String value) {
  final digits = normalizePhone(value);
  if (digits.length == 12 && digits.startsWith('998')) {
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8, 10)} '
        '${digits.substring(10)}';
  }
  if (digits.length == 9) {
    return '+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} '
        '${digits.substring(5, 7)} ${digits.substring(7)}';
  }
  return value;
}

String transliterateRuToUz(String value) {
  if (value.trim().isEmpty) return '';
  const digraphs = {
    'Щ': 'Shch',
    'щ': 'shch',
    'Ш': 'Sh',
    'ш': 'sh',
    'Ч': 'Ch',
    'ч': 'ch',
    'Ц': 'Ts',
    'ц': 'ts',
    'Ю': 'Yu',
    'ю': 'yu',
    'Я': 'Ya',
    'я': 'ya',
    'Ё': 'Yo',
    'ё': 'yo',
    'Ж': 'J',
    'ж': 'j',
  };
  const singles = {
    'А': 'A',
    'а': 'a',
    'Б': 'B',
    'б': 'b',
    'В': 'V',
    'в': 'v',
    'Г': 'G',
    'г': 'g',
    'Д': 'D',
    'д': 'd',
    'Е': 'E',
    'е': 'e',
    'З': 'Z',
    'з': 'z',
    'И': 'I',
    'и': 'i',
    'Й': 'Y',
    'й': 'y',
    'К': 'K',
    'к': 'k',
    'Л': 'L',
    'л': 'l',
    'М': 'M',
    'м': 'm',
    'Н': 'N',
    'н': 'n',
    'О': 'O',
    'о': 'o',
    'П': 'P',
    'п': 'p',
    'Р': 'R',
    'р': 'r',
    'С': 'S',
    'с': 's',
    'Т': 'T',
    'т': 't',
    'У': 'U',
    'у': 'u',
    'Ф': 'F',
    'ф': 'f',
    'Х': 'X',
    'х': 'x',
    'Ъ': '',
    'ъ': '',
    'Ы': 'Y',
    'ы': 'y',
    'Ь': '',
    'ь': '',
    'Э': 'E',
    'э': 'e',
  };
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(digraphs[char] ?? singles[char] ?? char);
  }
  return buffer.toString();
}

const Map<String, String> _catalogCategoryUzFallbacks = {
  'Напитки': 'Ichimliklar',
  'Роллы': 'Rollar',
  'Cуши': 'Sushi',
  'Суши': 'Sushi',
  'Cалаты': 'Salatlar',
  'Салаты': 'Salatlar',
  'Сеты': 'Setlar',
  'Cоусы': 'Souslar',
  'Соусы': 'Souslar',
  'Запеченные': 'Pishirilganlar',
  'Мини роллы': 'Mini rollar',
  'Холодные блюда': 'Sovuq taomlar',
  'Жаренные роллы': 'Qovurilgan rollar',
  'Кимпаб': 'Kimpab',
  'Горячка': 'Issiq taomlar',
  'Новинки': 'Yangi mahsulotlar',
  'Хлеб': 'Nonlar',
  'Гунканы': 'Gunkanlar',
  'Онигири': 'Onigiri',
  'Супы': 'Sho`rvalar',
  'Десерты': 'Shirinliklar',
  'Мини сеты': 'Mini setlar',
  'Акция!': 'Aksiya!',
};

const List<(String, String)> _catalogUzPhraseReplacements = [
  ('с морепродуктами', 'dengiz mahsulotlari bilan'),
  ('с копченным лососем', 'dudlangan losos bilan'),
  ('с курицей и сыром', 'tovuq va pishloq bilan'),
  ('с курицей', 'tovuq bilan'),
  ('с говядиной', "mol go'shti bilan"),
  ('с креветкой', 'krevetka bilan'),
  ('с лососем', 'losos bilan'),
  ('с угрем', 'ugor bilan'),
  ('с крабом', 'qisqichbaqa bilan'),
  ('с авокадо', 'avokado bilan'),
  ('с овощами', 'sabzavotlar bilan'),
  ('копченный', 'dudlangan'),
  ('копченый', 'dudlangan'),
  ('жаренные', 'qovurilgan'),
  ('жареный', 'qovurilgan'),
  ('запеченные', 'pishirilgan'),
  ('запеченный', 'pishirilgan'),
  ('горячий', 'issiq'),
  ('острый', 'achchiq'),
  ('креветка', 'krevetka'),
  ('креветкой', 'krevetka'),
  ('крабовый', 'qisqichbaqali'),
  ('крабом', 'qisqichbaqa'),
  ('краб', 'qisqichbaqa'),
  ('лососем', 'losos'),
  ('лосось', 'losos'),
  ('курицей', 'tovuq'),
  ('курица', 'tovuq'),
  ('куриный', 'tovuqli'),
  ('курицей', 'tovuq'),
  ('говядиной', "mol go'shti"),
  ('говядина', "mol go'shti"),
  ('овощами', 'sabzavotlar'),
  ('десерт', 'shirinlik'),
  ('дольки картошки', 'kartoshka bo`laklari'),
  ('картошка', 'kartoshka'),
  ('нагетсы', 'naggetslar'),
  ('пармезаном', 'parmezan bilan'),
  ('супы', 'sho`rvalar'),
  ('суп', 'sho`rva'),
  ('хлеб', 'non'),
  ('новинки', 'yangi mahsulotlar'),
  ('гункан', 'gunkan'),
  ('суши', 'sushi'),
  ('сет', 'set'),
  ('ролл', 'roll'),
  ('роллы', 'rollar'),
  ('шт', 'dona'),
];

String _translateCatalogRussianToUz(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final exactCategory = _catalogCategoryUzFallbacks[trimmed];
  if (exactCategory != null) return exactCategory;

  var translated = trimmed;
  for (final (source, target) in _catalogUzPhraseReplacements) {
    translated = translated.replaceAll(
      RegExp(source, caseSensitive: false, unicode: true),
      target,
    );
  }

  translated = transliterateRuToUz(translated);
  translated =
      translated.replaceAll(RegExp(r'\s+'), ' ').replaceAll('`', "'").trim();

  if (translated.isEmpty) return translated;
  return translated[0].toUpperCase() + translated.substring(1);
}

class AppSettings {
  const AppSettings({
    this.workStart = '11:00',
    this.workEnd = '23:00',
    this.packageFee = 0,
    this.deliveryFee = 0,
    this.contactPhone = '',
    this.telegram = '',
    this.langRuEnabled = true,
    this.langUzEnabled = true,
    this.siteEnabled = true,
  });

  final String workStart;
  final String workEnd;
  final int packageFee;
  final int deliveryFee;
  final String contactPhone;
  final String telegram;
  final bool langRuEnabled;
  final bool langUzEnabled;
  final bool siteEnabled;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      workStart: readString(json['work_start'], '11:00'),
      workEnd: readString(json['work_end'], '23:00'),
      packageFee: readInt(json['package_fee']),
      deliveryFee: readInt(json['delivery_fee']),
      contactPhone: readString(json['contact_phone']),
      telegram: readString(json['social_telegram']),
      langRuEnabled: json['lang_ru_enabled'] != false,
      langUzEnabled: json['lang_uz_enabled'] != false,
      siteEnabled: json['site_enabled'] != false,
    );
  }
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.nameRu,
    this.nameUz,
    this.photo,
    this.emoji,
    this.sortOrder,
  });

  final String id;
  final String nameRu;
  final String? nameUz;
  final String? photo;
  final String? emoji;
  final int? sortOrder;

  String title(String locale) {
    if (locale == 'uz' && readString(nameUz).isNotEmpty) return nameUz!;
    if (locale == 'uz') return _translateCatalogRussianToUz(nameRu);
    return nameRu;
  }

  factory CategoryModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> translation = const {},
    String? emoji,
  }) {
    final id = readString(json['category_id'] ?? json['id']);
    return CategoryModel(
      id: id,
      nameRu: readString(
        json['category_name'] ?? json['name'] ?? json['title'],
        'Категория',
      ).replaceAll('&off', '').trim(),
      nameUz: readString(translation['nameUz']).isEmpty
          ? null
          : readString(translation['nameUz']),
      photo:
          readString(json['photo']).isEmpty ? null : readString(json['photo']),
      emoji: emoji,
      sortOrder: translation['sortOrder'] == null
          ? null
          : readInt(translation['sortOrder']),
    );
  }
}

class DiscountModel {
  const DiscountModel({
    required this.discountValue,
    required this.resultType,
    this.promotionId,
    this.discountPrices = const [],
    this.isBonus = false,
    this.isBirthday = false,
  });

  final int discountValue;
  final int resultType;
  final int? promotionId;
  final List<dynamic> discountPrices;
  final bool isBonus;
  final bool isBirthday;

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      // Poster returns monetary promotion values in minor units, just like
      // product prices. Percentages remain unchanged by this normalizer.
      discountValue: normalizePosterPrice(json['discount_value']),
      resultType: readInt(json['result_type']),
      promotionId:
          json['promotion_id'] == null ? null : readInt(json['promotion_id']),
      discountPrices: readList(json['discount_prices']),
      isBonus: json['is_bonus'] == true,
      isBirthday: json['is_birthday'] == true,
    );
  }

  int apply(int price) {
    if (isBonus) return 0;
    var calculated = price;
    if (resultType == 3) {
      calculated =
          (price * (1 - discountValue / 100)).round().clamp(0, price).toInt();
    } else if (resultType == 1 || resultType == 2) {
      // Poster uses result type 2 for a fixed discount amount. It is a
      // deduction, not the final product price (e.g. 35,000 - 5,000).
      calculated = (price - discountValue).clamp(0, price).toInt();
    }
    // Poster sends special promotional prices in discount_prices with result
    // type 4. They are final prices and must not be treated as a deduction.
    if (resultType != 4) return calculated.clamp(0, price).toInt();
    final listedPrices = <int>[];
    final fallbackPrices = <int>[];
    for (final entry in discountPrices) {
      final json = readMap(entry);
      final value = normalizePosterPrice(
        json['price_value'] ??
            json['price'] ??
            json['value'] ??
            json['sum'] ??
            json['amount'] ??
            json['price_1'] ??
            json['price1'] ??
            json['1'],
      );
      if (value <= 0) continue;
      final target = readString(json['price_id'] ?? json['priceId']) == '1'
          ? listedPrices
          : fallbackPrices;
      target.add(value);
    }
    final prices = listedPrices.isNotEmpty ? listedPrices : fallbackPrices;
    if (prices.isNotEmpty) {
      calculated = calculated < prices.reduce((a, b) => a < b ? a : b)
          ? calculated
          : prices.reduce((a, b) => a < b ? a : b);
    }
    return calculated.clamp(0, price).toInt();
  }

  String label() {
    if (isBonus) return 'Подарок';
    if (resultType == 3 && discountValue > 0) return '-$discountValue%';
    if ((resultType == 1 || resultType == 2) && discountValue > 0) {
      return '-$discountValue сум';
    }
    return 'Акция';
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.nameRu,
    required this.price,
    this.nameUz,
    this.descriptionRu,
    this.descriptionUz,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.discount,
  });

  final String id;
  final String nameRu;
  final String? nameUz;
  final String? descriptionRu;
  final String? descriptionUz;
  final int price;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;
  final DiscountModel? discount;

  int get effectivePrice => discount?.apply(price) ?? price;
  bool get hasDiscount => discount != null && effectivePrice < price;

  ProductModel withoutDiscount() {
    return ProductModel(
      id: id,
      nameRu: nameRu,
      price: price,
      nameUz: nameUz,
      descriptionRu: descriptionRu,
      descriptionUz: descriptionUz,
      imageUrl: imageUrl,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }

  String title(String locale) {
    if (locale == 'uz' && readString(nameUz).isNotEmpty) return nameUz!;
    if (locale == 'uz') return _translateCatalogRussianToUz(nameRu);
    return nameRu;
  }

  String description(String locale) {
    if (locale == 'uz' && readString(descriptionUz).isNotEmpty) {
      return descriptionUz!;
    }
    if (locale == 'uz') {
      return _translateCatalogRussianToUz(readString(descriptionRu));
    }
    return readString(descriptionRu);
  }

  factory ProductModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> translation = const {},
    DiscountModel? discount,
  }) {
    final ingredients = readString(json['ingredients']);
    final description = readString(json['description'], ingredients);
    return ProductModel(
      id: readString(json['product_id'] ?? json['id']),
      nameRu: readString(json['product_name'] ?? json['name'], 'Товар'),
      nameUz: readString(translation['nameUz']).isEmpty
          ? null
          : readString(translation['nameUz']),
      descriptionRu: description.isEmpty ? null : description,
      descriptionUz: readString(translation['descUz']).isEmpty
          ? null
          : readString(translation['descUz']),
      price: normalizePosterPrice(json['price']),
      // The compact catalog intentionally returns `photo` only. Do not let an
      // empty optional `photo_origin` hide the real Poster product image.
      imageUrl: readString(json['photo_origin']).isNotEmpty
          ? readString(json['photo_origin'])
          : (readString(json['photo']).isEmpty
              ? null
              : readString(json['photo'])),
      categoryId: readString(json['category_id']).isEmpty
          ? null
          : readString(json['category_id']),
      categoryName: readString(json['category_name']).isEmpty
          ? null
          : readString(json['category_name']),
      discount: discount,
    );
  }

  Map<String, dynamic> toCartJson({required int quantity}) {
    return {
      'product_id': id,
      'name': nameRu,
      'price': price,
      'image': imageUrl,
      'category_id': categoryId,
      'qty': quantity,
    };
  }
}

class BannerModel {
  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.href,
    this.sortOrder = 0,
  });

  final String id;
  final String imageUrl;
  final String? href;
  final int sortOrder;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: readString(json['id']),
      imageUrl: readString(json['imageUrl'] ?? json['image']),
      href: readString(json['href']).isEmpty ? null : readString(json['href']),
      sortOrder: readInt(json['sortOrder']),
    );
  }
}

class PromotionModel {
  const PromotionModel({
    required this.id,
    required this.titleRu,
    this.titleUz,
    this.textRu,
    this.textUz,
    this.code,
    this.badge,
    this.imageUrl,
  });

  final String id;
  final String titleRu;
  final String? titleUz;
  final String? textRu;
  final String? textUz;
  final String? code;
  final String? badge;
  final String? imageUrl;

  String title(String locale) {
    if (locale == 'uz' && readString(titleUz).isNotEmpty) return titleUz!;
    return titleRu;
  }

  String text(String locale) {
    if (locale == 'uz' && readString(textUz).isNotEmpty) return textUz!;
    return readString(textRu);
  }
}

class MailingModel {
  const MailingModel({
    required this.id,
    required this.titleRu,
    required this.createdAt,
    this.titleUz,
    this.textRu,
    this.textUz,
    this.imageUrl,
  });

  final String id;
  final String titleRu;
  final String? titleUz;
  final String? textRu;
  final String? textUz;
  final String? imageUrl;
  final DateTime? createdAt;

  String title(String locale) {
    if (locale == 'uz' && readString(titleUz).isNotEmpty) return titleUz!;
    return titleRu;
  }

  String text(String locale) {
    if (locale == 'uz' && readString(textUz).isNotEmpty) return textUz!;
    return readString(textRu);
  }

  factory MailingModel.fromJson(Map<String, dynamic> json) {
    return MailingModel(
      id: readString(json['id'] ?? json['mailingId'] ?? json['mailing_id']),
      titleRu: readString(
          json['titleRu'] ?? json['title_ru'] ?? json['title'], 'Сообщение'),
      titleUz: readString(json['titleUz'] ?? json['title_uz']).isEmpty
          ? null
          : readString(json['titleUz'] ?? json['title_uz']),
      textRu:
          readString(json['textRu'] ?? json['text_ru'] ?? json['text']).isEmpty
              ? null
              : readString(json['textRu'] ?? json['text_ru'] ?? json['text']),
      textUz: readString(json['textUz'] ?? json['text_uz']).isEmpty
          ? null
          : readString(json['textUz'] ?? json['text_uz']),
      imageUrl: readString(
                  json['imageUrl'] ?? json['image_url'] ?? json['image'])
              .isEmpty
          ? null
          : readString(json['imageUrl'] ?? json['image_url'] ?? json['image']),
      createdAt: DateTime.tryParse(
        readString(json['createdAt'] ?? json['created_at'])
            .replaceAll(' ', 'T'),
      ),
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.bonus = 0,
    this.birthday,
  });

  final String id;
  final String name;
  final String phone;
  final int bonus;
  final String? birthday;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: readString(json['id']),
      name: readString(json['name'], 'Гость'),
      phone: readString(json['phone']),
      bonus: readInt(json['bonus']),
      birthday: readString(json['birthday']).isEmpty
          ? null
          : readString(json['birthday']),
    );
  }

  UserProfile copyWith(
      {String? name, String? phone, int? bonus, String? birthday}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bonus: bonus ?? this.bonus,
      birthday: birthday ?? this.birthday,
    );
  }
}

class AddressModel {
  const AddressModel({
    required this.id,
    required this.address,
    required this.lat,
    required this.lng,
    this.entrance,
    this.floor,
    this.apartment,
    this.intercom,
    this.isPrimary = false,
  });

  final String id;
  final String address;
  final double lat;
  final double lng;
  final String? entrance;
  final String? floor;
  final String? apartment;
  final String? intercom;
  final bool isPrimary;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: readString(json['id']),
      address: readString(json['address']),
      lat: readDouble(json['lat']) ?? 41.311081,
      lng: readDouble(json['lng']) ?? 69.240562,
      entrance: readString(json['entrance']).isEmpty
          ? null
          : readString(json['entrance']),
      floor:
          readString(json['floor']).isEmpty ? null : readString(json['floor']),
      apartment: readString(json['apartment']).isEmpty
          ? null
          : readString(json['apartment']),
      intercom: readString(json['intercom']).isEmpty
          ? null
          : readString(json['intercom']),
      isPrimary: json['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'lat': lat,
      'lng': lng,
      if (entrance != null) 'entrance': entrance,
      if (floor != null) 'floor': floor,
      if (apartment != null) 'apartment': apartment,
      if (intercom != null) 'intercom': intercom,
      'isPrimary': isPrimary,
    };
  }

  AddressModel copyWith({
    String? id,
    String? address,
    double? lat,
    double? lng,
    String? entrance,
    String? floor,
    String? apartment,
    String? intercom,
    bool? isPrimary,
  }) {
    return AddressModel(
      id: id ?? this.id,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      entrance: entrance ?? this.entrance,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      intercom: intercom ?? this.intercom,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class DeliveryEstimate {
  const DeliveryEstimate({
    required this.branch,
    required this.distanceKm,
    required this.minMinutes,
    required this.maxMinutes,
  });

  final BranchModel branch;
  final double distanceKm;
  final int minMinutes;
  final int maxMinutes;

  String distanceText(String locale) {
    final value = distanceKm < 10
        ? distanceKm.toStringAsFixed(1)
        : distanceKm.round().toString();
    return '$value km';
  }

  String timeText(String locale) {
    return locale == 'uz'
        ? '$minMinutes-$maxMinutes daqiqa'
        : '$minMinutes-$maxMinutes минут';
  }
}

class BranchModel {
  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
    this.spotId,
    this.lat,
    this.lng,
    this.phone,
    this.workTime,
  });

  final String id;
  final String name;
  final String address;
  final String? spotId;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? workTime;

  factory BranchModel.fromJson(Map<String, dynamic> json, String locale) {
    return BranchModel(
      id: readString(json['id'] ?? json['spot_id']),
      spotId: readString(json['spotId'] ?? json['spot_id']).isEmpty
          ? null
          : readString(json['spotId'] ?? json['spot_id']),
      name: locale == 'uz'
          ? readString(json['nameUz'] ?? json['name'], 'Wasabi Sushi')
          : readString(json['nameRu'] ?? json['name'], 'Wasabi Sushi'),
      address: locale == 'uz'
          ? readString(
              json['addressUz'] ?? json['pickupAddressUz'] ?? json['address'],
              'Ташкент',
            )
          : readString(
              json['addressRu'] ?? json['pickupAddressRu'] ?? json['address'],
              'Ташкент',
            ),
      lat: readDouble(json['lat']),
      lng: readDouble(json['lng']),
      phone:
          readString(json['phone']).isEmpty ? null : readString(json['phone']),
      workTime: readString(json['workTime']).isEmpty
          ? null
          : readString(json['workTime']),
    );
  }
}

class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.categoryId,
  });

  final String productId;
  final String name;
  final int price;
  final int quantity;
  final String? imageUrl;
  final String? categoryId;

  int get total => price * quantity;

  factory CartItem.fromProduct(ProductModel product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      name: product.nameRu,
      price: product.effectivePrice,
      imageUrl: product.imageUrl,
      categoryId: product.categoryId,
      quantity: quantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: readString(json['product_id'] ?? json['productId']),
      name: readString(json['name'], 'Товар'),
      price: readInt(json['price']),
      quantity: readInt(json['qty'] ?? json['quantity'], 1),
      imageUrl: readString(json['image'] ?? json['imageUrl']).isEmpty
          ? null
          : readString(json['image'] ?? json['imageUrl']),
      categoryId: readString(json['category_id'] ?? json['categoryId']).isEmpty
          ? null
          : readString(json['category_id'] ?? json['categoryId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'qty': quantity,
      if (imageUrl != null) 'image': imageUrl,
      if (categoryId != null) 'category_id': categoryId,
    };
  }

  Map<String, dynamic> toOrderJson() {
    return {
      'product_id': productId,
      'name': name,
      'price': price * 100,
      'qty': quantity,
      if (categoryId != null) 'menu_category_id': categoryId,
      if (imageUrl != null) 'photo': imageUrl,
    };
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      categoryId: categoryId,
    );
  }
}

enum DeliveryType { delivery, pickup }

enum PaymentMethod { cash, card, click, payme }

const checkoutPaymentMethods = [
  PaymentMethod.cash,
  PaymentMethod.click,
  PaymentMethod.payme,
];

extension PaymentMethodX on PaymentMethod {
  bool get isCheckoutSupported => checkoutPaymentMethods.contains(this);

  bool get requiresOnlinePayment =>
      this == PaymentMethod.click || this == PaymentMethod.payme;

  String get apiValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.click:
        return 'click';
      case PaymentMethod.payme:
        return 'payme';
    }
  }

  String label(String locale) {
    switch (this) {
      case PaymentMethod.cash:
        return locale == 'uz' ? 'Naqd' : 'Наличными';
      case PaymentMethod.card:
        return locale == 'uz' ? 'Karta orqali' : 'Картой при получении';
      case PaymentMethod.click:
        return 'Click';
      case PaymentMethod.payme:
        return 'Payme';
    }
  }
}

class CheckoutRequest {
  const CheckoutRequest({
    required this.deliveryType,
    required this.paymentMethod,
    required this.items,
    this.customerPhone,
    this.customerName,
    this.address,
    this.lat,
    this.lng,
    this.spotId,
    this.persons = 1,
    this.promoCode,
    this.checkoutPromotionId,
    this.comment,
    this.deliveryTimeMode = 'today',
    this.deliveryDate,
    this.deliveryClock,
    this.bonusAmount = 0,
  });

  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final List<CartItem> items;
  final String? customerPhone;
  final String? customerName;
  final String? address;
  final double? lat;
  final double? lng;
  final String? spotId;
  final int persons;
  final String? promoCode;
  final int? checkoutPromotionId;
  final String? comment;
  final String deliveryTimeMode;
  final String? deliveryDate;
  final String? deliveryClock;
  final int bonusAmount;

  Map<String, dynamic> toJson() {
    return {
      'customerPhone': customerPhone,
      'customerName': customerName,
      'deliveryType':
          deliveryType == DeliveryType.delivery ? 'delivery' : 'pickup',
      'payment': paymentMethod.apiValue,
      'address': address,
      'lat': lat,
      'lng': lng,
      'spotId': spotId,
      'persons': persons,
      'promoCode': promoCode,
      'checkoutPromotionId': checkoutPromotionId,
      'comment': comment,
      'deliveryTimeMode': deliveryTimeMode,
      'deliveryDate': deliveryDate,
      'deliveryClock': deliveryClock,
      'bonusAmount': bonusAmount,
      'items': items.map((item) => item.toOrderJson()).toList(),
    };
  }
}

class CheckoutResult {
  const CheckoutResult({required this.orderId, this.paymentUrl});

  final int orderId;
  final String? paymentUrl;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final paymentUrl = readString(json['paymentUrl'] ?? json['payment_url']);
    return CheckoutResult(
      orderId: readInt(json['orderId'] ?? json['order_id']),
      paymentUrl: paymentUrl.isEmpty ? null : paymentUrl,
    );
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.name,
    required this.quantity,
    this.productId,
    this.totalMinor,
  });

  final String? productId;
  final String name;
  final int quantity;
  final int? totalMinor;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: readString(json['productId'] ?? json['product_id']).isEmpty
          ? null
          : readString(json['productId'] ?? json['product_id']),
      name: readString(json['name'] ?? json['product_name'], 'Товар'),
      quantity: readInt(json['quantity'] ?? json['qty'] ?? json['count'], 1),
      totalMinor:
          json['totalMinor'] == null ? null : readInt(json['totalMinor']),
    );
  }
}

class GeocodeResult {
  const GeocodeResult({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;

  factory GeocodeResult.fromJson(Map<String, dynamic> json) {
    return GeocodeResult(
      address: readString(json['address']),
      lat: readDouble(json['lat']) ?? 41.311081,
      lng: readDouble(json['lng']) ?? 69.240562,
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.total,
    this.items = const [],
    this.source,
    this.paymentUrl,
  });

  final String id;
  final String status;
  final DateTime? createdAt;
  final int? total;
  final List<OrderItemModel> items;
  final String? source;
  final String? paymentUrl;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = readList(json['items']);
    return OrderModel(
      id: readString(
          json['id'] ?? json['incomingOrderId'] ?? json['transactionId']),
      status: readString(json['status'], 'new'),
      createdAt: DateTime.tryParse(
        readString(json['createdAt'] ?? json['created_at'])
            .replaceAll(' ', 'T'),
      ),
      total: json['totalMinor'] != null
          ? (readInt(json['totalMinor']) / 100).round()
          : json['total'] != null
              ? (readInt(json['total']) / 100).round()
              : null,
      items: rawItems
          .map((item) => OrderItemModel.fromJson(readMap(item)))
          .toList(growable: false),
      source: readString(json['source']).isEmpty
          ? null
          : readString(json['source']),
      paymentUrl: readString(json['paymentUrl']).isEmpty
          ? null
          : readString(json['paymentUrl']),
    );
  }
}

String encodeCart(List<CartItem> items) {
  return jsonEncode(items.map((item) => item.toJson()).toList());
}

List<CartItem> decodeCart(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return readList(decoded)
        .map((item) => CartItem.fromJson(readMap(item)))
        .where((item) => item.productId.isNotEmpty && item.quantity > 0)
        .toList();
  } catch (_) {
    return [];
  }
}
