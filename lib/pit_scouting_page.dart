import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'color_scheme.dart';
import 'dart:convert';
import 'dashboard_page.dart';

String robotWeight = "";
String driveType = "";
List<String> driveOptions = ['Swerve', 'Tank', 'Mechanum', 'Other'];

String motorType = "";
List<String> motorTypeOptions = ['Falcon', 'Kraken', 'Neo', 'CIM'];

String motorNum = "";

String bumperQuality = "";
List<String> bumperQualityOptions = ['1', '2', '3', '4', '5'];

String coralIntakeType = "";
List<String> coralIntakeOptions = [
  'Direct',
  'Funnel',
  'Ground',
  'Direct/Ground',
  'Funnel/Ground',
  'None'
];

String algaeIntakeType = "";
List<String> algaeIntakeOptions = ['Ground', 'Reef', 'Both', 'None'];

// Scoring
bool levelOne = false;
bool levelTwo = false;
bool levelThree = false;
bool levelFour = false;
bool processor = false;
bool net = false;
String climbType = "";
List<String> climbOptions = ['Shallow', 'Deep', 'No Hang'];

// Autonomous
int coralPoints = 0;
bool leavesStartLine = false;

class MyCustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class PitScouting extends StatefulWidget {
  const PitScouting({
    super.key,
    required this.teamName,
    required this.channel,
    required WebSocketService webSocketService,
  });
  final String teamName;
  final WebSocketChannel channel;

  @override
  State<PitScouting> createState() => _PitScouting();
}

class _PitScouting extends State<PitScouting> {
  late TextEditingController _controller1; // for robot weight
  late TextEditingController _controllerMotorNum; // for number of motors

  final List<String> entries = <String>[
    'Robot weight (lbs): ',
    'Type of drive: ',
    'Motor Type: ',
    'Number of motors: ',
    'Bumper quality: ',
    'Coral Intake Type: ',
    'Algae Intake Type: ',
    'Scoring Levels (L1-L4): ',
    'Can score in processor: ',
    'Can score into net: ',
    'Type of Climb: ',
    'Coral scored during Autonomous: ',
    'Can robot move off of starting line during Autonomous: ',
  ];

  @override
  void initState() {
    super.initState();
    _controller1 = TextEditingController();
    _controllerMotorNum = TextEditingController();
  }

  /// Resets the form state and clears the input fields.
  void _resetForm() {
    setState(() {
      robotWeight = "";
      driveType = "";
      motorType = "";
      motorNum = "";
      bumperQuality = "";
      coralIntakeType = "";
      algaeIntakeType = "";
      levelOne = false;
      levelTwo = false;
      levelThree = false;
      levelFour = false;
      processor = false;
      net = false;
      climbType = "";
      coralPoints = 0;
      leavesStartLine = false;
    });
    _controller1.clear();
    _controllerMotorNum.clear();
  }

  /// Opens a dialog simulating a dropdown for scoring levels with dynamic updates.
  Future<void> _showScoringDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Scoring Levels"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text("Level 1"),
                    value: levelOne,
                    onChanged: (value) {
                      setState(() {
                        levelOne = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Level 2"),
                    value: levelTwo,
                    onChanged: (value) {
                      setState(() {
                        levelTwo = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Level 3"),
                    value: levelThree,
                    onChanged: (value) {
                      setState(() {
                        levelThree = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Level 4"),
                    value: levelFour,
                    onChanged: (value) {
                      setState(() {
                        levelFour = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            )
          ],
        );
      },
    );
    setState(() {});
  }

  /// Returns a summary text of the selected scoring levels.
  String _getSelectedLevelsText() {
    List<String> selected = [];
    if (levelOne) selected.add("L1");
    if (levelTwo) selected.add("L2");
    if (levelThree) selected.add("L3");
    if (levelFour) selected.add("L4");
    return selected.isNotEmpty ? selected.join(", ") : "None";
  }

  /// Submits the pit scouting data to the SQL server and resets the form.
  Future<void> _submitPitScoutingData() async {
    final sql = '''
      INSERT INTO PitScoutingData (
        team_number, robot_weight, drive_type, motor_type, motor_count, bumper_quality,
        coral_intake_type, algae_intake_type,
        L1, L2, L3, L4, processor, net, climb_type,
        autonomous_coral_points, leaves_start_line
      )
      VALUES (
        '${widget.teamName}', '$robotWeight', '$driveType', '$motorType', '$motorNum', '$bumperQuality',
        '$coralIntakeType', '$algaeIntakeType',
        '${levelOne ? "true" : "false"}', '${levelTwo ? "true" : "false"}', '${levelThree ? "true" : "false"}', '${levelFour ? "true" : "false"}',
        '${processor ? "true" : "false"}', '${net ? "true" : "false"}', '$climbType', $coralPoints, '${leavesStartLine ? "true" : "false"}'
      )
    ''';

    final cmd = {
      "type": "query",
      "text": sql,
    };

    final encodedJson = jsonEncode(cmd);
    final prefix = '${encodedJson.length}\r\n';
    try {
      widget.channel.sink.add(prefix + encodedJson);
      debugPrint('Successfully sent pit scouting INSERT command: $sql');
      // Reset the form for next use
      _resetForm();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            webSocketService: WebSocketService(),
            onThemeChanged: (ThemeMode mode) {},
            teamName: widget.teamName,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Error sending pit scouting data to DB: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pit Scouting",
          textScaleFactor: 1.5,
        ),
        elevation: 21,
      ),
      body: ScrollConfiguration(
        behavior: MyCustomScrollBehavior(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: <Widget>[
            const SizedBox(height: 16),
            Center(
              child: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'link to ',
                      style: TextStyle(color: Colors.black87),
                    ),
                    TextSpan(
                      text: 'Robot Pictures Folder',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launch(
                              'https://drive.google.com/drive/folders/17r61d7tOUQLiKA4cnEW15pXioTIKt-yK?usp=drive_link');
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "General Robot Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Robot Weight
            Column(
              children: [
                Text(entries[0], textScaleFactor: 1.3),
                SizedBox(
                  width: width / 4,
                  child: TextField(
                    controller: _controller1,
                    onChanged: (String value) {
                      setState(() {
                        robotWeight = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Drive Type
            Column(
              children: [
                Text(entries[1], textScaleFactor: 1.3),
                DropdownButton<String>(
                  value: driveType.isNotEmpty ? driveType : null,
                  hint: const Text('Select Drive Type'),
                  items: driveOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      driveType = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Motor Type Dropdown
            Column(
              children: [
                Text(entries[2], textScaleFactor: 1.3),
                DropdownButton<String>(
                  value: motorType.isNotEmpty ? motorType : null,
                  hint: const Text('Select Motor Type'),
                  items: motorTypeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      motorType = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Number of Motors as Text Entry
            Column(
              children: [
                Text(entries[3], textScaleFactor: 1.3),
                SizedBox(
                  width: width / 3,
                  child: TextField(
                    controller: _controllerMotorNum,
                    keyboardType: TextInputType.number,
                    onChanged: (String value) {
                      setState(() {
                        motorNum = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bumper Quality as Spin Wheel (CupertinoPicker)
            Column(
              children: [
                Text(entries[4], textScaleFactor: 1.3),
                SizedBox(
                  height: 100,
                  width: width / 3,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: bumperQualityOptions.indexOf(
                          bumperQuality.isNotEmpty
                              ? bumperQuality
                              : bumperQualityOptions[0]),
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        bumperQuality = bumperQualityOptions[index];
                      });
                    },
                    children: List<Widget>.generate(
                      bumperQualityOptions.length,
                      (index) =>
                          Center(child: Text(bumperQualityOptions[index])),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Intake Information - New Dropdowns
            const Center(
              child: Text(
                "Intake Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Coral Intake Type
            Column(
              children: [
                Text(entries[5], textScaleFactor: 1.3),
                DropdownButton<String>(
                  value: coralIntakeType.isNotEmpty ? coralIntakeType : null,
                  hint: const Text('Select Coral Intake Type'),
                  items: coralIntakeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      coralIntakeType = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Algae Intake Type
            Column(
              children: [
                Text(entries[6], textScaleFactor: 1.3),
                DropdownButton<String>(
                  value: algaeIntakeType.isNotEmpty ? algaeIntakeType : null,
                  hint: const Text('Select Algae Intake Type'),
                  items: algaeIntakeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      algaeIntakeType = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Scoring Information (L1-L4) as a dropdown dialog
            Column(
              children: [
                Text(entries[7], textScaleFactor: 1.3),
                ElevatedButton(
                  onPressed: _showScoringDialog,
                  child: Text("Selected: " + _getSelectedLevelsText()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Processor Checkbox
            Column(
              children: [
                Text(entries[8], textScaleFactor: 1.3),
                Checkbox(
                  value: processor,
                  onChanged: (newValue) {
                    setState(() {
                      processor = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Net Checkbox
            Column(
              children: [
                Text(entries[9], textScaleFactor: 1.3),
                Checkbox(
                  value: net,
                  onChanged: (newValue) {
                    setState(() {
                      net = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Climb Type Dropdown
            Column(
              children: [
                Text(entries[10], textScaleFactor: 1.3),
                DropdownButton<String>(
                  value: climbType.isNotEmpty ? climbType : null,
                  hint: const Text('Select Climb Type'),
                  items: climbOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      climbType = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Autonomous - Coral Points as Spin Wheel from 0 to 6
            const Center(
              child: Text(
                "Autonomous",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Text(entries[11], textScaleFactor: 1.3),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: coralPoints,
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        coralPoints = index;
                      });
                    },
                    children: List<Widget>.generate(
                      7,
                      (index) => Center(child: Text('$index')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Autonomous - Leaves Start Line Checkbox
            Column(
              children: [
                Text(entries[12], textScaleFactor: 1.3),
                Checkbox(
                  value: leavesStartLine,
                  onChanged: (newValue) {
                    setState(() {
                      leavesStartLine = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                _submitPitScoutingData();
              },
              child: const Icon(Icons.send, color: colors.myOnPrimary),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
