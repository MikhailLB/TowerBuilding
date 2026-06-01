import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/core_config.dart';
import '../models/gate_models.dart';
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
    if (endpoint.isEmpty) return CoreReply.declined('endpoint_missing');
    try {
      final uri = Uri.parse(endpoint);
      final resp = await secureClient
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      if (kDebugMode) debugPrint('[HV.dispatch] HTTP ${resp.statusCode}');

      if (resp.statusCode != 200) {
        return CoreReply.declined('http_${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return CoreReply.declined('bad_json');
      }
      final reply = CoreReply.fromMap(decoded);
      if (kDebugMode) debugPrint('[HV.dispatch] granted=${reply.granted}');
      if (reply.granted && reply.destination != null) {
        await _vault.writeSavedUrl(reply.destination!);
        if (reply.expiresAt != null) {
          await _vault.writeSavedTtl(reply.expiresAt!);
        }
      }
      return reply;
    } catch (err, st) {
      if (kDebugMode) debugPrint('[HV.dispatch] error: $err\n$st');
      return CoreReply.declined(err.toString());
    }
  }
}
