import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

/// Model to hold the controllers for each team row.
class ScoutingData {
  TextEditingController compatibilityController;
  TextEditingController notableFeatsController;
  TextEditingController humanPlayerNetAccController;

  ScoutingData({
    required this.compatibilityController,
    required this.notableFeatsController,
    required this.humanPlayerNetAccController,
  });
}

class LeadScoutingPage extends StatefulWidget {
  const LeadScoutingPage({
    super.key,
    // For lead scouts, teamName now holds all three teams as a comma-separated string.
    required this.teamName,
    required this.matchNumber,
    required this.webSocketService,
    required this.onThemeChanged,
  });
  final String teamName;
  final String matchNumber; // retained for UI display if needed
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;

  @override
  State<LeadScoutingPage> createState() => _LeadScoutingPageState();
}

class _LeadScoutingPageState extends State<LeadScoutingPage> {
  String _username = "";
  late List<String> _teamNumbers; // Parsed list of team numbers
  late List<ScoutingData> _scoutingData;

  @override
  void initState() {
    super.initState();
    // Ensure the WebSocketService is connected.
    widget.webSocketService.connect();

    // Parse comma-separated team names.
    _teamNumbers = widget.teamName.split(",").map((s) => s.trim()).toList();
    // Pad with empty strings if there are fewer than 3 teams.
    while (_teamNumbers.length < 3) {
      _teamNumbers.add("");
    }
    // Initialize controllers for each team.
    _scoutingData = List.generate(
      _teamNumbers.length,
      (index) => ScoutingData(
        compatibilityController: TextEditingController(),
        notableFeatsController: TextEditingController(),
        humanPlayerNetAccController: TextEditingController(),
      ),
    );

    // Get the username.
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });

    // Fetch initial data using a dedicated query-response pattern.
    _fetchScoutingData();
  }

  @override
  void dispose() {
    // Dispose of all text controllers.
    for (final data in _scoutingData) {
      data.compatibilityController.dispose();
      data.notableFeatsController.dispose();
      data.humanPlayerNetAccController.dispose();
    }
    super.dispose();
  }

  /// Helper function to escape SQL strings.
  String escapeSQL(String input) {
    return input.replaceAll("'", "''");
  }

  /// Fetches scouting data from the MSSQL server for each team.
  /// If no row is found for a team, the fields remain empty.
  Future<void> _fetchScoutingData() async {
    for (int i = 0; i < _teamNumbers.length; i++) {
      final teamNumber = _teamNumbers[i];
      if (teamNumber.isEmpty) continue;
      final escapedTeamNumber = escapeSQL(teamNumber);
      // Only search by team number.
      final sql =
          "SELECT compatibility, notable_feats, human_player_net_acc FROM LeadScoutingData WHERE team_number = '$escapedTeamNumber'";
      final cmd = {
        "type": "query",
        "text": sql,
      };

      // Create a temporary subscription for this query.
      final completer = Completer<Map<String, dynamic>?>();
      late StreamSubscription sub;
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
            if (rows.isNotEmpty) {
              completer.complete(rows.first);
            } else {
              completer.complete(null);
            }
          }
        } catch (e) {
          completer.completeError(e);
        }
      });
      widget.webSocketService.sendLengthPrefixed(cmd);

      try {
        final row = await completer.future
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (row != null) {
          setState(() {
            _scoutingData[i].compatibilityController.text =
                row["compatibility"] ?? "";
            _scoutingData[i].notableFeatsController.text =
                row["notable_feats"] ?? "";
            _scoutingData[i].humanPlayerNetAccController.text =
                row["human_player_net_acc"] ?? "";
          });
        }
      } catch (e) {
        debugPrint("Error fetching data for team $teamNumber: $e");
      } finally {
        sub.cancel();
      }
    }
  }

  /// Submits (upserts) the updated scouting data to the MSSQL server.
  /// This version uses a MERGE statement so that if a row with the team number doesn't exist,
  /// it is inserted, and if it does exist, it is updated.
  Future<void> _submitLeadScoutingData() async {
    for (int i = 0; i < _teamNumbers.length; i++) {
      final teamNumber = _teamNumbers[i];
      if (teamNumber.isEmpty) continue;
      final escapedTeamNumber = escapeSQL(teamNumber);
      final compatibility =
          escapeSQL(_scoutingData[i].compatibilityController.text);
      final notableFeats =
          escapeSQL(_scoutingData[i].notableFeatsController.text);
      final netAcc =
          escapeSQL(_scoutingData[i].humanPlayerNetAccController.text);

      final sql = """
MERGE LeadScoutingData AS target
USING (SELECT '$escapedTeamNumber' AS team_number, '$compatibility' AS compatibility, '$notableFeats' AS notable_feats, '$netAcc' AS human_player_net_acc) AS source
ON (target.team_number = source.team_number)
WHEN MATCHED THEN 
    UPDATE SET compatibility = source.compatibility, notable_feats = source.notable_feats, human_player_net_acc = source.human_player_net_acc
WHEN NOT MATCHED THEN
    INSERT (team_number, compatibility, notable_feats, human_player_net_acc)
    VALUES (source.team_number, source.compatibility, source.notable_feats, source.human_player_net_acc);
""";
      final cmd = {
        "type": "query",
        "text": sql,
      };

      // Create a temporary subscription to listen for the query response (acknowledgment).
      final completer = Completer<bool>();
      late StreamSubscription sub;
      sub = widget.webSocketService.stream!.listen((rawMessage) {
        try {
          final int idx = rawMessage.indexOf('\r\n');
          if (idx < 0) return;
          final int len = int.parse(rawMessage.substring(0, idx));
          final String jsonPart = rawMessage.substring(idx + 2);
          if (jsonPart.length != len) return;
          final Map<String, dynamic> msg = jsonDecode(jsonPart);
          if (msg["type"] == "query") {
            // We assume that receipt of a query response means success.
            completer.complete(true);
          }
        } catch (e) {
          completer.completeError(e);
        }
      });
      widget.webSocketService.sendLengthPrefixed(cmd);

      try {
        await completer.future
            .timeout(const Duration(seconds: 5), onTimeout: () => false);
        debugPrint('Successfully merged data for $teamNumber');
      } catch (e, st) {
        debugPrint('Error submitting data for $teamNumber: $e\n$st');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting data for $teamNumber")),
        );
      } finally {
        sub.cancel();
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data submitted successfully")),
    );
    // Navigate to DashboardPage, passing the WebSocketService.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          teamName: widget.teamName,
          webSocketService: widget.webSocketService,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Lead Scouting Phase",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$_username: ${widget.teamName} in Match ${widget.matchNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FixedColumnWidth(80), // Column for team numbers.
          },
          children: [
            // Header row.
            TableRow(
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text("Team",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text("Compatibility",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text("Notable Feats",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text("Human Player Net ACC",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            // Data rows for each team.
            for (int i = 0; i < _teamNumbers.length; i++)
              TableRow(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.center,
                    child: Text(_teamNumbers[i]),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller:
                          _scoutingData[i].compatibilityController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      minLines: 1,
                      maxLines: null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller:
                          _scoutingData[i].notableFeatsController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      minLines: 1,
                      maxLines: null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller:
                          _scoutingData[i].humanPlayerNetAccController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      minLines: 1,
                      maxLines: null,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitLeadScoutingData,
          child: const Text("Next",
              style: TextStyle(color: colors.myOnPrimary)),
        ),
      ),
    );
  }
}
