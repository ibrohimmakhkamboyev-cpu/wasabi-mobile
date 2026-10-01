import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/utils/address_display.dart';

void main() {
  test('shortens Uzbek address to street and house number', () {
    expect(
      displayAddressLabel(
        'O‘zbekiston, Toshkent, Yashnobod tumani, Zumrad ko‘chasi, 11',
      ),
      'Zumrad ko‘chasi, 11',
    );
  });

  test('keeps short user-entered labels unchanged', () {
    expect(displayAddressLabel('Uy'), 'Uy');
  });

  test('removes mall and mahalla metadata from a geocoded address', () {
    expect(
      displayAddressLabel(
        'Узбекистан, Ташкент, ТРЦ Атриум, 2 этаж. Режим работы: ежедневно, '
        'махаллинский сход граждан Гузал, улица Гузаль, 11',
      ),
      'улица Гузаль, 11',
    );
  });

  test('keeps a named mahalla with its house number', () {
    expect(
      displayAddressLabel(
        'O‘zbekiston, Toshkent, Go‘zal mahalla fuqarolar yig‘ini, 15A',
      ),
      'Go‘zal, 15A',
    );
  });
}
