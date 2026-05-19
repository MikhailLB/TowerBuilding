import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'setup/app_identity.dart';
import 'views/launch_gate.dart';
import 'providers/install_tracker.dart';
import 'providers/net_watcher.dart';
import 'providers/notify_manager.dart';
import 'providers/gateway_client.dart';
import 'providers/local_store.dart';
import 'providers/http_layer.dart';

class BootController {
  final LocalStore cache;
  final NetWatcher radar;
  final InstallTracker install;
  final GatewayClient gate;
  final NotifyManager pulse;
  final bool firebaseReady;

  BootController._({
    required this.cache,
    required this.radar,
    required this.install,
    required this.gate,
    required this.pulse,
    required this.firebaseReady,
  });

  static Future<BootController> prepare() async {
    final firebaseReady = await _bootFirebase();

    await httpClient.warmup();

    final cache = LocalStore();
    try {
      await cache.bootstrap();
    } catch (err) {
      if (kDebugMode) debugPrint('[BootController] LocalStore failed: $err');
    }

    final radar = NetWatcher();
    final install = InstallTracker();
    final gate = GatewayClient(cache);
    final pulse = NotifyManager(cache);

    return BootController._(
      cache: cache,
      radar: radar,
      install: install,
      gate: gate,
      pulse: pulse,
      firebaseReady: firebaseReady,
    );
  }

  Widget buildHome({
    required WidgetBuilder fallbackHomeBuilder,
    SplashFactory? splashBuilder,
  }) {
    if (!AppIdentity.gateEnabled) {
      return Builder(builder: fallbackHomeBuilder);
    }
    return LaunchGate(
      cache: cache,
      radar: radar,
      install: install,
      gate: gate,
      pulse: pulse,
      fallbackHomeBuilder: fallbackHomeBuilder,
      splashBuilder: splashBuilder,
    );
  }

  static Future<bool> _bootFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (err) {
      if (kDebugMode) debugPrint('[BootController] Firebase skipped: $err');
      return false;
    }
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
      );
    } catch (err) {
      if (kDebugMode) debugPrint('[BootController] AppCheck skipped: $err');
    }
    return true;
  }
}
