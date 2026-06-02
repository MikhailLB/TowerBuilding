import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/net_probe.dart';
import '../services/push_agent.dart';
import '../services/tower_client.dart';
import '../services/vault.dart';
import 'offline_screen.dart';

Future<void> prepareWebEngine() async {}

class BrowserScreen extends StatefulWidget {
  final String url;
  final Vault vault;
  final PushAgent pushAgent;
  final NetProbe probe;

  const BrowserScreen({
    super.key,
    required this.url,
    required this.vault,
    required this.pushAgent,
    required this.probe,
  });

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _showingOffline = false;
  String? _lastUrl;
  int _redirectRetries = 0;

  void _setImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _setImmersive();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _setImmersive();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(towerHttpClient.userAgent)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
          _redirectRetries = 0;
          _injectSiteAreaKill();
          _injectKeyboardScrollFix();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame != true) return;
          final desc = error.description.toLowerCase();
          if ((desc.contains('too_many_redirects') ||
                  desc.contains('too many redirects') ||
                  error.errorCode == -1007 ||
                  error.errorCode == -9) &&
              _lastUrl != null &&
              _redirectRetries < 3) {
            _redirectRetries++;
            _controller.loadRequest(Uri.parse(_lastUrl!));
            return;
          }
          _checkAndShowOffline();
        },
        onHttpError: (_) {},
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri == null) return NavigationDecision.prevent;
          final s = uri.scheme;
          if (s == 'http' || s == 'https' || s == 'about' || s == 'data' || s == 'blob') {
            if (req.isMainFrame) _lastUrl = req.url;
            return NavigationDecision.navigate;
          }
          _launchExternal(uri);
          return NavigationDecision.prevent;
        },
      ))
      ..enableZoom(false);

    _configurePlatform();
    _controller.loadRequest(Uri.parse(widget.url));

    widget.pushAgent.onNotificationUrl = (url) {
      if (mounted) _controller.loadRequest(Uri.parse(url));
    };

    _connSub = widget.probe.onConnectivityChanged.listen((results) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        _checkAndShowOffline();
      }
    });
  }

  Future<void> _checkAndShowOffline() async {
    if (_showingOffline) return;
    final online = await widget.probe.hasInternet();
    if (online || !mounted) return;
    _showingOffline = true;
    final currentUrl = await _controller.currentUrl() ?? widget.url;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(
        retryBuilder: (_) => BrowserScreen(
          url: currentUrl,
          vault: widget.vault,
          pushAgent: widget.pushAgent,
          probe: widget.probe,
        ),
      ),
    ));
  }

  void _configurePlatform() {
    if (Platform.isAndroid && _controller.platform is AndroidWebViewController) {
      final ctrl = _controller.platform as AndroidWebViewController;
      ctrl.setMediaPlaybackRequiresUserGesture(false);
      ctrl.setOnShowFileSelector(_handleFileSelector);
      final cookieMgr = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      cookieMgr.setAcceptThirdPartyCookies(ctrl, true);
    }
  }

  Future<List<String>> _handleFileSelector(FileSelectorParams params) async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((f) => f.path != null)
            .map((f) => Uri.file(f.path!).toString())
            .toList();
      }
    } catch (_) {}
    return [];
  }

  void _injectKeyboardScrollFix() {
    _controller.runJavaScript('''
(function() {
  if (window.__kbScrollFixApplied) return;
  window.__kbScrollFixApplied = true;
  function isInput(el) {
    return el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable);
  }
  function doScroll() {
    var el = document.activeElement;
    if (!isInput(el)) return;
    var vp = window.visualViewport;
    if (vp) {
      var rect = el.getBoundingClientRect();
      var vpBottom = vp.offsetTop + vp.height;
      if (rect.bottom > vpBottom - 20 || rect.top < vp.offsetTop) {
        el.scrollIntoView({ behavior: 'auto', block: 'nearest' });
      }
    } else {
      el.scrollIntoView({ behavior: 'auto', block: 'nearest' });
    }
  }
  document.addEventListener('focusin', function(e) {
    if (isInput(e.target)) { setTimeout(doScroll, 350); }
  });
  if (window.visualViewport) {
    var prevH = window.visualViewport.height;
    window.visualViewport.addEventListener('resize', function() {
      var h = window.visualViewport.height;
      if (h < prevH) { setTimeout(doScroll, 120); }
      prevH = h;
    });
  }
})();
''');
  }

  void _injectSiteAreaKill() {
    _controller.runJavaScript(r'''
(function() {
  if (window.__flsaRunning) return;
  window.__flsaRunning = true;
  var CSS_ID = '__flsa';
  var CSS_TEXT =
    ':root{' +
      '--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;' +
      '--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;' +
      '--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;' +
    '}' +
    'html,body,#__nuxt,#__layout,#app,#root,.gameview-mobile-header{' +
      'padding-top:0!important;padding-left:0!important;' +
      'padding-right:0!important;margin-top:0!important;' +
    '}';
  function apply() {
    var head = document.head || document.documentElement;
    if (!head) return;
    var m = document.querySelector('meta[name="viewport"]');
    if (m && !/viewport-fit\s*=\s*contain/i.test(m.getAttribute('content') || '')) {
      var c = (m.getAttribute('content') || '')
        .replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '').trim();
      m.setAttribute('content', c + (c ? ', ' : '') + 'viewport-fit=contain');
    }
    var s = document.getElementById(CSS_ID);
    if (!s) { s = document.createElement('style'); s.id = CSS_ID; head.appendChild(s); }
    if (s.textContent !== CSS_TEXT) s.textContent = CSS_TEXT;
    if (head.lastElementChild !== s) head.appendChild(s);
  }
  apply();
  ['pushState','replaceState'].forEach(function(fn) {
    var orig = history[fn];
    history[fn] = function() { var r = orig.apply(this, arguments); setTimeout(apply, 80); setTimeout(apply, 400); return r; };
  });
  window.addEventListener('popstate', function() { setTimeout(apply, 80); });
  setInterval(apply, 2500);
})();
''');
  }

  Future<void> _launchExternal(Uri uri) async {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    widget.pushAgent.onNotificationUrl = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) { await _controller.goBack(); }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).orientation == Orientation.landscape
                    ? 0
                    : MediaQuery.of(context).viewPadding.top,
              ),
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
