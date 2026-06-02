import 'package:flutter/material.dart';

class OfflineScreen extends StatefulWidget {
  final WidgetBuilder retryBuilder;
  const OfflineScreen({super.key, required this.retryBuilder});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  bool _isRetrying = false;
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRetry() async {
    if (_isRetrying) return;
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final size = MediaQuery.of(context).size;
    final bgAsset = isLandscape
        ? 'assets/additional_assets/no_wifi/16x9_no_wifi_screen.webp'
        : 'assets/additional_assets/no_wifi/9x16_no_wifi_screen.webp';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bgAsset, fit: BoxFit.cover,
              width: size.width, height: size.height),
          Positioned(
            left: 36, right: 36,
            bottom: MediaQuery.of(context).padding.bottom + (isLandscape ? 16 : 32),
            child: ScaleTransition(
              scale: _btnScale,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _isRetrying ? null : const LinearGradient(
                      colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    color: _isRetrying ? Colors.amber.withValues(alpha: 0.3) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isRetrying ? [] : [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isRetrying ? null : _onRetry,
                      child: Center(
                        child: _isRetrying
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Connecting...',
                                    style: TextStyle(
                                      color: Colors.amber.withValues(alpha: 0.9),
                                      fontSize: 16, fontWeight: FontWeight.w600,
                                    )),
                              ])
                            : const Text('Retry',
                                style: TextStyle(
                                  color: Color(0xFF1A0A00),
                                  fontSize: 17, fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                )),
                      ),
                    ),
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
