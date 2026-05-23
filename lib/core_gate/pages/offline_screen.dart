import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../infra/connectivity_probe.dart';

/// No-internet screen with a Retry button. Shows background image if present,
/// otherwise falls back to a programmatic dark design.
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
      setState(() { _busy = false; _hint = true; });
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
    final landscape = size.width > size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _press,
                      builder: (_, _) => Transform.scale(
                        scale: 1.0 - 0.05 * _press.value,
                        child: GestureDetector(
                          onTap: _busy ? null : _retry,
                          child: Container(
                            width: landscape ? 260 : size.width * 0.6,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: _busy
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFFFFCC00), Color(0xFFFF8C00)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _busy ? Colors.amber.withValues(alpha: 0.3) : null,
                              boxShadow: _busy ? null : [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _busy
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.amber,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh_rounded,
                                            color: Color(0xFF1A0A00), size: 24),
                                        SizedBox(width: 8),
                                        Text('Retry',
                                            style: TextStyle(
                                              color: Color(0xFF1A0A00),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            )),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_hint)
              Positioned(
                top: 12, left: 20, right: 20,
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
