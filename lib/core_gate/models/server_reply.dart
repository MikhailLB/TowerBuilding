class ServerReply {
  final bool ok;
  final String? url;
  final String? message;
  final int? expires;

  ServerReply({required this.ok, this.url, this.message, this.expires});

  factory ServerReply.fromJson(Map<String, dynamic> json) {
    return ServerReply(
      ok:      json['ok'] as bool? ?? false,
      url:     json['url'] as String?,
      message: json['message'] as String?,
      expires: json['expires'] as int?,
    );
  }

  factory ServerReply.error(String message) =>
      ServerReply(ok: false, message: message);
}
