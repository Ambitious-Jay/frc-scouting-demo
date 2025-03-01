import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/lead_scout_notes_vis_page.dart';

// Define a simple model for a Team
class Team {
  final String number;
  final String name;

  Team({required this.number, required this.name});
}

// Function stub to fetch teams from the SQL backend
Future<List<Team>> fetchTeamsFromSQL() async {
  // TODO: Implement SQL query and data fetching logic here.
  // For example, use a package like 'sqflite' or call a backend API that returns team data.

  // This is just a placeholder returning some dummy data.
  return [
    Team(number: "254", name: "The Cheesy Poofs"),
    Team(number: "1678", name: "Citrus Circuits"),
    Team(number: "118", name: "Team Rocket"),
    Team(number: "1114", name: "Simbotics"),
    Team(number: "148", name: "RoboWarriors"),
    Team(number: "2056", name: "OP Robotics"),
    Team(number: "971", name: "Spartan Robotics"),
    Team(number: "330", name: "Team Phoenix"),
    Team(number: "1323", name: "The Innovators"),
    Team(number: "5460", name: "Cyberdynamics"),
  ];
}

class TeamSearchPage extends StatefulWidget {
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
          teamName: team.number,
          teamNickname: team.name,
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
