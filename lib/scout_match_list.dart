import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Model representing a match assignment.
class AssignmentItem {
  final String matchNumber;
  final String teamNumber;
  final String role;
  final bool isLeadScout;

  AssignmentItem({
    required this.matchNumber,
    required this.teamNumber,
    required this.role,
    this.isLeadScout = false,
  });

  factory AssignmentItem.fromMap(Map<String, dynamic> map) {
    return AssignmentItem(
      matchNumber: map['match_number'].toString(),
      teamNumber: map['TeamNumber'].toString(),
      role: map['role'].toString(),
      isLeadScout: map['is_lead_scout'] == true,
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

    final String sql = """
  SELECT 
    a.Match as match_number,
    a_role.role,
    CASE 
      WHEN a_role.role LIKE 'R%' THEN qm_red.team_keys
      WHEN a_role.role LIKE 'B%' THEN qm_blue.team_keys
      ELSE NULL
    END as team_keys,
    CASE WHEN ls.Names = '$_username' THEN 1 ELSE 0 END as is_lead_scout
  FROM Assignment a
  JOIN (
    SELECT 
      Match,
      CASE 
        WHEN R1 = '$_username' THEN 'R1'
        WHEN R2 = '$_username' THEN 'R2'
        WHEN R3 = '$_username' THEN 'R3'
        WHEN B1 = '$_username' THEN 'B1'
        WHEN B2 = '$_username' THEN 'B2'
        WHEN B3 = '$_username' THEN 'B3'
      END as role
    FROM Assignment
    WHERE 
      R1 = '$_username' OR R2 = '$_username' OR R3 = '$_username' OR
      B1 = '$_username' OR B2 = '$_username' OR B3 = '$_username'
  ) a_role ON a.Match = a_role.Match
  LEFT JOIN (
    SELECT match_number, team_keys
    FROM QualificationMatches
    WHERE alliance = 'red'
  ) qm_red ON a.Match = qm_red.match_number
  LEFT JOIN (
    SELECT match_number, team_keys
    FROM QualificationMatches
    WHERE alliance = 'blue'
  ) qm_blue ON a.Match = qm_blue.match_number
  LEFT JOIN LeadScouts ls ON ls.Names = '$_username'
  ORDER BY a.Match;
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
            final String roleFromDB = row['role']?.toString().trim() ?? '';
            final String roleUpper = roleFromDB.toUpperCase();

            // Check if this is a lead scout - compare with 1 instead of true
            final bool isLeadScout = row['is_lead_scout'] == 1 ||
                row['is_lead_scout'] == '1' ||
                row['is_lead_scout'] == true;

            final String teamKeysStr = row['team_keys'] ?? '';
            final List<String> teamKeys = teamKeysStr.isNotEmpty
                ? teamKeysStr.split(',').map((s) => s.trim()).toList()
                : [];

            String teamName = "";

            // Extract team based on role for all scouts (lead or not)
            if (roleUpper.isNotEmpty && roleUpper.length > 1) {
              int index = int.parse(roleUpper.substring(1)) - 1;

              // Get team based on position in role (R1, B2, etc.)
              if (index < teamKeys.length) {
                teamName = teamKeys[index];
              }
            }

            // Skip invalid assignments (for specific issues with Isabel's assignments)
            if (_username.toLowerCase() == "isabel") {
              // Skip matches where Isabel is incorrectly assigned outside her designated matches
              // Matches 11-20, 41-50, 61-70 are Isabel's designated periods
              int matchRange = (matchNum - 1) ~/ 10;
              if (!(matchRange == 1 || matchRange == 4 || matchRange == 6)) {
                continue;
              }
            }

            final String displayRole = isLeadScout ? 'Lead Scout' : 'Scout';

            assignments.add(AssignmentItem(
              matchNumber: matchNumber,
              teamNumber: teamName,
              role: displayRole,
              isLeadScout: isLeadScout,
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
    // Always navigate to AutoPage, passing isLeadScout parameter
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
          isLeadScout: assignment.isLeadScout, // Pass the lead scout flag
        ),
      ),
    );
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
