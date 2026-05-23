import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/core_config.dart';
import '../config/core_endpoint.dart';
import 'secure_client.dart';

/// AppsFlyer SDK wrapper. Provides conversion and deep-link payloads
/// for the core dispatch payload.
class InstallSignal {
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _conversion;
  Map<String, dynamic>? _deepLink;
  Map<String, dynamic>? _reopen;

  final Completer<Map<String, dynamic>> _conversionDone = Completer();
  final Completer<void> _deepLinkDone = Completer();

  bool _started = false;
  Future<void>? _warmupFuture;

  bool get started => _started;

  Future<void> warmup() => _warmupFuture ??= _doWarmup();

  Future<void> _doWarmup() async {
    if (_started) return;
    final devKey = CoreConfig.installKey;
    debugPrint('[TB.IS] warmup devKeyLen=${devKey.length}');
    if (devKey.isEmpty) {
      _started = true;
      if (!_conversionDone.isCompleted) _conversionDone.complete({});
      if (!_deepLinkDone.isCompleted) _deepLinkDone.complete();
      return;
    }
    _started = true;
    try {
      if (Platform.isIOS) await _requestAtt();
      final opts = AppsFlyerOptions(
        afDevKey: devKey,
        appId: CoreConfig.analyticsAppId,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 4,
      );
      _sdk = AppsflyerSdk(opts);
      _sdk!.onInstallConversionData(_onConversion);
      _sdk!.onAppOpenAttribution(_onReopen);
      _sdk!.onDeepLinking(_onDeepLink);
      await _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
      debugPrint('[TB.IS] initSdk OK');
      _armCallbackFallbacks();
    } catch (err, st) {
      debugPrint('[TB.IS] warmup error: $err\n$st');
      if (!_conversionDone.isCompleted) _conversionDone.complete({});
      if (!_deepLinkDone.isCompleted) _deepLinkDone.complete();
    }
  }

  Future<void> _requestAtt() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('[TB.IS] ATT status=$status');
      if (status != TrackingStatus.notDetermined) return;
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));
      final after = await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('[TB.IS] ATT after prompt=$after');
    } catch (err) {
      debugPrint('[TB.IS] ATT skipped: $err');
    }
  }

  Map<String, dynamic> _flatten(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    final inner = m['payload'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return m;
  }

  void _onConversion(dynamic raw) async {
    final data = _flatten(raw);
    debugPrint('[TB.IS] conversion ${jsonEncode(data)}');
    if (data['af_status'] == 'Organic') {
      await Future.delayed(Duration(seconds: CoreConfig.organicRetrySeconds));
      final retry = await _refetchGcd();
      _conversion = retry ?? data;
    } else {
      _conversion = data;
    }
    if (!_conversionDone.isCompleted) _conversionDone.complete(_conversion);
  }

  void _onReopen(dynamic raw) => _reopen = _flatten(raw);

  void _onDeepLink(DeepLinkResult r) {
    if (r.deepLink != null) _deepLink = r.deepLink!.clickEvent;
    if (!_deepLinkDone.isCompleted) _deepLinkDone.complete();
  }

  Future<Map<String, dynamic>?> _refetchGcd() async {
    try {
      final id = await deviceId();
      if (id == null) return null;
      final appId = Platform.isIOS ? CoreConfig.analyticsAppId : CoreConfig.bundleId;
      final url = gcdEndpointUrl(appId, id);
      if (url.isEmpty) return null;
      final resp = await secureClient.get(
        Uri.parse(url),
        headers: {'authorization': 'Bearer ${CoreConfig.installKey}'},
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) return d;
      }
    } catch (_) {}
    return null;
  }

  void _armCallbackFallbacks() {
    // On returning launches AppsFlyer often skips conversion/deep-link callbacks.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!_conversionDone.isCompleted) {
        _conversionDone.complete(_conversion ?? <String, dynamic>{});
      }
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!_deepLinkDone.isCompleted) _deepLinkDone.complete();
    });
  }

  Future<Map<String, dynamic>> awaitConversion({
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _conversionDone.future.timeout(timeout, onTimeout: () => <String, dynamic>{});

  Future<void> awaitDeepLink({
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _deepLinkDone.future.timeout(timeout, onTimeout: () {});

  Future<String?> deviceId() async {
    if (_sdk == null) return null;
    try { return await _sdk!.getAppsFlyerUID(); } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> buildPayload({
    required String locale,
    String? pushToken,
  }) async {
    final payload = <String, dynamic>{};
    if (_conversion != null) payload.addAll(_conversion!);
    if (_deepLink != null) {
      _deepLink!.forEach((k, v) => payload.putIfAbsent(k, () => v));
    }
    if (_reopen != null) {
      _reopen!.forEach((k, v) => payload.putIfAbsent(k, () => v));
    }

    final id = await deviceId();
    if (id != null && id.isNotEmpty) {
      payload['af_id'] = id;
    } else {
      payload.putIfAbsent('af_id', () => '');
    }

    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.authorized) {
          final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
          if (idfa.isNotEmpty && !idfa.startsWith('00000000-')) {
            payload.putIfAbsent('sub_id_10', () => idfa);
          }
        }
      } catch (_) {}
    }

    payload['bundle_id'] = CoreConfig.bundleId;
    payload['store_id']  = CoreConfig.platformStoreId;
    payload['os']        = Platform.isAndroid ? 'Android' : 'iOS';
    payload['locale']    = locale;
    if (pushToken != null && pushToken.isNotEmpty) {
      payload['push_token'] = pushToken;
    }
    if (CoreConfig.firebaseNumber.isNotEmpty) {
      payload['firebase_project_id'] = CoreConfig.firebaseNumber;
    }

    debugPrint('[TB.IS] payload keys=${payload.keys.toList()}');
    return payload;
  }
}
