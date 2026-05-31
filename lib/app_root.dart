import 'package:flutter/material.dart';

import 'flow/loading_screen.dart';
import 'theme/palette.dart';

/// Root application widget. Boots into the (unchanged) loading curtain, which
/// then hands off to the home screen.
class HollowValeApp extends StatelessWidget {
  const HollowValeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Village Puzzles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Hue.noon,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Hue.ember,
          brightness: Brightness.light,
        ),
        fontFamily: null,
      ),
      home: const LoadingScreen(),
    );
  }
}
