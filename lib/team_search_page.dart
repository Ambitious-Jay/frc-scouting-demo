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
    // 🚀 Demo data instead of SQL
    teams = [
      Team(number: "254", name: "The Cheesy Poofs"),
      Team(number: "1678", name: "Citrus Circuits"),
      Team(number: "118", name: "Robonauts"),
      Team(number: "1148", name: "Harvard Westlake Wolverines"),
      Team(number: "2056", name: "OP Robotics"),
    ];

    // Sort numerically with padding
    teams.sort(
        (a, b) => a.number.padLeft(5, '0').compareTo(b.number.padLeft(5, '0')));

    setState(() {
      filteredTeams = teams;
    });
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
        title: const Text('Search Teams (Demo)'),
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
