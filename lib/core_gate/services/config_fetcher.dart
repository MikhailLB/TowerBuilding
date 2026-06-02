import 'dart:convert';
import '../config/app_config.dart';
import '../models/server_reply.dart';
import 'tower_client.dart';
import 'vault.dart';

class ConfigFetcher {
  final Vault _vault;
  ConfigFetcher(this._vault);

  Future<ServerReply> fetchRemote(Map<String, dynamic> body) async {
    if (AppConfig.apiEndpoint.isEmpty) {
      return ServerReply.error('endpoint_missing');
    }
    try {
      final uri = Uri.parse(AppConfig.apiEndpoint);
      final response = await towerHttpClient
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = ServerReply.fromJson(json);
        if (reply.ok && reply.url != null) {
          await _vault.setSavedUrl(reply.url!);
          if (reply.expires != null) {
            await _vault.setUrlExpires(reply.expires!);
          }
        }
        return reply;
      } else {
        return ServerReply.error('http_${response.statusCode}');
      }
    } catch (e) {
      return ServerReply.error(e.toString());
    }
  }

  Future<String?> getSavedUrl() => _vault.getSavedUrl();
}
