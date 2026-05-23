import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../config/core_endpoint.dart';

String _androidUa({
  required int sdk,
  required String brand,
  required String model,
  required String build,
}) =>
    'Mozilla/5.0 (Linux; Android $sdk; $brand $model Build/$build) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/${uaChromeBuild()} Mobile Safari/537.36';

String _iosUa(String ver) {
  final dotless = ver.replaceAll('.', '_');
  return 'Mozilla/5.0 (iPhone; CPU iPhone OS $dotless like Mac OS X) '
      'AppleWebKit/${uaSafariBuild()} (KHTML, like Gecko) '
      'Version/$ver Mobile/15E148 Safari/${uaSafariBuild()}';
}

String _stockUa() => Platform.isAndroid
    ? _androidUa(sdk: 14, brand: 'Google', model: 'Pixel 9', build: 'BP1A.241005.002')
    : _iosUa('18.0');

/// HTTP client that injects a realistic mobile-browser User-Agent built from
/// actual device information so it varies per device.
class SecureClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  String _ua = '';

  Future<void> warmup() async {
    try {
      final probe = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await probe.androidInfo;
        final tag = info.display.isNotEmpty ? info.display : info.id;
        _ua = _androidUa(
          sdk: info.version.sdkInt,
          brand: info.brand,
          model: info.model,
          build: tag,
        );
      } else if (Platform.isIOS) {
        final info = await probe.iosInfo;
        _ua = _iosUa(info.systemVersion);
      } else {
        _ua = _stockUa();
      }
    } catch (_) {
      _ua = _stockUa();
    }
  }

  String get userAgent => _ua.isNotEmpty ? _ua : _stockUa();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!request.headers.containsKey('User-Agent') &&
        !request.headers.containsKey('user-agent')) {
      request.headers['User-Agent'] = userAgent;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final secureClient = SecureClient();
