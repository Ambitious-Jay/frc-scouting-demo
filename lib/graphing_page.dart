import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

/// Normalizes team numbers by removing the "frc" prefix if present
String normalizeTeamNumber(String team) {
  return team.startsWith('frc') ? team.substring(3) : team;
}

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
    String team = normalizeTeamNumber(row["team_number"].toString());
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
    String team = normalizeTeamNumber(row["team_number"].toString());
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

/// Fetches TBAMatchScores data from the WebSocket bridging server.
/// Returns a nested map of team → stat → list of [matchNumber (as String), value] pairs.
/// The available stats are:
///   "End Game Robot 1", "End Game Robot 2", "End Game Robot 3",
///   "Auto Line Robot 1", "Auto Line Robot 2", "Auto Line Robot 3"
Future<Map<String, Map<String, List<List<dynamic>>>>> fetchTBAMatchScoresData(
    WebSocketService webSocketService) async {
  String sql = """
    SELECT match_key, team_keys, 
           end_game_robot_1, end_game_robot_2, end_game_robot_3,
           auto_line_robot_1, auto_line_robot_2, auto_line_robot_3
    FROM TBAMatchScores
  """;

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
    print("Timeout on fetching TBA match scores");
    return [];
  });
  await sub.cancel();

  Map<String, Map<String, List<List<dynamic>>>> data = {};

  for (var row in rows) {
    String matchNumber = row["match_key"].toString();
    // Split and clean team numbers
    List<String> teams = (row["team_keys"] as String)
        .split(',')
        .map((team) => team.startsWith('frc') ? team.substring(3) : team)
        .toList();

    print("Processing TBA data for teams: $teams"); // Debug print

    // Process each team in the alliance
    for (int i = 0; i < teams.length; i++) {
      String team = teams[i];
      print("Processing team $team with match $matchNumber"); // Debug print

      if (!data.containsKey(team)) {
        data[team] = {
          "End Game": [],
          "Auto Line": [],
        };
      }

      // Convert end game status to numeric values
      int endGameStatus;
      int autoLineStatus;

      switch (i) {
        case 0:
          endGameStatus = _convertEndGameStatus(row["end_game_robot_1"]);
          autoLineStatus = row["auto_line_robot_1"] == "Yes" ? 1 : 0;
          break;
        case 1:
          endGameStatus = _convertEndGameStatus(row["end_game_robot_2"]);
          autoLineStatus = row["auto_line_robot_2"] == "Yes" ? 1 : 0;
          break;
        case 2:
          endGameStatus = _convertEndGameStatus(row["end_game_robot_3"]);
          autoLineStatus = row["auto_line_robot_3"] == "Yes" ? 1 : 0;
          break;
        default:
          continue;
      }

      data[team]!["End Game"]!.add([matchNumber, endGameStatus]);
      data[team]!["Auto Line"]!.add([matchNumber, autoLineStatus]);
    }
  }

  print("TBA data after processing:"); // Debug print
  data.forEach((team, stats) {
    print("Team $team stats: ${stats.keys}");
  });

  return data;
}

/// Converts end game status to numeric values:
/// None = 0, Parked = 1, ShallowCage = 2, DeepCage = 3
int _convertEndGameStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'none':
      return 0;
    case 'parked':
      return 1;
    case 'shallowcage':
      return 2;
    case 'deepcage':
      return 3;
    default:
      return 0;
  }
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
  Map<String, Map<String, List<List<dynamic>>>> tbaData = {};

  // Dropdown selections.
  late String _selectedTeam;
  late String _selectedStat;

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
      Map<String, Map<String, List<List<dynamic>>>> fetchedTBA =
          await fetchTBAMatchScoresData(webSocketService);

      print("Fetched TBA data keys: ${fetchedTBA.keys}");
      if (fetchedTBA.isNotEmpty) {
        String firstTeam = fetchedTBA.keys.first;
        print("First team TBA stats: ${fetchedTBA[firstTeam]!.keys}");
      }

      setState(() {
        teleopData = fetchedTeleop;
        autoData = fetchedAuto;
        tbaData = fetchedTBA;
        isLoading = false;

        // Initialize with first available team and stat from any dataset
        String? firstTeam;
        if (widget.initialTeam != null) {
          String normalizedInitialTeam =
              normalizeTeamNumber(widget.initialTeam!);
          if (fetchedTeleop.containsKey(normalizedInitialTeam) ||
              fetchedAuto.containsKey(normalizedInitialTeam) ||
              fetchedTBA.containsKey(normalizedInitialTeam)) {
            firstTeam = normalizedInitialTeam;
          }
        }

        if (firstTeam == null) {
          firstTeam = [
            ...fetchedTeleop.keys,
            ...fetchedAuto.keys,
            ...fetchedTBA.keys
          ].firstOrNull;
        }

        if (firstTeam != null) {
          _selectedTeam = firstTeam;
          // Get all available stats for this team
          Set<String> allStats = {};
          if (fetchedTeleop.containsKey(firstTeam)) {
            allStats.addAll(fetchedTeleop[firstTeam]!.keys);
          }
          if (fetchedAuto.containsKey(firstTeam)) {
            allStats.addAll(fetchedAuto[firstTeam]!.keys);
          }
          if (fetchedTBA.containsKey(firstTeam)) {
            allStats.addAll(fetchedTBA[firstTeam]!.keys);
          }
          _selectedStat = allStats.first;

          print("Selected team: $_selectedTeam");
          print("All available stats: $allStats");
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

    // Create a new map with all available data
    final Map<String, Map<String, List<List<dynamic>>>> currentData = {};

    // Get all unique teams and normalize their numbers
    Set<String> allTeams = {
      ...teleopData.keys.map(normalizeTeamNumber),
      ...autoData.keys.map(normalizeTeamNumber),
      ...tbaData.keys.map(normalizeTeamNumber),
    };

    // Combine all data for each team
    for (var team in allTeams) {
      currentData[team] = {};

      // Add mode-specific data if it exists
      if (_isAutonomous && autoData.containsKey(team)) {
        currentData[team]!.addAll(Map.from(autoData[team]!));
      } else if (!_isAutonomous && teleopData.containsKey(team)) {
        currentData[team]!.addAll(Map.from(teleopData[team]!));
      }

      // Always add TBA data if it exists
      if (tbaData.containsKey(team)) {
        currentData[team]!.addAll(Map.from(tbaData[team]!));
      }
    }

    // Sort teams numerically
    List<String> sortedTeams = currentData.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    if (!currentData.containsKey(_selectedTeam)) {
      _selectedTeam = sortedTeams.first;
    }

    // Get the series for the selected team and stat.
    List<List<dynamic>> statData =
        currentData[_selectedTeam]?[_selectedStat] ?? [];

    // Remove duplicate matches for the same stat
    Map<String, List<dynamic>> uniqueMatches = {};
    for (var data in statData) {
      String matchNumber = data[0].toString();
      if (!uniqueMatches.containsKey(matchNumber) ||
          uniqueMatches[matchNumber]![1] != data[1]) {
        uniqueMatches[matchNumber] = data;
      }
    }
    statData = uniqueMatches.values.toList();

    // Sort series by match number, handling "qm" prefix
    statData.sort((a, b) {
      String matchA = a[0].toString();
      String matchB = b[0].toString();

      // Remove "qm" prefix if present
      matchA =
          matchA.toLowerCase().startsWith('qm') ? matchA.substring(2) : matchA;
      matchB =
          matchB.toLowerCase().startsWith('qm') ? matchB.substring(2) : matchB;

      // Convert to integers for proper numeric sorting
      return int.parse(matchA).compareTo(int.parse(matchB));
    });

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

    // Get the y-axis title based on the selected stat
    String yAxisTitle = _selectedStat;
    if (_selectedStat == "End Game") {
      yAxisTitle = 'End Game Status';
    } else if (_selectedStat == "Auto Line") {
      yAxisTitle = 'Auto Line Status';
    }

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

                              // Create a new map for the combined data
                              final Map<String,
                                      Map<String, List<List<dynamic>>>>
                                  newData = {};

                              // Add mode-specific data
                              final modeData =
                                  _isAutonomous ? autoData : teleopData;
                              for (var team in modeData.keys) {
                                newData[team] = Map.from(modeData[team]!);
                              }

                              // Add TBA data
                              for (var team in tbaData.keys) {
                                if (!newData.containsKey(team)) {
                                  newData[team] = {};
                                }
                                newData[team]!.addAll(tbaData[team]!);
                              }

                              print(
                                  "Mode changed. Available stats: ${newData[newData.keys.first]?.keys}");

                              // Update selected team and stat
                              if (newData.isNotEmpty) {
                                if (!newData.containsKey(_selectedTeam)) {
                                  _selectedTeam = newData.keys.first;
                                }
                                // Keep the same stat if it exists for the new team
                                if (!newData[_selectedTeam]!
                                    .containsKey(_selectedStat)) {
                                  _selectedStat =
                                      newData[_selectedTeam]!.keys.first;
                                }
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
                    items: sortedTeams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team,
                        child: Text('Team $team'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTeam = value;
                          // Keep the same stat if it exists for the new team
                          if (!currentData[_selectedTeam]!
                              .containsKey(_selectedStat)) {
                            _selectedStat =
                                currentData[_selectedTeam]!.keys.first;
                          }
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
                  padding: const EdgeInsets.fromLTRB(4.0, 16.0, 48.0, 24.0),
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: _selectedStat == "End Game"
                          ? 0
                          : _selectedStat == "Auto Line"
                              ? 0
                              : 0,
                      maxY: _selectedStat == "End Game"
                          ? 3
                          : _selectedStat == "Auto Line"
                              ? 1
                              : spots
                                  .map((s) => s.y)
                                  .reduce((a, b) => a > b ? a : b),
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text('Match Number'),
                          axisNameSize: 30,
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 40,
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
                        leftTitles: AxisTitles(
                          axisNameWidget: Text(yAxisTitle),
                          axisNameSize: 30,
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 100, // Add more space for labels
                            getTitlesWidget: (value, meta) {
                              if (_selectedStat == "End Game") {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('None');
                                  case 1:
                                    return const Text('Parked');
                                  case 2:
                                    return const Text('ShallowCage');
                                  case 3:
                                    return const Text('DeepCage');
                                  default:
                                    return const SizedBox.shrink();
                                }
                              } else if (_selectedStat == "Auto Line") {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('No');
                                  case 1:
                                    return const Text('Yes');
                                  default:
                                    return const SizedBox.shrink();
                                }
                              }
                              return Text(value.toInt().toString());
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: 40,
                          ),
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
                              String value = spot.y.toString();
                              if (_selectedStat == "End Game") {
                                switch (spot.y.toInt()) {
                                  case 0:
                                    value = 'None';
                                    break;
                                  case 1:
                                    value = 'Parked';
                                    break;
                                  case 2:
                                    value = 'ShallowCage';
                                    break;
                                  case 3:
                                    value = 'DeepCage';
                                    break;
                                }
                              } else if (_selectedStat == "Auto Line") {
                                value = spot.y.toInt() == 1 ? 'Yes' : 'No';
                              }
                              return LineTooltipItem(
                                'Match $matchNumber\nValue: $value',
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
