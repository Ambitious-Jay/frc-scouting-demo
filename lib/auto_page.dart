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
  }) : super(key: key);

  final String teamName;
  final String teamNickname;
  final String matchNumber;
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;

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
  String? startPos = "Option one";

  late final TextEditingController _notesController;

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
    return Icon(iconData,
        color: Theme.of(context).colorScheme.primary,
        size: MediaQuery.of(context).size.width * 0.05);
  }

  Future<void> _submitAutoScoutingData() async {
    final sql = '''
      INSERT INTO AutoScouting (
        team_number, match_number, start_position, l4_count, l2_l3_count, l1_count, net_count, processor_count,
        in_center_zone, in_left_zone, in_right_zone, is_blue, field_flipped
      )
      VALUES (
        '${widget.teamName}', '${widget.matchNumber}', '${startPos ?? ""}',
        ${l4Counter.value}, ${l2l3Counter.value}, ${l1Counter.value},
        ${netCounter.value}, ${processorCounter.value},
        ${inCenterZone ? 1 : 0}, ${inLeftZone ? 1 : 0}, ${inRightZone ? 1 : 0},
        ${isBlue ? 1 : 0}, ${fieldFlipped ? 1 : 0}
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
      debugPrint('Successfully sent auto scouting INSERT command: $sql');
    } catch (e, st) {
      debugPrint('Error sending auto scouting data to DB: $e\n$st');
    }
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return buildLeadScoutLayout(constraints);
          } else {
            return buildMatchScoutLayout(constraints);
          }
        },
      ),
      bottomNavigationBar: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: Theme.of(context).colorScheme.secondary,
          iconColor: Theme.of(context).colorScheme.secondary,
        ),
        iconAlignment: IconAlignment.end,
        onPressed: () async {
          _submitAutoScoutingData();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ObjectivePage(
                teamName: widget.teamName,
                teamNickname: widget.teamNickname,
                matchNumber: widget.matchNumber,
                channel: widget.webSocketService.channel,
                onThemeChanged: widget.onThemeChanged,
                webSocketService: widget.webSocketService,
              ),
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Submit'),
      ),
    );
  }

  /// Mobile layout updated to fill available height.
  Widget buildMatchScoutLayout(BoxConstraints constraints) {
    const double screenPadding = 12;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fieldWidth = screenWidth - 2 * screenPadding;
    final double fieldHeight = fieldWidth;

    AssetImage bg = isBlue
        ? const AssetImage('assets/reefscape_blue_field.jpg')
        : const AssetImage('assets/reefscape_red_field.jpg');

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: fieldWidth,
                height: fieldHeight,
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
                    // Center checkbox.
                    Positioned(
                      top: fieldHeight / 2 - 25,
                      right:
                          (fieldFlipped ? fieldWidth * 4 / 5 : fieldWidth / 4) -
                              25,
                      child: Column(
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
                              })
                        ],
                      ),
                    ),
                    // Left and Right checkboxes.
                    Positioned(
                      left: (fieldFlipped ? 2 : 1) * fieldWidth / 3 - 25,
                      top: fieldHeight / 4 - 25,
                      child: Column(
                        children: [
                          Column(
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
                                  })
                            ],
                          ),
                          SizedBox(height: fieldHeight / 2 - 50),
                          Column(
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
                                  })
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Radio buttons for start position.
                    Positioned(
                      left: (fieldFlipped ? 1 : 7) * fieldWidth / 8 - 40,
                      top: fieldHeight / 4,
                      child: SizedBox(
                        width: 80,
                        height: fieldHeight / 3 * 2,
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text(""),
                              leading: Radio<String>(
                                  value: "rightStart",
                                  groupValue: startPos,
                                  onChanged: (String? value) {
                                    setState(() {
                                      startPos = value;
                                    });
                                  }),
                            ),
                            SizedBox(height: max(0, fieldHeight / 4 - 75)),
                            ListTile(
                              title: const Text(""),
                              leading: Radio<String>(
                                  value: "centerStart",
                                  groupValue: startPos,
                                  onChanged: (String? value) {
                                    setState(() {
                                      startPos = value;
                                    });
                                  }),
                            ),
                            SizedBox(height: max(0, fieldHeight / 4 - 75)),
                            ListTile(
                              title: const Text(""),
                              leading: Radio<String>(
                                  value: "leftStart",
                                  groupValue: startPos,
                                  onChanged: (String? value) {
                                    setState(() {
                                      startPos = value;
                                    });
                                  }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop layout now uses an Expanded widget for the main Row so that the TextField remains at the bottom without extra gap.
  Widget buildLeadScoutLayout(BoxConstraints constraints) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left side: Field view.
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: buildFieldSectionDesktop(),
                ),
              ),
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
            decoration: const InputDecoration(border: OutlineInputBorder()),
            minLines: 1,
            maxLines: null,
          ),
        ),
      ],
    );
  }

  /// Desktop Field Section: re-using the same Stack with all overlayed buttons.
  Widget buildFieldSectionDesktop() {
    double availableWidth = MediaQuery.of(context).size.width / 2 - 24;
    double fieldWidth = min(availableWidth, 400);
    double fieldHeight = fieldWidth;

    AssetImage bg = isBlue
        ? const AssetImage('assets/reefscape_blue_field.jpg')
        : const AssetImage('assets/reefscape_red_field.jpg');

    return Container(
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
          // Center zone.
          Positioned(
            top: fieldHeight / 2 - 25,
            right: (fieldFlipped ? fieldWidth * 4 / 5 : fieldWidth / 4) - 25,
            child: Column(
              children: [
                const Text("Center", style: TextStyle(color: Colors.black)),
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
          // Left and Right zones.
          Positioned(
            left: (fieldFlipped ? 2 : 1) * fieldWidth / 3 - 25,
            top: fieldHeight / 4 - 25,
            child: Column(
              children: [
                Column(
                  children: [
                    const Text("Left", style: TextStyle(color: Colors.black)),
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
                  children: [
                    const Text("Right", style: TextStyle(color: Colors.black)),
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
          // Radio buttons for start position.
          Positioned(
            left: (fieldFlipped ? 1 : 7) * fieldWidth / 8 - 40,
            top: fieldHeight / 4,
            child: SizedBox(
              width: 80,
              height: fieldHeight / 3 * 2,
              child: Column(
                children: [
                  ListTile(
                    title: const Text(""),
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
                  SizedBox(height: max(0, fieldHeight / 4 - 75)),
                  ListTile(
                    title: const Text(""),
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
                  SizedBox(height: max(0, fieldHeight / 4 - 75)),
                  ListTile(
                    title: const Text(""),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop Controls Section: shows a reef image next to counter buttons.
  Widget buildControlsSectionDesktop() {
    const double reefSize = 400;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: reefSize,
                  height: reefSize,
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
            const SizedBox(width: 200),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildCounterButton("Net", netCounter, doIncrement, 80),
                const SizedBox(height: 20),
                buildCounterButton(
                    "Processor", processorCounter, doIncrement, 80),
                const SizedBox(height: 20),
                Column(
                  children: [
                    const Text("+/-", style: TextStyle(fontSize: 16)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        maximumSize: const Size(80, 80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
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
            const SizedBox(width: 300),
            Column(
              children: [
                const Text("Excel", style: TextStyle(fontSize: 16)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(100, 100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to the excel functionality.
                  },
                  child: const Icon(Icons.rectangle),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Helper: builds a counter button with its label.
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          onPressed: () => updateCounter(counter, doIncrement),
          child: Text('${counter.value}',
              style: TextStyle(fontSize: buttonSize * 0.3)),
        ),
      ],
    );
  }
}
