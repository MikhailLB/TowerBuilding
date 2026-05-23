import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/core_config.dart';
import '../infra/alert_relay.dart';
import '../infra/connectivity_probe.dart';
import '../infra/core_dispatch.dart';
import '../infra/data_vault.dart';
import '../infra/install_signal.dart';
import 'web_shell.dart';

/// Push permission offer screen with an Accept / Skip choice.
/// Uses a programmatic UI so it doesn't depend on any external image assets
/// beyond the app's own theme colors.
class AllowScreen extends StatefulWidget {
  final DataVault vault;
  final AlertRelay alerts;
  final ConnectivityProbe probe;
  final InstallSignal signal;
  final CoreDispatch dispatch;
  final String destination;

  const AllowScreen({
    super.key,
    required this.vault,
    required this.alerts,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.destination,
  });

  @override
  State<AllowScreen> createState() => _AllowScreenState();
}

class _AllowScreenState extends State<AllowScreen>
    with TickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final granted = await widget.alerts.askConsent();
      if (granted) {
        final token = await widget.alerts.refreshTokenAfterConsent();
        if (token != null && token.isNotEmpty) {
          final body = await widget.signal.buildPayload(
            locale: 'en',
            pushToken: token,
          );
          widget.dispatch.send(body);
        }
      } else {
        await _setCooldown();
      }
      _openShell();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    await _setCooldown();
    _openShell();
  }

  Future<void> _setCooldown() async {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        CoreConfig.pushCooldownSeconds;
    await widget.vault.writePushCooldown(until);
  }

  void _openShell() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WebShell(
        destination: widget.destination,
        vault: widget.vault,
        alerts: widget.alerts,
        probe: widget.probe,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscape = size.width > size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF050912),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF050912), Color(0xFF0D1B2A)],
                ),
              ),
            ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 64, color: Colors.amber,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Stay in the game!',
                      style: TextStyle(
                        color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enable notifications to receive exclusive tower-building\nchallenges and season events.',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: landscape ? 24 : 40),
                    // Accept button
                    AnimatedBuilder(
                      animation: _glow,
                      builder: (_, child) => Container(
                        width: landscape ? 280 : size.width * 0.75,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFCC00), Color(0xFFFF8C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00)
                                  .withValues(alpha: 0.25 + 0.25 * _glow.value),
                              blurRadius: 12 + 8 * _glow.value,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: TextButton(
                        onPressed: _busy ? null : _accept,
                        child: _busy
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Color(0xFF1A0A00),
                                ),
                              )
                            : const Text('Accept',
                                style: TextStyle(
                                  color: Color(0xFF1A0A00),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Skip button
                    TextButton(
                      onPressed: _busy ? null : _skip,
                      child: const Text('Skip',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
