class WebSocketMessage {
  final String googleId;
  final String method;

  WebSocketMessage({
    required this.googleId,
    required this.method,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      googleId: json['GoogleId'],
      method: json['Method'],
    );
  }
}
