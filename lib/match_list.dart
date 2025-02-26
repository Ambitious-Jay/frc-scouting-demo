import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/alliance_data.dart';
import 'color_scheme.dart';

class MatchList extends StatefulWidget {
  const MatchList({Key? key}) : super(key: key);
  @override
  State<MatchList> createState() => _MatchList();
}

class _MatchList extends State<MatchList> {
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Enter Match',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Searching by",
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: height * 0.025),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    searchByMatch = !searchByMatch;
                  });
                },
                style: ElevatedButton.styleFrom(
                  // backgroundColor: park
                  //     ? Theme.of(context).colorScheme.primary
                  //     : Theme.of(context).colorScheme.secondary,
                  // foregroundColor: park
                  //     ? Theme.of(context).colorScheme.onPrimary
                  //     : Theme.of(context).colorScheme.onSecondary,
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  // minimumSize: const Size(100, 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: searchByMatch
                    ? const Text(
                        "Match",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      )
                    : const Text("Team",
                        style: TextStyle(fontSize: 20, color: Colors.black)),
              ),
            ],
          ),
          const Divider(),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AllianceData(
                                      allianceName: "placeholder alliance"),
                                ),
                              );
                            }),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                              backgroundColor: Colors.blue,
                            ),
                            child: Text("Blue"),
                            onPressed: () async {
                              // This fetches what will be displayed (make conditional??)
                              // List<String> matchData = await _fetchRow(matches[index]);
                              // This navigates to the next page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AllianceData(
                                      allianceName: "placeholder alliance"),
                                ),
                              );
                            }),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                              backgroundColor: Colors.red,
                            ),
                            child: Text("Red"),
                            onPressed: () async {
                              // This fetches what will be displayed (make conditional??)
                              // List<String> matchData = await _fetchRow(matches[index]);
                              // This navigates to the next page
                              // Navigator.push(
                              //     context,
                              //     MaterialPageRoute( builder: (context) =>  MatchListDisplay (matchData: matchData, matchID: matches[index]) )
                              // );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AllianceData(
                                      allianceName: "placeholder alliance"),
                                ),
                              );
                            })
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
