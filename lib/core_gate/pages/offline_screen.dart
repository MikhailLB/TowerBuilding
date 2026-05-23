import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infra/connectivity_probe.dart';
import '../ui/gate_assets.dart';

/// No-internet screen — full-screen artwork with a Retry overlay.
class OfflineScreen extends StatefulWidget {
  final WidgetBuilder retryBuilder;
  final ConnectivityProbe probe;

  const OfflineScreen({
    super.key,
    required this.retryBuilder,
    required this.probe,
  });

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  bool _hint = false;
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    await _press.forward();
    await _press.reverse();
    if (!mounted) return;
    setState(() => _busy = true);
    final online = await widget.probe.isOnline();
    if (!mounted) return;
    if (!online) {
      setState(() {
        _busy = false;
        _hint = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
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
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).viewPadding.top;
    final orientation = MediaQuery.of(context).orientation;
    final landscape = orientation == Orientation.landscape;
    final bg = GateAssets.noWifi(orientation);

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
                  const ColoredBox(color: Color(0xFF0D1B2A)),
            ),
            if (landscape)
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.06,
                child: Center(
                  child: SizedBox(
                    width: size.width * 0.32,
                    child: _RetryButton(
                      busy: _busy,
                      press: _press,
                      onTap: _retry,
                      compact: true,
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: size.width * 0.08,
                right: size.width * 0.08,
                bottom: size.height * 0.07,
                child: _RetryButton(
                  busy: _busy,
                  press: _press,
                  onTap: _retry,
                ),
              ),
            if (_hint)
              Positioned(
                top: topInset + 12,
                left: 20,
                right: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      'Still no internet — please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.busy,
    required this.press,
    required this.onTap,
    this.compact = false,
  });

  final bool busy;
  final AnimationController press;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: press,
      builder: (context, child) => Transform.scale(
        scale: 1.0 - 0.05 * press.value,
        child: GestureDetector(
          onTap: busy ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: compact ? 12 : 18),
            decoration: BoxDecoration(
              gradient: busy
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: busy ? Colors.amber.withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(compact ? 40 : 50),
              boxShadow: busy
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: compact ? 20 : 22,
                      height: compact ? 20 : 22,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.amber,
                      ),
                    )
                  : Text(
                      'Retry',
                      style: TextStyle(
                        color: const Color(0xFF1A0A00),
                        fontSize: compact ? 16 : 20,
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
