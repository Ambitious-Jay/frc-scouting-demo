import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/scroll_controller.dart';

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

String Combatability = 'is it?';
String Feats = 'kachow';
String HPlayer = 'hallo';

final ScrollController compatibilityController = ScrollController();
final ScrollController featsController = ScrollController();
final ScrollController hPlayerController = ScrollController();

class LeadScoutNotesVisPage extends StatefulWidget {
  const LeadScoutNotesVisPage({super.key, required this.teamName});
  final String teamName;

  @override
  State<LeadScoutNotesVisPage> createState() => _LeadScoutNotesVisPage();
}

class _LeadScoutNotesVisPage extends State<LeadScoutNotesVisPage> {
  Future<void> setUp() async {}

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

  @override
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
                        onPressed: () async {},
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
                        onPressed: () async {},
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
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.teamName),
        ),
        body: Center(
          child: ListView(
            children: [
              buildStatsContainer(width, height),

              const Divider(),

              // First Row
              Column(
                children: [
                  Container(
                    height: height * 0.05,
                    width: width,
                    alignment: Alignment.center,
                    child: const Text(
                      'Compatibility',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 30.0),
                    child: Text(
                      Combatability,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Second Row
              Column(
                children: [
                  Container(
                    height: height * 0.05,
                    width: width,
                    alignment: Alignment.center,
                    child: const Text(
                      'Notable Feats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 30.0),
                    child: Text(
                      Feats,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Third Row
              Column(
                children: [
                  Container(
                    height: height * 0.05,
                    width: width,
                    alignment: Alignment.center,
                    child: const Text(
                      'Human Player Net ACC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 30.0),
                    child: Text(
                      HPlayer,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),

              // Container(
              //   width: width,
              //   height: height * 1 / 13,
              //   //color Colors.amber[300],
              //   alignment: AlignmentDirectional.center,
              // ),
              // ElevatedButton(
              //   onPressed: () async {
              //     // await _submitSection();
              //     // setState(() {
              //     //   Navigator.push(
              //     //     context,
              //     //     MaterialPageRoute
              //     //     (
              //     //       builder: (context) => Entrance(onThemeChanged: (newTheme) {
              //     //     })
              //     //     )
              //     //   );
              //     // });
              //   },
              //   child: const Text("Next",
              //       style: TextStyle(color: colors.myOnPrimary)),
              // )
            ],
          ),
        ),
        bottomNavigationBar: ElevatedButton(
          onPressed: () async {
            // await _submitSection();
            // setState(() {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute
            //     (
            //       builder: (context) => Entrance(onThemeChanged: (newTheme) {
            //     })
            //     )
            //   );
            // });
          },
          child:
              const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
        ));
  }
}
