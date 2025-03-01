import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/alliance_data.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'color_scheme.dart';

class ScoutMatchList extends StatefulWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;

  const ScoutMatchList({
    Key? key,
    required this.id,
    required this.webSocketService,
    required this.onThemeChanged,
    WebSocketChannel? channel,
  }) : super(key: key);
  final String id;

  @override
  State<ScoutMatchList> createState() => _ScoutMatchList();
}

class _ScoutMatchList extends State<ScoutMatchList> {
  final TextEditingController searchController = TextEditingController();
  Map<String, String> matches = {}; // Changed from Map<String, List<String>>
  List<String> filteredMatches = [];
  bool searchByMatch = true;

  @override
  void initState() {
    super.initState();
    filteredMatches = matches.keys.toList(); // Start with all matches displayed
    searchController.addListener(filterMatches);
  }

  void filterMatches() {
    // Renamed from filterTeams for clarity
    setState(() {
      String query = searchController.text.toLowerCase();
      if (searchByMatch) {
        // Search by match number
        filteredMatches = matches.keys
            .where((match) =>
                match.toLowerCase() == "qm" + query ||
                match.toLowerCase().startsWith("qm" + query))
            .toList();
      } else {
        // Search by team number
        filteredMatches = matches.entries
            .where((entry) => entry.value.toLowerCase().contains(query))
            .map((entry) => entry.key)
            .toList();
      }
    });
  }

  void toggleSearch() {
    searchByMatch = !searchByMatch;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fillMatches(col) async {
    // This gets the matches for one scout to list
    matches.clear(); // Clear existing data before adding new
    matches.addAll({
      "qm1": "1114",
      "qm2": "148",
      "qm3": "1678",
      "qm4": "1323",
      "qm5": "4414",
      "qm6": "2056",
      "qm7": "2910",
      "qm8": "3310",
      "qm9": "148",
      "qm10": "2056",
      "qm11": "1678",
      "qm12": "4414",
      "qm13": "2910",
      "qm14": "148",
      "qm15": "1323",
    });

    filteredMatches = matches.keys.toList(); // Refresh displayed matches
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Matches to Scout"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: filteredMatches.length,
              itemBuilder: (BuildContext context, int index) {
                String matchKey = filteredMatches[index];
                String teamToScout = matches[matchKey] ?? "";

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                  ),
                  child: SizedBox(
                    height: height / 12,
                    width: width / 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                            ),
                            child: Text("${matchKey}: Team ${teamToScout}"),
                            onPressed: () async {
                              // This navigates to the next page
                              // Add your navigation code here
                            }),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                            ),
                            child: Text("Scout"),
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AutoPage(
                                    teamName: teamToScout,
                                    teamNickname:
                                        "temporary filler fix mattin to do",
                                    id: matchKey,
                                    channel: widget.webSocketService.channel!,
                                    onThemeChanged: (ThemeMode) {},
                                    webSocketService: widget.webSocketService,
                                  ),
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => Container(
                alignment: AlignmentDirectional.center,
                height: height / 150,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () async {
            await _fillMatches(1);
          }),
    );
  }
}
