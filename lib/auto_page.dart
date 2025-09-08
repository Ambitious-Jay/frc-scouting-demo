import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/objective_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class IntegerWrapper {
  int value = 0;
  IntegerWrapper(this.value);
}

class AutoPage extends StatefulWidget {
  const AutoPage({
    Key? key,
    required this.teamName,
    required this.teamNickname,
    required this.matchNumber,
    required this.channel,
    required this.onThemeChanged,
    required this.webSocketService,
    this.isLeadScout = false,
  }) : super(key: key);

  final String teamName;
  final String teamNickname;
  final String matchNumber;
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;
  final bool isLeadScout;

  @override
  _AutoPageState createState() => _AutoPageState();
}

class _AutoPageState extends State<AutoPage> {
  ThemeMode themeMode = ThemeMode.system;
  String _username = "";
  bool isBlue = true;
  bool inCenterZone = false;
  bool inLeftZone = false;
  bool inRightZone = false;
  bool fieldFlipped = false;

  IntegerWrapper l4Counter = IntegerWrapper(0);
  IntegerWrapper l2l3Counter = IntegerWrapper(0);
  IntegerWrapper l1Counter = IntegerWrapper(0);
  IntegerWrapper netCounter = IntegerWrapper(0);
  IntegerWrapper processorCounter = IntegerWrapper(0);

  bool doIncrement = true;
  String? startPos = "Not pressed";

  late final TextEditingController _notesController;
  String _notesValue = "";
  bool _isLoading = true;
  Map<String, dynamic>? pitScoutingData;

  double min(double valOne, double valTwo) {
    return valOne > valTwo ? valTwo : valOne;
  }

  double max(double valOne, double valTwo) {
    return valOne > valTwo ? valOne : valTwo;
  }

  void updateCounter(IntegerWrapper counter, bool doIncrement) {
    setState(() {
      int inc = doIncrement ? 1 : -1;
      if (counter.value + inc >= 0) {
        counter.value += inc;
      }
    });
  }

  Icon get signIcon {
    IconData iconData = doIncrement ? Icons.add : Icons.remove;
    return Icon(
      iconData,
      color: Theme.of(context).colorScheme.primary,
      size: MediaQuery.of(context).size.width * 0.05,
    );
  }

  Future<void> _submitAutoScoutingData() async {
  final fakeData = {
    "team": widget.teamName,
    "match": widget.matchNumber,
    "L4": l4Counter.value,
    "L2/L3": l2l3Counter.value,
    "L1": l1Counter.value,
    "Net": netCounter.value,
    "Processor": processorCounter.value,
    "StartPos": startPos,
    "Zones": {
      "Center": inCenterZone,
      "Left": inLeftZone,
      "Right": inRightZone,
    },
  };

  debugPrint("🚫 [FAKE SUBMIT] Auto scouting data (not sent): $fakeData");
  await Future.delayed(const Duration(milliseconds: 500)); // pretend delay
}

  Future<void> _fetchLeadScoutingData() async {
    // Add 'frc' prefix to team number for querying LeadScoutingData table
    final String teamNumberWithPrefix =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName
            : 'frc${widget.teamName}';

    final sql =
        "SELECT notes FROM LeadScoutingData WHERE team_number='$teamNumberWithPrefix'";
    final cmd = {"type": "query", "text": sql};

    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    debugPrint('Fetching lead scouting notes for team ${widget.teamName}');

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        // Guard against empty or "null" responses
        if (jsonPart.trim().isEmpty || jsonPart.trim() == "null") {
          return;
        }
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          if (rows.isNotEmpty) {
            completer.complete(rows.first);
          } else {
            completer.complete(null);
          }
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(cmd);

    try {
      final row = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      if (row != null && row.containsKey("notes")) {
        final notes = row["notes"] ?? "";
        debugPrint("Received lead scout notes: '$notes'");

        if (mounted) {
          setState(() {
            _notesValue = notes;
            // Immediately update the controller text
            _notesController.text = notes;
          });
        }
      } else {
        debugPrint("No lead scouting notes found for team ${widget.teamName}");
        // Set to empty string if no notes found
        if (mounted) {
          setState(() {
            _notesValue = "";
            _notesController.text = "";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching lead scouting data: $e");
    } finally {
      sub.cancel();
    }
  }

  Future<void> _fetchPitScoutingData() async {
    if (!mounted) return;

    // For PitScoutingData, remove 'frc' prefix if present
    final String normalizedTeamNumber =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName.substring(3)
            : widget.teamName;

    final sql = """
      SELECT * FROM PitScoutingData WHERE team_number='$normalizedTeamNumber'
    """;

    final cmd = {"type": "query", "text": sql};
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    debugPrint('Fetching pit scouting data for team $normalizedTeamNumber');

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);

        if (jsonPart.trim().isEmpty || jsonPart.trim() == "null") {
          return;
        }

        if (jsonPart.length != len) return;

        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          if (rows.isNotEmpty) {
            debugPrint("Received pit scouting data: ${jsonEncode(rows.first)}");
            completer.complete(rows.first);
          } else {
            completer.complete(null);
          }
        }
      } catch (e) {
        debugPrint("Error processing pit scouting data: $e");
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(cmd);

    try {
      final row = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint("Timeout fetching pit scouting data");
          return null;
        },
      );

      if (row != null) {
        if (mounted) {
          setState(() {
            pitScoutingData = Map<String, dynamic>.from(row);
            debugPrint(
                "Updated pit scouting data in state: ${jsonEncode(pitScoutingData)}");
          });
        }
      } else {
        debugPrint("No pit scouting data found for team $normalizedTeamNumber");
        if (mounted) {
          setState(() {
            pitScoutingData = {
              'team_number': normalizedTeamNumber,
              'robot_weight': "",
              'drive_type': "",
              'motor_type': "",
              'motor_count': 0,
              'bumper_quality': 0,
              'coral_intake_type': "",
              'algae_intake_type': "",
              'L1': "false",
              'L2': "false",
              'L3': "false",
              'L4': "false",
              'processor': "false",
              'net': "false",
              'climb_type': "",
              'autonomous_coral_points': 0,
              'leaves_start_line': "false"
            };
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching pit scouting data: $e");
      if (mounted) {
        setState(() {
          pitScoutingData = {
            'team_number': normalizedTeamNumber,
            'robot_weight': "",
            'drive_type': "",
            'motor_type': "",
            'motor_count': 0,
            'bumper_quality': 0,
            'coral_intake_type': "",
            'algae_intake_type': "",
            'L1': "false",
            'L2': "false",
            'L3': "false",
            'L4': "false",
            'processor': "false",
            'net': "false",
            'climb_type': "",
            'autonomous_coral_points': 0,
            'leaves_start_line': "false"
          };
        });
      }
    } finally {
      sub.cancel();
    }
  }

  Future<void> _submitLeadScoutingNotes() async {
  debugPrint(
      "🚫 [FAKE SUBMIT] Lead scouting notes for ${widget.teamName}: $_notesValue");
  await Future.delayed(const Duration(milliseconds: 300));
}

  Future<void> _submitPitScoutingData() async {
  debugPrint("🚫 [FAKE SUBMIT] Pit scouting data requested (no DB call).");
  await Future.delayed(const Duration(milliseconds: 300));
}

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });

    // Load all data when the page is initialized
    _loadAllData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Column(
          children: [
            const Text("Auto Phase"),
            Text(
              '$_username: Team ${widget.teamName} in match ${widget.matchNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                fieldFlipped = !fieldFlipped;
              });
            },
            icon: const Icon(Icons.rotate_90_degrees_ccw),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading team data..."),
                ],
              ),
            )
          : widget.isLeadScout
              ? buildLeadScoutLayout(BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height))
              : buildMatchScoutLayout(BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height)),
      bottomNavigationBar: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: Theme.of(context).colorScheme.secondary,
          iconColor: Theme.of(context).colorScheme.secondary,
        ),
        iconAlignment: IconAlignment.end,
        onPressed: _isLoading
            ? null // Disable the button while loading
            : () async {
                // Always submit auto scouting data
                await _submitAutoScoutingData();

                // Only submit lead scouting notes if the user is a lead scout
                if (widget.isLeadScout) {
                  await _submitLeadScoutingNotes();
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ObjectivePage(
                      teamName: widget.teamName,
                      teamNickname: widget.teamNickname,
                      matchNumber: widget.matchNumber,
                      channel: widget.webSocketService.channel!,
                      onThemeChanged: widget.onThemeChanged,
                      webSocketService: widget.webSocketService,
                      isLeadScout: widget.isLeadScout,
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Next'),
      ),
    );
  }

  Widget buildMatchScoutLayout(BoxConstraints constraints) {
    const double screenPadding = 12;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fieldWidth = min(screenWidth - 2 * screenPadding, 400);
    final double fieldHeight = fieldWidth;
    AssetImage bg = isBlue
        ? const AssetImage('assets/reefscape_blue_field.jpg')
        : const AssetImage('assets/reefscape_red_field.jpg');
    AssetImage reefImg = const AssetImage('assets/reef.png');

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      height: fieldHeight,
                      child: Transform.rotate(
                        angle: fieldFlipped ? 3.14159265 : 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: bg,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 3 * fieldHeight / 4 - 25,
                      right:
                          (fieldFlipped ? fieldWidth * 4 / 5 : fieldWidth / 4) -
                              25,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("Center",
                              style: TextStyle(color: Colors.black)),
                          Checkbox(
                            value: inCenterZone,
                            checkColor: Colors.black,
                            activeColor: Colors.black,
                            onChanged: (bool? value) {
                              setState(() {
                                inCenterZone = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: (fieldFlipped ? 2 : 1) * fieldWidth / 3 - 25,
                      top: fieldHeight / 4 - 25,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("Left",
                                  style: TextStyle(color: Colors.black)),
                              Checkbox(
                                value: inLeftZone,
                                checkColor: Colors.black,
                                activeColor: Colors.black,
                                onChanged: (bool? value) {
                                  setState(() {
                                    inLeftZone = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: fieldHeight / 2 - 50),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("Right",
                                  style: TextStyle(color: Colors.black)),
                              Checkbox(
                                value: inRightZone,
                                checkColor: Colors.black,
                                activeColor: Colors.black,
                                onChanged: (bool? value) {
                                  setState(() {
                                    inRightZone = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: (fieldFlipped ? 1 : 4) * fieldWidth / 5 - 40,
                      top: fieldHeight / 4,
                      child: SizedBox(
                        width: 150,
                        height: fieldHeight / 3 * 2,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  startPos = "rightStart";
                                });
                              },
                              child: ListTile(
                                title: const Text("Right",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black)),
                                leading: Radio<String>(
                                  value: "rightStart",
                                  groupValue: startPos,
                                  onChanged: (String? value) {
                                    setState(() {
                                      startPos = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: max(0, fieldHeight / 4 - 95)),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  startPos = "centerStart";
                                });
                              },
                              child: ListTile(
                                title: const Text("Center",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black)),
                                leading: Radio<String>(
                                  value: "centerStart",
                                  groupValue: startPos,
                                  onChanged: (String? value) {
                                    setState(() {
                                      startPos = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: max(0, fieldHeight / 4 - 95)),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  startPos = "leftStart";
                                });
                              },
                              child: ListTile(
                                title: const Text("Left",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black)),
                                leading: Radio<String>(
                                  value: "leftStart",
                                  groupValue: startPos,
                                  onChanged: (String? value) {
                                    setState(() {
                                      startPos = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: screenWidth * 0.03),
                  SizedBox(
                    width: screenWidth * 0.375,
                    height: screenWidth,
                    child: Image(
                      image: reefImg,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: Text("L4",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize:
                              Size(screenWidth * 0.30, screenWidth * 0.20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () => updateCounter(l4Counter, doIncrement),
                        child: Text('${l4Counter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Text("L2 & L3",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize:
                              Size(screenWidth * 0.30, screenWidth * 0.20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () =>
                            updateCounter(l2l3Counter, doIncrement),
                        child: Text('${l2l3Counter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Text("L1",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize:
                              Size(screenWidth * 0.30, screenWidth * 0.20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () => updateCounter(l1Counter, doIncrement),
                        child: Text('${l1Counter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.10)),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.0125),
                        child: Text("Net",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: Size.square(screenWidth * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () => updateCounter(netCounter, doIncrement),
                        child: Text('${netCounter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.1)),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.0125),
                        child: Text("Processor",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: Size.square(screenWidth * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () =>
                            updateCounter(processorCounter, doIncrement),
                        child: Text('${processorCounter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.1)),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.0125),
                        child: Text("+/-",
                            style: TextStyle(fontSize: screenWidth * 0.075)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          minimumSize: Size.square(screenWidth * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () {
                          setState(() {
                            doIncrement = !doIncrement;
                          });
                        },
                        child: signIcon,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLeadScoutLayout(BoxConstraints constraints) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left side: Field view.
              // Expanded(
              //   flex: 1,
              //   child: SingleChildScrollView(
              //     padding: const EdgeInsets.all(12),
              //     child: buildFieldSectionDesktop(),
              //   ),
              // ),
              // Right side: Controls.
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: buildControlsSectionDesktop(),
                ),
              ),
            ],
          ),
        ),
        // Only show notes field for lead scouts
        if (widget.isLeadScout) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                "Notes:",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter notes about this team...",
              ),
              minLines: 3,
              maxLines: 5,
              onChanged: (value) {
                _notesValue = value;
              },
            ),
          ),
        ],
      ],
    );
  }


  Widget buildControlsSectionDesktop() {
    double availableWidth = MediaQuery.of(context).size.width / 2 - 24;
    double fieldWidth = min(availableWidth, 400);
    double fieldHeight = fieldWidth;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                SizedBox(
                  width: fieldWidth,
                  height: fieldHeight,
                  child: Image(
                    image: AssetImage('assets/reef.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildCounterButton("L4", l4Counter, doIncrement, 80),
                    const SizedBox(height: 20),
                    buildCounterButton("L2 & L3", l2l3Counter, doIncrement, 80),
                    const SizedBox(height: 20),
                    buildCounterButton("L1", l1Counter, doIncrement, 80),
                  ],
                ),
              ],
            ),
            SizedBox(width: availableWidth / 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildCounterButton("Net", netCounter, doIncrement, 80),
                const SizedBox(height: 20),
                buildCounterButton(
                    "Processor", processorCounter, doIncrement, 80),
                SizedBox(width: availableWidth / 16),
                Column(
                  children: [
                    const Text("+/-", style: TextStyle(fontSize: 16)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: () {
                        setState(() {
                          doIncrement = !doIncrement;
                        });
                      },
                      child: Center(child: signIcon),
                    ),
                  ],
                ),
              ],
            ),
            // Only show capabilities button for lead scouts
            if (widget.isLeadScout) ...[
              SizedBox(width: availableWidth / 8),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(150, 100),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: _isLoading
                        ? null // Disable button while loading
                        : () {
                            // Check if pit data is properly loaded
                            bool isDataComplete = pitScoutingData != null &&
                                pitScoutingData!.containsKey('robot_weight') &&
                                pitScoutingData!.containsKey('drive_type');

                            if (!isDataComplete) {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const Dialog(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text("Loading capabilities data..."),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              // Try to refetch the data
                              _fetchPitScoutingData().then((_) {
                                if (mounted) {
                                  Navigator.of(context)
                                      .pop(); // Close loading dialog
                                  if (pitScoutingData != null &&
                                      pitScoutingData!
                                          .containsKey('robot_weight')) {
                                    setState(() {}); // Force a rebuild
                                    // _showCapabilitiesEditDialog();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Error loading data. Please try again."),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              });
                            } else {
                              // _showCapabilitiesEditDialog();
                            }
                          },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_attributes,
                          size: 36,
                          color: _isLoading
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Capabilities",
                          style: TextStyle(
                            fontSize: 16,
                            color: _isLoading ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Method to load all data and track loading state
  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Fetch lead scouting notes first if user is a lead scout
      if (widget.isLeadScout) {
        await _fetchLeadScoutingData();
      }

      // Then fetch pit scouting data
      await _fetchPitScoutingData();

      // Force a rebuild to ensure the UI reflects the loaded data
      if (mounted) {
        setState(() {
          // Ensure controller text is updated with fetched notes
          if (widget.isLeadScout &&
              _notesValue.isNotEmpty &&
              _notesController.text != _notesValue) {
            _notesController.text = _notesValue;
          }
        });
      }

      debugPrint(
          "All data loaded. Notes: '$_notesValue', Controller: '${_notesController.text}'");
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error loading data. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // End loading
        });
      }
    }
  }

  Widget _buildDialogTextField(TextEditingController controller, String label,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Widget _buildDialogCheckbox(
      String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // Helper functions for safe type conversion
  String safeString(dynamic value) {
    if (value == null) return "";
    return value.toString();
  }

  int safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  bool safeBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    String str = value.toString().toLowerCase();
    return str == "true" || str == "1" || str == "yes";
  }

  // Method to save capabilities data to the database
  Future<void> _saveCapabilitiesData(
    String robotWeight,
    String driveType,
    String motorType,
    String motorCount,
    String bumperQuality,
    String coralIntakeType,
    String algaeIntakeType,
    String climbType,
    String autonomousCoralPoints,
    bool l1,
    bool l2,
    bool l3,
    bool l4,
    bool processor,
    bool net,
    bool leavesStartLine) async {
  final fakeCaps = {
    "robotWeight": robotWeight,
    "driveType": driveType,
    "motorType": motorType,
    "motorCount": motorCount,
    "bumperQuality": bumperQuality,
    "coralIntakeType": coralIntakeType,
    "algaeIntakeType": algaeIntakeType,
    "climbType": climbType,
    "autoCoralPoints": autonomousCoralPoints,
    "capabilities": {
      "L1": l1,
      "L2": l2,
      "L3": l3,
      "L4": l4,
      "Processor": processor,
      "Net": net,
      "LeavesStartLine": leavesStartLine,
    }
  };

  debugPrint("🚫 [FAKE SUBMIT] Pit capabilities (not saved): $fakeCaps");
  await Future.delayed(const Duration(milliseconds: 500));
}

  Widget buildCounterButton(String label, IntegerWrapper counter,
      bool doIncrement, double buttonSize) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(buttonSize * 0.1),
          child: Text(label, style: TextStyle(fontSize: buttonSize * 0.15)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.secondary,
            minimumSize: Size(buttonSize, buttonSize),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          onPressed: () => updateCounter(counter, doIncrement),
          child: Text('${counter.value}',
              style: TextStyle(fontSize: buttonSize * 0.3)),
        ),
      ],
    );
  }

  // Also override the didUpdateWidget method to update the controller when needed
  @override
  void didUpdateWidget(AutoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the text field if _notesValue changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_notesController.text != _notesValue) {
        _notesController.text = _notesValue;
      }
    });
  }
}
