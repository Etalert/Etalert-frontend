import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketState {
  final Map<String, dynamic> data;

  WebSocketState({required this.data});
}

final webSocketStateProvider = StateProvider<WebSocketState>((ref) {
  return WebSocketState(data: {});
});

class WebSocketChannelState {
  static WebSocketChannel? channel;
}
