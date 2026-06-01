// Gate data models — session routing state and endpoint reply.

/// How the app should route on each launch.
///
/// [web]   → open WebView (returning user with a saved URL).
/// [game]  → open the white-part game (organic / unattributed).
/// [fresh] → no decision yet; full attribution pipeline will run.
enum LaunchMode {
  web,
  game,
  fresh;

  String toKey() {
    switch (this) {
      case LaunchMode.web:   return 'web';
      case LaunchMode.game:  return 'game';
      case LaunchMode.fresh: return 'fresh';
    }
  }

  static LaunchMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return LaunchMode.web;
      case 'game':
      case 'arcade':
        return LaunchMode.game;
      default:
        return LaunchMode.fresh;
    }
  }
}

/// Decoded response from the remote core endpoint.
/// Accepts several alternative field names so the client works with
/// slightly different backend conventions without code changes.
class CoreReply {
  final bool granted;
  final String? destination;
  final String? note;
  final int? expiresAt;

  const CoreReply._({
    required this.granted,
    this.destination,
    this.note,
    this.expiresAt,
  });

  factory CoreReply.fromMap(Map<String, dynamic> raw) {
    final granted = (raw['ok'] as bool?)       ??
                    (raw['granted'] as bool?)   ??
                    (raw['accepted'] as bool?)  ??
                    false;

    final destination = raw['url'] as String?       ??
                        raw['link'] as String?      ??
                        raw['target'] as String?    ??
                        raw['destination'] as String?;

    final note = raw['message'] as String? ??
                 raw['note'] as String?    ??
                 raw['reason'] as String?;

    final dynamic ttl = raw['expires'] ?? raw['expires_at'] ?? raw['valid_until'];
    int? expires;
    if (ttl is int) {
      expires = ttl;
    } else if (ttl is num) {
      expires = ttl.toInt();
    } else if (ttl is String) {
      expires = int.tryParse(ttl);
    }

    return CoreReply._(
      granted: granted,
      destination: destination,
      note: note,
      expiresAt: expires,
    );
  }

  factory CoreReply.declined(String reason) =>
      CoreReply._(granted: false, note: reason);
}
