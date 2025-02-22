import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_table_page.dart';
import 'package:frc1148_2025_scouting_app/preset_comment.dart';
import 'color_scheme.dart';

Map<String, int> stored = {
  'Coral Per Match': 0,
  'L4 OPR Count': 1,
  'L3/L2 OPR Count': 2,
  'L1 OPR Count': 3,
  'Algae Per Match': 4,
  'Net OPR Count': 5,
  'Processor OPR Count': 6,
};
String deepCage = 'TRUE';
String ShallowCage = 'False';

class AllianceData extends StatefulWidget {
  const AllianceData({super.key, required this.allianceName});
  final String allianceName;
  @override
  State<AllianceData> createState() => _AllianceData();
}

class _AllianceData extends State<AllianceData> {
  Future<void> _submitSection() async {
    try {} catch (e) {
      print('Error: $e');
    }
  }

  //custom container to cut out repetitive code (This is 100% something Claude cooked up I can't deny)
  Widget buildStatItem(String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: height * 0.0175),
        ),
        const SizedBox(height: 4),
        Text(
          stored[label].toString(),
          style: TextStyle(
            fontSize: height * 0.02,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget buildStatsContainer(double width, double height) {
     return Container(
      width: width,
      height: height * 1 / 3,
      alignment: AlignmentDirectional.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("Coral Per Match", height)),
                Expanded(child: buildStatItem("L4 OPR Count", height)),
                Expanded(child: buildStatItem("L3/L2 OPR Count", height)),
                Expanded(child: buildStatItem("L1 OPR Count", height)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("Algae Per Match", height)),
                Expanded(child: buildStatItem("Net OPR Count", height)),
                Expanded(child: buildStatItem("Processor OPR Count", height)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Can Deep Cage",
                      style: TextStyle(fontSize: height * 0.0175),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deepCage,
                      style: TextStyle(
                        fontSize: height * 0.02,
                        color: Colors.red,
                      ),
                    ),
                  ],
                )),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Can Shallow Cage",
                      style: TextStyle(fontSize: height * 0.0175),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ShallowCage,
                      style: TextStyle(
                        fontSize: height * 0.02,
                        color: Colors.red,
                      ),
                    ),
                  ],
                )),
                Expanded(
                    child: Column(
                  children: [
                    Expanded(
                      // child: Text(
                      //   "Auto Table",
                      //   style: TextStyle(fontSize: height * 0.0175),
                      // ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AutoTablePage(
                                  onThemeChanged: (ThemeMode mode) {
                                setState(() {});
                              }),
                            ),
                          );
                        },
                        child: const Text("Auto Table",
                            style: TextStyle(
                                color: Colors.lightBlue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.lightBlue)),
                      ),
                    ),
                    Expanded(
                      // child: Text(
                      //   "Preset Comments",
                      //   style: TextStyle(fontSize: height * 0.0175),
                      // ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PresetComment(
                                  onThemeChanged: (ThemeMode mode) {
                                setState(() {});
                              }),
                            ),
                          );
                        },
                        child: const Text("Preset Comments",
                            style: TextStyle(
                                color: Colors.lightBlue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.lightBlue)),
                      ),
                    ),
                  ],
                ))
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Alliance Info"),
            Text(widget.allianceName),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            buildStatsContainer(width, height),
            const Divider(),
            buildStatsContainer(width, height),
            const Divider(),
            buildStatsContainer(width, height),
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () async {},
        child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
      ),
    );
  }
}
