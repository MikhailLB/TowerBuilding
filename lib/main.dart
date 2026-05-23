import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'core_gate/config/core_endpoint.dart';
import 'core_gate/config/tracking_keys.dart';
import 'core_gate/infra/alert_relay.dart';
import 'core_gate/infra/connectivity_probe.dart';
import 'core_gate/infra/core_dispatch.dart';
import 'core_gate/infra/data_vault.dart';
import 'core_gate/infra/install_signal.dart';
import 'core_gate/infra/secure_client.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';

late final GameProgress progress;

Future<void> _bootFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (err) {
    debugPrint('[TB.BOOT] Firebase skipped: $err');
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (err) {
    debugPrint('[TB.BOOT] AppCheck skipped: $err');
  }
}

Future<void> main() async {
  final sw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ── White-part game init ───────────────────────────────────
  final storage = await StorageService.create();
  progress = GameProgress(storage);
  await AudioService.init(progress);

  // ── Gray gate init — Firebase + UA warmup + vault in parallel
  final firebaseFuture = _bootFirebase();
  final agentFuture    = secureClient.warmup();
  final vault          = DataVault();
  final vaultFuture    = vault.init().catchError((err) {
    debugPrint('[TB.BOOT] vault init failed: $err');
  });

  await firebaseFuture;
  debugPrint('[TB.BOOT] firebase ready ${sw.elapsedMilliseconds}ms');
  await Future.wait([agentFuture, vaultFuture]);
  debugPrint('[TB.BOOT] agent+vault ready ${sw.elapsedMilliseconds}ms');

  final probe    = ConnectivityProbe();
  final signal   = InstallSignal();
  final dispatch = CoreDispatch(vault);
  final alerts   = AlertRelay(vault);

  // Pre-fire push bootstrap so APNs poll overlaps with first-frame render
  unawaited(alerts.bootstrap().catchError((err) {
    debugPrint('[TB.BOOT] alerts pre-fire: $err');
  }));

  final gateEnabled =
      coreEndpointUrl().isNotEmpty || trackingDevKey().isNotEmpty;

  debugPrint('[TB.BOOT] gateEnabled=$gateEnabled  ${sw.elapsedMilliseconds}ms');

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(TowerGateApp(
    vault: vault,
    probe: probe,
    signal: signal,
    dispatch: dispatch,
    alerts: alerts,
    gateEnabled: gateEnabled,
  ));
}
