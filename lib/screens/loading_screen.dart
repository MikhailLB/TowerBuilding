import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../ui/resource_paths.dart';
import 'main_menu_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _barDuration = Duration(milliseconds: 4500);
  static const Duration _minSplashDuration = Duration(milliseconds: 6000);

  VideoPlayerController? _video;
  Orientation? _videoOrientation;
  bool _videoLoading = false;
  bool _videoFailed = false;

  late final AnimationController _progress;
  bool _progressStarted = false;
  bool _assetsPreloadStarted = false;
  DateTime? _splashStart;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _progress = AnimationController(
      vsync: this,
      duration: _barDuration,
    )
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _maybeGoNext();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (!_videoLoading && _videoOrientation != orientation) {
      _loadVideo(orientation);
    }
  }

  Future<void> _loadVideo(Orientation orientation) async {
    _videoLoading = true;
    final path = orientation == Orientation.landscape
        ? ResourcePaths.loadingVideoLandscape
        : ResourcePaths.loadingVideoPortrait;

    final previous = _video;
    final controller = VideoPlayerController.asset(path);
    try {
      await controller.initialize().timeout(const Duration(seconds: 6));
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _videoOrientation = orientation;
        _videoFailed = false;
      });
      await previous?.dispose();
      _startProgressIfNeeded();
      _startPreloadIfNeeded();
    } catch (e, st) {
      debugPrint('Loading video failed ($path): $e\n$st');
      await controller.dispose();
      if (mounted) {
        setState(() {
          _videoOrientation = orientation;
          _videoFailed = true;
        });
      }
      _startProgressIfNeeded();
      _startPreloadIfNeeded();
    } finally {
      _videoLoading = false;
    }
  }

  void _startProgressIfNeeded() {
    if (_progressStarted) return;
    _progressStarted = true;
    _splashStart = DateTime.now();
    _progress.forward();
  }

  void _startPreloadIfNeeded() {
    if (_assetsPreloadStarted) return;
    _assetsPreloadStarted = true;
    unawaited(_preloadGameAssets());
  }

  Future<void> _preloadGameAssets() async {
    Flame.images.prefix = '';
    final paths = <String>[
      ResourcePaths.sky,
      ResourcePaths.ground,
      ResourcePaths.cloud,
      ResourcePaths.hook,
      ResourcePaths.startBg,
      ResourcePaths.startBuilding,
      ResourcePaths.logo,
      ResourcePaths.logoName,
      ...ResourcePaths.allBlocks,
      for (var i = 1; i <= 4; i++) ResourcePaths.loadingBar(i),
    ];
    for (final p in paths) {
      try {
        await Flame.images.load(p);
      } catch (e) {
        debugPrint('LoadingScreen: failed to preload $p: $e');
      }
    }
    try {
      GoogleFonts.bangers();
      GoogleFonts.fredoka();
      await GoogleFonts.pendingFonts(<TextStyle>[
        GoogleFonts.bangers(),
        GoogleFonts.fredoka(),
      ]);
    } catch (e) {
      debugPrint('LoadingScreen: Google Fonts preload failed: $e');
    }
  }

  void _maybeGoNext() {
    if (_navigated) return;
    if (_progress.status != AnimationStatus.completed) return;
    final start = _splashStart;
    if (start != null) {
      final remaining = _minSplashDuration - DateTime.now().difference(start);
      if (remaining > Duration.zero) {
        Future.delayed(remaining, _maybeGoNext);
        return;
      }
    }
    _goNext();
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) =>
            const MainMenuScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _video?.dispose();
    _progress.dispose();
    super.dispose();
  }

  Widget _buildVideoBackground() {
    final video = _video;
    final videoReady = video != null && video.value.isInitialized;
    if (videoReady) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }
    return const ColoredBox(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final video = _video;
    final videoReady = video != null && video.value.isInitialized;
    final screenReady = videoReady || _videoFailed;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildVideoBackground()),
          Positioned(
            left: 0,
            right: 0,
            bottom: isPortrait ? 6 : 2,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: screenReady ? 1.0 : 0.0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      final state = (_progress.value * 4)
                          .clamp(0.0, 4.0)
                          .floor()
                          .clamp(1, 4);
                      return _LoadingBar(
                        state: state,
                        isPortrait: isPortrait,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.state, required this.isPortrait});

  final int state;
  final bool isPortrait;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = isPortrait ? size.width * 0.7 : size.height * 0.4;
    return Image.asset(
      ResourcePaths.loadingBar(state),
      width: width,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}
