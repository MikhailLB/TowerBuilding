import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_root.dart';
import 'core/player_state.dart';
import 'core/save_store.dart';
import 'core/sound_desk.dart';

/// Global player state, available to every screen once [main] has run.
late final PlayerState player;

Future<void> main() async {
  runZonedGuarded(_boot, (error, stack) {
    debugPrint('BOOT FATAL: $error\n$stack');
    runApp(_BootErrorApp(message: '$error'));
  });
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
  };
  debugPrint('BOOT: start');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  debugPrint('BOOT: orientation set');

  final store = await SaveStore.open();
  player = PlayerState(store);
  debugPrint('BOOT: store opened');

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  debugPrint('BOOT: runApp');
  runApp(const HollowValeApp());

  // Audio is brought up after the first frame so a stalled native audio
  // session can never block the UI.
  unawaited(_bootAudio());
}

Future<void> _bootAudio() async {
  try {
    await SoundDesk.boot(player);
    debugPrint('BOOT: audio ready');
  } catch (e) {
    debugPrint('BOOT: audio boot failed: $e');
  }
}

/// Last-resort screen shown if startup throws before the app can mount. Avoids
/// a silent black screen and surfaces the actual error.
class _BootErrorApp extends StatelessWidget {
  const _BootErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF2E2014),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              'Startup error:\n\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
