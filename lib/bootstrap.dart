import 'package:flutter/material.dart';

import 'screens/loading_screen.dart';
import 'ui/visual_tokens.dart';

class TowerApp extends StatelessWidget {
  const TowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TowerBuilding: Stack & Balance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.sky,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
