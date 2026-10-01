# Run Wasabi Mobile

This archive contains the Flutter app source, assets, platform projects, Firebase configuration, and tests. Generated build files are recreated locally.

## Requirements

- Flutter SDK
- Android Studio for Android, or Xcode and CocoaPods for iOS
- Access to the live Wasabi backend at `https://wasabisushi.uz`
- An active Yandex MapKit SDK key for the native map

## Start

From this project directory:

```bash
flutter pub get
flutter run --dart-define=YANDEX_MAPKIT_API_KEY=<your-mapkit-sdk-key>
```

For a different backend, also pass `--dart-define=API_BASE_URL=<backend-url>`.

Run `flutter analyze` and `flutter test` to check the source. Apple and Android release signing credentials are managed separately and are not included in this archive. Live orders and payments require the backend and payment provider to be available.
