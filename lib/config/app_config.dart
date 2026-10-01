class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://wasabisushi.uz',
  );
  static String orderPaymentUrl(int orderId) =>
      '$apiBaseUrl/api/orders/$orderId/payment';

  static const _adminPanelOverride = String.fromEnvironment('ADMIN_PANEL_URL');
  static String get adminPanelUrl =>
      _adminPanelOverride.isEmpty ? '$apiBaseUrl/admin' : _adminPanelOverride;

  static const supportTelegram = String.fromEnvironment(
    'SUPPORT_TELEGRAM',
    defaultValue: 'https://t.me/',
  );

  static const defaultPhone = String.fromEnvironment(
    'WASABI_PHONE',
    defaultValue: '+998 90 123 45 67',
  );

  static const clickPaymentUrl = String.fromEnvironment('CLICK_PAYMENT_URL');
  static const paymePaymentUrl = String.fromEnvironment('PAYME_PAYMENT_URL');

  static const yandexMapkitApiKey = String.fromEnvironment(
    'YANDEX_MAPKIT_API_KEY',
  );

}
