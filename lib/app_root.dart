import 'package:flutter/material.dart';

import 'flow/loading_screen.dart';
import 'theme/palette.dart';

/// Root application widget. Boots into the original loading curtain, which then
/// hands off to the home hub.
class TowerBuildingApp extends StatelessWidget {
  const TowerBuildingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Building',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Hue.noon,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Hue.ember,
          brightness: Brightness.light,
        ),
        sliderTheme: const SliderThemeData(
          trackHeight: 4,
          overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
