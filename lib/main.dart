import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/objective_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

/// Manages the WebSocket connection for the entire app.
/// Opens the connection in initState and closes it in dispose.
/// Passes the WebSocketChannel to child widgets as needed.
class _MainAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;

  /// The WebSocket channel connecting to the bridging server
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  /// Connects to the bridging server and sends the "open" command
  void _connectWebSocket() {
    const url = 'ws://100.121.101.39:10980';
    try {
      _channel = HtmlWebSocketChannel.connect(url);
      debugPrint('Connecting to bridging server at $url');
    } catch (e, st) {
      debugPrint('Error connecting to bridging server: $e\n$st');
      _channel = null;
      return;
    }

    // Listen for messages from the server
    _channel!.stream.listen(
      (rawMessage) {
        debugPrint('Received from server (raw): $rawMessage');
        _handleServerMessage(rawMessage);
      },
      onError: (err) => debugPrint('WebSocket onError: $err'),
      onDone: () => debugPrint('WebSocket connection closed.'),
    );

    // Send "open" command to establish the SQL connection
    final openCmd = {
      "type": "open",
      "text": "Server=MT-server\\SQLEXPRESS;"
          "Database=1148-Scouting;"
          "User Id=1148Robotics;Password=1148Robotics;"
          "Trusted_Connection=yes;",
    };
    _sendLengthPrefixed(openCmd);
  }

  /// Parses incoming messages and delegates handling based on message type
  void _handleServerMessage(String raw) {
    try {
      final i = raw.indexOf('\r\n');
      if (i <= 0) return;
      final len = int.parse(raw.substring(0, i));
      final jsonPart = raw.substring(i + 2);
      if (jsonPart.length == len) {
        final decoded = jsonDecode(jsonPart);
        _processDecoded(decoded);
      } else {
        debugPrint(
            'Received message length mismatch: Expected $len, got ${jsonPart.length}');
      }
    } catch (e) {
      debugPrint('Error handling server message: $e');
    }
  }

  /// Handles different types of messages from the server
  void _processDecoded(dynamic msg) {
    if (msg is! Map) return;
    final type = msg["type"];

    switch (type) {
      case "ok":
        debugPrint('Server responded with "ok".');
        break;

      case "error":
        debugPrint('Server error: ${msg["error"]}');
        break;

      case "query":
        // Handle responses from "query" commands (e.g., INSERT, SELECT)
        final rows = msg["rows"];
        if (rows == null || (rows is List && rows.isEmpty)) {
          debugPrint(
              'Server says "query" completed. No rows returned (likely INSERT).');
        } else {
          debugPrint('Server says "query" completed. Rows: $rows');
        }
        break;

      default:
        debugPrint('Unknown message type: $type => $msg');
        break;
    }
  }

  /// Sends a length-prefixed JSON message to the server
  void _sendLengthPrefixed(Map<String, dynamic> msg) {
    if (_channel == null) return;
    try {
      final encoded = jsonEncode(msg);
      final prefix = '${encoded.length}\r\n';
      _channel!.sink.add(prefix + encoded);
      debugPrint('Sent to server: ${msg["type"]}');
    } catch (e) {
      debugPrint('Error sending message to server: $e');
    }
  }

  @override
  void dispose() {
    // Send "close" command to gracefully close the SQL connection
    final closeCmd = {"type": "close", "text": ""};
    _sendLengthPrefixed(closeCmd);

    // Close the WebSocket connection
    _channel?.sink.close();
    _channel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scouting Home Page',
      theme: ThemeData.from(colorScheme: lightColorScheme),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme),
      themeMode: themeMode,
      home: ObjectivePage(
        key: const Key('objective_page'),
        onThemeChanged: (ThemeMode mode) {
          setState(() {
            themeMode = mode;
          });
        },

        /// Pass the WebSocket channel to ObjectivePage
        channel: _channel,
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
