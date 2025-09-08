import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
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
  String _username = "Scout User"; // demo username
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _injectDemoAssignments();
  }

  void _injectDemoAssignments() {
    // Demo assignments (normally fetched from DB)
    setState(() {
      _assignments = [
        AssignmentItem(
          matchNumber: "qm121",
          teamNumber: "3061",
          role: "Scout",
        ),
        // AssignmentItem(
        //   matchNumber: "qm2",
        //   teamNumber: "254",
        //   role: "Scout",
        // ),
        // AssignmentItem(
        //   matchNumber: "qm3",
        //   teamNumber: "1678",
        //   role: "Lead Scout",
        //   isLeadScout: true,
        // ),
      ];
      _loading = false;
      _errorMessage = null;
    });
  }

  void _onMatchPressed(AssignmentItem assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoPage(
          teamName: assignment.teamNumber,
          teamNickname: "DemoBots", // fake nickname
          matchNumber: assignment.matchNumber,
          channel: widget.webSocketService.channel!,
          onThemeChanged: widget.onThemeChanged,
          webSocketService: widget.webSocketService,
          isLeadScout: assignment.isLeadScout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Matches to Scout (Demo)"),
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