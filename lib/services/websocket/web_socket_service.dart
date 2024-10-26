// web_socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/web_socket_message/web_socket_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? channel;
  Timer? reconnectTimer;
  String googleId;
  final Function(Map<String, dynamic>)? onEventUpdate;

  WebSocketService({this.onEventUpdate, required this.googleId});

  void connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse(dotenv.get('WEBSOCKET_URL')),
      );

      channel?.stream.listen(
        (message) {
          final data = WebSocketMessage.fromJson(jsonDecode(message));
          //check if the message is for the current user
          if (data.googleId == googleId) {
            print('received message: $message');

            //check if the message is an update event
            if (data.method == 'update') {
              try {
                final eventData = jsonDecode(message);
                if (onEventUpdate != null) {
                  final updatedEvent = {
                    'id': eventData['id'],
                    'name': eventData['name'],
                    'date': eventData['date'],
                    'time': _parseTimeString(eventData['startTime']),
                    'endTime': eventData['isHaveEndTime']
                        ? _parseTimeString(eventData['endTime'])
                        : null,
                    'isHaveEndTime': eventData['isHaveEndTime'],
                  };
                  onEventUpdate!(updatedEvent);
                  print('updated event: $updatedEvent');
                }
              } catch (e) {
                print('Error processing WebSocket message: $e');
              }
            }
          }
        },
        onDone: () {
          print('WebSocket connection closed, trying to reconnect...');
          attemptReconnect();
        },
        onError: (error) {
          print('WebSocket error: $error');
          attemptReconnect();
        },
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      attemptReconnect();
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void attemptReconnect() {
    if (reconnectTimer == null || !reconnectTimer!.isActive) {
      reconnectTimer = Timer(const Duration(seconds: 5), () {
        print('Reconnecting to WebSocket...');
        connectWebSocket();
        print('Connected to WebSocket');
      });
    }
  }

  void closeWebSocket() {
    // channel?.sink.close(status.goingAway);
    channel?.sink.close(1000);
    reconnectTimer?.cancel();
  }
}
