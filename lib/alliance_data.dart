import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_table_page.dart';
import 'package:frc1148_2025_scouting_app/graphing_page.dart';
import 'package:frc1148_2025_scouting_app/preset_comment.dart';
import 'color_scheme.dart';

// Example team data - in a real app, this would come from your database or API
Map<String, Map<String, dynamic>> teamsData = {
  '1148': {
    'Coral Per Match': 3.2,
    'L4 OPR Count': 2,
    'L3/L2 OPR Count': 1,
    'L1 OPR Count': 4,
    'Algae Per Match': 2.7,
    'Net OPR Count': 3,
    'Processor OPR Count': 2,
    'EPA': 3.45,
    'Rank': 1,
    'WLR': '5-2-0',
    'Processor': 'TRUE',
    'Net': 'TRUE',
    'Hang': 'deep Cage',
    'L1': 3,
    'L2/L3': 2,
    'L4': 1,
    'CPM': 3.2,
    'APM': 2.7,
  },
  '254': {
    'Coral Per Match': 2.8,
    'L4 OPR Count': 3,
    'L3/L2 OPR Count': 2,
    'L1 OPR Count': 1,
    'Algae Per Match': 3.1,
    'Net OPR Count': 4,
    'Processor OPR Count': 3,
    'EPA': 4.12,
    'Rank': 2,
    'WLR': '7-1-0',
    'Processor': 'False',
    'Net': 'TRUE',
    'Hang': 'shallow Cage',
    'L1': 1,
    'L2/L3': 2,
    'L4': 3,
    'CPM': 2.8,
    'APM': 3.1,
  },
  '1678': {
    'Coral Per Match': 1.9,
    'L4 OPR Count': 1,
    'L3/L2 OPR Count': 3,
    'L1 OPR Count': 2,
    'Algae Per Match': 2.2,
    'Net OPR Count': 2,
    'Processor OPR Count': 1,
    'EPA': 2.87,
    'Rank': 3,
    'WLR': '3-4-1',
    'Processor': 'TRUE',
    'Net': 'FALSE',
    'Hang': 'none',
    'L1': 2,
    'L2/L3': 3,
    'L4': 1,
    'CPM': 1.9,
    'APM': 2.2,
  },
};

// Constants
const String deepCage = 'TRUE';
const String shallowCage = 'FALSE'; // Fixed the variable name to camelCase

class AllianceData extends StatefulWidget {
  const AllianceData({super.key, required this.allianceNames});
  final String allianceNames;
  @override
  State<AllianceData> createState() => _AllianceData();
}

class _AllianceData extends State<AllianceData> {
  List<String> _teamNames = [];
  
  // Add the ability to fetch or update team data
  Map<String, dynamic> getTeamData(String teamName) {
    // Return team data if exists, otherwise return empty data
    return teamsData[teamName] ?? createEmptyTeamData();
  }
  
  // Create empty data structure for a new team
  Map<String, dynamic> createEmptyTeamData() {
    return {
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
      'Hang': 'none',
      'L1': 0,
      'L2/L3': 0,
      'L4': 0,
      'CPM': 0,
      'APM': 0,
    };
  }

  @override
  void initState() {
    super.initState();
    // Split the alliance names string to get individual team names
    _teamNames = widget.allianceNames.split(',').map((name) => name.trim()).toList();
    
    // Ensure we have at least 3 items in the list, even if empty strings
    while (_teamNames.length < 3) {
      _teamNames.add("Team ${_teamNames.length + 1}");
    }
  }

  Future<void> _submitSection() async {
    try {
      // Implement submission logic
    } catch (e) {
      print('Error: $e');
    }
  }

  // Custom container to display a single statistic
  Widget buildStatItem(String label, double height, Map<String, dynamic> teamData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: height * 0.018),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          teamData[label]?.toString() ?? 'N/A',
          style: TextStyle(
            fontSize: height * 0.02,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Build a container for team statistics
  Widget buildStatsContainer(double width, double height, String teamName) {
    // Get data for this specific team
    final teamData = getTeamData(teamName);
    
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
                Expanded(child: buildStatItem("EPA", height, teamData)),
                Expanded(child: buildStatItem("Rank", height, teamData)),
                Expanded(child: buildStatItem("WLR", height, teamData)),
              ],
            ),
          ),
          
          SizedBox(height: height * 0.02),
          
          // Second row: Processor, Net, Hang
          Container(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("Processor", height, teamData)),
                Expanded(child: buildStatItem("Net", height, teamData)),
                Expanded(child: buildStatItem("Hang", height, teamData)),
              ],
            ),
          ),
          
          SizedBox(height: height * 0.02),
          
          // Third row: L1, L2/L3, L4
          Container(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("L1", height, teamData)),
                Expanded(child: buildStatItem("L2/L3", height, teamData)),
                Expanded(child: buildStatItem("L4", height, teamData)),
              ],
            ),
          ),
          
          SizedBox(height: height * 0.02),
          
          // Fourth row: CPM, APM, CPM
          Container(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("CPM", height, teamData)),
                Expanded(child: buildStatItem("APM", height, teamData)),
                Expanded(child: buildStatItem("Coral Per Match", height, teamData)),
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
                DataColumn(label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('L4 OPR Count')),
                  DataCell(Text(teamData['L4 OPR Count'].toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('L3/L2 OPR Count')),
                  DataCell(Text(teamData['L3/L2 OPR Count'].toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('L1 OPR Count')),
                  DataCell(Text(teamData['L1 OPR Count'].toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Net OPR Count')),
                  DataCell(Text(teamData['Net OPR Count'].toString())),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Processor OPR Count')),
                  DataCell(Text(teamData['Processor OPR Count'].toString())),
                ]),
              ],
            ),
          ),
          
          SizedBox(height: height * 0.02),
          
          // Buttons for Auto Table and Preset Comments
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
                        builder: (context) => AutoTablePage(teamNumber: teamName, onThemeChanged: (ThemeMode ) {  },),
                      ),
                    );
                  },
                  child: const Text(
                    "Auto Table",
                    style: TextStyle(
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlue
                    )
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
                        builder: (context) => PresetComment(teamNumber: teamName, onThemeChanged: (ThemeMode ) {  },),
                      ),
                    );
                  },
                  child: const Text(
                    "Preset Comments",
                    style: TextStyle(
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlue
                    )
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
                      builder: (context) => Graphing(),
                    ),
                  );
                  },
                  child: const Text(
                    "Graphing",
                    style: TextStyle(
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.lightBlue
                    )
                  ),
                ),
              ),
            ],
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
            Text(widget.allianceNames),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            buildStatsContainer(width, height, _teamNames[0]),
            const Divider(),
            buildStatsContainer(width, height, _teamNames[1]),
            const Divider(),
            buildStatsContainer(width, height, _teamNames[2]),
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () async {
          await _submitSection();
          // Navigate to next screen or handle submission completion
        },
        child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
      ),
    );
  }
}