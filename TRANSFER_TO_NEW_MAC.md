# Transfer Wasabi Mobile to another Mac

## Current project settings

- iOS bundle ID: `uz.wasabi.wasabiMobile`
- Android package: `uz.wasabi.wasabi_mobile`
- Apple Developer Team: `MH67RWWAG3`
- Firebase project: `wasabi-sushi-1ef8d`
- iOS Firebase config: `ios/Runner/GoogleService-Info.plist`
- Android Firebase config: `android/app/google-services.json`
- iOS push entitlement: `ios/Runner/Runner.entitlements`

## On the new Mac

1. Install Xcode from the App Store.
2. Open Xcode once and sign in:
   `Xcode` -> `Settings...` -> `Accounts`
3. Add the Apple ID that has access to team `MH67RWWAG3`.
4. Install Flutter and CocoaPods.
5. Open Terminal in the project folder and run:

```bash
flutter pub get
cd ios
pod install
cd ..
```

6. Open the iOS workspace:

```bash
open ios/Runner.xcworkspace
```

7. In Xcode:
   `Runner` target -> `Signing & Capabilities`

Confirm:

- Team: `MH67RWWAG3`
- Bundle Identifier: `uz.wasabi.wasabiMobile`
- Capability: `Push Notifications`

8. Build/install to iPhone:

```bash
flutter devices
flutter build ios --release
flutter install -d <iphone-device-id> --release
```

## Firebase APNs

Firebase already uses project `wasabi-sushi-1ef8d`.

In Firebase Console, make sure iOS app `uz.wasabi.wasabiMobile` has APNs key:

- Key ID: `7N5M4JGD7A`
- Team ID: `MH67RWWAG3`

## If iPhone refuses to open the app

On iPhone:

`Settings` -> `General` -> `VPN & Device Management` -> trust the developer profile.
