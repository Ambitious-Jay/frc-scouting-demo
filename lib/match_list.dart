import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/alliance_data.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'color_scheme.dart';

/// Model representing a qualification match with red and blue alliances.
class QualificationMatch {
  final String matchNumber;
  final List<String> redAlliance;
  final List<String> blueAlliance;

  QualificationMatch({
    required this.matchNumber,
    required this.redAlliance,
    required this.blueAlliance,
  });
}

class MatchList extends StatefulWidget {
  final WebSocketService webSocketService;
  const MatchList({Key? key, required this.webSocketService}) : super(key: key);

  @override
  State<MatchList> createState() => _MatchListState();
}

class _MatchListState extends State<MatchList> {
  final TextEditingController searchController = TextEditingController();
  List<QualificationMatch> matches = [];
  List<QualificationMatch> filteredMatches = [];
  Timer? autoRefreshTimer;
  StreamSubscription? querySubscription;

  @override
  void initState() {
    super.initState();
    // Auto refresh every 30 seconds.
    autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fillMatches();
    });
    _fillMatches();
    searchController.addListener(filterMatches);
  }

  /// Fetches match data from the QualificationMatches table.
  /// Expects rows with "match_number", "alliance", and "team_keys" (comma‑separated).
  Future<void> _fillMatches() async {
    final String sql =
        "SELECT match_number, alliance, team_keys FROM QualificationMatches ORDER BY match_number";
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };

    final completer = Completer<List<QualificationMatch>>();
    List<QualificationMatch> fetchedMatches = [];

    // Listen for the query response.
    querySubscription = widget.webSocketService.stream?.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final String lenStr = rawMessage.substring(0, idx);
        final int len = int.parse(lenStr);
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          // Group rows by match number.
          Map<String, Map<String, List<String>>> matchMap = {};
          for (var row in rows) {
            String matchNumber = row["match_number"].toString();
            String alliance = row["alliance"].toString().toLowerCase();
            String teamKeysStr = row["team_keys"] ?? "";
            List<String> teamKeys =
                teamKeysStr.split(",").map((s) => s.trim()).toList();
            if (!matchMap.containsKey(matchNumber)) {
              matchMap[matchNumber] = {"red": [], "blue": []};
            }
            if (alliance == "red" || alliance == "blue") {
              matchMap[matchNumber]![alliance] = teamKeys;
            }
          }
          fetchedMatches = matchMap.entries.map((entry) {
            return QualificationMatch(
              matchNumber: entry.key,
              redAlliance: entry.value["red"] ?? [],
              blueAlliance: entry.value["blue"] ?? [],
            );
          }).toList();
          completer.complete(fetchedMatches);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    // Send the query.
    widget.webSocketService.sendLengthPrefixed(queryCmd);

    try {
      final result = await completer.future;
      // Update the matches in setState...
      setState(() {
        matches = result;
        // Do NOT override filteredMatches here!
      });
      // ...then re-apply the user’s search so the highlights remain.
      filterMatches();
    } catch (e) {
      print("Error fetching matches: $e");
    }
    querySubscription?.cancel();
  }

  /// Filters the matches based on the search query.
  /// If query is less than 3 characters, searches by match number (substring).
  /// Otherwise, it checks if any alliance contains a team substring.
  void filterMatches() {
    String query = searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        filteredMatches = List.from(matches);
      });
    } else if (query.length < 3) {
      setState(() {
        filteredMatches =
            matches.where((m) => m.matchNumber.contains(query)).toList();
      });
    } else {
      String lowerQuery = query.toLowerCase();
      setState(() {
        filteredMatches = matches.where((m) {
          bool inRed = m.redAlliance.any(
            (team) => team.toLowerCase().contains(lowerQuery),
          );
          bool inBlue = m.blueAlliance.any(
            (team) => team.toLowerCase().contains(lowerQuery),
          );
          return inRed || inBlue;
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    autoRefreshTimer?.cancel();
    querySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use custom colors from your color scheme.
    final Color blueColor = colors.myBlue;
    final Color redColor = colors.myRed;
    // Default text color for buttons is white.
    final Color defaultTextColor = Colors.white;
    // Highlighted text color from your color scheme (black).
    final Color highlightedTextColor = colors.myOnSurface;

    final String searchQuery = searchController.text.trim().toLowerCase();
    final bool isTeamSearch = searchQuery.length >= 3;

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: Column(
        children: [
          // Single search field for match number or team number.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Enter Match Number or Team Number',
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
              padding: const EdgeInsets.all(8),
              itemCount: filteredMatches.length,
              itemBuilder: (BuildContext context, int index) {
                final match = filteredMatches[index];
                // Determine whether the searched team is in each alliance.
                bool teamInBlue = false;
                bool teamInRed = false;
                if (isTeamSearch) {
                  teamInBlue = match.blueAlliance.any((team) =>
                      team.trim().toLowerCase().contains(searchQuery));
                  teamInRed = match.redAlliance.any((team) =>
                      team.trim().toLowerCase().contains(searchQuery));
                }

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
                        // Display the match number.
                        Text(
                          "Match ${match.matchNumber}",
                          style: const TextStyle(fontSize: 20),
                        ),
                        // Blue alliance button.
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            side:
                                const BorderSide(color: Colors.grey, width: 1),
                            backgroundColor: blueColor,
                            // If the searched team is in the blue alliance, change text color to black.
                            foregroundColor: teamInBlue
                                ? highlightedTextColor
                                : defaultTextColor,
                          ),
                          child: const Text("Blue"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllianceData(
                                  allianceNames: match.blueAlliance.join(","),
                                ),
                              ),
                            );
                          },
                        ),
                        // Red alliance button.
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            side:
                                const BorderSide(color: Colors.grey, width: 1),
                            backgroundColor: redColor,
                            // If the searched team is in the red alliance, change text color to black.
                            foregroundColor: teamInRed
                                ? highlightedTextColor
                                : defaultTextColor,
                          ),
                          child: const Text("Red"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllianceData(
                                  allianceNames: match.redAlliance.join(","),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  SizedBox(height: height / 150),
            ),
          ),
        ],
      ),
    );
  }
}
