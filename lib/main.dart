import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'core/player_state.dart';
import 'core/save_store.dart';
import 'core/sound_desk.dart';
import 'core_gate/config/core_endpoint.dart';
import 'core_gate/config/tracking_keys.dart';
import 'core_gate/infra/alert_relay.dart';
import 'core_gate/infra/connectivity_probe.dart';
import 'core_gate/infra/core_dispatch.dart';
import 'core_gate/infra/data_vault.dart';
import 'core_gate/infra/install_signal.dart';
import 'core_gate/infra/secure_client.dart';

/// Global player state — available to all white-layer screens after [main].
late final PlayerState player;

Future<void> _bootFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (err) {
    if (kDebugMode) debugPrint('[HV.boot] Firebase skipped: $err');
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
    if (kDebugMode) debugPrint('[HV.boot] AppCheck skipped: $err');
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

  // ── White-layer init ──────────────────────────────────────────
  final store = await SaveStore.open();
  player = PlayerState(store);

  unawaited(SoundDesk.boot(player).catchError((err) {
    if (kDebugMode) debugPrint('[HV.boot] audio failed: $err');
  }));

  // ── Gray gate init — Firebase + UA warmup + vault in parallel ─
  final firebaseFuture = _bootFirebase();
  final agentFuture    = secureClient.warmup();
  final vault          = DataVault();
  final vaultFuture    = vault.init().catchError((err) {
    if (kDebugMode) debugPrint('[HV.boot] vault init failed: $err');
  });

  await firebaseFuture;
  await Future.wait([agentFuture, vaultFuture]);
  if (kDebugMode) debugPrint('[HV.boot] ready ${sw.elapsedMilliseconds}ms');

  final probe    = ConnectivityProbe();
  final signal   = InstallSignal();
  final dispatch = CoreDispatch(vault);
  final alerts   = AlertRelay(vault);

  unawaited(alerts.bootstrap().catchError((err) {
    if (kDebugMode) debugPrint('[HV.boot] alerts error: $err');
  }));
  unawaited(signal.warmup().catchError((err) {
    if (kDebugMode) debugPrint('[HV.boot] signal error: $err');
  }));

  final gateEnabled =
      coreEndpointUrl().isNotEmpty || trackingDevKey().isNotEmpty;

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
