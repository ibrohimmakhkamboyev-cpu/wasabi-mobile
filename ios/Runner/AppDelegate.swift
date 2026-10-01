import Flutter
import CoreLocation
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var pendingLocationResult: FlutterResult?
  private var locationRetryCount = 0
  private var locationTimeoutWorkItem: DispatchWorkItem?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = kCLDistanceFilterNone
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    configureNativeChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func configureNativeChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "uz.wasabi.mobile/native",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "getString":
        guard let key = args?["key"] as? String else {
          result(nil)
          return
        }
        result(UserDefaults.standard.string(forKey: key))
      case "setString":
        guard let key = args?["key"] as? String, let value = args?["value"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "key and value are required", details: nil))
          return
        }
        UserDefaults.standard.set(value, forKey: key)
        result(nil)
      case "remove":
        if let key = args?["key"] as? String {
          UserDefaults.standard.removeObject(forKey: key)
        }
        result(nil)
      case "openUrl":
        guard
          let raw = args?["url"] as? String,
          let url = URL(string: raw)
        else {
          result(FlutterError(code: "INVALID_URL", message: "url is required", details: nil))
          return
        }
        UIApplication.shared.open(url) { success in
          success
            ? result(nil)
            : result(FlutterError(code: "OPEN_URL_FAILED", message: raw, details: nil))
        }
      case "getCurrentLocation":
        if self.pendingLocationResult != nil {
          result(FlutterError(code: "LOCATION_BUSY", message: "location request already running", details: nil))
          return
        }
        self.pendingLocationResult = result
        self.locationRetryCount = 0
        self.locationTimeoutWorkItem?.cancel()
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
          self.locationManager.requestWhenInUseAuthorization()
        } else if status == .denied || status == .restricted {
          self.pendingLocationResult = nil
          result(FlutterError(code: "LOCATION_DENIED", message: "location permission denied", details: nil))
        } else {
          if self.replyWithRecentLocation() {
            return
          }
          self.startLocationUpdates()
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard pendingLocationResult != nil else { return }
    let status = CLLocationManager.authorizationStatus()
    if status == .authorizedWhenInUse || status == .authorizedAlways {
      startLocationUpdates()
    } else if status == .denied || status == .restricted {
      let result = pendingLocationResult
      pendingLocationResult = nil
      result?(FlutterError(code: "LOCATION_DENIED", message: "location permission denied", details: nil))
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    manager.stopUpdatingLocation()
    locationTimeoutWorkItem?.cancel()
    locationTimeoutWorkItem = nil
    let result = pendingLocationResult
    pendingLocationResult = nil
    locationRetryCount = 0
    result?([
      "lat": location.coordinate.latitude,
      "lng": location.coordinate.longitude
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let locationError = error as? CLError,
       locationError.code == .locationUnknown,
       pendingLocationResult != nil,
       locationRetryCount < 3 {
      locationRetryCount += 1
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
        guard let self, self.pendingLocationResult != nil else { return }
        self.startLocationUpdates()
      }
      return
    }
    manager.stopUpdatingLocation()
    locationTimeoutWorkItem?.cancel()
    locationTimeoutWorkItem = nil
    if let cached = manager.location {
      let result = pendingLocationResult
      pendingLocationResult = nil
      locationRetryCount = 0
      result?([
        "lat": cached.coordinate.latitude,
        "lng": cached.coordinate.longitude
      ])
      return
    }
    let result = pendingLocationResult
    pendingLocationResult = nil
    locationRetryCount = 0
    result?(FlutterError(code: "LOCATION_FAILED", message: error.localizedDescription, details: nil))
  }

  private func startLocationUpdates() {
    guard pendingLocationResult != nil else { return }
    locationTimeoutWorkItem?.cancel()
    let timeout = DispatchWorkItem { [weak self] in
      guard let self, self.pendingLocationResult != nil else { return }
      self.locationManager.stopUpdatingLocation()
      if let cached = self.locationManager.location {
        let result = self.pendingLocationResult
        self.pendingLocationResult = nil
        self.locationRetryCount = 0
        self.locationTimeoutWorkItem = nil
        result?([
          "lat": cached.coordinate.latitude,
          "lng": cached.coordinate.longitude
        ])
      } else {
        let result = self.pendingLocationResult
        self.pendingLocationResult = nil
        self.locationRetryCount = 0
        self.locationTimeoutWorkItem = nil
        result?(FlutterError(code: "LOCATION_TIMEOUT", message: "location request timed out", details: nil))
      }
    }
    locationTimeoutWorkItem = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)
    locationManager.startUpdatingLocation()
  }

  private func replyWithRecentLocation() -> Bool {
    guard let location = locationManager.location,
          location.horizontalAccuracy >= 0,
          Date().timeIntervalSince(location.timestamp) <= 300,
          let result = pendingLocationResult
    else { return false }
    pendingLocationResult = nil
    locationRetryCount = 0
    result([
      "lat": location.coordinate.latitude,
      "lng": location.coordinate.longitude
    ])
    return true
  }
}
