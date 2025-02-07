// import 'package:flutter/material.dart';
// import 'package:frc1148_2025_scouting_app/color_scheme.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:math' as math;

// class TeamGraphing extends StatefulWidget {
//   const TeamGraphing({super.key, required this.allTeams, required this.teamName});

//   final String teamName;
//   final List<String> allTeams;
//   @override
//   State<TeamGraphing> createState() => _TeamGraphingState();
// }

// class _TeamGraphingState extends State<TeamGraphing> {
//   //List<String> allTeams = List.empty();
//   List<String> selectedTeams = List.empty(growable: true);

//   String selectedTeamsDisplay = "";
//   List<Widget> allTeamColorsDisplay = List.empty(growable: true);

//   Map<String, Color> allTeamColors = {};

//   String selectedMetric = "";
//   List<LineChartBarData> coordinates = List.empty(growable: true);

//   List<String> allMetricsName = List.empty(growable: true);

//   void _updateTeams() {
//     try {
//       for (int i = 0; i < widget.allTeams.length; i++){
//         allTeamColors[widget.allTeams[i]] = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
//       }

//       setState(() {});
//       print(widget.allTeams.length);
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   Map<String, List<Map<String, List<int>>>> all = {};

//   bool isNumeric(String s) {
//     return double.tryParse(s) != null;
//   }

//   Future<void> _updateGraphs() async {
//     try {

//       var sheet = null;// await SheetsHelper.sheetSetup("App results");

//       final rows = await sheet!.values.allRows();

//       allMetricsName = rows[0];

//       for (int k = 0; k < widget.allTeams.length; k++){
//         List<Map<String, List<int>>> rutro = List.empty(growable: true);
//         print ("got");
//         for (int i = 1; i < rows.length; i++){
//           if (rows[i][0] != ""){
//             int spaceLoc = rows[i][0].indexOf(" ");
//             String teamNumber = rows[i][0].substring(spaceLoc+1);
//             String matchNumber = rows[i][0].substring(1, spaceLoc);
//             if (teamNumber == widget.allTeams[k]){
//               final allMetricsInAMatch = rows[i];

//               Map<String, List<int>> aMatch = {};

//               for (int j = 2; j < allMetricsInAMatch.length; j++){
//                 if (isNumeric( allMetricsInAMatch[j])){
//                   String columnName = allMetricsName[j];
//                   List<int> coordinate = [int.parse(matchNumber), int.parse(allMetricsInAMatch[j])];
//                   if (aMatch.containsKey(columnName)) {
//                     aMatch.update(columnName, (value) => coordinate);
//                   } else {
//                     aMatch.putIfAbsent(columnName, () => coordinate);
//                   }
//                 }

//               }
//               rutro.add(aMatch);
//             }
//           }
//         }

//         if (all.containsKey(widget.allTeams[k])) {
//           print ("here");
//           all.update(widget.allTeams[k], (value) => rutro);
//         } else {
//           print ("here");
//           all.putIfAbsent(widget.allTeams[k], () => rutro);
//         }
//       }
//       setState(() {});
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     all = {};

//     _updateTeams();
//     _updateGraphs();
//   }

//   @override
//   Widget build(BuildContext context) {
//     double height = MediaQuery.of(context).size.height;
//     double width = MediaQuery.of(context).size.width;
//     TextEditingController teamDrop = TextEditingController();
//     TextEditingController metricDrop = TextEditingController();
//     if (widget.allTeams.isEmpty || all.isEmpty) {
//       return const SafeArea(
//         child: Scaffold(
//             body: Center(
//               child: Text(
//                 "loading ...",
//               ),
//             )),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Graphing"),
//       ),
//       body: SizedBox(
//         height: height,
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Text(selectedTeamsDisplay),
//               Row(mainAxisAlignment: MainAxisAlignment.center ,children: allTeamColorsDisplay,),
//               Text(selectedMetric),
//               DropdownMenu<String>(
//                   width: width,
//                   hintText: "Select Teams To Compare",
//                   requestFocusOnTap: true,
//                   controller: teamDrop,
//                   enableFilter: true,
//                   label: const Text('Select Teams To Compare'),
//                   onSelected: (String? value) {
//                     // setState(() {
//                     //   teamDrop.text = "";
//                     // });
//                     if (!selectedTeams.contains(value)) {

//                       setState(() {
//                         selectedTeamsDisplay += "$value, ";
//                         selectedTeams.add (value!);
//                         allTeamColorsDisplay.add(Icon(Icons.circle, color: allTeamColors[value],));
//                         allTeamColorsDisplay.add(const SizedBox(width: 10,),);
//                       });

//                       if (selectedMetric != ""){
//                         LineChartBarData line;
//                         print (all[value]);
//                         List<FlSpot> spots = List.empty(growable: true);
//                         for (int j = 0; j < all[value]!.length; j++){
//                           FlSpot spot = FlSpot(all[value]![j][selectedMetric]![0] as double, all[value]![j][selectedMetric]![1] as double);
//                           spots.add(spot);

//                         }
//                         line = LineChartBarData(spots: spots, color: allTeamColors[value]);
//                         //print (line);
//                         setState(() {
//                           coordinates.add(line);
//                         });
//                       }
//                     }

//                   },
//                   dropdownMenuEntries:
//                       widget.allTeams.map<DropdownMenuEntry<String>>((String menu) {
//                     return DropdownMenuEntry<String>(
//                         value: menu,
//                         label: menu,);
//                   }).toList(),
//               ),
//               DropdownMenu<String>(
//                   width: width,
//                   hintText: "Select Metrics to Compare",
//                   requestFocusOnTap: true,
//                   controller: metricDrop,
//                   enableFilter: true,
//                   label: const Text('Select Metrics to Compare'),
//                   onSelected: (String? value) {
//                     //coordinates = List.empty(growable: true);
//                     // setState(() {
//                     //   metricDrop.text = "";
//                     // });
//                     selectedMetric = value!;
//                     coordinates = List.empty(growable: true);
//                     try{
//                       for (int i = 0; i < selectedTeams.length; i++){
//                         ScatterChartData line;

//                         List<ScatterSpot> spots = List.empty(growable: true);
//                         for (int j = 0; j < all[selectedTeams[i]]!.length; j++){
//                           if (all[selectedTeams[i]]![j][value] != null){
//                             ScatterSpot spot = ScatterSpot(all[selectedTeams[i]]![j][value]![0] as double, all[selectedTeams[i]]![j][value]![1] as double);
//                             spots.add(spot);
//                           }

//                         }
//                         line = ScatterChartData(scatterSpots: spots);
//                         //print (line);
//                         setState(() {
//                           //coordinates.add(line);
//                         });
//                       }
//                     }
//                     catch(e){
//                       print (e);
//                     }

//                   },
//                   dropdownMenuEntries:
//                       allMetricsName.sublist(2).map<DropdownMenuEntry<String>>((String menu) {
//                     return DropdownMenuEntry<String>(
//                         value: menu,
//                         label: menu,);
//                   }).toList(),
//               ),
//               coordinates.isNotEmpty ?
//               SizedBox(
//                 height: height*0.5,
//                 width: width,
//                 child: LineChart(
//                   LineChartData(
//                     lineBarsData: coordinates,
//                   ),
//                 ),
//               )
//               : const SizedBox(),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: (){
//           setState(() {
//             selectedTeams = List.empty(growable: true);
//             selectedTeamsDisplay = "";
//             allTeamColorsDisplay = List.empty(growable: true);
//             selectedMetric = "";
//             coordinates = List.empty(growable: true);
//           });
//         },
//         child: const Icon(Icons.delete),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FlexibleScatterPlot extends StatefulWidget {
  final Map<String, Map<String, double>> teamData;

  const FlexibleScatterPlot({
    super.key,
    required this.teamData,
  });

  @override
  State<FlexibleScatterPlot> createState() => _FlexibleScatterPlotState();
}

class _FlexibleScatterPlotState extends State<FlexibleScatterPlot> {
  // Store team-to-color assignments
  final Map<String, Color> selectedTeams = {};

  // Keep track of which colors are available to use
  final List<Color> availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  String? selectedXMetric;
  String? selectedYMetric;

  // Get the next available color and remove it from the pool
  Color getNextColor() {
    if (availableColors.isEmpty) {
      // If we run out of colors, generate a new one
      // This ensures we never have duplicates even with many teams
      return Colors.primaries[selectedTeams.length % Colors.primaries.length];
    }
    return availableColors.removeAt(0);
  }

  // Handle team selection/deselection
  void toggleTeam(String team, bool selected) {
    setState(() {
      if (selected) {
        selectedTeams[team] = getNextColor();
      } else {
        // Put the color back in the available pool when removing a team
        availableColors.insert(0, selectedTeams[team]!);
        selectedTeams.remove(team);
      }
    });
  }

  // Rest of the implementation remains the same
  List<String> get availableMetrics {
    Set<String> metrics = {};
    for (var teamMetrics in widget.teamData.values) {
      metrics.addAll(teamMetrics.keys);
    }
    return metrics.toList()..sort();
  }

  double getMinValue(String? metric) {
    if (metric == null) return 0;
    double min = double.infinity;
    for (var team in selectedTeams.keys) {
      final value = widget.teamData[team]?[metric];
      if (value != null && value < min) {
        min = value;
      }
    }
    return min.isFinite ? min : 0;
  }

  double getMaxValue(String? metric) {
    if (metric == null) return 0;
    double max = double.negativeInfinity;
    for (var team in selectedTeams.keys) {
      final value = widget.teamData[team]?[metric];
      if (value != null && value > max) {
        max = value;
      }
    }
    return max.isFinite ? max : 0;
  }

  List<ScatterSpot> getScatterSpots() {
    List<ScatterSpot> spots = [];
    if (selectedXMetric == null || selectedYMetric == null) return spots;

    for (String team in selectedTeams.keys) {
      final teamMetrics = widget.teamData[team];
      if (teamMetrics == null) continue;

      final xValue = teamMetrics[selectedXMetric];
      final yValue = teamMetrics[selectedYMetric];

      if (xValue == null || yValue == null) continue;

      spots.add(
        ScatterSpot(
          xValue,
          yValue,
          dotPainter: FlDotCirclePainter(
            color: selectedTeams[team]!,
            strokeWidth: 1,
            strokeColor: selectedTeams[team]!.withOpacity(0.5),
            radius: 8,
          ),
          show: true,
        ),
      );
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Teams to Compare:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.teamData.keys.map((team) {
                  final isSelected = selectedTeams.containsKey(team);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('Team $team'),
                      selected: isSelected,
                      selectedColor: isSelected
                          ? selectedTeams[team]?.withOpacity(0.3)
                          : null,
                      onSelected: (selected) => toggleTeam(team, selected),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[850],
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'X-Axis Metric',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedXMetric,
                      items: availableMetrics.map((metric) {
                        return DropdownMenuItem(
                          value: metric,
                          child: Text(metric),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedXMetric = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[850],
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Y-Axis Metric',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedYMetric,
                      items: availableMetrics.map((metric) {
                        return DropdownMenuItem(
                          value: metric,
                          child: Text(metric),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedYMetric = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedTeams.isNotEmpty)
              Row(
                children: [
                  ...selectedTeams.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Team ${entry.key}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            const SizedBox(height: 16),
            if (selectedXMetric != null &&
                selectedYMetric != null &&
                selectedTeams.isNotEmpty)
              Expanded(
                child: ScatterChart(
                  ScatterChartData(
                    scatterSpots: getScatterSpots(),
                    minX: getMinValue(selectedXMetric) - 0.5,
                    maxX: getMaxValue(selectedXMetric) + 0.5,
                    minY: getMinValue(selectedYMetric) - 0.5,
                    maxY: getMaxValue(selectedYMetric) + 0.5,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text(
                          selectedXMetric!,
                          style: TextStyle(color: Colors.white70),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(1),
                            style:
                                TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          selectedYMetric!,
                          style: TextStyle(color: Colors.white70),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(1),
                            style:
                                TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ),
                      ),
                      topTitles: AxisTitles(),
                      rightTitles: AxisTitles(),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.white24),
                    ),
                    backgroundColor: Colors.grey[900],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
