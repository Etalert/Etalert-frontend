import 'dart:convert';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/theme/color_schemes.g.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/router_provider.dart';
import 'package:frontend/providers/web_socket_provider.dart';
import '../../providers/schedule_provider.dart';
import '../theme/custom_color.g.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class ETAlert extends ConsumerStatefulWidget {
  const ETAlert({super.key});

  @override
  ConsumerState<ETAlert> createState() => _ETAlertState();
}

class _ETAlertState extends ConsumerState<ETAlert> {
  void connectWebSocket() async {
    final websocketUrl = dotenv.env['WEBSOCKET_URL'];

    if (websocketUrl == null) {
      print('Error: WEBSOCKET_URL is not set in the environment variables.');
      return;
    }

    final uri = Uri.parse(websocketUrl);
    final websocketChannel = WebSocketChannel.connect(uri);
    WebSocketChannelState.channel = websocketChannel;

    await websocketChannel.ready;
    print('Websocket connected');

    if (AuthState.googleId != null) {
      websocketChannel.sink.add(jsonEncode({"userId": AuthState.googleId}));
      print(AuthState.googleId);
      print('Sent userId to websocket');
    }

    websocketChannel.stream.listen((message) {
      print(message);
      final Map<String, dynamic> data = json.decode(message);
      print('Received data: $data');
      ref
          .read(webSocketStateProvider.notifier)
          .update((state) => WebSocketState(data: data));
    }, onDone: () {
      print('Websocket closed');
      connectWebSocket();
    }, onError: (error) {
      print('Error: $error');
      connectWebSocket();
    });
  }

  @override
  void initState() {
    connectWebSocket();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WebSocketState>(webSocketStateProvider, (previous, next) {
      final data = next.data;

      // Check if data contains schedule information to update
      if (data.containsKey('scheduleUpdate') && AuthState.googleId != null) {
        ref
            .read(scheduleProvider(AuthState.googleId!).notifier)
            .updateScheduleFromData(data['scheduleUpdate']);
      }
    });
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          lightCustomColors = lightCustomColors.harmonized(lightScheme);

          // Repeat for the dark color scheme.
          darkScheme = darkDynamic.harmonized();
          darkCustomColors = darkCustomColors.harmonized(darkScheme);
        } else {
          // Otherwise, use fallback schemes.
          lightScheme = lightColorScheme;
          darkScheme = darkColorScheme;
        }

        final router = ref.watch(routerProvider);

        return MaterialApp.router(
          title: 'ETAlert',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            extensions: [lightCustomColors],
          ),
          // darkTheme: ThemeData(
          //   useMaterial3: true,
          //   colorScheme: darkScheme,
          //   extensions: [darkCustomColors],
          // ),
          routerConfig: router,
        );
      },
    );
  }
}
