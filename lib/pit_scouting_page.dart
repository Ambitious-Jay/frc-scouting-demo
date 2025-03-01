import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'color_scheme.dart';
import 'dart:convert';
import 'dashboard_page.dart'; 

// Global variables for pit scouting values
String robotWeight = "";
String driveType = "";
List<String> driveOptions = ['Swerve', 'Tank', 'Mechanum', 'Other'];
String motorType = "";
String motorNum = "";
String bumperQuality = ""; // subjective

// Intake
bool intakeStation = false;
bool coralGround = false;
bool algaeGround = false; // not pushing
bool algaeReefControlled = false; // not just knocking off

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

/// Custom scroll behavior that disables the default overscroll glow.
class MyCustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class PitScouting extends StatefulWidget {
  const PitScouting(
      {super.key,
      required this.teamName,
      required this.channel,
      required WebSocketService webSocketService});
  final String teamName;
  final WebSocketChannel channel;

  @override
  State<PitScouting> createState() => _PitScouting();
}

class _PitScouting extends State<PitScouting> {
  late TextEditingController _controller1;
  late TextEditingController _controller2;
  late TextEditingController _controller3;
  late TextEditingController _controller4;

  final List<String> entries = <String>[
    'Robot weight (lbs): ',
    'Type of drive: ',
    'Type of motor: ',
    'Number of motors: ',
    'Bumper quality: ',
    // ---
    'Can pick up coral from Coral Station: ',
    'Can pick up coral from ground: ',
    'Can pick up algae from ground (not just pushing): ',
    'Can remove algae from reef (controlled, not just knocking off): ',
    // ---
    'Can score coral onto L1: ',
    'Can score coral onto L2: ',
    'Can score coral onto L3: ',
    'Can score coral onto L4: ',
    'Can score in processor: ',
    'Can score into net: ',
    'Type of Climb: ',
    // ---
    'Coral scored during Autonomous: ',
    'Can robot move off of starting line during Autonomous: ',
  ];

  @override
  void initState() {
    super.initState();
    _controller1 = TextEditingController();
    _controller2 = TextEditingController();
    _controller3 = TextEditingController();
    _controller4 = TextEditingController();
  }

  /// Submits the pit scouting data to the SQL server.
  /// Builds an INSERT statement targeting "PitScoutingData" and sends it over the WebSocket.
  Future<void> _submitPitScoutingData() async {
    final sql = '''
      INSERT INTO PitScoutingData (
        team_number, robot_weight, drive_type, motor_type, motor_count, bumper_quality,
        intake_station, coral_ground, algae_ground, algae_reef_controlled,
        level_one, level_two, level_three, level_four, processor, net, climb_type,
        autonomous_coral_points, leaves_start_line
      )
      VALUES (
        '${widget.teamName}', '$robotWeight', '$driveType', '$motorType', '$motorNum', '$bumperQuality',
        ${intakeStation ? 1 : 0}, ${coralGround ? 1 : 0}, ${algaeGround ? 1 : 0}, ${algaeReefControlled ? 1 : 0},
        ${levelOne ? 1 : 0}, ${levelTwo ? 1 : 0}, ${levelThree ? 1 : 0}, ${levelFour ? 1 : 0},
        ${processor ? 1 : 0}, ${net ? 1 : 0}, '$climbType', $coralPoints, ${leavesStartLine ? 1 : 0}
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
      // After sending, redirect to DashboardPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            webSocketService: WebSocketService(), // pass your existing instance if available
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
    double height = MediaQuery.of(context).size.height;
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
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            const Center(
              child: Text(
                "General Robot Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
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
                      print("Robot weight: $value");
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            // Motor Type
            Column(
              children: [
                Text(entries[2], textScaleFactor: 1.3),
                SizedBox(
                  width: width / 3,
                  child: TextField(
                    controller: _controller2,
                    onChanged: (String value) {
                      setState(() {
                        motorType = value;
                      });
                      print("Motor type: $value");
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Motor Count
            Column(
              children: [
                Text(entries[3], textScaleFactor: 1.3),
                SizedBox(
                  width: width / 3,
                  child: TextField(
                    controller: _controller3,
                    onChanged: (String value) {
                      setState(() {
                        motorNum = value;
                      });
                      print("Motor count: $value");
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Bumper Quality
            Column(
              children: [
                Text(entries[4], textScaleFactor: 1.3),
                SizedBox(
                  width: width / 3,
                  child: TextField(
                    controller: _controller4,
                    onChanged: (String value) {
                      setState(() {
                        bumperQuality = value;
                      });
                      print("Bumper quality: $value");
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Intake Information
            const Center(
              child: Text(
                "Intake Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: [
                Text(entries[5], textScaleFactor: 1.3),
                Checkbox(
                  value: intakeStation,
                  onChanged: (newValue) {
                    setState(() {
                      intakeStation = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Coral from Ground
            Column(
              children: [
                Text(entries[6], textScaleFactor: 1.3),
                Checkbox(
                  value: coralGround,
                  onChanged: (newValue) {
                    setState(() {
                      coralGround = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Algae from Ground
            Column(
              children: [
                Text(entries[7], textScaleFactor: 1.3),
                Checkbox(
                  value: algaeGround,
                  onChanged: (newValue) {
                    setState(() {
                      algaeGround = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Algae Reef Controlled
            Column(
              children: [
                Text(entries[8], textScaleFactor: 1.3),
                Checkbox(
                  value: algaeReefControlled,
                  onChanged: (newValue) {
                    setState(() {
                      algaeReefControlled = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Scoring Information Header
            const Center(
              child: Text(
                "Scoring Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            // Level One
            Column(
              children: [
                Text(entries[9], textScaleFactor: 1.3),
                Checkbox(
                  value: levelOne,
                  onChanged: (newValue) {
                    setState(() {
                      levelOne = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Level Two
            Column(
              children: [
                Text(entries[10], textScaleFactor: 1.3),
                Checkbox(
                  value: levelTwo,
                  onChanged: (newValue) {
                    setState(() {
                      levelTwo = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Level Three
            Column(
              children: [
                Text(entries[11], textScaleFactor: 1.3),
                Checkbox(
                  value: levelThree,
                  onChanged: (newValue) {
                    setState(() {
                      levelThree = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Level Four
            Column(
              children: [
                Text(entries[12], textScaleFactor: 1.3),
                Checkbox(
                  value: levelFour,
                  onChanged: (newValue) {
                    setState(() {
                      levelFour = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Processor
            Column(
              children: [
                Text(entries[13], textScaleFactor: 1.3),
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
            SizedBox(height: 16),
            // Net
            Column(
              children: [
                Text(entries[14], textScaleFactor: 1.3),
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
            SizedBox(height: 16),
            // Climb Type
            Column(
              children: [
                Text(entries[15], textScaleFactor: 1.3),
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
            SizedBox(height: 16),
            // Autonomous - Coral Points
            const Center(
              child: Text(
                "Autonomous",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: [
                Text(entries[16], textScaleFactor: 1.3),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (String value) {
                    setState(() {
                      coralPoints = int.tryParse(value) ?? 0;
                    });
                    print("Coral Points: $value");
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Autonomous - Leaves Start Line
            Column(
              children: [
                Text(entries[17], textScaleFactor: 1.3),
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
            SizedBox(height: 16),
            // Submission Button
            ElevatedButton(
              onPressed: () async {
                await _submitPitScoutingData();
              },
              child: const Icon(Icons.send, color: colors.myOnPrimary),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
