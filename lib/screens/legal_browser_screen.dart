import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../ui/visual_tokens.dart';

/// Lightweight in-app browser for privacy policy / support pages.
class LegalBrowserScreen extends StatefulWidget {
  final String title;
  final String url;

  const LegalBrowserScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<LegalBrowserScreen> createState() => _LegalBrowserScreenState();
}

class _LegalBrowserScreenState extends State<LegalBrowserScreen> {
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
      backgroundColor: AppColors.sky,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.text,
        title: Text(widget.title, style: AppTextStyles.button(size: 18)),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
        ],
      ),
    );
  }
}
