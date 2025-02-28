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
    required this.webSocketService,
    required this.onThemeChanged,
    WebSocketChannel? channel,
  }) : super(key: key);
  @override
  State<ScoutMatchList> createState() => _ScoutMatchList();
}

class _ScoutMatchList extends State<ScoutMatchList> {
  final TextEditingController searchController = TextEditingController();
  Map<String, List<String>> matches = {};
  List<String> filteredMatches = [];
  bool searchByMatch = true;

  @override
  void initState() {
    super.initState();
    filteredMatches = matches.keys.toList(); // Start with all teams displayed
    searchController.addListener(filterTeams);
  }

  void filterTeams() {
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
            .where((entry) => entry.value.any((team) => team.contains(query)))
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
    // This gets the matches they we list
    // try {
    //   final sheet = await SheetsHelper.sheetSetup('TBA-data');

    //   final cell = await sheet?.cells.column(col);
    //   for (int i = 0; i < cell!.length; i++){
    //     matches.add(cell[i].value);
    //   }
    //   setState(() {});

    // } catch (e) {
    //   print('Error: $e');
    // }
    // "qm1": ["254", "1678", "973", "4414", "118", "148"],
    //   "qm2": ["1678", "148", "118", "254", "973", "4414"],
    //   "qm3": ["4414", "973", "1678", "148", "118", "254"],
    //   "qm4": ["973", "254", "4414", "1678", "118", "148"],
    //   "qm5": ["118", "4414", "148", "254", "973", "1678"],
    //   "qm6": ["148", "118", "254", "1678", "4414", "973"],
    // setState(() {});
    matches.clear(); // Clear existing data before adding new
    matches.addAll({
      "qm1": ["1114", "254", "1678", "2056", "118", "148"],
      "qm2": ["148", "118", "3310", "2056", "2910", "1323"],
      "qm3": ["1678", "4414", "2910", "254", "1114", "2056"],
      "qm4": ["1323", "118", "148", "2910", "4414", "1678"],
      "qm5": ["4414", "1114", "254", "3310", "148", "1678"],
      "qm6": ["2056", "254", "1323", "3310", "118", "2910"],
      "qm7": ["2910", "1678", "1114", "148", "2056", "4414"],
      "qm8": ["3310", "1323", "2056", "4414", "254", "2910"],
      "qm9": ["148", "1678", "118", "1114", "1323", "3310"],
      "qm10": ["2056", "2910", "254", "148", "4414", "1323"],
      "qm11": ["1678", "3310", "1114", "118", "2056", "254"],
      "qm12": ["4414", "1323", "2910", "1114", "118", "148"],
      "qm13": ["2910", "2056", "254", "1678", "4414", "1323"],
      "qm14": ["148", "3310", "1114", "1678", "2056", "254"],
      "qm15": ["1323", "2910", "118", "4414", "148", "3112"],
    });

    filteredMatches = matches.keys.toList(); // Refresh displayed matches
    setState(() {});
  }

// This fetches the contents of what will be displayed from buttons

  // Future<List<String>> _fetchRow(String matchID) async {
  //   try {

  //   } catch (e) {
  //     print('Error: $e');
  //     return List.empty();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: filteredMatches.length,
              itemBuilder: (BuildContext context, int index) {
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
                        //TODO: update placehold alliance with alliance when backend works
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                            ),
                            child: Text(filteredMatches[index]),
                            onPressed: () async {
                              // This fetches what will be displayed (make conditional??)
                              // List<String> matchData = await _fetchRow(matches[index]);
                              // This navigates to the next page
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const AllianceData(
                              //         allianceName: "placeholder alliance"),
                              //   ),
                              // );
                            }),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                            ),
                            child: Text("Next Match"),
                            onPressed: () async {
                              // This fetches what will be displayed (make conditional??)
                              // List<String> matchData = await _fetchRow(matches[index]);
                              // This navigates to the next page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AutoPage(
                                    teamName: "1148",
                                    id: '',
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
