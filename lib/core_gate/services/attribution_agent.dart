import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../config/analytics_config.dart';
import 'tower_client.dart';

class AttributionAgent {
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _attributionData;
  Map<String, dynamic>? _deepLinkData;
  Map<String, dynamic>? _appOpenData;

  final Completer<Map<String, dynamic>> _attrCompleter = Completer();
  final Completer<void> _deepLinkCompleter = Completer();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final opts = AppsFlyerOptions(
        afDevKey: AppConfig.analyticsKey,
        appId: AppConfig.analyticsAppId,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 10,
      );
      _sdk = AppsflyerSdk(opts);

      _sdk!.onInstallConversionData(_onConversion);
      _sdk!.onAppOpenAttribution(_onAppOpen);
      _sdk!.onDeepLinking(_onDeepLink);

      await _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      if (kDebugMode) debugPrint('[AG] initSdk OK');
    } catch (err, st) {
      if (kDebugMode) debugPrint('[AG] init error: $err\n$st');
      if (!_attrCompleter.isCompleted) _attrCompleter.complete({});
      if (!_deepLinkCompleter.isCompleted) _deepLinkCompleter.complete();
    }
  }

  void _onConversion(dynamic raw) async {
    final data = _flattenPayload(raw);
    if (kDebugMode) debugPrint('[AG] onConversion: ${jsonEncode(data)}');

    if (data['af_status'] == 'Organic') {
      await Future.delayed(Duration(seconds: AppConfig.gcdRetrySeconds));
      final retry = await _retryViaGcd();
      _attributionData = retry ?? data;
    } else {
      _attributionData = data;
    }
    if (!_attrCompleter.isCompleted) _attrCompleter.complete(_attributionData);
  }

  void _onAppOpen(dynamic raw) {
    _appOpenData = _flattenPayload(raw);
  }

  void _onDeepLink(DeepLinkResult result) {
    if (result.deepLink != null) {
      _deepLinkData = result.deepLink!.clickEvent;
    }
    if (!_deepLinkCompleter.isCompleted) _deepLinkCompleter.complete();
  }

  Map<String, dynamic> _flattenPayload(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    final inner = m['payload'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return m;
  }

  Future<Map<String, dynamic>?> _retryViaGcd() async {
    try {
      final uid = await getUid();
      if (uid == null) return null;
      final appId = Platform.isIOS ? AppConfig.analyticsAppId : AppConfig.bundleId;
      final url = resolveGcdEndpoint(appId, uid);
      if (url.isEmpty) return null;
      final resp = await towerHttpClient
          .get(Uri.parse(url), headers: {'authorization': 'Bearer ${AppConfig.analyticsKey}'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) {
          if (kDebugMode) debugPrint('[AG] GCD retry data: ${jsonEncode(d)}');
          return d;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> waitForAttribution({Duration timeout = const Duration(seconds: 30)}) =>
      _attrCompleter.future.timeout(timeout, onTimeout: () => <String, dynamic>{});

  Future<void> waitForDeepLink({Duration timeout = const Duration(seconds: 5)}) =>
      _deepLinkCompleter.future.timeout(timeout, onTimeout: () {});

  Future<String?> getUid() async {
    if (_sdk == null) return null;
    try { return await _sdk!.getAppsFlyerUID(); } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> buildPayload({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};

    if (_attributionData != null) body.addAll(_attributionData!);
    _deepLinkData?.forEach((k, v) => body.putIfAbsent(k, () => v));
    _appOpenData?.forEach((k, v) => body.putIfAbsent(k, () => v));

    body['af_id']    = await getUid() ?? '';
    body['bundle_id'] = AppConfig.bundleId;
    body['os']       = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id'] = AppConfig.storeId;
    body['locale']   = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    if (AppConfig.messagingProject.isNotEmpty) {
      body['firebase_project_id'] = AppConfig.messagingProject;
    }

    if (kDebugMode) debugPrint('[AG] payload: ${jsonEncode(body)}');
    return body;
  }
}
