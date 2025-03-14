import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

/// Fetches teleop data from the MatchData table via the WebSocket bridging server.
/// Returns a nested map of team → stat → list of [matchNumber (as String), value] pairs.
/// The available stats are:
///   "L1", "L2/3", "L4", "Coral Total" (L1+L2/3+L4), "Net", "Processor", "Algae Total" (Net+Processor).
Future<Map<String, Map<String, List<List<dynamic>>>>> fetchTeleopData(
    WebSocketService webSocketService) async {
  String sql =
      "SELECT team_number, match_number, l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter FROM MatchData";

  final Map<String, dynamic> queryCmd = {
    "type": "query",
    "text": sql,
  };

  final completer = Completer<List<Map<String, dynamic>>>();
  late StreamSubscription sub;
  List<Map<String, dynamic>> rowsResult = [];

  sub = webSocketService.stream!.listen((rawMessage) {
    try {
      final int idx = rawMessage.indexOf('\r\n');
      if (idx < 0) return;
      final int len = int.parse(rawMessage.substring(0, idx));
      final String jsonPart = rawMessage.substring(idx + 2);
      if (jsonPart.length != len) return;
      final Map<String, dynamic> msg = jsonDecode(jsonPart);
      if (msg["type"] == "query") {
        final List<dynamic> rows = msg["rows"];
        rowsResult = rows.map((r) => Map<String, dynamic>.from(r)).toList();
        completer.complete(rowsResult);
      }
    } catch (e) {
      completer.completeError(e);
    }
  });

  webSocketService.sendLengthPrefixed(queryCmd);

  final rows =
      await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
    print("Timeout on fetching teleop match scores");
    return [];
  });
  await sub.cancel();

  // Group and transform rows.
  Map<String, Map<String, List<List<dynamic>>>> data = {};

  for (var row in rows) {
    String team = row["team_number"].toString();
    String matchNumber = row["match_number"].toString();
    num l1Val = row["l1Counter"];
    num l2l3Val = row["l2l3Counter"];
    num l4Val = row["l4Counter"];
    num netVal = row["netCounter"];
    num procVal = row["processorCounter"];
    num coralTotal = l1Val + l2l3Val + l4Val;
    num algaeTotal = netVal + procVal;

    if (!data.containsKey(team)) {
      data[team] = {
        "L1": [],
        "L2/3": [],
        "L4": [],
        "Coral Total": [],
        "Net": [],
        "Processor": [],
        "Algae Total": [],
      };
    }

    data[team]!["L1"]!.add([matchNumber, l1Val]);
    data[team]!["L2/3"]!.add([matchNumber, l2l3Val]);
    data[team]!["L4"]!.add([matchNumber, l4Val]);
    data[team]!["Coral Total"]!.add([matchNumber, coralTotal]);
    data[team]!["Net"]!.add([matchNumber, netVal]);
    data[team]!["Processor"]!.add([matchNumber, procVal]);
    data[team]!["Algae Total"]!.add([matchNumber, algaeTotal]);
  }

  return data;
}

/// Fetches autonomous data from the AutoScouting table via the WebSocket bridging server.
/// Returns a nested map of team → stat → list of [matchNumber (as String), value] pairs.
/// The available stats are:
///   "L1", "L2/3", "L4", "Coral Total" (L1+L2/3+L4), "Net", "Processor", "Algae Total" (Net+Processor).
Future<Map<String, Map<String, List<List<dynamic>>>>> fetchAutoData(
    WebSocketService webSocketService) async {
  String sql =
      "SELECT team_number, match_number, l4_count, l2_l3_count, l1_count, net_count, processor_count FROM AutoScouting";

  final Map<String, dynamic> queryCmd = {
    "type": "query",
    "text": sql,
  };

  final completer = Completer<List<Map<String, dynamic>>>();
  late StreamSubscription sub;
  List<Map<String, dynamic>> rowsResult = [];

  sub = webSocketService.stream!.listen((rawMessage) {
    try {
      final int idx = rawMessage.indexOf('\r\n');
      if (idx < 0) return;
      final int len = int.parse(rawMessage.substring(0, idx));
      final String jsonPart = rawMessage.substring(idx + 2);
      if (jsonPart.length != len) return;
      final Map<String, dynamic> msg = jsonDecode(jsonPart);
      if (msg["type"] == "query") {
        final List<dynamic> rows = msg["rows"];
        rowsResult = rows.map((r) => Map<String, dynamic>.from(r)).toList();
        completer.complete(rowsResult);
      }
    } catch (e) {
      completer.completeError(e);
    }
  });

  webSocketService.sendLengthPrefixed(queryCmd);

  final rows =
      await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
    print("Timeout on fetching autonomous match scores");
    return [];
  });
  await sub.cancel();

  Map<String, Map<String, List<List<dynamic>>>> data = {};

  for (var row in rows) {
    String team = row["team_number"].toString();
    String matchNumber = row["match_number"].toString();
    num l1Val = row["l1_count"];
    num l2l3Val = row["l2_l3_count"];
    num l4Val = row["l4_count"];
    num netVal = row["net_count"];
    num procVal = row["processor_count"];
    num coralTotal = l1Val + l2l3Val + l4Val;
    num algaeTotal = netVal + procVal;

    if (!data.containsKey(team)) {
      data[team] = {
        "L1": [],
        "L2/3": [],
        "L4": [],
        "Coral Total": [],
        "Net": [],
        "Processor": [],
        "Algae Total": [],
      };
    }

    data[team]!["L1"]!.add([matchNumber, l1Val]);
    data[team]!["L2/3"]!.add([matchNumber, l2l3Val]);
    data[team]!["L4"]!.add([matchNumber, l4Val]);
    data[team]!["Coral Total"]!.add([matchNumber, coralTotal]);
    data[team]!["Net"]!.add([matchNumber, netVal]);
    data[team]!["Processor"]!.add([matchNumber, procVal]);
    data[team]!["Algae Total"]!.add([matchNumber, algaeTotal]);
  }

  return data;
}

/// Graphing page that displays a line chart for selected match data.
class Graphing extends StatefulWidget {
  final String? initialTeam;
  
  const Graphing({
    Key? key,
    this.initialTeam,
  }) : super(key: key);

  @override
  State<Graphing> createState() => _GraphingState();
}

class _GraphingState extends State<Graphing> {
  bool isLoading = true;
  // Toggle between teleop and autonomous.
  bool _isAutonomous = false;

  // Data sets.
  Map<String, Map<String, List<List<dynamic>>>> teleopData = {};
  Map<String, Map<String, List<List<dynamic>>>> autoData = {};

  // Dropdown selections.
  late String _selectedTeam;
  late String
      _selectedStat; // Options: "L1", "L2/3", "L4", "Coral Total", "Net", "Processor", "Algae Total"

  // Use the WebSocketService singleton.
  final WebSocketService webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    webSocketService.connect();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      Map<String, Map<String, List<List<dynamic>>>> fetchedTeleop =
          await fetchTeleopData(webSocketService);
      Map<String, Map<String, List<List<dynamic>>>> fetchedAuto =
          await fetchAutoData(webSocketService);
      setState(() {
        teleopData = fetchedTeleop;
        autoData = fetchedAuto;
        isLoading = false;
      //   if (teleopData.isNotEmpty) {
      //     _selectedTeam = teleopData.keys.first;
      //     _selectedStat = teleopData[_selectedTeam]!.keys.first;
      //   }
      // });
      if (teleopData.isNotEmpty) {
          if (widget.initialTeam != null && teleopData.containsKey(widget.initialTeam)) {
            _selectedTeam = widget.initialTeam!;
          } else {
            _selectedTeam = teleopData.keys.first;
          }
          _selectedStat = teleopData[_selectedTeam]!.keys.first;
        }
      });
      } catch (e) {
        print("Error fetching data: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Graphing')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final Map<String, Map<String, List<List<dynamic>>>> currentData =
        _isAutonomous ? autoData : teleopData;

    if (currentData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Graphing')),
        body: const Center(child: Text('No data found')),
      );
    }

    if (!currentData.containsKey(_selectedTeam)) {
      _selectedTeam = currentData.keys.first;
      _selectedStat = currentData[_selectedTeam]!.keys.first;
    }

    // Get the series for the selected team and stat.
    List<List<dynamic>> statData =
        currentData[_selectedTeam]?[_selectedStat] ?? [];

    // Sort series by match number (as strings).
    statData.sort((a, b) => a[0].toString().compareTo(b[0].toString()));

    // Create chart spots using the list index as the x-axis.
    final spots = statData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value[1]).toDouble();
      return FlSpot(index.toDouble(), value);
    }).toList();

    double average = spots.isNotEmpty
        ? spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length
        : 0;
    final double minX = 0;
    final double maxX = spots.isNotEmpty ? (spots.length - 1).toDouble() : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Graphing'),
      ),
      body: Center(
        child: FractionallySizedBox(
          heightFactor: 0.6,
          child: Column(
            children: [
              // Row for toggling Autonomous mode.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isAutonomous,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _isAutonomous = value;
                              final newData =
                                  _isAutonomous ? autoData : teleopData;
                              if (newData.isNotEmpty) {
                                _selectedTeam = newData.keys.first;
                                _selectedStat =
                                    newData[_selectedTeam]!.keys.first;
                              }
                            });
                          }
                        },
                      ),
                      const Text("Autonomous?")
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dropdowns for selecting team and stat.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: _selectedTeam,
                    items: currentData.keys.map((team) {
                      return DropdownMenuItem<String>(
                        value: team,
                        child: Text('Team $team'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTeam = value;
                          _selectedStat =
                              currentData[_selectedTeam]!.keys.first;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedStat,
                    items: currentData[_selectedTeam]!.keys.map((stat) {
                      return DropdownMenuItem<String>(
                        value: stat,
                        child: Text(stat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStat = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Line chart.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text('Match Number'),
                          axisNameSize: 30,
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0)
                                return const SizedBox.shrink();
                              final index = value.toInt();
                              if (index < 0 || index >= statData.length)
                                return const SizedBox.shrink();
                              final matchNumber = statData[index][0].toString();
                              return Text(matchNumber);
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: average,
                            color: Colors.red.withOpacity(0.7),
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.centerRight,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                              labelResolver: (_) =>
                                  '\nAvg: ${average.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              final matchNumber =
                                  (index >= 0 && index < statData.length)
                                      ? statData[index][0].toString()
                                      : "N/A";
                              return LineTooltipItem(
                                'Match $matchNumber\nValue: ${spot.y}',
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false,
                          barWidth: 3,
                          color: Colors.white,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
