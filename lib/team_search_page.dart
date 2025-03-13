import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/lead_scout_notes_vis_page.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

// Define a simple model for a Team
class Team {
  final String number;
  final String name;

  Team({required this.number, required this.name});
}

class TeamSearchPage extends StatefulWidget {
  final WebSocketService webSocketService;

  const TeamSearchPage({Key? key, required this.webSocketService})
      : super(key: key);

  @override
  _TeamSearchPageState createState() => _TeamSearchPageState();
}

class _TeamSearchPageState extends State<TeamSearchPage> {
  final TextEditingController searchController = TextEditingController();

  List<Team> teams = [];
  List<Team> filteredTeams = [];

  @override
  void initState() {
    super.initState();
    loadTeams();
    searchController.addListener(filterTeams);
  }

  Future<void> loadTeams() async {
    teams = await fetchTeamsFromSQL();
    setState(() {
      filteredTeams = teams;
    });
  }

  /// Fetch teams from the StatsboticsEPA table using a WebSocket query.
  Future<List<Team>> fetchTeamsFromSQL() async {
    // Create the SQL query to fetch team and team_name
    final String sql = "SELECT team, team_name FROM StatsboticsEPA";
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };

    // Create a completer to wait for the query response.
    final completer = Completer<List<Team>>();

    // Listen for the response on the WebSocket stream.
    final subscription = widget.webSocketService.stream?.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return; // Invalid message, so ignore.
        final String lenStr = rawMessage.substring(0, idx);
        final int len = int.parse(lenStr);
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          // Convert each row to a Team instance.
          List<Team> fetchedTeams = rows.map((row) {
            // Assume each row is a Map with keys "team" and "team_name".
            return Team(
              number: row["team"].toString(),
              name: row["team_name"] ?? "",
            );
          }).toList();
          completer.complete(fetchedTeams);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    // Send the query command using a length-prefixed message.
    widget.webSocketService.sendLengthPrefixed(queryCmd);

    // Await the response.
    final teamsResult = await completer.future;
    subscription?.cancel();
    return teamsResult;
  }

  void filterTeams() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredTeams = teams.where((team) {
        return team.number.toLowerCase().contains(query) ||
            team.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void onTeamTap(Team team) {
    // Navigate to the team details page using the team's number.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeadScoutNotesVisPage(
          teamNumber: team.number,
          teamNickname: team.name,
          webSocketService: widget.webSocketService,
          teamName: team.name,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Teams'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Enter Team Number or Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              itemCount: filteredTeams.length,
              itemBuilder: (context, index) {
                final team = filteredTeams[index];
                return ListTile(
                  title: Text(
                    "Team ${team.number}",
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    team.name,
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => onTeamTap(team),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
