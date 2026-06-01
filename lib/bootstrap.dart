import 'package:flutter/material.dart';

import 'core_gate/config/core_config.dart';
import 'core_gate/infra/alert_relay.dart';
import 'core_gate/infra/connectivity_probe.dart';
import 'core_gate/infra/core_dispatch.dart';
import 'core_gate/infra/data_vault.dart';
import 'core_gate/infra/install_signal.dart';
import 'core_gate/pages/load_gate.dart';

class TowerGateApp extends StatelessWidget {
  final DataVault vault;
  final ConnectivityProbe probe;
  final InstallSignal signal;
  final CoreDispatch dispatch;
  final AlertRelay alerts;
  final bool gateEnabled;

  const TowerGateApp({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.alerts,
    required this.gateEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final Widget home = gateEnabled
        ? LoadGate(
            vault: vault,
            probe: probe,
            signal: signal,
            dispatch: dispatch,
            alerts: alerts,
          )
        : const Scaffold(backgroundColor: Colors.black);

    return MaterialApp(
      title: CoreConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC233),
          brightness: Brightness.dark,
        ),
      ),
      home: home,
    );
  }
}
