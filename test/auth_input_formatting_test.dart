import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasabi_mobile/services/wasabi_api.dart';
import 'package:wasabi_mobile/state/app_state.dart';
import 'package:wasabi_mobile/theme/app_theme.dart';
import 'package:wasabi_mobile/ui/screens/auth_screen.dart';
import 'package:wasabi_mobile/ui/widgets/common.dart';

void main() {
  testWidgets('registration formats and caps phone and birthday input',
      (tester) async {
    final api = _PhoneCaptureApi();

    await tester.pumpWidget(
      AppScope(
        state: AppState(api: api),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );

    await tester.tap(find.text("Ro'yxatdan o'tish"));
    await tester.pumpAndSettle();

    final phoneFinder = find.widgetWithText(TextField, 'Telefon');
    await tester.enterText(phoneFinder, '977722279123');

    final phoneField = tester.widget<TextField>(phoneFinder);
    expect(phoneField.controller?.text, '97 772 22 79');
    expect(phoneField.style?.fontSize, 18);
    expect(phoneField.decoration?.prefixStyle?.fontSize, 18);

    final birthdayFinder = find.widgetWithText(TextField, "Tug'ilgan sana");
    await tester.enterText(birthdayFinder, '20090205123');
    expect(
      tester.widget<TextField>(birthdayFinder).controller?.text,
      '2009-02-05',
    );

    await tester.enterText(find.widgetWithText(TextField, 'Ism'), 'Ali');
    await tester.tap(find.text('Kod yuborish'));
    await tester.pump();

    expect(api.lastRegisterCodePhone, '+998977722279');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('phone field accepts a pasted full Uzbek number', (tester) async {
    await tester.pumpWidget(
      AppScope(
        state: AppState(api: _PhoneCaptureApi()),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );

    final phoneFinder = find.widgetWithText(TextField, 'Telefon');
    await tester.enterText(phoneFinder, '+998 97 772 22 79');

    expect(
      tester.widget<TextField>(phoneFinder).controller?.text,
      '97 772 22 79',
    );
  });
}

class _PhoneCaptureApi extends WasabiApi {
  String? lastRegisterCodePhone;

  @override
  Future<String> sendRegisterCode({
    required String phone,
    required String locale,
  }) async {
    lastRegisterCodePhone = phone;
    return 'register';
  }
}
