import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/core_config.dart';
import '../infra/alert_relay.dart';
import '../infra/connectivity_probe.dart';
import '../infra/core_dispatch.dart';
import '../infra/data_vault.dart';
import '../infra/install_signal.dart';
import '../ui/gate_assets.dart';
import 'web_shell.dart';

/// Push permission offer — full-screen artwork with Accept / Skip overlays.
class AllowScreen extends StatefulWidget {
  final DataVault vault;
  final AlertRelay alerts;
  final ConnectivityProbe probe;
  final InstallSignal signal;
  final CoreDispatch dispatch;
  final String destination;
  final bool layoutSettle;

  const AllowScreen({
    super.key,
    required this.vault,
    required this.alerts,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.destination,
    this.layoutSettle = false,
  });

  @override
  State<AllowScreen> createState() => _AllowScreenState();
}

class _AllowScreenState extends State<AllowScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
        layoutSettle: widget.layoutSettle,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final landscape = orientation == Orientation.landscape;
    final bg = GateAssets.notification(orientation);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              bg,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: Color(0xFF050912)),
            ),
            if (!landscape)
              Positioned(
                left: size.width * 0.08,
                right: size.width * 0.08,
                bottom: size.height * 0.07,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AcceptButton(onTap: _accept, busy: _busy),
                    const SizedBox(height: 18),
                    _SkipButton(onTap: _busy ? null : _skip),
                  ],
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.06,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: size.width * 0.32,
                      child: _AcceptButton(
                        onTap: _accept,
                        busy: _busy,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SkipButton(onTap: _busy ? null : _skip, compact: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcceptButton extends StatefulWidget {
  const _AcceptButton({
    required this.onTap,
    required this.busy,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool busy;
  final bool compact;

  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.busy ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.busy
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) => AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 18),
            decoration: BoxDecoration(
              gradient: widget.busy
                  ? null
                  : LinearGradient(
                      colors: _pressed
                          ? const [Color(0xFFE6A800), Color(0xFFCC8800)]
                          : const [Color(0xFFFFCC00), Color(0xFFFF9900)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: widget.busy ? Colors.amber.withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(50),
              boxShadow: widget.busy
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFFF9900).withValues(
                          alpha: _pressed ? 0.2 : _glowAnim.value,
                        ),
                        blurRadius: _pressed ? 8 : 14 + _glowAnim.value * 18,
                        spreadRadius: _pressed ? 0 : _glowAnim.value * 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.busy
                  ? SizedBox(
                      width: widget.compact ? 20 : 22,
                      height: widget.compact ? 20 : 22,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF1A0A00),
                      ),
                    )
                  : Text(
                      'Accept',
                      style: TextStyle(
                        color: const Color(0xFF1A0A00),
                        fontSize: widget.compact ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  const _SkipButton({required this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.5 : 0.85,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
          child: Center(
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 16 : 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
