import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../infra/alert_relay.dart';
import '../infra/connectivity_probe.dart';
import '../infra/data_vault.dart';
import '../infra/secure_client.dart';
import 'offline_screen.dart';

/// In-app WebView browser with immersive mode, full JS injection suite,
/// keyboard scroll fixes, safe-area compensation, and push URL routing.
class WebShell extends StatefulWidget {
  final String destination;
  final DataVault vault;
  final AlertRelay alerts;
  final ConnectivityProbe probe;
  final VoidCallback? onFirstPaint;
  /// Delays WKWebView mount until immersive mode settles (cold-start push).
  final bool layoutSettle;

  const WebShell({
    super.key,
    required this.destination,
    required this.vault,
    required this.alerts,
    required this.probe,
    this.onFirstPaint,
    this.layoutSettle = false,
  });

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> with WidgetsBindingObserver {
  late final WebViewController _wv;
  StreamSubscription<bool>? _connSub;
  bool _offlineRouted = false;
  String? _lastMainFrameUrl;
  int _redirectRetries = 0;
  bool _firstPaintFired = false;
  bool _showWebView = false;
  Widget? _fullscreenOverlay;
  void Function()? _dismissOverlay;

  void _applyImmersive() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyImmersive();
      _drainStash();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _applyImmersive();

    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _wv = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(secureClient.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(_buildDelegate());

    _configurePlatform();

    if (widget.layoutSettle && Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _deferredMount());
    } else {
      _showWebView = true;
      _wv.loadRequest(Uri.parse(widget.destination));
    }

    widget.alerts.onPushUrl = (url) {
      if (!mounted) return;
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _wv.loadRequest(uri);
      } catch (_) {}
    };

    _connSub = widget.probe.watch().listen((online) {
      if (!online) _maybeRouteOffline();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _drainStash());
  }

  Future<void> _deferredMount() async {
    _applyImmersive();
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _showWebView = true);
    _wv.loadRequest(Uri.parse(widget.destination));
  }

  void _scheduleViewportNudges() {
    for (final ms in const [400, 800, 1200, 1800]) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _nudgeViewport();
        _reapplySafeArea();
      });
    }
  }

  void _nudgeViewport() {
    _wv.runJavaScript(r'''
(function(){
  try{
    var w=window,h=w.innerHeight;
    ['resize','orientationchange'].forEach(function(n){w.dispatchEvent(new Event(n));});
    if(w.visualViewport)w.visualViewport.dispatchEvent(new Event('resize'));
    var de=document.documentElement,bd=document.body;
    if(de)de.style.setProperty('min-height',h+'px');
    if(bd)bd.style.setProperty('min-height',h+'px');
  }catch(e){}
})();
''');
  }

  Future<void> _drainStash() async {
    final url = await widget.vault.consumeOneShotUrl();
    if (url != null && url.isNotEmpty && mounted) {
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _wv.loadRequest(uri);
      } catch (_) {}
    }
  }

  NavigationDelegate _buildDelegate() {
    return NavigationDelegate(
      onPageStarted: (_) {},
      onPageFinished: (_) {
        _redirectRetries = 0;
        _injectSafeArea();
        _injectKeyboardFix();
        _injectAntiZoom();
        _injectMediaAutoplay();
        _nudgeViewport();
        _scheduleViewportNudges();
        if (!_firstPaintFired) {
          _firstPaintFired = true;
          Future.delayed(const Duration(milliseconds: 600), () {
            try { widget.onFirstPaint?.call(); } catch (_) {}
          });
        }
      },
      onWebResourceError: (err) {
        if (err.isForMainFrame != true) return;
        final desc = err.description.toLowerCase();
        final loop = desc.contains('too_many_redirects') ||
            desc.contains('too many redirects') ||
            err.errorCode == -1007 || err.errorCode == -9;
        if (loop && _lastMainFrameUrl != null && _redirectRetries < 3) {
          _redirectRetries++;
          _wv.loadRequest(Uri.parse(_lastMainFrameUrl!));
          return;
        }
        _maybeRouteOffline();
      },
      onHttpError: (_) {},
      onNavigationRequest: (req) {
        final uri = Uri.tryParse(req.url);
        if (uri == null) return NavigationDecision.prevent;
        final s = uri.scheme;
        if (s == 'http' || s == 'https' || s == 'about' ||
            s == 'data' || s == 'blob') {
          if (req.isMainFrame) _lastMainFrameUrl = req.url;
          return NavigationDecision.navigate;
        }
        _launchExternal(uri);
        return NavigationDecision.prevent;
      },
    );
  }

  void _configurePlatform() {
    if (Platform.isIOS && _wv.platform is WebKitWebViewController) {
      (_wv.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
    if (Platform.isAndroid && _wv.platform is AndroidWebViewController) {
      final android = _wv.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setCustomWidgetCallbacks(
        onShowCustomWidget: (w, hide) {
          _dismissOverlay = hide;
          if (mounted) setState(() => _fullscreenOverlay = w);
        },
        onHideCustomWidget: () {
          _dismissOverlay = null;
          if (mounted) setState(() => _fullscreenOverlay = null);
        },
      );
      final cookies = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      cookies.setAcceptThirdPartyCookies(android, true);
    }
  }

  Future<void> _maybeRouteOffline() async {
    if (_offlineRouted) return;
    final ok = await widget.probe.isOnline();
    if (ok || !mounted) return;
    _offlineRouted = true;
    final current = await _wv.currentUrl() ?? widget.destination;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(
        probe: widget.probe,
        retryBuilder: (_) => WebShell(
          destination: current,
          vault: widget.vault,
          alerts: widget.alerts,
          probe: widget.probe,
        ),
      ),
    ));
  }

  void _launchExternal(Uri uri) async {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  // ── JS injections ─────────────────────────────────────────

  void _reapplySafeArea() {
    _wv.runJavaScript('try{var o=window.__wq7;o&&o.fit&&o.fit();}catch(e){}');
  }

  void _injectSafeArea() {
    _wv.runJavaScript(r'''
(function(){
  var O=window.__wq7||(window.__wq7={});
  if(O.a)return;O.a=1;
  var cc=String.fromCharCode;
  var nuxt=cc(35,95,95,110,117,120,116);
  var lay=cc(35,95,95,108,97,121,111,117,116);
  var hdr=cc(46,103,97,109,101,118,105,101,119,45,109,111,98,105,108,101,45,104,101,97,100,101,114);
  var tgt='html,body,#app,#root,'+nuxt+','+lay+','+hdr;
  var root=':root{--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;'
    +'--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;'
    +'--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;}';
  var box='{padding-top:0!important;padding-left:0!important;padding-right:0!important;margin-top:0!important;}';
  var sheet=root+tgt+box;
  var tag='vp-fit-layer';
  function kbOn(){var v=window.visualViewport;return !!v&&v.height<window.innerHeight*0.72;}
  function fit(){
    if(kbOn())return;
    var head=document.head||document.documentElement;if(!head)return;
    var meta=document.querySelector('meta[name=viewport]');
    if(meta){
      var c=meta.getAttribute('content')||'';
      if(!/viewport-fit\s*=\s*contain/i.test(c)){
        c=c.replace(/,?\s*viewport-fit\s*=\s*[a-z]+/ig,'').replace(/^\s*,/,'').trim();
        meta.setAttribute('content',c?c+', viewport-fit=contain':'viewport-fit=contain');
      }
    }
    var st=document.getElementById(tag);
    if(!st){st=document.createElement('style');st.id=tag;head.appendChild(st);}
    if(st.textContent!==sheet)st.textContent=sheet;
    if(head.lastElementChild!==st)head.appendChild(st);
  }
  O.fit=fit;
  fit();
  ['pushState','replaceState'].forEach(function(n){
    var f=history[n];
    history[n]=function(){var r=f.apply(this,arguments);setTimeout(fit,160);setTimeout(fit,640);return r;};
  });
  window.addEventListener('popstate',function(){setTimeout(fit,160);});
  setInterval(fit,2800);
})();
''');
  }

  void _injectKeyboardFix() {
    _wv.runJavaScript(r'''
(function(){
  var O=window.__wq7||(window.__wq7={});
  if(O.k)return;O.k=1;
  function isField(n){return !!n&&(n.tagName==='INPUT'||n.tagName==='TEXTAREA'||n.isContentEditable===true);}
  function bring(){
    var el=document.activeElement;if(!isField(el))return;
    var v=window.visualViewport;
    if(v){
      var b=el.getBoundingClientRect();
      if(b.bottom>v.offsetTop+v.height-22||b.top<v.offsetTop)el.scrollIntoView({block:'center'});
    }else{el.scrollIntoView({block:'center'});}
  }
  document.addEventListener('focusin',function(e){if(isField(e.target))setTimeout(bring,360);});
  var v=window.visualViewport;
  if(v){
    var prev=v.height;
    v.addEventListener('resize',function(){var h=v.height;if(h<prev-56)setTimeout(bring,120);prev=h;});
  }
})();
''');
  }

  void _injectAntiZoom() {
    if (!Platform.isIOS) return;
    _wv.runJavaScript(r'''
(function(){
  var O=window.__wq7||(window.__wq7={});
  if(O.z)return;O.z=1;
  var s=document.createElement('style');
  s.id='vp-zoom-layer';
  s.textContent='input,textarea,select,[contenteditable]{font-size:max(16px,1em)!important;}';
  (document.head||document.documentElement).appendChild(s);
})();
''');
  }

  void _injectMediaAutoplay() {
    _wv.runJavaScript(r'''
(function(){
  var O=window.__wq7||(window.__wq7={});
  if(O.v)return;O.v=1;
  function arm(el){
    try{
      el.muted=true;el.defaultMuted=true;el.autoplay=true;el.playsInline=true;
      el.setAttribute('playsinline','');el.setAttribute('webkit-playsinline','');
      var p=el.play&&el.play();if(p&&p.catch)p.catch(function(){});
    }catch(e){}
  }
  function scan(root){
    try{var list=(root||document).getElementsByTagName('video');for(var i=0;i<list.length;i++)arm(list[i]);}catch(e){}
  }
  scan(document);
  document.addEventListener('touchend',function(){scan(document);},{passive:true});
  var mo=new MutationObserver(function(recs){
    for(var i=0;i<recs.length;i++){
      var add=recs[i].addedNodes||[];
      for(var j=0;j<add.length;j++){
        var n=add[j];if(!n||n.nodeType!==1)continue;
        if(n.tagName==='VIDEO')arm(n);scan(n);
      }
    }
  });
  mo.observe(document.documentElement,{childList:true,subtree:true});
  setInterval(function(){scan(document);},1800);
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    widget.alerts.onPushUrl = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _fullscreenOverlay != null) _dismissOverlay?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: safe.top, bottom: safe.bottom,
                left: safe.left, right: safe.right,
              ),
              child: _showWebView
                  ? WebViewWidget(controller: _wv)
                  : const ColoredBox(color: Colors.black),
            ),
            if (_fullscreenOverlay != null)
              Positioned.fill(child: _fullscreenOverlay!),
          ],
        ),
      ),
    );
  }
}
