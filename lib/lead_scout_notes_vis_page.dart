import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_table_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/preset_comment.dart';
import 'package:frc1148_2025_scouting_app/scroll_controller.dart';

// Define a structure to organize data by categories
Map<String, Map<String, Map<String, dynamic>>> robotData = {
  'Performance Stats': {
    'Scoring': {
      'Coral Per Match': 0,
      'L4 OPR Count': 1,
      'L3/L2 OPR Count': 2,
      'L1 OPR Count': 3,
      'Algae Per Match': 4,
      'Net OPR Count': 5,
      'Processor OPR Count': 6,
    },
    'Capabilities': {
      'Can Deep Cage': 'TRUE',
      'Can Shallow Cage': 'False',
    },
  },
  'Robot Specifications': {
    'Drivetrain': {
      'Robot weight (lbs)': 120,
      'Type of drive': 'tank',
      'Type of motor': 'kraken',
      'Number of motors': 4,
      'Bumper quality': 5,
    },
    'Intake': {
      'Can pick up coral from Coral Station': 'TRUE',
      'Can pick up coral from ground': 'FALSE',
      'Can pick up algae from ground (controlled)': 'FALSE',
      'Can remove algae from reef (controlled)': 'TRUE',
    },
    'Scoring': {
      'Can score coral onto L1': 'TRUE',
      'Can score coral onto L2': 'TRUE',
      'Can score coral onto L3': 'TRUE',
      'Can score coral onto L4': 'TRUE',
      'Can score in processor': 'TRUE',
      'Can score into net': 'TRUE',
      'Type of Climb': 'Deep Cage',
    },
    'Autonomous': {
      'Coral scored during Auton': '6 L4',
      'Leave AutoLine in Auton': 'TRUE',
    },
  },
  'Notes': {
    'Team Compatibility': {
      'Description': 'is it?',
    },
    'Notable Feats': {
      'Description': 'kachow',
    },
    'Human Player': {
      'Net ACC': 'hallo',
    },
  },
};

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
    // First check if it's in the Performance Stats section
    if (robotData['Performance Stats']!['Scoring']!.containsKey(label)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: height * 0.0175),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            robotData['Performance Stats']!['Scoring']![label].toString(),
            style: TextStyle(
              fontSize: height * 0.02,
              color: Colors.red,
            ),
          ),
        ],
      );
    } 
    // Check if it's in the Capabilities section
    else if (robotData['Performance Stats']!['Capabilities']!.containsKey(label)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: height * 0.0175),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            robotData['Performance Stats']!['Capabilities']![label].toString(),
            style: TextStyle(
              fontSize: height * 0.02,
              color: Colors.red,
            ),
          ),
        ],
      );
    }
    // Check all categories in Robot Specifications
    else {
      for (var category in robotData['Robot Specifications']!.keys) {
        if (robotData['Robot Specifications']![category]!.containsKey(label)) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: height * 0.0175),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                robotData['Robot Specifications']![category]![label].toString(),
                style: TextStyle(
                  fontSize: height * 0.02,
                  color: Colors.red,
                ),
              ),
            ],
          );
        }
      }
    }
    
    // Fallback for any other items not found in the structure
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: height * 0.0175),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          "Not found",
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
                Expanded(child: buildStatItem("Can Deep Cage", height)),
                Expanded(child: buildStatItem("Can Shallow Cage", height)),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
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
                  )
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRobotSpecificationsContainer(double width, double height) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text(
              "Robot Specifications",
              style: TextStyle(
                fontSize: height * 0.025,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // For each category in Robot Specifications
          ...robotData['Robot Specifications']!.entries.map((category) => 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 15.0, bottom: 5.0),
                  child: Text(
                    category.key,
                    style: TextStyle(
                      fontSize: height * 0.02,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 10.0,
                    runSpacing: 15.0,
                    children: category.value.keys.map((label) => 
                      SizedBox(
                        width: width * 0.45,
                        child: buildStatItem(label, height),
                      )
                    ).toList(),
                  ),
                ),
                SizedBox(height: 10),
              ],
            )
          ).toList(),
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
              
              buildRobotSpecificationsContainer(width, height),
              
              const Divider(),

              // Team Compatibility
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
                      robotData['Notes']!['Team Compatibility']!['Description'].toString(),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Notable Feats
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
                      robotData['Notes']!['Notable Feats']!['Description'].toString(),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Human Player Net ACC
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
                      robotData['Notes']!['Human Player']!['Net ACC'].toString(),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              
              const Divider(),
            ],
          ),
        ),
        bottomNavigationBar: ElevatedButton(
          onPressed: () async {
            // Navigation code would go here
          },
          child:
              const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
        ));
  }
}