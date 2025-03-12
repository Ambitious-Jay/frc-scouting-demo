import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:frc1148_2025_scouting_app/objective_page.dart';
import 'package:frc1148_2025_scouting_app/lead_scouting_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Model representing a match assignment.
class AssignmentItem {
  final String matchNumber; // Renamed from matchID
  final String teamNumber;
  final String role;

  AssignmentItem({
    required this.matchNumber,
    required this.teamNumber,
    required this.role,
  });

  factory AssignmentItem.fromMap(Map<String, dynamic> map) {
    return AssignmentItem(
      matchNumber: map['match_number'].toString(),
      teamNumber: map['TeamNumber'].toString(),
      role: map['role'].toString(),
    );
  }
}

class ScoutMatchList extends StatefulWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;
  const ScoutMatchList({
    Key? key,
    required this.webSocketService,
    required this.onThemeChanged,
    WebSocketChannel? channel,
  }) : super(key: key);

  @override
  State<ScoutMatchList> createState() => _ScoutMatchListState();
}

class _ScoutMatchListState extends State<ScoutMatchList> {
  List<AssignmentItem> _assignments = [];
  String _username = "";
  bool _loading = false;
  String? _errorMessage;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
      _fetchAssignments();
    });

    _wsSubscription = widget.webSocketService.stream?.listen((rawMessage) {
      _handleServerMessage(rawMessage);
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchAssignments() async {
    if (_username.isEmpty) {
      setState(() {
        _errorMessage = "Username not found.";
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    // The query now filters QualificationMatches by alliance.
    final String sql = """
      SELECT 
        a.match_number,
        CASE 
          WHEN a.R1 = '$_username' THEN 'R1'
          WHEN a.R2 = '$_username' THEN 'R2'
          WHEN a.R3 = '$_username' THEN 'R3'
          WHEN a.B1 = '$_username' THEN 'B1'
          WHEN a.B2 = '$_username' THEN 'B2'
          WHEN a.B3 = '$_username' THEN 'B3'
          WHEN a.red_lead = '$_username' THEN 'red_lead'
          WHEN a.blue_lead = '$_username' THEN 'blue_lead'
        END as role,
        qm.team_keys
      FROM Assignment a
      JOIN QualificationMatches qm ON a.match_number = qm.match_number
      WHERE 
      (
        ((a.R1 = '$_username' OR a.R2 = '$_username' OR a.R3 = '$_username' OR a.red_lead = '$_username') 
          AND qm.alliance = 'red')
        OR
        ((a.B1 = '$_username' OR a.B2 = '$_username' OR a.B3 = '$_username' OR a.blue_lead = '$_username') 
          AND qm.alliance = 'blue')
      )
      ORDER BY a.match_number;
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    widget.webSocketService.sendLengthPrefixed(queryCmd);
    print('Sent assignment query: $sql');
  }

  void _handleServerMessage(String raw) {
    try {
      final int idx = raw.indexOf('\r\n');
      if (idx < 0) return;
      final String lenStr = raw.substring(0, idx);
      final int len = int.parse(lenStr);
      final String jsonPart = raw.substring(idx + 2);
      if (jsonPart.length != len) {
        print('Length mismatch: expected $len, got ${jsonPart.length}');
        return;
      }
      final Map<String, dynamic> msg = jsonDecode(jsonPart);
      if (msg["type"] == "query") {
        final List<dynamic> rows = msg["rows"];
        if (rows == null || rows.isEmpty) {
          setState(() {
            _errorMessage = "No match assignments found.";
            _assignments = [];
            _loading = false;
          });
        } else {
          List<AssignmentItem> assignments = [];
          for (final row in rows) {
            // Create matchNumber (e.g., "qm1", "qm2", etc.) from match_number.
            final int matchNum = row['match_number'] is int
                ? row['match_number']
                : int.parse(row['match_number'].toString());
            final String matchNumber = 'qm' + matchNum.toString();

            // Normalize role value.
            final String roleFromDB = row['role'].toString().trim();
            final String roleUpper = roleFromDB.toUpperCase();

            final String teamKeysStr = row['team_keys'];
            final List<String> teamKeys =
                teamKeysStr.split(',').map((s) => s.trim()).toList();
            String teamName = "";
            // For regular scouts: extract the digit from the role (e.g., "R1" -> index 0, "B2" -> index 1)
            if (roleUpper == 'R1' || roleUpper == 'R2' || roleUpper == 'R3') {
              int index = int.parse(roleUpper.substring(1)) - 1;
              if (index < teamKeys.length) {
                teamName = teamKeys[index];
              }
            } else if (roleUpper == 'B1' || roleUpper == 'B2' || roleUpper == 'B3') {
              int index = int.parse(roleUpper.substring(1)) - 1;
              if (index < teamKeys.length) {
                teamName = teamKeys[index];
              }
            } else if (roleUpper == 'BLUE_LEAD' || roleUpper == 'RED_LEAD') {
              // For lead scouts, pass all teams in the alliance.
              teamName = teamKeys.join(", ");
            }

            final String displayRole =
                roleUpper.contains('LEAD') ? 'Lead Scout' : 'Scout';

            assignments.add(AssignmentItem(
              matchNumber: matchNumber,
              teamNumber: teamName,
              role: displayRole,
            ));
          }
          setState(() {
            _assignments = assignments;
            _loading = false;
          });
          print("Fetched ${assignments.length} assignments.");
        }
      }
    } catch (e) {
      print("Error processing server message: $e");
      setState(() {
        _errorMessage = "Error processing server message: $e";
        _loading = false;
      });
    }
  }

  void _onMatchPressed(AssignmentItem assignment) {
    if (assignment.role.toLowerCase().contains('lead')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeadScoutingPage(
            teamName: assignment.teamNumber,
            matchNumber: assignment.matchNumber,
            // channel: widget.webSocketService.channel!,
            onThemeChanged: widget.onThemeChanged,
            webSocketService: widget.webSocketService,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AutoPage(
            teamName: assignment.teamNumber,
            teamNickname: "", // Optionally, add more info here.
            matchNumber: assignment.matchNumber,
            channel: widget.webSocketService.channel!,
            onThemeChanged: widget.onThemeChanged,
            webSocketService: widget.webSocketService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Matches to Scout"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssignments,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _assignments.isEmpty
                  ? const Center(child: Text("No assignments found."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _assignments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final AssignmentItem assignment = _assignments[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ListTile(
                            title: Text(
                              "${assignment.matchNumber}: Team ${assignment.teamNumber}",
                              style: const TextStyle(
                                color: Color(0xFFFFA5A5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Role: ${assignment.role}"),
                            trailing: ElevatedButton(
                              child: const Text("Scout"),
                              onPressed: () => _onMatchPressed(assignment),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
