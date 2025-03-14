import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

class AutoTablePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final String teamNumber;
  final WebSocketService webSocketService;

  const AutoTablePage({
    Key? key,
    required this.onThemeChanged,
    required this.teamNumber,
    required this.webSocketService,
  }) : super(key: key);

  @override
  State<AutoTablePage> createState() => _AutoTablePageState();
}

class _AutoTablePageState extends State<AutoTablePage> {
  ThemeMode themeMode = ThemeMode.system;

  // Lists to hold each column's data:
  List<String> startingPositionList = [];
  List<String> zoneDataList = [];
  List<String> fieldFlippedList = [];
  List<String> coralDataList = [];
  List<String> algaeDataList = [];

  /// A helper function to interpret "truthy" values from the DB (BIT columns).
  bool isTrue(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val; // e.g., true or false
    if (val is int) return val == 1; // e.g., 1 or 0
    if (val is String) {
      // e.g., "1", "true", "True"
      return val == '1' || val.toLowerCase() == 'true';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _fetchAutoScoutingData();
  }

  Future<void> _fetchAutoScoutingData() async {
    final String teamNumber = widget.teamNumber;
    final String sql = """
      SELECT match_number, start_position,
             l4_count, l2_l3_count, l1_count,
             net_count, processor_count,
             in_center_zone, in_left_zone, in_right_zone,
             is_blue, field_flipped
      FROM AutoScouting
      WHERE team_number = 'frc$teamNumber'
    """;

    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };

    final completer = Completer<List<Map<String, dynamic>>>();
    late StreamSubscription sub;
    List<Map<String, dynamic>> rowsResult = [];

    // Listen for the query result
    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;

        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          rowsResult = rows.map((r) => Map<String, dynamic>.from(r)).toList();
          completer.complete(rowsResult);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final rows = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );
    await sub.cancel();

    if (rows.isEmpty) {
      debugPrint("No auto scouting data found for team $teamNumber");
      return;
    }

    setState(() {
      // Starting position
      startingPositionList = rows.map((row) {
        return row["start_position"]?.toString() ?? "N/A";
      }).toList();

      // Zones
      zoneDataList = rows.map((row) {
        List<String> zones = [];
        if (isTrue(row["in_left_zone"])) zones.add("Left");
        if (isTrue(row["in_center_zone"])) zones.add("Center");
        if (isTrue(row["in_right_zone"])) zones.add("Right");
        return zones.isNotEmpty ? zones.join(", ") : "N/A";
      }).toList();

      // Field flipped
      fieldFlippedList = rows.map((row) {
        return isTrue(row["field_flipped"]) ? "Flipped" : "Normal";
      }).toList();

      // Coral
      coralDataList = rows.map((row) {
        return "L4: ${row["l4_count"]}, L2/L3: ${row["l2_l3_count"]}, L1: ${row["l1_count"]}";
      }).toList();

      // Algae (net + processor)
      algaeDataList = rows.map((row) {
        return "Net: ${row["net_count"]}, Processor: ${row["processor_count"]}";
      }).toList();
    });
  }

  /// Builds a text cell for the table.
  Widget _cell(String text, double fontSize, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fixed smaller font size for mobile
    const double fontSize = 14.0;

    // Build the table rows
    final List<TableRow> rows = [];

    // Header row
    rows.add(
      TableRow(
        children: [
          _cell("Start", fontSize, isHeader: true),
          _cell("Zone", fontSize, isHeader: true),
          _cell("Field", fontSize, isHeader: true),
          _cell("Coral", fontSize, isHeader: true),
          _cell("Algae", fontSize, isHeader: true),
        ],
      ),
    );

    // Data rows
    for (int i = 0; i < startingPositionList.length; i++) {
      rows.add(
        TableRow(
          children: [
            _cell(startingPositionList[i], fontSize),
            _cell(zoneDataList[i], fontSize),
            _cell(fieldFlippedList[i], fontSize),
            _cell(coralDataList[i], fontSize),
            _cell(algaeDataList[i], fontSize),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Auto Table'),
      ),
      // We allow both horizontal and vertical scrolling for the table
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            // Optional: Add borders if desired
            // border: TableBorder.all(color: Colors.grey),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: rows,
          ),
        ),
      ),
    );
  }
}
