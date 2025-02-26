import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Graphing extends StatefulWidget {
  // The first element is the match number, the second is the score.
  //Top-level key: Team number (as a String, e.g., "1678")
  //   Value: A Map where:
  //       Key: Stat type (e.g., "Auton Score")
  //       Value: A List of pairs, each in the form [matchNumber, score]
  //           matchNumber (int): The match number.
  //           score (num): The score for that match.
  final Map<String, Map<String, List<List<num>>>> allData = {
  "1678": {
    "Auton Score": [
      [1, 15.0],
      [5, 18.0],
      [43, 12.0],
      [44, 20.0],
      [61, 22.0],
      [70, 19.0],
      [75, 21.0],
      [80, 23.0],
    ],
    "Teleop Score": [
      [1, 35.0],
      [5, 40.0],
      [43, 32.0],
      [44, 45.0],
      [61, 38.0],
      [70, 39.0],
      [75, 42.0],
      [80, 41.0],
    ],
    "Endgame Score": [
      [1, 10.0],
      [5, 15.0],
      [43, 10.0],
      [44, 20.0],
      [61, 18.0],
      [70, 16.0],
      [75, 19.0],
      [80, 21.0],
    ],
  },
  "254": {
    "Auton Score": [
      [2, 20.0],
      [6, 22.0],
      [10, 18.0],
      [12, 24.0],
      [16, 21.0],
      [18, 23.0],
    ],
    "Teleop Score": [
      [2, 40.0],
      [6, 38.0],
      [10, 42.0],
      [12, 45.0],
      [16, 44.0],
      [18, 46.0],
    ],
    "Endgame Score": [
      [2, 12.0],
      [6, 15.0],
      [10, 14.0],
      [12, 16.0],
      [16, 18.0],
      [18, 20.0],
    ],
  },
  "1114": {
    "Auton Score": [
      [1, 10.0],
      [3, 12.0],
      [7, 14.0],
      [15, 16.0],
      [20, 18.0],
      [22, 20.0],
      [30, 22.0],
      [35, 24.0],
    ],
    "Teleop Score": [
      [1, 30.0],
      [3, 32.0],
      [7, 34.0],
      [15, 36.0],
      [20, 38.0],
      [22, 40.0],
      [30, 42.0],
      [35, 44.0],
    ],
    "Endgame Score": [
      [1, 8.0],
      [3, 10.0],
      [7, 12.0],
      [15, 14.0],
      [20, 56.0],
      [22, 18.0],
      [30, 20.0],
      [35, 22.0],
    ],
  },
  "2056": {
    "Auton Score": [
      [5, 22.0],
      [7, 24.0],
      [20, 21.0],
      [33, 23.0],
      [38, 25.0],
      [42, 26.0],
    ],
    "Teleop Score": [
      [5, 40.0],
      [7, 42.0],
      [20, 45.0],
      [33, 47.0],
      [38, 48.0],
      [42, 50.0],
    ],
    "Endgame Score": [
      [5, 12.0],
      [7, 14.0],
      [20, 16.0],
      [33, 18.0],
      [38, 20.0],
      [42, 22.0],
    ],
  },
  "148": {
    "Auton Score": [
      [1, 16.0],
      [5, 17.0],
      [6, 18.0],
      [9, 15.0],
      [15, 20.0],
      [25, 21.0],
      [28, 22.0],
    ],
    "Teleop Score": [
      [1, 30.0],
      [5, 32.0],
      [6, 34.0],
      [9, 36.0],
      [15, 38.0],
      [25, 40.0],
      [28, 42.0],
    ],
    "Endgame Score": [
      [1, 10.0],
      [5, 12.0],
      [6, 11.0],
      [9, 13.0],
      [15, 14.0],
      [25, 15.0],
      [28, 16.0],
    ],
  },
  "118": {
    "Auton Score": [
      [3, 25.0],
      [8, 26.0],
      [13, 27.0],
      [27, 28.0],
      [40, 29.0],
      [50, 30.0],
      [60, 31.0],
      [65, 32.0],
    ],
    "Teleop Score": [
      [3, 42.0],
      [8, 40.0],
      [13, 44.0],
      [27, 46.0],
      [40, 48.0],
      [50, 47.0],
      [60, 49.0],
      [65, 51.0],
    ],
    "Endgame Score": [
      [3, 18.0],
      [8, 20.0],
      [13, 22.0],
      [27, 24.0],
      [40, 26.0],
      [50, 28.0],
      [60, 30.0],
      [65, 32.0],
    ],
  },
};


  @override
  State<Graphing> createState() => _GraphingState();
}

class _GraphingState extends State<Graphing> {
  late String _selectedTeam;
  late String _selectedStat;

  @override
  void initState() {
    super.initState();
    if (widget.allData.isNotEmpty) {
      _selectedTeam = widget.allData.keys.first;
      _selectedStat = widget.allData[_selectedTeam]!.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the optimized data for the selected team & stat.
    final List<List<num>> statData =
        widget.allData[_selectedTeam]?[_selectedStat] ?? [];

    // Sort the data by match number (the first element in each pair).
    statData.sort((a, b) => a[0].compareTo(b[0]));

    // Create chart spots: x-values are the index in the sorted list,
    // y-values are the score (second element in each pair).
    final spots = statData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value[1] as num).toDouble();
      return FlSpot(index.toDouble(), value);
    }).toList();

    // Compute the average score.
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
              // Dropdowns for selecting team and stat.
              Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: _selectedTeam,
                      items: widget.allData.keys.map((team) {
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
                                widget.allData[_selectedTeam]!.keys.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    DropdownButton<String>(
                      value: _selectedStat,
                      items: widget.allData[_selectedTeam]!.keys.map((stat) {
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
              ),
              const SizedBox(height: 20),
              // The chart.
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
                              if (index < 0 || index >= statData.length) {
                                return const SizedBox.shrink();
                              }
                              // Use the actual match number from the data.
                              final matchNumber = statData[index][0];
                              return Text(matchNumber.toString());
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
                                      ? statData[index][0]
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
