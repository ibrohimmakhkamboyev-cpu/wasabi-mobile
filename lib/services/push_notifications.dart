import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'native_bridge.dart';

typedef PushTokenCallback = Future<void> Function(
  String token,
  String platform,
  String installationId,
);
typedef PushMessageCallback = Future<void> Function(RemoteMessage message);

const _installationIdKey = 'wasabi_push_installation_id_v1';
const _maxPushImageBytes = 1500000;

const _androidChannel = AndroidNotificationChannel(
  'wasabi_orders',
  'Wasabi orders',
  description: 'Order updates and Wasabi notifications',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase background init failed: $error');
  }
  _logPushMessage('background', message);
}

@pragma('vm:entry-point')
void localNotificationBackgroundTapHandler(NotificationResponse response) {
  debugPrint('Notification background tap payload=${response.payload}');
}

class PushNotifications {
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _localNotificationsReady = false;
  String? _installationId;
  Future<void>? _configurationFuture;
  PushMessageCallback? _onMessage;

  Future<void> ensureConfigured({
    required PushTokenCallback onToken,
    PushMessageCallback? onMessage,
  }) async {
    _onMessage = onMessage;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final installationId = await _getOrCreateInstallationId();

    if (!_initialized) {
      final configuration =
          _configurationFuture ??= _configureOnce(onToken, installationId);
      await configuration;
      if (!_initialized) {
        _configurationFuture = null;
        return;
      }
    }
    if (!_firebaseReady) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      if (!await _waitForApnsToken(messaging)) return;
    }

    final token = await messaging.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _forwardToken(token, installationId, onToken);
  }

  Future<void> _configureOnce(
    PushTokenCallback onToken,
    String installationId,
  ) async {
    await _configureLocalNotifications();
    _firebaseReady = await _initializeFirebase();
    if (!_firebaseReady) return;
    _configureMessageHandlers(onToken, installationId);
    _initialized = true;
  }

  Future<bool> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      final token = await messaging.getAPNSToken();
      if (token != null && token.trim().isNotEmpty) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('APNs token was not available; push registration will retry.');
    return false;
  }

  Future<void> _forwardToken(
    String token,
    String installationId,
    PushTokenCallback onToken,
  ) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await onToken(token, platform, installationId);
    } catch (error, stackTrace) {
      debugPrint('Could not register push token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Firebase init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _configureLocalNotifications() async {
    if (_localNotificationsReady) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          localNotificationBackgroundTapHandler,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _localNotificationsReady = true;
  }

  void _configureMessageHandlers(
    PushTokenCallback onToken,
    String installationId,
  ) {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_forwardToken(token, installationId, onToken));
    });

    FirebaseMessaging.onMessage.listen((message) {
      _logPushMessage('foreground', message);
      unawaited(_showForegroundNotification(message));
      unawaited(_handleIncomingMessage(message));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRemoteNotificationTap('background_tap', message);
      unawaited(_handleIncomingMessage(message));
    });

    unawaited(FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      _handleRemoteNotificationTap('terminated_tap', message);
      unawaited(_handleIncomingMessage(message));
    }));
  }

  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    if (readPushString(message.data['type']) != 'mailing') return;
    try {
      await _onMessage?.call(message);
    } catch (error) {
      debugPrint('Could not refresh mailings after push: $error');
    }
  }

  Future<String> _getOrCreateInstallationId() async {
    final cached = _installationId;
    if (cached != null) return cached;

    final stored = (await NativeBridge.getString(_installationIdKey))?.trim();
    if (stored != null && RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(stored)) {
      _installationId = stored;
      return stored;
    }

    final random = Random.secure();
    final generated = List<int>.generate(24, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    await NativeBridge.setString(_installationIdKey, generated);
    _installationId = generated;
    return generated;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_localNotificationsReady) return;
    final notification = message.notification;
    final title = notification?.title ?? readPushString(message.data['title']);
    final body = notification?.body ?? readPushString(message.data['body']);
    if (title.isEmpty && body.isEmpty) return;

    final imageUrl = notification?.android?.imageUrl ??
        notification?.apple?.imageUrl ??
        readPushString(message.data['imageUrl']);
    await _localNotifications.show(
      id: _notificationId(message),
      title: title.isEmpty ? 'Wasabi' : title,
      body: body,
      notificationDetails: await _detailsForPush(imageUrl),
      payload: jsonEncode(message.data),
    );
  }

  Future<NotificationDetails> _detailsForPush(String imageUrl) async {
    Uint8List? imageBytes;
    String? attachmentPath;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      try {
        imageBytes = await _downloadPushImage(Uri.parse(imageUrl));
        if (Platform.isIOS && imageBytes != null && imageBytes.isNotEmpty) {
          final file = File(
            '${Directory.systemTemp.path}/wasabi-push-${DateTime.now().microsecondsSinceEpoch}.jpg',
          );
          await file.writeAsBytes(imageBytes, flush: true);
          attachmentPath = file.path;
        }
      } catch (_) {
        // A failed image must never stop delivery of the text notification.
      }
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'wasabi_orders',
        'Wasabi orders',
        channelDescription: 'Order updates and Wasabi notifications',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: imageBytes == null || imageBytes.isEmpty
            ? null
            : BigPictureStyleInformation(
                ByteArrayAndroidBitmap(imageBytes),
                hideExpandedLargeIcon: true,
              ),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: attachmentPath == null
            ? null
            : [DarwinNotificationAttachment(attachmentPath)],
      ),
    );
  }

  Future<Uint8List?> _downloadPushImage(Uri uri) async {
    final response = await http.Request('GET', uri)
        .send()
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    if (response.contentLength != null &&
        response.contentLength! > _maxPushImageBytes) {
      return null;
    }

    final bytes = BytesBuilder(copy: false);
    var size = 0;
    await for (final chunk in response.stream) {
      size += chunk.length;
      if (size > _maxPushImageBytes) return null;
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  int _notificationId(RemoteMessage message) {
    final sentAt = message.sentTime?.millisecondsSinceEpoch;
    if (sentAt != null) return sentAt.remainder(1 << 31);
    return (message.messageId ?? jsonEncode(message.data)).hashCode &
        0x7fffffff;
  }
}

void _handleLocalNotificationTap(NotificationResponse response) {
  debugPrint('Notification tap payload=${response.payload}');
}

void _handleRemoteNotificationTap(String source, RemoteMessage message) {
  _logPushMessage(source, message);
}

void _logPushMessage(String source, RemoteMessage message) {
  debugPrint(
    'Push message source=$source id=${message.messageId} data=${message.data}',
  );
}

String readPushString(Object? value) => value?.toString().trim() ?? '';
