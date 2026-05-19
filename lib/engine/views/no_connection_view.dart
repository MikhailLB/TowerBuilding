import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../setup/asset_manifest.dart';
import '../providers/net_watcher.dart';
import 'widgets/retry_btn.dart';

class NoConnectionView extends StatefulWidget {
  final WidgetBuilder retryBuilder;
  final NetWatcher radar;

  const NoConnectionView({
    super.key,
    required this.retryBuilder,
    required this.radar,
  });

  @override
  State<NoConnectionView> createState() => _NoConnectionViewState();
}

class _NoConnectionViewState extends State<NoConnectionView>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _portraitCtl;
  VideoPlayerController? _landscapeCtl;
  VoidCallback? _portraitListener;
  VoidCallback? _landscapeListener;

  bool _videosReady = false;
  bool _busy = false;
  bool _hint = false;
  Timer? _hintTimer;

  late final AnimationController _press;

  static const double _buttonBottom = 40.0;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _initBothVideos();
  }

  Future<void> _initBothVideos() async {
    final portraitPath = MediaConfig.networkPauseBackgroundPortrait;
    final landscapePath = MediaConfig.networkPauseBackgroundLandscape;

    if (portraitPath == null && landscapePath == null) return;

    try {
      VideoPlayerController? portrait;
      VideoPlayerController? landscape;

      final futures = <Future<void>>[];

      if (portraitPath != null) {
        portrait = VideoPlayerController.asset(portraitPath);
        futures.add(portrait.initialize());
      }
      if (landscapePath != null) {
        landscape = VideoPlayerController.asset(landscapePath);
        futures.add(landscape.initialize());
      }

      await Future.wait(futures);

      if (!mounted) {
        await portrait?.dispose();
        await landscape?.dispose();
        return;
      }

      for (final ctl in [portrait, landscape]) {
        if (ctl == null) continue;
        ctl.setLooping(true);
        ctl.setVolume(0);
        try {
          await ctl.play();
        } catch (_) {}
      }

      _portraitListener = () => _restartIfFinished(portrait);
      _landscapeListener = () => _restartIfFinished(landscape);
      portrait?.addListener(_portraitListener!);
      landscape?.addListener(_landscapeListener!);

      setState(() {
        _portraitCtl = portrait;
        _landscapeCtl = landscape;
        _videosReady = true;
      });
    } catch (e) {
      debugPrint('[NoConn] video init failed: $e');
    }
  }

  void _restartIfFinished(VideoPlayerController? c) {
    if (c == null) return;
    final v = c.value;
    if (!v.isInitialized || v.isPlaying) return;
    if (v.position < v.duration) return;
    c.seekTo(Duration.zero);
    c.play();
  }

  void _kickIfNotPlaying(VideoPlayerController? c) {
    if (c == null || !c.value.isInitialized || c.value.isPlaying) return;
    c.play();
  }

  @override
  void dispose() {
    if (_portraitListener != null) {
      _portraitCtl?.removeListener(_portraitListener!);
    }
    if (_landscapeListener != null) {
      _landscapeCtl?.removeListener(_landscapeListener!);
    }
    _portraitCtl?.dispose();
    _landscapeCtl?.dispose();
    _hintTimer?.cancel();
    _press.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_busy) return;
    await _press.forward();
    await _press.reverse();
    if (!mounted) return;
    setState(() => _busy = true);

    final online = await widget.radar.isReachable();
    if (!mounted) return;

    if (!online) {
      _hintTimer?.cancel();
      setState(() {
        _busy = false;
        _hint = true;
      });
      _hintTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _hint = false);
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050912),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final ctl = isPortrait ? _portraitCtl : _landscapeCtl;

          if (ctl != null && ctl.value.isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _kickIfNotPlaying(ctl);
            });
          }

          final videoReady =
              _videosReady && ctl != null && ctl.value.isInitialized;

          final imagePath = isPortrait
              ? MediaConfig.networkPauseImagePortrait
              : MediaConfig.networkPauseImageLandscape;
          final hasImage = imagePath != null && imagePath.isNotEmpty;

          return LayoutBuilder(
            builder: (context, c) {
              final buttonWidth = isPortrait
                  ? (c.maxWidth * 0.55).clamp(200.0, 360.0)
                  : (c.maxWidth * 0.28).clamp(220.0, 420.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (videoReady)
                    _FullCoverVideo(controller: ctl)
                  else if (hasImage)
                    Image.asset(imagePath, fit: BoxFit.cover)
                  else
                    _DefaultBackground(isPortrait: isPortrait),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _buttonBottom,
                    child: Center(
                      child: RetryButton(
                        width: buttonWidth,
                        busy: _busy,
                        press: _press,
                        onTap: _retry,
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Align(
                      alignment: isPortrait
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: isPortrait ? 80 : 12,
                        ),
                        child: AnimatedOpacity(
                          opacity: _hint ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              child: Text(
                                'Still no internet — please try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FullCoverVideo extends StatelessWidget {
  const _FullCoverVideo({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

class _DefaultBackground extends StatelessWidget {
  final bool isPortrait;
  const _DefaultBackground({required this.isPortrait});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111929), Color(0xFF050912)],
            ),
          ),
        ),
        Align(
          alignment: Alignment(0, isPortrait ? -0.30 : -0.40),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Color(0xFFE0E5EE)),
              SizedBox(height: 14),
              Text(
                'No internet connection',
                style: TextStyle(
                  color: Color(0xFFE0E5EE),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Reconnect and tap Retry.',
                style: TextStyle(color: Color(0x99E0E5EE), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
