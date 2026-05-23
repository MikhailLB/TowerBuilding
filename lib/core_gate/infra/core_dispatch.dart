import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/core_config.dart';
import '../models/core_reply.dart';
import 'data_vault.dart';
import 'secure_client.dart';

/// Posts the install/launch payload to the core endpoint and caches
/// the returned destination URL. Returns [CoreReply.declined] when
/// the endpoint is not yet provisioned so callers fall back gracefully.
class CoreDispatch {
  final DataVault _vault;

  CoreDispatch(this._vault);

  Future<CoreReply> send(Map<String, dynamic> body) async {
    final endpoint = CoreConfig.configEndpoint;
    debugPrint('[TB.CD] send → endpoint="$endpoint"');
    if (endpoint.isEmpty) {
      debugPrint('[TB.CD] endpoint not configured — declined');
      return CoreReply.declined('endpoint_missing');
    }
    try {
      final uri = Uri.parse(endpoint);
      debugPrint('[TB.CD] POST $uri  body=${jsonEncode(body)}');
      final resp = await secureClient
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      debugPrint('[TB.CD] HTTP ${resp.statusCode}');
      final preview = resp.body.length > 500
          ? '${resp.body.substring(0, 500)}…'
          : resp.body;
      debugPrint('[TB.CD] body=$preview');

      if (resp.statusCode != 200) {
        return CoreReply.declined('http_${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return CoreReply.declined('bad_json');
      }
      final reply = CoreReply.fromMap(decoded);
      debugPrint('[TB.CD] reply granted=${reply.granted} dest=${reply.destination}');
      if (reply.granted && reply.destination != null) {
        await _vault.writeSavedUrl(reply.destination!);
        if (reply.expiresAt != null) {
          await _vault.writeSavedTtl(reply.expiresAt!);
        }
      }
      return reply;
    } catch (err, st) {
      debugPrint('[TB.CD] error: $err\n$st');
      return CoreReply.declined(err.toString());
    }
  }
}
