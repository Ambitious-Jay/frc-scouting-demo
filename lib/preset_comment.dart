import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/scroll_controller.dart';

class PresetComment extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final String teamNumber;
  final String teamName;

  const PresetComment({
    Key? key,
    required this.onThemeChanged,
    required this.teamNumber,
    required this.teamName,
  }) : super(key: key);

  @override
  State<PresetComment> createState() => _PresetCommentState();
}

class _PresetCommentState extends State<PresetComment> {
  late Future<Map<String, int>> presetDataFuture;

  @override
  void initState() {
    super.initState();
    presetDataFuture = _fetchPresetData();
  }

  Future<Map<String, int>> _fetchPresetData() async {
    // Replace this simulated delay and dummy data with your actual
    // database call to fetch the EndgameData row for widget.teamNumber.
    // For example, send a query like:
    // SELECT attempt_to_park, defense, mechanism_broke, stopped_moving, fast, good_driving, bad_driving,
    //        tippy, not_tippy, consistent_coral, inaccurate_coral, good_defense, bad_defense,
    //        jams_often, fast_climb, slow_climb, consistent_auton, inconsistent_auton, net_algae
    // FROM EndgameData WHERE team_number = '${widget.teamNumber}'
    await Future.delayed(Duration(seconds: 1));
    // Dummy data returned for demonstration:
    return {
      'attempt_to_park': 2,
      'defense': 3,
      'mechanism_broke': 1,
      'stopped_moving': 0,
      'fast': 4,
      'good_driving': 5,
      'bad_driving': 2,
      'tippy': 1,
      'not_tippy': 0,
      'consistent_coral': 3,
      'inaccurate_coral': 1,
      'good_defense': 4,
      'bad_defense': 1,
      'jams_often': 2,
      'fast_climb': 3,
      'slow_climb': 1,
      'consistent_auton': 4,
      'inconsistent_auton': 0,
      'net_algae': 2,
    };
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width  = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${widget.teamName} - Preset Comments'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: presetDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No data found"));
          }

          // Extract data and sort by descending frequency.
          Map<String, int> data = snapshot.data!;
          List<MapEntry<String, int>> entries = data.entries.toList();
          entries.sort((a, b) => b.value.compareTo(a.value));

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(height * 0.005),
                child: Text(
                  "Comments by frequency",
                  style: TextStyle(fontSize: height * 0.0375),
                ),
              ),
              const Divider(),
              Padding(
                padding: EdgeInsets.all(height * 0.005),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Comment",
                        style: TextStyle(fontSize: width * 0.0625),
                      ),
                    ),
                    Text(
                      "Frequency",
                      style: TextStyle(fontSize: width * 0.0625),
                      textAlign: TextAlign.right,
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  controller: AdjustableScrollController(15),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatPresetComment(entry.key),
                                    style: TextStyle(fontSize: width * 0.0625),
                                  ),
                                ),
                                Text(
                                  entry.value.toString(),
                                  style: TextStyle(fontSize: width * 0.0625),
                                  textAlign: TextAlign.right,
                                )
                              ],
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white)
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Convert database column names to user-friendly labels.
  String _formatPresetComment(String key) {
    Map<String, String> friendlyNames = {
      'attempt_to_park': 'Attempt to Park',
      'defense': 'Defense',
      'mechanism_broke': 'Mechanism Broke',
      'stopped_moving': 'Stopped Moving',
      'fast': 'Fast',
      'good_driving': 'Good Driving',
      'bad_driving': 'Bad Driving',
      'tippy': 'Tippy',
      'not_tippy': 'Not Tippy',
      'consistent_coral': 'Consistent Coral',
      'inaccurate_coral': 'Inaccurate Coral',
      'good_defense': 'Good Defense',
      'bad_defense': 'Bad Defense',
      'jams_often': 'Jams Often',
      'fast_climb': 'Fast Climb',
      'slow_climb': 'Slow Climb',
      'consistent_auton': 'Consistent Auton',
      'inconsistent_auton': 'Inconsistent Auton',
      'net_algae': 'Net Algae',
    };

    return friendlyNames[key] ?? key;
  }
}
