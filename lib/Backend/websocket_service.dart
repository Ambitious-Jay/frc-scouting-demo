import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<dynamic>? _controller;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _manualClose = false; // Flag for manual close

  /// URL of the WebSocket bridging server
  static const String _url = 'ws://100.121.101.39:10980';

  /// Expose a nullable broadcast stream
  Stream<dynamic>? get stream => _controller?.stream;

  /// FIX: Return the actual channel instead of null.
  WebSocketChannel? get channel => _channel;

  /// Initialize the WebSocket connection
  void connect() {
    if (_isConnecting || _isConnected) {
      print(
          '[WebSocketService] Already connected or connecting. Skipping connect().');
      return;
    }

    print('[WebSocketService] Attempting to connect to $_url');
    _isConnecting = true;
    _manualClose = false; // reset manual close flag

    try {
      _controller = StreamController<dynamic>.broadcast();
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

    // Listen to the channel
    _channel!.stream.listen(
      (rawMessage) {
        print('[WebSocketService] Received from server: $rawMessage');
        _controller?.add(rawMessage);
      },
      onError: (err) {
        print('[WebSocketService] WebSocket onError: $err');
        _isConnected = false;
        _controller?.addError(err);
        _controller?.close();
        _controller = null;
        if (!_manualClose) {
          _attemptReconnect();
        }
      },
      onDone: () {
        print('[WebSocketService] WebSocket connection closed.');
        _isConnected = false;
        _controller?.close();
        _controller = null;
        if (!_manualClose) {
          _attemptReconnect();
        } else {
          print('[WebSocketService] Manual close => no reconnect.');
          _manualClose = false; // reset
        }
      },
      cancelOnError: true,
    );

    // Optionally send an "open" command to establish the SQL connection
    final openCmd = {
      "type": "open",
      "text": "Server=MT-server\\SQLEXPRESS;"
          "Database=1148-Scouting;"
          "User Id=1148Robotics;Password=1148Robotics;"
          "Trusted_Connection=yes;",
    };
    sendLengthPrefixed(openCmd);
  }

  /// Sends a length-prefixed JSON message
  void sendLengthPrefixed(Map<String, dynamic> msg) {
    if (_channel == null) {
      print('[WebSocketService] Cannot send message. No active channel.');
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

  /// Closes the WebSocket connection manually
  void disconnect() {
    if (_channel != null) {
      print('[WebSocketService] Disconnecting...');
      _manualClose = true; // Mark that we closed intentionally

      // Optionally tell server to close DB connection
      final closeCmd = {"type": "close", "text": ""};
      sendLengthPrefixed(closeCmd);

      // Close the WebSocket
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;

      print('[WebSocketService] WebSocket connection closed by client.');
    }
  }

  /// Attempts to reconnect after 5 seconds
  void _attemptReconnect() {
    if (_isConnecting) return;
    print('[WebSocketService] Attempting to reconnect in 5 seconds...');
    Future.delayed(const Duration(seconds: 5), () {
      if (!_manualClose && !_isConnected) {
        print('[WebSocketService] Reconnecting...');
        connect();
      }
    });
  }
}
