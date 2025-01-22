// lib/Backend/websocket_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() => _instance;

  WebSocketService._internal() {
    connect();
  }

  WebSocketChannel? _channel;
  StreamController<dynamic> _controller = StreamController.broadcast();
  bool _isConnecting = false;
  bool _isConnected = false;

  /// URL of the WebSocket bridging server
  static const String _url = 'ws://100.121.101.39:10980';

  /// Stream of incoming messages
  Stream<dynamic> get stream => _controller.stream;

  /// Initialize the WebSocket connection
  void connect() {
    if (_isConnecting || _isConnected) {
      print('[WebSocketService] Already connected or connecting.');
      return;
    }

    _isConnecting = true;
    print('[WebSocketService] Attempting to connect to $_url');

    try {
      _channel = HtmlWebSocketChannel.connect(_url);
      _isConnected = true;
      _isConnecting = false;
      print('[WebSocketService] Successfully connected to $_url');
    } catch (e, st) {
      _isConnecting = false;
      _isConnected = false;
      print('[WebSocketService] Error connecting to $_url: $e\n$st');
      _attemptReconnect();
      return;
    }

    // Listen for incoming messages and add them to the controller
    _channel!.stream.listen(
      (rawMessage) {
        print('[WebSocketService] Received from server: $rawMessage');
        _controller.add(rawMessage);
      },
      onError: (err) {
        print('[WebSocketService] WebSocket onError: $err');
        _isConnected = false;
        _attemptReconnect();
      },
      onDone: () {
        print('[WebSocketService] WebSocket connection closed.');
        _isConnected = false;
        _attemptReconnect();
      },
    );

    // Send "open" command to establish the SQL connection
    final openCmd = {
      "type": "open",
      "text": "Server=MT-server\\SQLEXPRESS;"
          "Database=1148-Scouting;"
          "User Id=1148Robotics;Password=1148Robotics;"
          "Trusted_Connection=yes;",
    };
    sendLengthPrefixed(openCmd);
  }

  /// Sends a length-prefixed JSON message to the server
  void sendLengthPrefixed(Map<String, dynamic> msg) {
    if (_channel == null) {
      print('[WebSocketService] Cannot send message. No active WebSocket connection.');
      return;
    }
    try {
      final encoded = jsonEncode(msg);
      final prefix = '${encoded.length}\r\n';
      _channel!.sink.add(prefix + encoded);
      print('[WebSocketService] Sent to server: ${msg["type"]}');
    } catch (e) {
      print('[WebSocketService] Error sending message to server: $e');
    }
  }

  /// Closes the WebSocket connection
  void disconnect() {
    if (_channel != null) {
      // Send "close" command to gracefully close the SQL connection
      final closeCmd = {"type": "close", "text": ""};
      sendLengthPrefixed(closeCmd);

      // Close the WebSocket connection
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      print('[WebSocketService] WebSocket connection closed by client.');
    }
    _controller.close();
  }

  /// Attempts to reconnect after a delay
  void _attemptReconnect() {
    if (_isConnecting) return;
    print('[WebSocketService] Attempting to reconnect in 5 seconds...');
    Future.delayed(const Duration(seconds: 5), () {
      print('[WebSocketService] Reconnecting...');
      connect();
    });
  }
}
