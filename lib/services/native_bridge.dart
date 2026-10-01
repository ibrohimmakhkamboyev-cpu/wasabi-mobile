import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeBridge {
  NativeBridge._();

  static const _nativeTimeout = Duration(milliseconds: 800);
  static const _channel = MethodChannel('uz.wasabi.mobile/native');
  static final Map<String, String> _memoryStore = {};

  static Future<String?> getString(String key) async {
    try {
      return await _channel.invokeMethod<String>(
          'getString', {'key': key}).timeout(_nativeTimeout);
    } catch (_) {
      return _memoryStore[key];
    }
  }

  static Future<void> setString(String key, String value) async {
    _memoryStore[key] = value;
    try {
      await _channel.invokeMethod<void>('setString', {
        'key': key,
        'value': value,
      });
    } catch (_) {
      // Tests and unsupported platforms use the in-memory fallback.
    }
  }

  static Future<void> remove(String key) async {
    _memoryStore.remove(key);
    try {
      await _channel.invokeMethod<void>('remove', {'key': key});
    } catch (_) {
      // Tests and unsupported platforms use the in-memory fallback.
    }
  }

  static Future<void> openUrl(String url, {bool throwOnFailure = false}) async {
    if (url.trim().isEmpty) return;
    try {
      await _channel.invokeMethod<void>('openUrl', {'url': url});
    } catch (error) {
      if (throwOnFailure) rethrow;
      debugPrint('Could not open external link');
    }
  }

  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'getCurrentLocation',
      );
      final lat = value?['lat'];
      final lng = value?['lng'];
      if (lat is num && lng is num) {
        return {'lat': lat.toDouble(), 'lng': lng.toDouble()};
      }
    } catch (error) {
      debugPrint('Could not get location: $error');
    }
    return null;
  }
}
