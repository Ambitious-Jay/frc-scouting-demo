import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Import your WebSocketService (adjust path as needed):
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

/// Holds a single data point for the scatter chart.
class TeamSpotData {
  final String teamNumber;
  final double x;
  final double y;
  final Color color;

  TeamSpotData({
    required this.teamNumber,
    required this.x,
    required this.y,
    required this.color,
  });
}

class ScatterPlot extends StatefulWidget {
  final WebSocketService webSocketService;

  const ScatterPlot({
    Key? key,
    required this.webSocketService,
  }) : super(key: key);

  @override
  State<ScatterPlot> createState() => _ScatterPlotState();
}

class _ScatterPlotState extends State<ScatterPlot> {
  Map<String, Map<String, double>> teamData = {};
  Map<String, Color> teamColorMap = {};
  List<String> allMetrics = [];
  String? selectedXMetric;
  String? selectedYMetric;
  List<TeamSpotData> allSpots = [];
  double? xMin, xMax, yMin, yMax;
  StreamSubscription? querySubscription;
  bool isLoading = false;

  final List<Color> presetColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
  ];
  final math.Random rng = math.Random();

  @override
  void initState() {
    super.initState();
    _fetchAllDesiredMetrics();
  }

  @override
  void dispose() {
    querySubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllDesiredMetrics() async {
    setState(() {
      isLoading = true;
    });

    // Game metrics explanation:
    // - Coral: Game pieces that can be scored in L1, L2/3, and L4 scoring locations
    // - Algae: Game pieces that can be processed through Net and Processor mechanisms
    // - CPM (Coral Per Match): Average of L1 + L2/3 + L4 coral pieces scored per match
    // - APM (Algae Per Match): Average of Net + Processor algae pieces processed per match

    const String sql = """
      -- L4 OPR
      SELECT
        OPR.Team AS team_number,
        'L4 OPR' AS metric_name,
        OPR.OPR_teleop_reef_top_count AS metric_value
      FROM OPR

      UNION ALL
      -- L3/L2 OPR
      SELECT
        OPR.Team AS team_number,
        'L3/L2 OPR' AS metric_name,
        OPR.OPR_teleop_reef_mid_count AS metric_value
      FROM OPR

      UNION ALL
      -- L1 OPR
      SELECT
        OPR.Team AS team_number,
        'L1 OPR' AS metric_name,
        OPR.OPR_teleop_trough_count AS metric_value
      FROM OPR

      UNION ALL
      -- Net OPR
      SELECT
        OPR.Team AS team_number,
        'Net OPR' AS metric_name,
        OPR.OPR_net_algae_count AS metric_value
      FROM OPR

      UNION ALL
      -- Processor OPR (using Wall Algae data)
      SELECT
        OPR.Team AS team_number,
        'Processor OPR' AS metric_name,
        OPR.OPR_wall_algae_count AS metric_value
      FROM OPR

      UNION ALL
      -- EPA
      SELECT
        CAST(StatsboticsEPA.team AS varchar) AS team_number,
        'EPA' AS metric_name,
        StatsboticsEPA.total_epa AS metric_value
      FROM StatsboticsEPA

      -- Get average L1 from MatchData
      UNION ALL
      SELECT
        REPLACE(md.team_number, 'frc', '') AS team_number,
        'L1 Average' AS metric_name,
        AVG(CAST(md.l1Counter AS FLOAT)) AS metric_value
      FROM MatchData md
      GROUP BY md.team_number

      -- Get average L2/3 from MatchData
      UNION ALL
      SELECT
        REPLACE(md.team_number, 'frc', '') AS team_number,
        'L2/3 Average' AS metric_name,
        AVG(CAST(md.l2l3Counter AS FLOAT)) AS metric_value
      FROM MatchData md
      GROUP BY md.team_number

      -- Get average L4 from MatchData
      UNION ALL
      SELECT
        REPLACE(md.team_number, 'frc', '') AS team_number,
        'L4 Average' AS metric_name,
        AVG(CAST(md.l4Counter AS FLOAT)) AS metric_value
      FROM MatchData md
      GROUP BY md.team_number

      -- Get CPM (Average of L1+L2/3+L4)
      UNION ALL
      SELECT
        REPLACE(md.team_number, 'frc', '') AS team_number,
        'CPM' AS metric_name,
        AVG(CAST(md.l1Counter AS FLOAT) + CAST(md.l2l3Counter AS FLOAT) + CAST(md.l4Counter AS FLOAT)) AS metric_value
      FROM MatchData md
      GROUP BY md.team_number

      -- Get average Net from MatchData
      UNION ALL
      SELECT
        REPLACE(md.team_number, 'frc', '') AS team_number,
        'Net Average' AS metric_name,
        AVG(CAST(md.netCounter AS FLOAT)) AS metric_value
      FROM MatchData md
      GROUP BY md.team_number

      -- Get average Processor from MatchData
      UNION ALL
      SELECT
        REPLACE(md.team_number, 'frc', '') AS team_number,
        'Processor Average' AS metric_name,
        AVG(CAST(md.processorCounter AS FLOAT)) AS metric_value
      FROM MatchData md
      GROUP BY md.team_number

      -- Get APM (Average of Net+Processor)
      UNION ALL
      SELECT
        REPLACE(md.team_number, 'frc', '') AS team_number,
        'APM' AS metric_name,
        AVG(CAST(md.netCounter AS FLOAT) + CAST(md.processorCounter AS FLOAT)) AS metric_value
      FROM MatchData md
      GROUP BY md.team_number

      -- Get Auton L1 Average from AutoScouting
      UNION ALL
      SELECT
        REPLACE(auto.team_number, 'frc', '') AS team_number,
        'Auton L1 Average' AS metric_name,
        AVG(CAST(auto.l1_count AS FLOAT)) AS metric_value
      FROM AutoScouting auto
      GROUP BY auto.team_number

      -- Get Auton L2/L3 Average from AutoScouting
      UNION ALL
      SELECT
        REPLACE(auto.team_number, 'frc', '') AS team_number,
        'Auton L2/L3 Average' AS metric_name,
        AVG(CAST(auto.l2_l3_count AS FLOAT)) AS metric_value
      FROM AutoScouting auto
      GROUP BY auto.team_number

      -- Get Auton L4 Average from AutoScouting
      UNION ALL
      SELECT
        REPLACE(auto.team_number, 'frc', '') AS team_number,
        'Auton L4 Average' AS metric_name,
        AVG(CAST(auto.l4_count AS FLOAT)) AS metric_value
      FROM AutoScouting auto
      GROUP BY auto.team_number

      -- Get Auton Total Coral (Average of L1+L2/L3+L4 in Auton)
      UNION ALL
      SELECT
        REPLACE(auto.team_number, 'frc', '') AS team_number,
        'Auton Total Coral' AS metric_name,
        AVG(CAST(auto.l1_count AS FLOAT) + CAST(auto.l2_l3_count AS FLOAT) + CAST(auto.l4_count AS FLOAT)) AS metric_value
      FROM AutoScouting auto
      GROUP BY auto.team_number

      -- End Game Average - robot 1
      UNION ALL 
      SELECT
        team AS team_number,
        'End Game Average' AS metric_name,
        AVG(
          CASE 
            WHEN end_game = 'None' THEN 0
            WHEN end_game = 'Parked' THEN 1
            WHEN end_game = 'ShallowCage' THEN 2
            WHEN end_game = 'DeepCage' THEN 3
            ELSE 0
          END
        ) AS metric_value
      FROM (
        SELECT 
          SUBSTRING(tba.team_keys, 4, CHARINDEX(',', tba.team_keys + ',') - 4) AS team,
          tba.end_game_robot_1 AS end_game
        FROM TBAMatchScores tba
        WHERE tba.end_game_robot_1 IS NOT NULL AND tba.team_keys LIKE 'frc%'
      ) AS t
      GROUP BY team

      -- End Game Average - robot 2
      UNION ALL 
      SELECT
        team AS team_number,
        'End Game Average' AS metric_name,
        AVG(
          CASE 
            WHEN end_game = 'None' THEN 0
            WHEN end_game = 'Parked' THEN 1
            WHEN end_game = 'ShallowCage' THEN 2
            WHEN end_game = 'DeepCage' THEN 3
            ELSE 0
          END
        ) AS metric_value
      FROM (
        SELECT 
          SUBSTRING(
            tba.team_keys, 
            CHARINDEX(',', tba.team_keys) + 4, 
            CHARINDEX(',', tba.team_keys, CHARINDEX(',', tba.team_keys) + 1) - CHARINDEX(',', tba.team_keys) - 4
          ) AS team,
          tba.end_game_robot_2 AS end_game
        FROM TBAMatchScores tba
        WHERE tba.end_game_robot_2 IS NOT NULL 
          AND tba.team_keys LIKE 'frc%' 
          AND CHARINDEX(',', tba.team_keys) > 0
      ) AS t
      WHERE team != ''
      GROUP BY team

      -- End Game Average - robot 3
      UNION ALL 
      SELECT
        team AS team_number,
        'End Game Average' AS metric_name,
        AVG(
          CASE 
            WHEN end_game = 'None' THEN 0
            WHEN end_game = 'Parked' THEN 1
            WHEN end_game = 'ShallowCage' THEN 2
            WHEN end_game = 'DeepCage' THEN 3
            ELSE 0
          END
        ) AS metric_value
      FROM (
        SELECT 
          SUBSTRING(
            tba.team_keys, 
            CHARINDEX(',', tba.team_keys, CHARINDEX(',', tba.team_keys) + 1) + 4,
            LEN(tba.team_keys)
          ) AS team,
          tba.end_game_robot_3 AS end_game
        FROM TBAMatchScores tba
        WHERE tba.end_game_robot_3 IS NOT NULL 
          AND tba.team_keys LIKE 'frc%'
          AND CHARINDEX(',', tba.team_keys, CHARINDEX(',', tba.team_keys) + 1) > 0
      ) AS t
      WHERE team != ''
      GROUP BY team

      -- Auto Line Percentage - robot 1
      UNION ALL 
      SELECT
        team AS team_number,
        'Auto Line Percentage' AS metric_name,
        AVG(
          CASE 
            WHEN auto_line = 'Yes' THEN 1
            ELSE 0
          END
        ) * 100 AS metric_value
      FROM (
        SELECT 
          SUBSTRING(tba.team_keys, 4, CHARINDEX(',', tba.team_keys + ',') - 4) AS team,
          tba.auto_line_robot_1 AS auto_line
        FROM TBAMatchScores tba
        WHERE tba.auto_line_robot_1 IS NOT NULL AND tba.team_keys LIKE 'frc%'
      ) AS t
      GROUP BY team

      -- Auto Line Percentage - robot 2
      UNION ALL 
      SELECT
        team AS team_number,
        'Auto Line Percentage' AS metric_name,
        AVG(
          CASE 
            WHEN auto_line = 'Yes' THEN 1
            ELSE 0
          END
        ) * 100 AS metric_value
      FROM (
        SELECT 
          SUBSTRING(
            tba.team_keys, 
            CHARINDEX(',', tba.team_keys) + 4, 
            CHARINDEX(',', tba.team_keys, CHARINDEX(',', tba.team_keys) + 1) - CHARINDEX(',', tba.team_keys) - 4
          ) AS team,
          tba.auto_line_robot_2 AS auto_line
        FROM TBAMatchScores tba
        WHERE tba.auto_line_robot_2 IS NOT NULL 
          AND tba.team_keys LIKE 'frc%' 
          AND CHARINDEX(',', tba.team_keys) > 0
      ) AS t
      WHERE team != ''
      GROUP BY team

      -- Auto Line Percentage - robot 3
      UNION ALL 
      SELECT
        team AS team_number,
        'Auto Line Percentage' AS metric_name,
        AVG(
          CASE 
            WHEN auto_line = 'Yes' THEN 1
            ELSE 0
          END
        ) * 100 AS metric_value
      FROM (
        SELECT 
          SUBSTRING(
            tba.team_keys, 
            CHARINDEX(',', tba.team_keys, CHARINDEX(',', tba.team_keys) + 1) + 4,
            LEN(tba.team_keys)
          ) AS team,
          tba.auto_line_robot_3 AS auto_line
        FROM TBAMatchScores tba
        WHERE tba.auto_line_robot_3 IS NOT NULL 
          AND tba.team_keys LIKE 'frc%'
          AND CHARINDEX(',', tba.team_keys, CHARINDEX(',', tba.team_keys) + 1) > 0
      ) AS t
      WHERE team != ''
      GROUP BY team

      ORDER BY team_number
    """;

    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };

    final completer = Completer<Map<String, Map<String, double>>>();
    final Map<String, Map<String, double>> fetchedData = {};

    querySubscription = widget.webSocketService.stream?.listen((rawMessage) {
      try {
        final idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final lenStr = rawMessage.substring(0, idx);
        final int len = int.parse(lenStr);
        final jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;

        final msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          for (var row in rows) {
            final String teamNum = row["team_number"].toString();
            final String metricName = row["metric_name"].toString();
            final double metricValue =
                double.tryParse(row["metric_value"].toString()) ?? 0.0;

            if (!fetchedData.containsKey(teamNum)) {
              fetchedData[teamNum] = {};
            }
            fetchedData[teamNum]![metricName] = metricValue;
          }
          completer.complete(fetchedData);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    try {
      final result = await completer.future;

      // Assign a color to each team
      final Map<String, Color> newTeamColorMap = {};
      int colorIndex = 0;
      for (String t in result.keys) {
        if (colorIndex < presetColors.length) {
          newTeamColorMap[t] = presetColors[colorIndex];
        } else {
          newTeamColorMap[t] =
              Color((rng.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
        }
        colorIndex++;
      }

      // Collect all unique metrics
      final Set<String> metricNames = {};
      for (var metricsMap in result.values) {
        metricNames.addAll(metricsMap.keys);
      }
      final List<String> metricList = metricNames.toList()..sort();

      // Auto-select first two metrics if available
      String? defaultX;
      String? defaultY;
      if (metricList.length >= 2) {
        defaultX = metricList[0];
        defaultY = metricList[1];
      }

      setState(() {
        teamData = result;
        teamColorMap = newTeamColorMap;
        allMetrics = metricList;
        selectedXMetric = defaultX;
        selectedYMetric = defaultY;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching metrics: $e");
      setState(() {
        isLoading = false;
      });
    } finally {
      querySubscription?.cancel();
    }
  }

  List<ScatterSpot> _buildScatterSpots() {
    allSpots.clear();
    if (selectedXMetric == null || selectedYMetric == null) return [];

    xMin = double.infinity;
    xMax = double.negativeInfinity;
    yMin = double.infinity;
    yMax = double.negativeInfinity;

    for (String team in teamData.keys) {
      final metrics = teamData[team]!;
      final xVal = metrics[selectedXMetric!];
      final yVal = metrics[selectedYMetric!];
      if (xVal == null || yVal == null) continue;

      xMin = math.min(xMin!, xVal);
      xMax = math.max(xMax!, xVal);
      yMin = math.min(yMin!, yVal);
      yMax = math.max(yMax!, yVal);

      allSpots.add(
        TeamSpotData(
          teamNumber: team,
          x: xVal,
          y: yVal,
          color: teamColorMap[team] ?? Colors.white,
        ),
      );
    }

    if (allSpots.isEmpty) return [];

    // Expand axis ranges slightly
    final xRange = xMax! - xMin!;
    final yRange = yMax! - yMin!;
    if (xRange > 0) {
      xMin = xMin! - (xRange * 0.05);
      xMax = xMax! + (xRange * 0.05);
    }
    if (yRange > 0) {
      yMin = yMin! - (yRange * 0.05);
      yMax = yMax! + (yRange * 0.05);
    }

    return allSpots.map((ts) {
      return ScatterSpot(
        ts.x,
        ts.y,
        dotPainter: FlDotCirclePainter(
          color: ts.color,
          radius: 6,
          strokeWidth: 1,
          strokeColor: ts.color.withOpacity(0.5),
        ),
      );
    }).toList();
  }

  int _getAxisDecimalPlaces(double minVal, double maxVal) {
    final range = (maxVal - minVal).abs();
    if (range < 0.01) return 4;
    if (range < 0.1) return 3;
    if (range < 1) return 2;
    if (range < 10) return 1;
    return 0;
  }

  String _formatMetricName(String raw) {
    return raw.replaceAll(RegExp(r'[_]+'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (teamData.isEmpty || allMetrics.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ScatterPlot Coral & Algae')),
        body: const Center(child: Text("No data or metrics found.")),
      );
    }

    final spots = _buildScatterSpots();
    if (selectedXMetric == null ||
        selectedYMetric == null ||
        spots.isEmpty ||
        xMin == null ||
        xMax == null ||
        yMin == null ||
        yMax == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ScatterPlot Coral & Algae')),
        body: const Center(child: Text("Please pick valid metrics.")),
      );
    }

    final xDecimalPlaces = _getAxisDecimalPlaces(xMin!, xMax!);
    final yDecimalPlaces = _getAxisDecimalPlaces(yMin!, yMax!);

    return Scaffold(
      appBar: AppBar(title: const Text('ScatterPlot Coral & Algae')),
      body: SafeArea(
        child: Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Two dropdowns for X & Y
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[850],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'X-Axis Metric',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      value: selectedXMetric,
                      onChanged: (val) {
                        setState(() {
                          selectedXMetric = val;
                        });
                      },
                      items: allMetrics
                          .where((m) => m != selectedYMetric)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_formatMetricName(m)),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[850],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Y-Axis Metric',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      value: selectedYMetric,
                      onChanged: (val) {
                        setState(() {
                          selectedYMetric = val;
                        });
                      },
                      items: allMetrics
                          .where((m) => m != selectedXMetric)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_formatMetricName(m)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart with moderate padding and adjusted axis settings
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 8, bottom: 16, top: 8),
                  child: ScatterChart(
                    ScatterChartData(
                      clipData: FlClipData.none(), // disable clipping
                      scatterTouchData: ScatterTouchData(
                        enabled: true,
                        touchTooltipData: ScatterTouchTooltipData(
                          getTooltipItems: (touchedSpot) {
                            final match = allSpots.firstWhere(
                              (ts) =>
                                  ts.x == touchedSpot.x &&
                                  ts.y == touchedSpot.y,
                              orElse: () => TeamSpotData(
                                teamNumber: 'Unknown',
                                x: 0,
                                y: 0,
                                color: Colors.white,
                              ),
                            );
                            return ScatterTooltipItem(
                              'Team ${match.teamNumber}\n'
                              '${_formatMetricName(selectedXMetric!)}: '
                              '${match.x.toStringAsFixed(xDecimalPlaces)}\n'
                              '${_formatMetricName(selectedYMetric!)}: '
                              '${match.y.toStringAsFixed(yDecimalPlaces)}',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                        mouseCursorResolver: (event, response) {
                          return (response == null ||
                                  response.touchedSpot == null)
                              ? MouseCursor.defer
                              : SystemMouseCursors.click;
                        },
                      ),
                      scatterSpots: spots,
                      minX: xMin,
                      maxX: xMax,
                      minY: yMin,
                      maxY: yMax,
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.white24),
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
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          axisNameSize: 20, // enough space for the axis title
                          axisNameWidget: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _formatMetricName(selectedYMetric!),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (val, _) => Text(
                              val.toStringAsFixed(yDecimalPlaces),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameSize: 20,
                          axisNameWidget: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatMetricName(selectedXMetric!),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (val, _) => Text(
                              val.toStringAsFixed(xDecimalPlaces),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
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
                      backgroundColor: Colors.grey[900],
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
