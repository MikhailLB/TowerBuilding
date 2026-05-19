import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/launch_mode.dart';
import '../providers/install_tracker.dart';
import '../providers/net_watcher.dart';
import '../providers/notify_manager.dart';
import '../providers/gateway_client.dart';
import '../providers/local_store.dart';
import 'web_layer.dart';
import 'splash_view.dart';
import 'no_connection_view.dart';
import 'notify_prompt_view.dart';

typedef SplashFactory = Widget Function(
  Future<WidgetBuilder> routeFuture,
  Future<void> contentReady,
  Future<bool> keepAsUnderlay,
);

class LaunchGate extends StatefulWidget {
  final LocalStore cache;
  final NetWatcher radar;
  final InstallTracker install;
  final GatewayClient gate;
  final NotifyManager pulse;
  final WidgetBuilder fallbackHomeBuilder;
  final SplashFactory? splashBuilder;

  const LaunchGate({
    super.key,
    required this.cache,
    required this.radar,
    required this.install,
    required this.gate,
    required this.pulse,
    required this.fallbackHomeBuilder,
    this.splashBuilder,
  });

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  late final Future<WidgetBuilder> _routeFuture;
  final Completer<void> _contentReady = Completer<void>();
  final Completer<bool> _keepUnderlay = Completer<bool>();
  bool _isWebFlow = false;

  void _markContentReady([String reason = 'eager']) {
    if (_contentReady.isCompleted) return;
    if (kDebugMode) debugPrint('[LaunchGate] contentReady: $reason');
    _contentReady.complete();
  }

  @override
  void initState() {
    super.initState();
    _routeFuture = _kickoff();
  }

  @override
  void dispose() {
    widget.pulse.onTokenRotated = null;
    super.dispose();
  }

  Future<WidgetBuilder> _kickoff() async {
    widget.pulse.onTokenRotated = _onTokenRotated;
    try {
      await widget.pulse.bootstrap();
    } catch (err) {
      if (kDebugMode) debugPrint('[LaunchGate] pulse bootstrap failed: $err');
    }

    WidgetBuilder builder;
    try {
      final route = widget.cache.readRoute();
      switch (route) {
        case LaunchMode.web:
          builder = await _runReturningWebFlow();
          break;
        case LaunchMode.arcade:
          builder = widget.fallbackHomeBuilder;
          break;
        case LaunchMode.pristine:
          builder = await _runFirstLaunchFlow();
          break;
      }
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[LaunchGate] kickoff failed: $err\n$st');
      }
      builder = widget.fallbackHomeBuilder;
    }

    if (!_isWebFlow) {
      _markContentReady('non-web route');
    }
    if (!_keepUnderlay.isCompleted) {
      _keepUnderlay.complete(_isWebFlow);
    }
    return builder;
  }

  Future<WidgetBuilder> _runFirstLaunchFlow() async {
    final online = await widget.radar.isReachable();
    if (!online) {
      return _offlineBuilder(returnAsFirstLaunch: true);
    }

    await widget.install.warmup();
    await Future.wait([
      widget.install.awaitConversion(),
      widget.install.awaitDeepLink(),
    ]);

    final body = await widget.install.composePayload(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: widget.pulse.token,
    );
    final reply = await widget.gate.dispatch(body);

    if (reply.granted && reply.destination != null) {
      await widget.cache.writeRoute(LaunchMode.web);
      return await _webBuilder(reply.destination!);
    }
    await widget.cache.writeRoute(LaunchMode.arcade);
    return widget.fallbackHomeBuilder;
  }

  Future<WidgetBuilder> _runReturningWebFlow() async {
    final online = await widget.radar.isReachable();
    if (!online) {
      return _offlineBuilder(returnAsFirstLaunch: false);
    }

    final oneShot = await widget.cache.consumeOneShotPush();
    if (oneShot != null) {
      return await _webBuilder(oneShot);
    }

    final cached = await widget.cache.readCachedTarget();

    await widget.install.warmup();
    await Future.wait([
      widget.install.awaitConversion(timeout: const Duration(seconds: 9)),
      widget.install.awaitDeepLink(),
    ]);

    final body = await widget.install.composePayload(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: widget.pulse.token,
    );
    final reply = await widget.gate.dispatch(body);

    if (reply.granted && reply.destination != null) {
      return await _webBuilder(reply.destination!);
    }
    if (cached != null) {
      return await _webBuilder(cached);
    }
    return _offlineBuilder(returnAsFirstLaunch: false);
  }

  Future<WidgetBuilder> _webBuilder(String url) async {
    if (widget.cache.needsPushPrompt()) {
      final canAsk = await widget.pulse.shouldOfferConsent();
      if (kDebugMode) {
        debugPrint('[LaunchGate] push offer gate: canAsk=$canAsk');
      }
      if (canAsk) {
        return (_) => NotifyPromptView(
              cache: widget.cache,
              pulse: widget.pulse,
              radar: widget.radar,
              destination: url,
            );
      }
    }
    _isWebFlow = true;
    return (_) => WebLayer(
          destination: url,
          cache: widget.cache,
          pulse: widget.pulse,
          radar: widget.radar,
          onFirstPaint: () => _markContentReady('webview first paint'),
        );
  }

  WidgetBuilder _offlineBuilder({required bool returnAsFirstLaunch}) {
    return (_) => NoConnectionView(
          radar: widget.radar,
          retryBuilder: (_) => LaunchGate(
            cache: widget.cache,
            radar: widget.radar,
            install: widget.install,
            gate: widget.gate,
            pulse: widget.pulse,
            fallbackHomeBuilder: widget.fallbackHomeBuilder,
            splashBuilder: widget.splashBuilder,
          ),
        );
  }

  void _onTokenRotated(String fresh) async {
    final body = await widget.install.composePayload(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: fresh,
    );
    widget.gate.dispatch(body);
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.splashBuilder;
    if (builder != null) {
      return builder(
        _routeFuture,
        _contentReady.future,
        _keepUnderlay.future,
      );
    }
    return SplashView(
      routeFuture: _routeFuture,
      contentReady: _contentReady.future,
      keepAsUnderlay: _keepUnderlay.future,
    );
  }
}
