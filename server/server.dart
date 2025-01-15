import 'dart:io';
import 'dart:convert';
import 'package:frc1148_2025_scouting_app/SQLServerSocket/DartClient/lib/sqlconnection.dart';
// import 'package:frc1148_2025_scouting_app/SQLServerSocket/DartClient/lib/table.dart';

SqlConnection? globalConn;

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 10980);
  print(
      'WebSocket bridging server running on ws://${server.address.host}:${server.port}');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      // Start timing the WebSocket handshake
      final handshakeStopwatch = Stopwatch()..start();

      final ws = await WebSocketTransformer.upgrade(request);

      // Stop timing after the handshake completes
      handshakeStopwatch.stop();
      final handshakeMs = handshakeStopwatch.elapsedMilliseconds;
      print('New WebSocket connection: ${ws.hashCode}, '
          'handshake took $handshakeMs ms');

      final buffer = StringBuffer();

      ws.listen(
        (data) async {
          // data is "length\r\njson"
          buffer.write(data);
          final content = buffer.toString();
          final idx = content.indexOf('\r\n');
          if (idx > 0) {
            final len = int.parse(content.substring(0, idx));
            final cmd = content.substring(idx + 2);
            if (cmd.length == len) {
              buffer.clear();
              try {
                final message = jsonDecode(cmd);
                if (message is Map) {
                  await _handleMessage(ws, message.cast<String, dynamic>());
                }
              } catch (e, st) {
                print('Error parsing JSON: $e\n$st');
                _sendReply(ws, {
                  "type": "error",
                  "error": "Invalid JSON: $e",
                  "elapsedMs": 0
                });
              }
            }
          }
        },
        onError: (err) => print('WebSocket error: $err'),
        onDone: () => print('WebSocket closed: ${ws.hashCode}'),
      );
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
    }
  }
}

Future<void> _handleMessage(WebSocket ws, Map<String, dynamic> msg) async {
  final type = msg["type"];
  final text = msg["text"] ?? "";

  switch (type) {
    case "open":
      {
        print('Client requests "open" with connStr="$text"');
        globalConn?.close();

        globalConn = SqlConnection(
          text,
          address:
              "100.121.101.39", // your .NET bridging server machine name / IP
          port: 10981, // .NET bridging server's port
        );

        // Time how long it takes to open the SQL connection
        final stopwatch = Stopwatch()..start();
        try {
          await globalConn!.open();
          stopwatch.stop();
          print('globalConn connected: ${globalConn!.connected}');
          _sendReply(ws, {
            "type": "ok",
            "elapsedMs": stopwatch.elapsedMilliseconds,
          });
        } catch (e) {
          stopwatch.stop();
          print('Error opening connection: $e');
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
        if (globalConn == null || !globalConn!.connected) {
          _sendReply(ws, {
            "type": "error",
            "error": "No open connection.",
            "elapsedMs": 0
          });
          return;
        }
        print('Client requests "query" => $text');

        // Time how long the query takes
        final stopwatch = Stopwatch()..start();
        try {
          // Actually call the raw-socket .NET bridging
          final rows = await globalConn!.query(text);

          stopwatch.stop();
          print('Query completed in ${stopwatch.elapsedMilliseconds} ms.');

          // Example: Print rows in console in a nice table format
          if (rows.isEmpty) {
            print('[Query] No rows returned.');
          } else if (rows.first is Map<String, dynamic>) {
            final firstRow = rows.first as Map<String, dynamic>;
            final columns = firstRow.keys.toList();

            // Print column headers
            print(columns.join(' | '));
            // Print a separator
            print('-' * (columns.join(' | ').length));

            // Print each row
            for (final row in rows) {
              final rowMap = row as Map<String, dynamic>;
              final rowData = columns.map((col) {
                final val = rowMap[col];
                return val == null ? 'NULL' : val.toString();
              }).toList();
              print(rowData.join(' | '));
            }
          } else {
            // If it's not a list of maps, just print raw
            print('[Query] Got ${rows.length} rows (not Map-based).');
            print(rows);
          }

          // Respond to Flutter with the rows + elapsed time
          _sendReply(ws, {
            "type": "query",
            "rows": rows,
            "elapsedMs": stopwatch.elapsedMilliseconds,
          });
        } catch (e, st) {
          stopwatch.stop();
          print('Error in query: $e\n$st');
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
        print('Client requests "close"');
        // Time how long closing takes
        final stopwatch = Stopwatch()..start();

        if (globalConn != null && globalConn!.connected) {
          await globalConn!.close();
          globalConn = null;
        }
        stopwatch.stop();

        _sendReply(ws, {
          "type": "ok",
          "elapsedMs": stopwatch.elapsedMilliseconds,
        });
      }
      break;

    default:
      _sendReply(ws, {
        "type": "error",
        "error": "Unknown message type: $type",
        "elapsedMs": 0
      });
      break;
  }
}

/// Helper to send length‐prefixed JSON back to Flutter
void _sendReply(WebSocket ws, Map<String, dynamic> msg) {
  final encoded = jsonEncode(msg);
  final prefix = '${encoded.length}\r\n';
  ws.add(prefix + encoded);
}
