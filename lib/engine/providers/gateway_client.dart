import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../setup/app_identity.dart';
import '../domain/gateway_reply.dart';
import 'local_store.dart';
import 'http_layer.dart';

class GatewayClient {
  final LocalStore _cache;

  GatewayClient(this._cache);

  Future<GatewayReply> dispatch(Map<String, dynamic> body) async {
    final endpoint = AppIdentity.configUrl;
    if (endpoint.isEmpty) {
      if (kDebugMode) {
        debugPrint('[GWC] gateway endpoint missing — declined');
      }
      return GatewayReply.declined('endpoint_missing');
    }

    try {
      final uri = Uri.parse(endpoint);
      final response = await httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 18));

      if (kDebugMode) {
        debugPrint('[GWC] status=${response.statusCode}');
        final preview = response.body.length > 600
            ? '${response.body.substring(0, 600)}…'
            : response.body;
        debugPrint('[GWC] body=$preview');
      }

      if (response.statusCode != 200) {
        return GatewayReply.declined('http_${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return GatewayReply.declined('bad_json');
      }

      final reply = GatewayReply.fromMap(decoded);
      if (reply.granted && reply.destination != null) {
        await _cache.writeCachedTarget(reply.destination!);
        final ttl = reply.expiresAtEpoch;
        if (ttl != null) {
          await _cache.writeCachedTtl(ttl);
        }
      }
      return reply;
    } catch (err, st) {
      if (kDebugMode) {
        debugPrint('[GWC] dispatch error: $err');
        debugPrint('$st');
      }
      return GatewayReply.declined(err.toString());
    }
  }
}
