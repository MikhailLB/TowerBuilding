import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_store.dart';
import 'http_layer.dart';

const String pushChannelId = 'tbld_notify_ch';
const String pushChannelLabel = 'App Updates';
const String pushIconRes = '@drawable/ic_pulse_notification';

@pragma('vm:entry-point')
Future<void> _pushBgHandler(RemoteMessage _) async {}

class NotifyManager {
  final FlutterLocalNotificationsPlugin _tray =
      FlutterLocalNotificationsPlugin();
  final LocalStore _cache;
  FirebaseMessaging? _messaging;
  String? _token;
  bool _ready = false;
  Future<bool>? _consentInFlight;

  void Function(String url)? onPushDestination;
  void Function(String token)? onTokenRotated;

  NotifyManager(this._cache);

  String? get token => _token;
  bool get ready => _ready;

  Future<void> bootstrap() async {
    if (_ready) return;
    try {
      try {
        await Firebase.initializeApp();
      } catch (err) {
        if (kDebugMode) {
          debugPrint('[NTF] Firebase init skipped: $err');
        }
        return;
      }

      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_pushBgHandler);

      await _setupTray();

      try {
        _token = await _messaging!.getToken();
      } catch (err) {
        if (kDebugMode) debugPrint('[NTF] getToken failed: $err');
      }

      _messaging!.onTokenRefresh.listen((fresh) {
        _token = fresh;
        onTokenRotated?.call(fresh);
      });

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onTapInBackground);

      final cold = await _messaging!.getInitialMessage();
      if (cold != null) _onColdStart(cold);

      _ready = true;
      if (kDebugMode) {
        debugPrint(
          '[NTF] bootstrap OK, token=${_token == null ? 'null' : '${_token!.substring(0, _token!.length.clamp(0, 12))}…'}',
        );
      }
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[NTF] bootstrap failed: $err');
        debugPrint('$st');
      }
    }
  }

  Future<void> _setupTray() async {
    const androidInit = AndroidInitializationSettings(pushIconRes);
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _tray.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map && decoded['url'] is String) {
            final url = decoded['url'] as String;
            if (url.isNotEmpty) onPushDestination?.call(url);
          }
        } catch (_) {}
      },
    );

    if (Platform.isAndroid) {
      final impl = _tray.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          pushChannelId,
          pushChannelLabel,
          description: 'Real-time updates and offers.',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<bool> askConsent() async {
    if (_messaging == null) {
      if (kDebugMode) {
        debugPrint('[NTF] askConsent skipped — Firebase missing');
      }
      return false;
    }
    final pending = _consentInFlight;
    if (pending != null) return pending;

    final flow = _askConsentImpl();
    _consentInFlight = flow;
    try {
      return await flow;
    } finally {
      _consentInFlight = null;
    }
  }

  Future<bool> _askConsentImpl() async {
    try {
      if (Platform.isAndroid) {
        return await _consentAndroid();
      }
      return await _consentIos();
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[NTF] consent error: $err');
        debugPrint('$st');
      }
      return false;
    }
  }

  static const int _systemDeniedCooldownSeconds = 365 * 24 * 3600;

  Future<void> _markSystemDenied() async {
    await _cache.writePushConsent(false);
    await _cache.writePushCooldownUntil(
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
          _systemDeniedCooldownSeconds,
    );
  }

  Future<bool> _consentAndroid() async {
    final impl = _tray.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) {
      return _consentIos();
    }
    final already = await impl.areNotificationsEnabled();
    if (already == true) {
      await _cache.writePushConsent(true);
      return true;
    }
    final granted = await impl.requestNotificationsPermission();
    if (granted == true) {
      await _cache.writePushConsent(true);
      return true;
    }
    await _markSystemDenied();
    return false;
  }

  Future<bool> _consentIos() async {
    final settings = await _messaging!.getNotificationSettings();
    final status = settings.authorizationStatus;

    if (status == AuthorizationStatus.denied) {
      await _markSystemDenied();
      return false;
    }

    if (status != AuthorizationStatus.notDetermined) {
      final ok = status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      await _cache.writePushConsent(ok);
      return ok;
    }

    final result = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final ok = result.authorizationStatus == AuthorizationStatus.authorized ||
        result.authorizationStatus == AuthorizationStatus.provisional;
    if (!ok && result.authorizationStatus == AuthorizationStatus.denied) {
      await _markSystemDenied();
      return false;
    }
    await _cache.writePushConsent(ok);
    return ok;
  }

  Future<bool> shouldOfferConsent() async {
    final m = _messaging;
    if (m == null) return false;
    try {
      if (Platform.isAndroid) {
        final impl = _tray.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (impl == null) return true;
        final enabled = await impl.areNotificationsEnabled();
        return enabled != true;
      }
      final settings = await m.getNotificationSettings();
      final status = settings.authorizationStatus;
      if (status == AuthorizationStatus.notDetermined) return true;
      if (status == AuthorizationStatus.denied) {
        await _markSystemDenied();
      }
      return false;
    } catch (err) {
      if (kDebugMode) debugPrint('[NTF] shouldOfferConsent error: $err');
      return false;
    }
  }

  void _onForeground(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    String? imageUrl;
    if (Platform.isAndroid) {
      imageUrl = notif.android?.imageUrl;
    } else {
      imageUrl = notif.apple?.imageUrl;
    }

    AndroidNotificationDetails? androidDetails;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final bytes = await _downloadImage(imageUrl);
      if (bytes != null) {
        androidDetails = AndroidNotificationDetails(
          pushChannelId,
          pushChannelLabel,
          importance: Importance.high,
          priority: Priority.high,
          icon: pushIconRes,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon:
                const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }

    androidDetails ??= const AndroidNotificationDetails(
      pushChannelId,
      pushChannelLabel,
      importance: Importance.high,
      priority: Priority.high,
      icon: pushIconRes,
    );

    final payload =
        message.data.isNotEmpty ? jsonEncode(message.data) : null;

    await _tray.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _onColdStart(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      _cache.stashOneShotPush(url);
    }
  }

  void _onTapInBackground(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      onPushDestination?.call(url);
    }
  }

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }
}
