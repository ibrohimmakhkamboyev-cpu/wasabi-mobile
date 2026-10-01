# Wasabi Mobile

Flutter-приложение для Wasabi Sushi: каталог, корзина, оформление заказа,
личный кабинет, адреса, акции, филиалы и история заказов.

Backend по умолчанию берется из существующего сайта. Для запуска передайте URL:

```bash
flutter pub get
flutter create .
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Для Android-эмулятора обычно нужен `http://10.0.2.2:3000`.

Админка остается общей с сайтом: `/admin` в проекте `wasabi-sayt`.
