import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core_gate/screens/gate_screen.dart';
import 'core_gate/services/attribution_agent.dart';
import 'core_gate/services/config_fetcher.dart';
import 'core_gate/services/net_probe.dart';
import 'core_gate/services/push_agent.dart';
import 'core_gate/services/tower_client.dart';
import 'core_gate/services/vault.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';
import 'ui/visual_tokens.dart';

late final GameProgress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init (optional — app works without it)
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (_) {}

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // HTTP client with real device User-Agent
  await towerHttpClient.init();

  // Game services
  final gameStorage = await StorageService.create();
  progress = GameProgress(gameStorage);
  await AudioService.init(progress);

  // Gray flow services
  final vault = Vault();
  await vault.init();
  final probe = NetProbe();
  final agent = AttributionAgent();
  final fetcher = ConfigFetcher(vault);
  final pushAgent = PushAgent(vault);

  runApp(TowerBuildingApp(
    vault: vault,
    probe: probe,
    agent: agent,
    fetcher: fetcher,
    pushAgent: pushAgent,
  ));
}

class TowerBuildingApp extends StatelessWidget {
  final Vault vault;
  final NetProbe probe;
  final AttributionAgent agent;
  final ConfigFetcher fetcher;
  final PushAgent pushAgent;

  const TowerBuildingApp({
    super.key,
    required this.vault,
    required this.probe,
    required this.agent,
    required this.fetcher,
    required this.pushAgent,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Building',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.sky,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
      ),
      home: GateScreen(
        vault: vault,
        probe: probe,
        agent: agent,
        fetcher: fetcher,
        pushAgent: pushAgent,
      ),
    );
  }
}
