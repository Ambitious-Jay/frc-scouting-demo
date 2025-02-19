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

class TeamSpotData {
  final String team;
  final double x;
  final double y;
  final Color color;

  TeamSpotData(this.team, this.x, this.y, this.color);
}

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
  late Map<String, Color> teamsMap = {};
  double? xMin, xMax, yMin, yMax;

  final Map<String, String> metricDisplayNames = {
    'avgAutoPoints': 'Average Auto Points',
    'avgTeleopPoints': 'Average Teleop Points',
    'avgCycleTime': 'Average Cycle Time',
    'defenseRating': 'Defense Rating',
    'autoConsistency': 'Auto Consistency',
    'climbSuccessRate': 'Climb Success Rate',
    'pickupSuccessRate': 'Pickup Success Rate',
    'maxMatchScore': 'Maximum Match Score'
  };

  String getDisplayName(String metric) {
    return metricDisplayNames[metric] ?? _generateDisplayName(metric);
  }

  String _generateDisplayName(String metric) {
    final words = metric
        .replaceAllMapped(
          RegExp(r'([A-Z])|(_)'),
          (Match m) => ' ${m.group(0)}',
        )
        .split(' ');

    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

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
  List<TeamSpotData> teamSpots = [];

  @override
  void initState() {
    super.initState();
    teamsMap = {};
    for (String team in widget.teamData.keys) {
      teamsMap[team] = getNextColor();
    }

    final metrics = availableMetrics;
    if (metrics.length >= 2) {
      selectedXMetric = metrics[0];
      selectedYMetric = metrics[1];
    }
  }

  Color getNextColor() {
    if (availableColors.isEmpty) {
      return Colors.primaries[teamsMap.length % Colors.primaries.length];
    }
    return availableColors.removeAt(0);
  }

  void calculateRanges() {
    if (selectedXMetric == null || selectedYMetric == null) return;

    xMin = double.infinity;
    xMax = double.negativeInfinity;
    yMin = double.infinity;
    yMax = double.negativeInfinity;

    for (var teamMetrics in widget.teamData.values) {
      final xValue = teamMetrics[selectedXMetric];
      final yValue = teamMetrics[selectedYMetric];

      if (xValue != null) {
        xMin = xMin!.compareTo(xValue) <= 0 ? xMin : xValue;
        xMax = xMax!.compareTo(xValue) >= 0 ? xMax : xValue;
      }
      if (yValue != null) {
        yMin = yMin!.compareTo(yValue) <= 0 ? yMin : yValue;
        yMax = yMax!.compareTo(yValue) >= 0 ? yMax : yValue;
      }
    }
  }

  int getDecimalPlaces(double range) {
    if (range < 0.01) return 4;
    if (range < 0.1) return 3;
    if (range < 1) return 2;
    if (range < 10) return 1;
    return 0;
  }

  int getAxisDecimalPlaces(bool isXAxis) {
    if (isXAxis) {
      if (xMin == null || xMax == null) return 2;
      return getDecimalPlaces(xMax! - xMin!);
    } else {
      if (yMin == null || yMax == null) return 2;
      return getDecimalPlaces(yMax! - yMin!);
    }
  }

  List<String> get availableMetrics {
    Set<String> metrics = {};
    for (var teamMetrics in widget.teamData.values) {
      metrics.addAll(teamMetrics.keys);
    }
    return metrics.toList()..sort();
  }

  List<String> get availableYMetrics {
    return availableMetrics
        .where((metric) => metric != selectedXMetric)
        .toList();
  }

  List<String> get availableXMetrics {
    return availableMetrics
        .where((metric) => metric != selectedYMetric)
        .toList();
  }

  List<ScatterSpot> getScatterSpots() {
    List<ScatterSpot> spots = [];
    teamSpots.clear();

    if (selectedXMetric == null || selectedYMetric == null) return spots;

    calculateRanges();

    // Add padding to the ranges
    if (xMin != null && xMax != null) {
      double xRange = xMax! - xMin!;
      xMin = xMin! - (xRange * 0.05); // 5% padding
      xMax = xMax! + (xRange * 0.05);
    }
    if (yMin != null && yMax != null) {
      double yRange = yMax! - yMin!;
      yMin = yMin! - (yRange * 0.05);
      yMax = yMax! + (yRange * 0.05);
    }

    for (String team in teamsMap.keys) {
      final teamMetrics = widget.teamData[team];
      if (teamMetrics == null) continue;

      final xValue = teamMetrics[selectedXMetric];
      final yValue = teamMetrics[selectedYMetric];

      if (xValue == null || yValue == null) continue;

      teamSpots.add(TeamSpotData(
        team,
        xValue,
        yValue,
        teamsMap[team]!,
      ));

      spots.add(
        ScatterSpot(
          xValue,
          yValue,
          dotPainter: FlDotCirclePainter(
            color: teamsMap[team]!,
            strokeWidth: 1,
            strokeColor: teamsMap[team]!.withOpacity(0.5),
            radius: 6,
          ),
          show: true,
        ),
      );
    }
    return spots;
  }

  Widget _buildMetricDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: items.map((metric) {
          return DropdownMenuItem(
            value: metric,
            child: Text(getDisplayName(metric)),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            if (label.startsWith('X')) {
              selectedXMetric = newValue;
            } else {
              selectedYMetric = newValue;
            }
          });
        },
      ),
    );
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
            const Text(
              'Select Metrics to Compare:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildMetricDropdown(
                        context: context,
                        label: 'X-Axis Metric',
                        value: selectedXMetric,
                        items: availableXMetrics,
                      ),
                      const SizedBox(height: 16),
                      _buildMetricDropdown(
                        context: context,
                        label: 'Y-Axis Metric',
                        value: selectedYMetric,
                        items: availableYMetrics,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricDropdown(
                        context: context,
                        label: 'X-Axis Metric',
                        value: selectedXMetric,
                        items: availableXMetrics,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricDropdown(
                        context: context,
                        label: 'Y-Axis Metric',
                        value: selectedYMetric,
                        items: availableYMetrics,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (selectedXMetric != null && selectedYMetric != null)
              Expanded(
                child: ScatterChart(
                  ScatterChartData(
                    scatterTouchData: ScatterTouchData(
                      enabled: true,
                      touchTooltipData: ScatterTouchTooltipData(
                        getTooltipItems: (ScatterSpot touchedSpot) {
                          final teamSpot = teamSpots.firstWhere(
                            (ts) =>
                                ts.x == touchedSpot.x && ts.y == touchedSpot.y,
                            orElse: () =>
                                TeamSpotData('Unknown', 0, 0, Colors.grey),
                          );
                          return ScatterTooltipItem(
                            'Team ${teamSpot.team}\n'
                            '${getDisplayName(selectedXMetric!)}: ${teamSpot.x.toStringAsFixed(getAxisDecimalPlaces(true))}\n'
                            '${getDisplayName(selectedYMetric!)}: ${teamSpot.y.toStringAsFixed(getAxisDecimalPlaces(false))}',
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      mouseCursorResolver: (event, response) {
                        return response == null || response.touchedSpot == null
                            ? MouseCursor.defer
                            : SystemMouseCursors.click;
                      },
                    ),
                    scatterSpots: getScatterSpots(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(bottom: 0.5),
                          child: Text(
                            getDisplayName(selectedYMetric!),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(getAxisDecimalPlaces(false)),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(),
                          child: Text(
                            getDisplayName(selectedXMetric!),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: ((xMax ?? 0) - (xMin ?? 0)) / 6,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(getAxisDecimalPlaces(true)),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => const FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.white24),
                    ),
                    backgroundColor: Colors.grey[900],
                    minX: xMin,
                    maxX: xMax,
                    minY: yMin,
                    maxY: yMax,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
