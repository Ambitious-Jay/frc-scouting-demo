import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/alliance_data.dart';
import 'color_scheme.dart';

class MatchList extends StatefulWidget {
  const MatchList({Key? key}) : super(key: key);
  @override
  State<MatchList> createState() => _MatchList();
}

class _MatchList extends State<MatchList> {
  @override
  void initState() {
    super.initState();
  }

  List<String> matches = List.empty(growable: true);

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
    matches.add("qm1");
    matches.add("qm2");
    matches.add("qm3");
    matches.add("qm4");
    matches.add("qm5");
    matches.add("qm6");
    matches.add("qm7");
    matches.add("qm8");
    matches.add("qm9");
    matches.add("qm10");
    matches.add("qm11");
    matches.add("qm12");
    matches.add("qm13");
    matches.add("qm14");
    matches.add("qm15");
    matches.add("qm16");
    matches.add("qm17");
    matches.add("qm18");
    matches.add("qm19");
    matches.add("qm11");
    matches.add("qm12");
    matches.add("qm13");
    matches.add("qm14");
    matches.add("qm15");
    matches.add("qm16");
    matches.add("qm17");
    matches.add("qm18");
    matches.add("qm19");
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
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: matches.length,
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
                children: [ //TODO: update placehold alliance with alliance when backend works
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        side: BorderSide(color: Colors.grey, width: 1),
                      ),
                      child: Text(matches[index]),
                      onPressed: () async {
                        // This fetches what will be displayed (make conditional??)
                        // List<String> matchData = await _fetchRow(matches[index]);
                        // This navigates to the next page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AllianceData(allianceName: "placeholder alliance"),
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
                            builder: (context) =>
                                const AllianceData(allianceName: "placeholder alliance"),
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
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () async {
            await _fillMatches(1);
          }),
    );
  }
}
