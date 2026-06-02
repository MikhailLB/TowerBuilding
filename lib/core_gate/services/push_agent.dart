import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'tower_client.dart';
import 'vault.dart';

@pragma('vm:entry-point')
Future<void> _bgMessageHandler(RemoteMessage message) async {}

class PushAgent {
  final FlutterLocalNotificationsPlugin _localNf =
      FlutterLocalNotificationsPlugin();
  final Vault _vault;
  FirebaseMessaging? _messaging;
  String? _token;
  bool _initialized = false;

  Function(String url)? onNotificationUrl;
  Function(String token)? onTokenRefresh;

  PushAgent(this._vault);

  String? get token => _token;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_bgMessageHandler);
      await _initLocalNotifications();
      _token = await _messaging!.getToken();
      _messaging!.onTokenRefresh.listen((t) {
        _token = t;
        onTokenRefresh?.call(t);
      });
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onWarmTap);
      final initial = await _messaging!.getInitialMessage();
      if (initial != null) _onColdTap(initial);
      _initialized = true;
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_pulse_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNf.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        if (resp.payload == null) return;
        try {
          final data = jsonDecode(resp.payload!) as Map<String, dynamic>;
          final url = data['url'] as String?;
          if (url != null && url.isNotEmpty) onNotificationUrl?.call(url);
        } catch (_) {}
      },
    );
    if (Platform.isAndroid) {
      final plugin = _localNf.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(const AndroidNotificationChannel(
        'tbld_notify_ch',
        'Tower Building Notifications',
        description: 'Push notifications',
        importance: Importance.high,
      ));
    }
  }

  Future<bool> requestPermission() async {
    if (_messaging == null) return false;
    final settings = await _messaging!.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    await _vault.setNfGranted(granted);
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      await _vault.setNfOsDenied();
    }
    return granted;
  }

  void _onForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || !Platform.isAndroid) return;
    final imgUrl = message.notification?.android?.imageUrl;
    AndroidNotificationDetails? details;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      final bytes = await _downloadImage(imgUrl);
      if (bytes != null) {
        details = AndroidNotificationDetails(
          'tbld_notify_ch', 'Tower Building Notifications',
          importance: Importance.high, priority: Priority.high,
          icon: '@drawable/ic_pulse_notification',
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }
    details ??= const AndroidNotificationDetails(
      'tbld_notify_ch', 'Tower Building Notifications',
      importance: Importance.high, priority: Priority.high,
      icon: '@drawable/ic_pulse_notification',
    );
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
    await _localNf.show(
      notification.hashCode, notification.title, notification.body,
      NotificationDetails(android: details), payload: payload,
    );
  }

  void _onColdTap(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) _vault.setPushUrl(url);
  }

  void _onWarmTap(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) onNotificationUrl?.call(url);
  }

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final resp = await towerHttpClient.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return resp.bodyBytes;
    } catch (_) {}
    return null;
  }
}
