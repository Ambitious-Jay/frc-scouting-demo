import 'package:flutter/material.dart';

class TeamSearchPage extends StatefulWidget {
  @override
  _TeamSearchPageState createState() => _TeamSearchPageState();
}

class _TeamSearchPageState extends State<TeamSearchPage> {
  final TextEditingController searchController = TextEditingController();
  final List<String> teams = [
    "Team 254",
    "Team 1678",
    "Team 118",
    "Team 1114",
    "Team 148",
    "Team 2056",
    "Team 971",
    "Team 330",
    "Team 1323",
    "Team 5460"
  ];
  List<String> filteredTeams = [];

  @override
  void initState() {
    super.initState();
    filteredTeams = teams; // Start with all teams displayed
    searchController.addListener(filterTeams);
  }

  void filterTeams() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredTeams =
          teams.where((team) => team.toLowerCase().contains(query)).toList();
    });
  }

  void onTeamTap(String teamName) {
    // direct to page for team
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
                hintText: 'Enter Team Name',
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
              itemCount: filteredTeams.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredTeams.length) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  title: Text(
                    filteredTeams[index],
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () =>
                      onTeamTap(filteredTeams[index]), // Navigate on tap
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
