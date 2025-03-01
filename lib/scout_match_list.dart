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
  final int rowSeq;
  final String matchID;
  final String teamNumber;
  final String role;

  AssignmentItem({
    required this.rowSeq,
    required this.matchID,
    required this.teamNumber,
    required this.role,
  });

  factory AssignmentItem.fromMap(Map<String, dynamic> map) {
    return AssignmentItem(
      rowSeq: map['row_seq'] is int
          ? map['row_seq']
          : int.parse(map['row_seq'].toString()),
      matchID: map['MatchID'] as String,
      teamNumber: map['TeamNumber'] as String,
      role: map['role'] as String,
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
    final String sql =
        "SELECT row_seq, 'qm' + CAST(match_number AS VARCHAR(10)) AS MatchID, "
        "team_key AS TeamNumber, role "
        "FROM Assignment "
        "WHERE scout_name = '$_username' "
        "ORDER BY row_seq;";
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
          List<AssignmentItem> assignments =
              rows.map((row) => AssignmentItem.fromMap(row)).toList();
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
    if (assignment.role.toLowerCase() == 'lead') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeadScoutingPage(
            teamName: assignment.teamNumber,
            id: assignment.matchID,
            channel: widget.webSocketService.channel!,
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
            id: assignment.matchID,
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
    final double h = MediaQuery.of(context).size.height;
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
                              "${assignment.matchID}: Team ${assignment.teamNumber}",
                              style: TextStyle(
                                color: const Color(0xFFFFA5A5),
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
