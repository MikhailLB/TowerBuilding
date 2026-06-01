import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/palette.dart';
import '../theme/type_scale.dart';

/// In-app browser for the privacy policy and support pages reachable from the
/// home screen footer.
class WebPanelScreen extends StatefulWidget {
  const WebPanelScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<WebPanelScreen> createState() => _WebPanelScreenState();
}

class _WebPanelScreenState extends State<WebPanelScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hue.noon,
      appBar: AppBar(
        backgroundColor: Hue.panelDeep,
        foregroundColor: Hue.parchment,
        title: Text(widget.title,
            style: Lettering.heading(size: 17, color: Hue.parchment)),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Hue.ember),
            ),
        ],
      ),
    );
  }
}
