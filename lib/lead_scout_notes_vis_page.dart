import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_table_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/graphing_page.dart';
import 'package:frc1148_2025_scouting_app/preset_comment.dart';
import 'package:frc1148_2025_scouting_app/scroll_controller.dart';

// Define a structure to organize data by categories
Map<String, Map<String, Map<String, dynamic>>> robotData = {
  'Performance Stats': {
    'Scoring': {
      'Coral Per Match': 0,
      'L4 OPR Count': 0,
      'L3/L2 OPR Count': 0,
      'L1 OPR Count': 0,
      'Algae Per Match': 0,
      'Net OPR Count': 0,
      'Processor OPR Count': 0,
      'EPA': 0.0,
      'Rank': 0,
      'WLR': '0-0-0',
      'Processor': 'FALSE',
      'Net': 'FALSE',
      'CPM': 0,
      'APM': 0,
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
  const LeadScoutNotesVisPage({
    super.key,
    required this.teamName,
    required this.teamNickname,
    // required this.id,
  });
  final String teamName;
  final String teamNickname;
  // final String id;

  @override
  State<LeadScoutNotesVisPage> createState() => _LeadScoutNotesVisPage();
}

class _LeadScoutNotesVisPage extends State<LeadScoutNotesVisPage> {
  String teamName = "";

  @override
  void initState() {
    super.initState();
    teamName = widget.teamName;
  }

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
    else if (robotData['Performance Stats']!['Capabilities']!
        .containsKey(label)) {
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
      padding: EdgeInsets.all(width * 0.02),
      child: Column(
        children: [
          // Team Name and Number at the top
          Container(
            width: width,
            padding: EdgeInsets.symmetric(vertical: height * 0.01),
            child: Text(
              teamName,
              style: TextStyle(
                fontSize: height * 0.025,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: height * 0.01),

          // First row: EPA, Rank, WLR
          Container(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("EPA", height)),
                Expanded(child: buildStatItem("Rank", height)),
                Expanded(child: buildStatItem("WLR", height)),
              ],
            ),
          ),

          SizedBox(height: height * 0.02),

          // Second row: Processor, Net
          Container(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("Processor", height)),
                Expanded(child: buildStatItem("Net", height)),
              ],
            ),
          ),

          SizedBox(height: height * 0.02),

          // Third row: CPM, APM, Coral Per Match
          Container(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("CPM", height)),
                Expanded(child: buildStatItem("APM", height)),
                Expanded(child: buildStatItem("Coral Per Match", height)),
              ],
            ),
          ),

          SizedBox(height: height * 0.03),

          // OPR Table
          Container(
            width: width * 0.9,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable(
              columnSpacing: width * 0.05,
              headingRowHeight: height * 0.04,
              dataRowHeight: height * 0.04,
              columns: const [
                DataColumn(
                    label: Text('Metric',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Value',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('L4 OPR Count')),
                  DataCell(Text(robotData['Performance Stats']!['Scoring']![
                          'L4 OPR Count']
                      .toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('L3/L2 OPR Count')),
                  DataCell(Text(robotData['Performance Stats']!['Scoring']![
                          'L3/L2 OPR Count']
                      .toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('L1 OPR Count')),
                  DataCell(Text(robotData['Performance Stats']!['Scoring']![
                          'L1 OPR Count']
                      .toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Net OPR Count')),
                  DataCell(Text(robotData['Performance Stats']!['Scoring']![
                          'Net OPR Count']
                      .toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Processor OPR Count')),
                  DataCell(Text(robotData['Performance Stats']!['Scoring']![
                          'Processor OPR Count']
                      .toString())),
                ]),
              ],
            ),
          ),

          SizedBox(height: height * 0.02),

          // Buttons for Auto Table, Preset Comments, and Graphing
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Navigate to Auto Table page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AutoTablePage(
                          teamNumber: teamName,
                          onThemeChanged: (ThemeMode mode) {},
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Auto Table",
                    style: TextStyle(
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlue,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Navigate to Preset Comments page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PresetComment(
                          teamNumber: teamName,
                          onThemeChanged: (ThemeMode mode) {},
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Preset Comments",
                    style: TextStyle(
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlue,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Navigate to Graphing page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Graphing(),
                      ),
                    );
                  },
                  child: const Text(
                    "Graphing",
                    style: TextStyle(
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlue,
                    ),
                  ),
                ),
              ),
            ],
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text(
              "Robot Specifications",
              style: TextStyle(
                fontSize: height * 0.025,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // For each category in Robot Specifications
          ...robotData['Robot Specifications']!
              .entries
              .map((category) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, top: 15.0, bottom: 5.0),
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
                          children: category.value.keys
                              .map((label) => SizedBox(
                                    width: width * 0.45,
                                    child: buildStatItem(label, height),
                                  ))
                              .toList(),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ))
              .toList(),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Lead Scout Notes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Team ${widget.teamName} "${widget.teamNickname}"',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
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
                    robotData['Notes']!['Team Compatibility']!['Description']
                        .toString(),
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
                    robotData['Notes']!['Notable Feats']!['Description']
                        .toString(),
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
        child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
      ),
    );
  }
}
