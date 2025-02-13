import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Import your full-featured Table, ColumnDefinition, ChangeSet, etc. from table.dart
import 'table.dart';

/// A raw‐socket SQL client that sends/receives length‐prefixed JSON
/// messages like {"type":"open","text":"Server=..."} to a bridging server.
///
/// This version references the advanced `Table` (with row-change logic)
/// from your separate `table.dart`.
class SqlConnection {
  late Socket _socket;
  late StringBuffer _receiveBuffer;
  late Completer<String> _completer;
  late bool _connected;

  late String _address;
  late int _port;
  late String
      _connectionString; // e.g. "Server=MT-server\\SQLEXPRESS;Database=..."

  /// True if we successfully opened and haven't closed yet.
  bool get connected => _connected;

  /// Provide a connection string (e.g., Server=...;Database=...;User Id=..., etc.)
  /// plus the address/port for the raw-socket bridging server.
  SqlConnection(
    String connStr, {
    String address = "MT-server",
    int port = 10981,
  }) {
    _address = address;
    _port = port;
    _connected = false;
    _connectionString = connStr;
  }

  // -----------------------------------------------------------------
  // CORE METHODS: open(), close(), basic query()
  // -----------------------------------------------------------------

  /// Opens a raw TCP socket to [_address]:[_port], then sends:
  ///   { "type": "open", "text": _connectionString }
  /// If bridging server responds with {"type":"ok"}, we set _connected=true.
  /// If it responds with {"type":"error"}, we throw an error.
  Future<bool> open() async {
    try {
      print('[SqlConnection] connecting to $_address:$_port ...');
      _socket = await Socket.connect(_address, _port);
      print('[SqlConnection] connected to $_address:$_port');
    } catch (ex) {
      throw "Can't connect to $_address:$_port => $ex";
    }

    _connected = false;

    // Listen for bridging server responses
    utf8.decoder.bind(_socket).listen(
          _receiveData,
          onError: _onError,
          onDone: _onDone,
        );

    final connectCompleter = Completer<bool>();

    // Send "open" command
    final jsonCmd = jsonEncode({
      "type": "open",
      "text": _connectionString,
    });

    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);
      if (res is _OkResult) {
        _connected = true;
        connectCompleter.complete(true);
      } else if (res is _ErrorResult) {
        connectCompleter.completeError(res.error);
      } else {
        connectCompleter.completeError("Unexpected response to open()");
      }
    }).catchError((err) {
      connectCompleter.completeError(err);
    });

    return connectCompleter.future;
  }

  /// Closes the connection by sending { "type": "close", "text": "" }.
  /// If bridging server responds "ok", sets _connected=false; if "error", throw.
  Future<bool> close() {
    if (!_connected) {
      throw "Not connected, cannot close.";
    }
    final disconnectCompleter = Completer<bool>();

    final jsonCmd = jsonEncode({
      "type": "close",
      "text": "",
    });

    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);
      if (res is _OkResult) {
        _connected = false;
        disconnectCompleter.complete(true);
      } else if (res is _ErrorResult) {
        disconnectCompleter.completeError(res.error);
      } else {
        disconnectCompleter.completeError("Unexpected response to close()");
      }
    }).catchError((err) {
      disconnectCompleter.completeError(err);
    });

    return disconnectCompleter.future;
  }

  /// Basic query returning List<dynamic> rows.
  /// Sends { "type":"query", "text": sql }, expects { "type":"query", "rows":[...] } from bridging server.
  Future<List<dynamic>> query(String sql) {
    if (!_connected) {
      throw "Not connected, cannot query.";
    }

    final jsonCmd = jsonEncode({
      "type": "query",
      "text": sql,
    });

    final compl = Completer<List<dynamic>>();
    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);
      if (res is _ErrorResult) {
        compl.completeError(res.error);
      } else if (res is _QueryResult) {
        compl.complete(res.rows);
      } else {
        compl.completeError("Unknown response to query()");
      }
    }).catchError((err) {
      compl.completeError(err);
    });

    return compl.future;
  }

  // -----------------------------------------------------------------
  // ADDITIONAL METHODS: queryTable(), postBack(), querySingle(), queryValue(), execute()
  // -----------------------------------------------------------------

  /// Runs a query expecting { "type":"table", "tablename":..., "rows":[...], "columns":[...] }.
  /// The bridging server must handle "table" messages.
  /// If it responds with a Table-like structure, we return a real [Table] (from table.dart).
  Future<Table> queryTable(String sql) {
    if (!connected) {
      throw "Not connected, cannot queryTable.";
    }

    final jsonCmd = jsonEncode({
      "type": "table",
      "text": sql,
    });

    final compl = Completer<Table>();
    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);

      if (res is _ErrorResult) {
        compl.completeError(res.error);
      } else if (res is _TableResult) {
        // Build a Table object (from table.dart) using the bridging server's data
        final table = Table(
          this, // the SqlConnection
          res.tableName, // e.g. result["tablename"]
          res.rows, // List<Map<String,dynamic>>
          res.columns, // List<Map<String,String>>
        );
        compl.complete(table);
      } else {
        compl.completeError("Unexpected response to queryTable()");
      }
    }).catchError((err) {
      compl.completeError(err);
    });

    return compl.future;
  }

  /// POSTBACK operation. Typically used to push changes from a Table to the server.
  /// bridging server must handle { "type":"postback" } and return { "type":"postback", "idcolumn":"...", "identities":[...] }
  Future<PostBackResponse> postBack(ChangeSet chg) {
    if (!connected) {
      throw "Not connected, cannot postBack.";
    }

    final params = jsonEncode(chg.toEncodable());
    final jsonCmd = jsonEncode({
      "type": "postback",
      "text": params,
    });

    final compl = Completer<PostBackResponse>();
    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);

      if (res is _ErrorResult) {
        compl.completeError(res.error);
      } else if (res is _PostBackResult) {
        // Build a real PostBackResponse from bridging server data
        final resp = PostBackResponse();
        resp.idcolumn = res.idcolumn;
        resp.identities = res.identities;
        compl.complete(resp);
      } else {
        compl.completeError("Invalid postback response");
      }
    }).catchError((err) {
      compl.completeError(err);
    });

    return compl.future;
  }

  /// Runs a "querysingle" type, which returns the first row or null if none.
  /// bridging server must implement { "type":"querysingle" } => { "type":"query", "rows":[...] }
  Future<Map<String, dynamic>?> querySingle(String sql) {
    if (!connected) {
      throw "Not connected, cannot querySingle.";
    }

    final jsonCmd = jsonEncode({
      "type": "querysingle",
      "text": sql,
    });

    final compl = Completer<Map<String, dynamic>?>();
    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);
      if (res is _ErrorResult) {
        compl.completeError(res.error);
      } else if (res is _QueryResult) {
        if (res.rows.isEmpty) {
          compl.complete(null);
        } else {
          final firstRow = res.rows[0];
          if (firstRow is Map<String, dynamic>) {
            compl.complete(firstRow);
          } else {
            // If rows aren't Maps for some reason
            compl.completeError("Unexpected row type in querySingle");
          }
        }
      } else {
        compl.completeError("Unknown response to querySingle()");
      }
    }).catchError((err) {
      compl.completeError(err);
    });

    return compl.future;
  }

  /// Runs a "queryvalue" type, which returns a single value from the first row/column, or null if none.
  Future<dynamic> queryValue(String sql) {
    if (!connected) {
      throw "Not connected, cannot queryValue.";
    }

    final jsonCmd = jsonEncode({
      "type": "queryvalue",
      "text": sql,
    });

    final compl = Completer<dynamic>();
    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);
      if (res is _ErrorResult) {
        compl.completeError(res.error);
      } else if (res is _QueryResult) {
        if (res.rows.isEmpty) {
          compl.complete(null);
        } else {
          // bridging server typically returns rows[0]["value"]
          final firstRow = res.rows[0];
          if (firstRow is Map<String, dynamic>) {
            compl.complete(firstRow["value"]);
          } else {
            compl.completeError("Unexpected row type in queryValue");
          }
        }
      } else {
        compl.completeError("Unknown response to queryValue()");
      }
    }).catchError((err) {
      compl.completeError(err);
    });

    return compl.future;
  }

  /// Executes a SQL command (INSERT, UPDATE, DELETE) returning the # of rows affected.
  /// bridging server must handle { type:"execute", text: "..."} => usually responds with { type:"query", rows:[ { rowsAffected: N } ] }
  Future<int> execute(String sql) {
    if (!connected) {
      throw "Not connected, cannot execute.";
    }

    final jsonCmd = jsonEncode({
      "type": "execute",
      "text": sql,
    });

    final compl = Completer<int>();
    _sendCommand(jsonCmd).then((respStr) {
      final res = _parseResult(respStr);
      if (res is _ErrorResult) {
        compl.completeError(res.error);
      } else if (res is _QueryResult) {
        if (res.rows.isEmpty) {
          compl.complete(-1);
        } else {
          final row0 = res.rows[0];
          if (row0 is Map && row0.containsKey("rowsAffected")) {
            compl.complete(row0["rowsAffected"]);
          } else {
            compl.complete(-1);
          }
        }
      } else {
        compl.completeError("Unknown response to execute()");
      }
    }).catchError((err) {
      compl.completeError(err);
    });

    return compl.future;
  }

  // -----------------------------------------------------------------
  // INTERNAL: Socket read/write and result parsing
  // -----------------------------------------------------------------

  /// Sends "length\r\njson" to the bridging server, returns a Future<String>
  /// that completes when we get the bridging server's reply (also length\r\njson).
  Future<String> _sendCommand(String command) {
    _receiveBuffer = StringBuffer();
    _completer = Completer<String>();

    final payload = '${command.length}\r\n$command';
    _socket.write(payload);

    return _completer.future;
  }

  /// Called when the bridging server closes the socket or the connection ends.
  void _onDone() {
    print('[SqlConnection] onDone() - server closed the socket?');
  }

  /// Called if there's a socket-level error (I/O, network, etc.).
  void _onError(error) {
    print('[SqlConnection] onError: $error');
  }

  /// Accumulates incoming data, looking for "length\r\njson".
  /// Once we detect a complete JSON chunk, we complete _completer with that JSON string.
  void _receiveData(dynamic data) {
    if (_completer.isCompleted) return;

    _receiveBuffer.write(data);
    final content = _receiveBuffer.toString();

    final idx = content.indexOf("\r\n");
    if (idx > 0) {
      final len = int.parse(content.substring(0, idx));
      final cmd = content.substring(idx + 2);
      if (cmd.length == len) {
        _completer.complete(cmd);
      }
    }
  }

  /// Parse the JSON from the bridging server into one of our internal result classes
  /// (e.g., _OkResult, _ErrorResult, _QueryResult, _TableResult, _PostBackResult).
  dynamic _parseResult(String jsonStr) {
    final Map result = jsonDecode(jsonStr);

    switch (result["type"]) {
      case "ok":
        return _OkResult("ok");
      case "error":
        return _ErrorResult(result["error"]);
      case "query":
        return _QueryResult(
          result["rows"],
          result["columns"],
        );
      case "table":
        return _TableResult(
          result["tablename"],
          result["rows"],
          result["columns"],
        );
      case "postback":
        return _PostBackResult(
          result["idcolumn"],
          result["identities"],
        );
      default:
        throw "Unknown response type: ${result["type"]}";
    }
  }
}

// ---------------------------------------------------------------------
// INTERNAL RESULT CLASSES used by _parseResult
// ---------------------------------------------------------------------

class _ErrorResult {
  final String error;
  _ErrorResult(this.error);
}

class _OkResult {
  final String ok;
  _OkResult(this.ok);
}

/// For { "type":"query", "rows":[...], "columns": {...} }
class _QueryResult {
  final List<dynamic> rows;
  final Map<String, dynamic> columns;

  _QueryResult(
    List<dynamic> rowsData,
    Map<String, dynamic>? columnsData,
  )   : rows = rowsData,
        columns = columnsData ?? {};
}

/// For { "type":"table", "tablename": "...", "rows":[...], "columns":[...] }
class _TableResult {
  final String tableName;
  final List<Map<String, dynamic>> rows;
  final List<Map<String, String>> columns;

  _TableResult(
    this.tableName,
    this.rows,
    this.columns,
  );
}

/// For { "type":"postback", "idcolumn":"...", "identities":[1,2,3] }
class _PostBackResult {
  final String idcolumn;
  final List<int> identities;
  _PostBackResult(this.idcolumn, this.identities);
}

/// Optionally used to fix "datetime" or other typed columns
class TypeFixer {
  static void fixColumn(
    List<dynamic> rows,
    String columnName,
    String columnType,
  ) {
    if (columnType == "datetime") {
      for (int i = 0; i < rows.length; i++) {
        if (rows[i][columnName] != null) {
          rows[i][columnName] = DateTime.parse(rows[i][columnName]);
        }
      }
    }
  }
}
