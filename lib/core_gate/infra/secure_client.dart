import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Lightweight HTTP reply wrapper. Mirrors only the surface the gate needs
/// (`statusCode`, decoded `body`, raw `bodyBytes`) so callers stay agnostic
/// of the underlying transport.
class NetReply {
  final int statusCode;
  final Uint8List bodyBytes;
  NetReply(this.statusCode, this.bodyBytes);
  String get body => utf8.decode(bodyBytes, allowMalformed: true);
}

String _iosAgent(String version) {
  final compact = version.replaceAll('.', '_');
  return 'Mozilla/5.0 (iPhone; CPU iPhone OS $compact like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/$version Mobile/15E148 Safari/604.1';
}

String _androidAgent(String release) =>
    'Mozilla/5.0 (Linux; Android $release; K) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/137.0.0.0 Mobile Safari/537.36';

/// Networking facade built directly on `dart:io` HttpClient. Carries a
/// User-Agent assembled from the live OS version so it varies per device
/// without bundling a device-info plugin. Redirects are followed natively.
class SecureClient {
  final HttpClient _io = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12)
    ..autoUncompress = true;

  String _ua = '';

  Future<void> warmup() async {
    _ua = _resolveAgent();
  }

  String get userAgent => _ua.isNotEmpty ? _ua : _resolveAgent();

  String _resolveAgent() {
    try {
      final raw = Platform.operatingSystemVersion;
      if (Platform.isIOS) {
        final m = RegExp(r'(\d+(?:\.\d+){0,2})').firstMatch(raw);
        return _iosAgent(m?.group(1) ?? '17.0');
      }
      if (Platform.isAndroid) {
        final m = RegExp(r'(\d+(?:\.\d+){0,2})').firstMatch(raw);
        return _androidAgent(m?.group(1) ?? '14');
      }
    } catch (_) {}
    return _iosAgent('17.0');
  }

  Future<NetReply> get(Uri uri, {Map<String, String>? headers}) =>
      _exchange('GET', uri, headers, null);

  Future<NetReply> post(Uri uri,
          {Map<String, String>? headers, Object? body}) =>
      _exchange('POST', uri, headers, body);

  Future<NetReply> _exchange(
    String verb,
    Uri uri,
    Map<String, String>? headers,
    Object? body,
  ) async {
    final req = await _io.openUrl(verb, uri);
    req.followRedirects = true;
    req.maxRedirects = 6;
    var hasUa = false;
    headers?.forEach((k, v) {
      req.headers.set(k, v);
      if (k.toLowerCase() == 'user-agent') hasUa = true;
    });
    if (!hasUa) req.headers.set(HttpHeaders.userAgentHeader, userAgent);

    if (body != null) {
      final List<int> payload =
          body is String ? utf8.encode(body) : (body as List<int>);
      req.add(payload);
    }

    final resp = await req.close();
    final sink = BytesBuilder(copy: false);
    await for (final chunk in resp) {
      sink.add(chunk);
    }
    return NetReply(resp.statusCode, sink.takeBytes());
  }
}

final SecureClient secureClient = SecureClient();
