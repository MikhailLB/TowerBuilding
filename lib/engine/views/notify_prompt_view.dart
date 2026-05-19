import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../setup/asset_manifest.dart';
import '../setup/app_identity.dart';
import '../providers/net_watcher.dart';
import '../providers/notify_manager.dart';
import '../providers/local_store.dart';
import 'web_layer.dart';
import 'widgets/action_plate.dart';

class NotifyPromptView extends StatefulWidget {
  final LocalStore cache;
  final NotifyManager pulse;
  final NetWatcher radar;
  final String destination;

  const NotifyPromptView({
    super.key,
    required this.cache,
    required this.pulse,
    required this.radar,
    required this.destination,
  });

  @override
  State<NotifyPromptView> createState() => _NotifyPromptViewState();
}

class _NotifyPromptViewState extends State<NotifyPromptView>
    with TickerProviderStateMixin {
  VideoPlayerController? _video;
  Orientation? _videoOrientation;
  bool _videoLoading = false;
  bool _videoFailed = false;
  bool _busy = false;

  late final AnimationController _shimmer;
  late final AnimationController _pulse;

  static const double _buttonBottom = 40.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
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
    final asset = orientation == Orientation.landscape
        ? MediaConfig.notifyOfferVideoLandscape
        : MediaConfig.notifyOfferVideoPortrait;

    if (asset == null || asset.isEmpty) {
      if (mounted) {
        setState(() {
          _videoOrientation = orientation;
          _videoFailed = true;
        });
      }
      _videoLoading = false;
      return;
    }

    final previous = _video;
    final controller = VideoPlayerController.asset(asset);
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
    } catch (e, st) {
      debugPrint('[NotifyPrompt] video failed ($asset): $e\n$st');
      await controller.dispose();
      if (mounted) {
        setState(() {
          _videoOrientation = orientation;
          _videoFailed = true;
        });
      }
    } finally {
      _videoLoading = false;
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    _shimmer.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.pulse.askConsent();
      _openShell();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _registerCooldown();
    _openShell();
  }

  Future<void> _registerCooldown() async {
    final until = (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
        AppIdentity.notifyCooldownSeconds;
    await widget.cache.writePushCooldownUntil(until);
  }

  void _openShell() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WebLayer(
          destination: widget.destination,
          cache: widget.cache,
          pulse: widget.pulse,
          radar: widget.radar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final ready = video != null && video.value.isInitialized;
    return Scaffold(
      backgroundColor: const Color(0xFF050912),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final landscape = orientation == Orientation.landscape;
          final bgPath = landscape
              ? (MediaConfig.notifyOfferBackgroundLandscape ??
                  MediaConfig.notifyOfferBackground)
              : (MediaConfig.notifyOfferBackgroundPortrait ??
                  MediaConfig.notifyOfferBackground);
          final hasBg = bgPath != null && bgPath.isNotEmpty;
          return LayoutBuilder(
            builder: (context, c) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (ready)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: video.value.size.width,
                        height: video.value.size.height,
                        child: VideoPlayer(video),
                      ),
                    )
                  else if (_videoFailed && hasBg)
                    Image.asset(bgPath!, fit: BoxFit.cover)
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF132036), Color(0xFF050912)],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _buttonBottom,
                    child:
                        landscape ? _landscapeButtons(c) : _portraitButtons(c),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _portraitButtons(BoxConstraints c) {
    final buttonWidth = c.maxWidth * 0.78;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionPlate(
          width: buttonWidth,
          label: 'ACCEPT',
          busy: _busy,
          enabled: !_busy,
          shimmer: _shimmer,
          pulse: _pulse,
          variant: ButtonVariant.gold,
          onTap: _accept,
        ),
        SizedBox(height: c.maxHeight * 0.022),
        ActionPlate(
          width: buttonWidth,
          label: 'SKIP',
          busy: false,
          enabled: !_busy,
          shimmer: _shimmer,
          pulse: _pulse,
          variant: ButtonVariant.slate,
          onTap: _skip,
        ),
      ],
    );
  }

  Widget _landscapeButtons(BoxConstraints c) {
    final buttonWidth = (c.maxWidth * 0.28).clamp(220.0, 380.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionPlate(
          width: buttonWidth,
          label: 'ACCEPT',
          busy: _busy,
          enabled: !_busy,
          shimmer: _shimmer,
          pulse: _pulse,
          variant: ButtonVariant.gold,
          onTap: _accept,
          aspectRatio: 5.6,
        ),
        SizedBox(height: c.maxHeight * 0.025),
        ActionPlate(
          width: buttonWidth,
          label: 'SKIP',
          busy: false,
          enabled: !_busy,
          shimmer: _shimmer,
          pulse: _pulse,
          variant: ButtonVariant.slate,
          onTap: _skip,
          aspectRatio: 5.6,
        ),
      ],
    );
  }
}
