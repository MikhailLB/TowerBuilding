class GatewayReply {
  final bool granted;
  final String? destination;
  final String? note;
  final int? expiresAtEpoch;

  const GatewayReply._({
    required this.granted,
    this.destination,
    this.note,
    this.expiresAtEpoch,
  });

  factory GatewayReply.fromMap(Map<String, dynamic> raw) {
    final granted = (raw['ok'] as bool?) ??
        (raw['granted'] as bool?) ??
        (raw['accepted'] as bool?) ??
        false;

    final destination = raw['url'] as String? ??
        raw['link'] as String? ??
        raw['target'] as String? ??
        raw['destination'] as String?;

    final note = raw['message'] as String? ??
        raw['note'] as String? ??
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

    return GatewayReply._(
      granted: granted,
      destination: destination,
      note: note,
      expiresAtEpoch: expires,
    );
  }

  factory GatewayReply.declined(String reason) {
    return GatewayReply._(granted: false, note: reason);
  }
}
