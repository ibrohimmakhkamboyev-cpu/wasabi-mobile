String displayAddressLabel(String address) {
  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length < 2) return address.trim();

  String? usefulPart(String part) {
    final normalized = part
        .toLowerCase()
        .replaceAll('ʻ', "'")
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('`', "'");
    if (normalized == "o'zbekiston" ||
        normalized == 'uzbekistan' ||
        normalized == 'узбекистан') {
      return null;
    }
    if (normalized == 'toshkent' ||
        normalized == 'tashkent' ||
        normalized == 'ташкент') {
      return null;
    }
    // Reverse geocoding can include a nearby mall and its opening hours.
    // They describe a point of interest, not the customer's address.
    if (normalized.contains('трц') ||
        normalized.contains('тц ') ||
        normalized.contains('торгов') ||
        normalized.contains('этаж') ||
        normalized.contains('режим работы') ||
        normalized.contains('ежедневно')) {
      return null;
    }
    // Keep the mahalla name but discard only its administrative wording.
    final cleaned = part
        .replaceAll(RegExp(r'\s+mahalla.*$', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'^махаллинский\s+сход\s+граждан\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+мфй$', caseSensitive: false), '')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  final useful = parts.map(usefulPart).whereType<String>().toList();

  if (useful.isEmpty) return address.trim();

  bool isStreet(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('ko‘ch') ||
        normalized.contains("ko'ch") ||
        normalized.contains('kochasi') ||
        normalized.contains('улиц') ||
        normalized.contains('ул.') ||
        normalized.contains('просп') ||
        normalized.contains('проезд') ||
        normalized.contains('street');
  }

  bool hasHouseNumber(String value) =>
      RegExp(r'(^|\s)\d+[a-zа-я]?(?:/\d+)?($|\s)', caseSensitive: false)
          .hasMatch(value);

  // Prefer a real street and its house number. This also keeps the display
  // compact when Yandex returns extra administrative components.
  final streetIndex = useful.indexWhere(isStreet);
  if (streetIndex >= 0) {
    final street = useful[streetIndex];
    if (hasHouseNumber(street)) return street;
    final house = useful.skip(streetIndex + 1).firstWhere(
          hasHouseNumber,
          orElse: () => '',
        );
    return house.isEmpty ? street : '$street, $house';
  }

  final numberedIndex = useful.indexWhere(hasHouseNumber);
  if (numberedIndex >= 0) {
    final numbered = useful[numberedIndex];
    final named = useful.take(numberedIndex).lastWhere(
          (part) => RegExp(r'[A-Za-zА-Яа-яЎўҚқҒғҲҳ]').hasMatch(part),
          orElse: () => '',
        );
    return named.isEmpty ? numbered : '$named, $numbered';
  }
  return useful.last;
}
