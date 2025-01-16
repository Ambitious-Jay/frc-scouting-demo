import 'dart:io';
import 'dart:convert';

import 'package:frc1148_2025_scouting_app/SQLServerSocket/DartClient/lib/sqlconnection.dart';

/// Tracks each WebSocket client and its own SqlConnection.
/// This design supports multiple clients connecting, so each client
/// has its own distinct connection rather than one global connection.
final Map<WebSocket, SqlConnection?> _connections = {};

Future<void> main() async {
  HttpServer? server;

  try {
    // Binds to port 10980 on all IPv4 interfaces
    server = await HttpServer.bind(InternetAddress.anyIPv4, 10980);
    print(
        'WebSocket bridging server running on ws://${server.address.host}:${server.port}');
  } catch (e, st) {
    print('Error binding server on port 10980: $e\n$st');
    return;
  }

  // Listens for incoming HttpRequests
  await for (HttpRequest request in server) {
    // Checks if the incoming request is a valid WebSocket upgrade request
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final handshakeStopwatch = Stopwatch()..start();

      WebSocket? ws;
      try {
        // Attempts to upgrade the request to a WebSocket
        ws = await WebSocketTransformer.upgrade(request);
      } catch (e, st) {
        print('Error upgrading connection to WebSocket: $e\n$st');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
        continue;
      }

      handshakeStopwatch.stop();
      final handshakeMs = handshakeStopwatch.elapsedMilliseconds;
      print(
          'New WebSocket client: ${ws.hashCode}, handshake took $handshakeMs ms');

      // Store a null SqlConnection for this client until they send "open"
      _connections[ws] = null;

      // Listens for messages from this WebSocket client
      // and handles them in _handleRawData.
      ws.listen(
        (data) => _handleRawData(ws!, data),
        onError: (err) =>
            print('WebSocket error from client ${ws.hashCode}: $err'),
        onDone: () => _onClientDone(ws!),
      );
    } else {
      // Forbid non-WebSocket requests
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
    }
  }
}

/// Reads "length\r\njson" from the client, decodes the JSON,
/// and hands off to _handleMessage for actual logic.
void _handleRawData(WebSocket ws, dynamic data) {
  try {
    final raw = data.toString();
    final idx = raw.indexOf('\r\n');
    if (idx <= 0) return; // Ignore malformed data
    final len = int.parse(raw.substring(0, idx));
    final jsonPart = raw.substring(idx + 2);

    if (jsonPart.length != len) return; // Length mismatch, ignore

    final msg = jsonDecode(jsonPart);
    if (msg is Map<String, dynamic>) {
      _handleMessage(ws, msg);
    }
  } catch (e, st) {
    print('Error processing data from client ${ws.hashCode}: $e\n$st');
    _sendReply(ws, {
      "type": "error",
      "error": "Invalid message: $e",
      "elapsedMs": 0,
    });
  }
}

/// Handles "open", "query", and "close" commands for each WebSocket client.
/// Each WebSocket has its own entry in _connections.
Future<void> _handleMessage(WebSocket ws, Map<String, dynamic> msg) async {
  final type = msg["type"];
  final text = (msg["text"] ?? "") as String;

  switch (type) {
    case "open":
      {
        print('Client ${ws.hashCode} requests "open" with connStr="$text"');
        // If there's an existing connection, close it to avoid conflicts
        await _closeConnectionFor(ws);

        final conn = SqlConnection(
          text,
          address: "100.121.101.39",
          port: 10981,
        );
        _connections[ws] = conn;

        final stopwatch = Stopwatch()..start();
        try {
          await conn.open();
          stopwatch.stop();
          print('Client ${ws.hashCode} connected to DB: ${conn.connected}');
          _sendReply(ws, {
            "type": "ok",
            "elapsedMs": stopwatch.elapsedMilliseconds,
          });
        } catch (e) {
          stopwatch.stop();
          print('Error opening connection for client ${ws.hashCode}: $e');
          _connections[ws] = null;
          _sendReply(ws, {
            "type": "error",
            "error": e.toString(),
            "elapsedMs": stopwatch.elapsedMilliseconds,
          });
        }
      }
      break;

    case "query":
      {
        final conn = _connections[ws];
        if (conn == null || !conn.connected) {
          _sendReply(ws, {
            "type": "error",
            "error": "No open connection for this client.",
            "elapsedMs": 0
          });
          return;
        }
        print('Client ${ws.hashCode} requests "query": $text');

        final stopwatch = Stopwatch()..start();
        try {
          // Calls .query(...) on that client's SqlConnection
          final rows = await conn.query(text);
          stopwatch.stop();

          print(
              'Query for client ${ws.hashCode} took ${stopwatch.elapsedMilliseconds} ms, returned ${rows.length} rows.');

          _sendReply(ws, {
            "type": "query",
            "rows": rows,
            "elapsedMs": stopwatch.elapsedMilliseconds,
          });
        } catch (e, st) {
          stopwatch.stop();
          print('Error in query for client ${ws.hashCode}: $e\n$st');
          _sendReply(ws, {
            "type": "error",
            "error": e.toString(),
            "elapsedMs": stopwatch.elapsedMilliseconds,
          });
        }
      }
      break;

    case "close":
      {
        print('Client ${ws.hashCode} requests "close"');
        final stopwatch = Stopwatch()..start();
        await _closeConnectionFor(ws);
        stopwatch.stop();
        _sendReply(ws, {
          "type": "ok",
          "elapsedMs": stopwatch.elapsedMilliseconds,
        });
      }
      break;

    default:
      // Unknown command
      _sendReply(ws, {
        "type": "error",
        "error": "Unknown message type: $type",
        "elapsedMs": 0
      });
      break;
  }
}

/// Closes the connection for a particular WebSocket client if it's open.
Future<void> _closeConnectionFor(WebSocket ws) async {
  final conn = _connections[ws];
  if (conn != null && conn.connected) {
    try {
      await conn.close();
    } catch (e) {
      print('Error closing connection for client ${ws.hashCode}: $e');
    }
  }
  _connections[ws] = null;
}

/// Called when the client WebSocket is done (onDone). Removes from map.
void _onClientDone(WebSocket ws) {
  print('WebSocket closed: ${ws.hashCode}');
  _closeConnectionFor(ws);
  _connections.remove(ws);
}

/// Sends a JSON reply in "length\r\njson" format to the specified client.
void _sendReply(WebSocket ws, Map<String, dynamic> msg) {
  final encoded = jsonEncode(msg);
  final prefix = '${encoded.length}\r\n';
  try {
    ws.add(prefix + encoded);
  } catch (e) {
    print('Error sending reply to client ${ws.hashCode}: $e');
  }
}
