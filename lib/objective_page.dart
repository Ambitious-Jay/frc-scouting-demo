import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/endgame.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ObjectivePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final WebSocketChannel? channel;
  final WebSocketService webSocketService;
  final String teamName; // Team number
  final String matchNumber; // Match number (e.g., "qm1")
  final String teamNickname;

  const ObjectivePage({
    Key? key,
    required this.onThemeChanged,
    required this.channel,
    required this.webSocketService,
    required this.teamName,
    required this.teamNickname,
    required this.matchNumber,
  }) : super(key: key);

  @override
  State<ObjectivePage> createState() => _ObjectivePageState();
}

class _ObjectivePageState extends State<ObjectivePage> {
  ThemeMode themeMode = ThemeMode.system;

  // We'll fetch the username from AuthService.
  String _username = "";

  // Controllers for notes
  late final TextEditingController _notesController;

  // Counters
  int l4Counter = 0;
  int l2l3Counter = 0;
  int l1Counter = 0;
  int netCounter = 0;
  int processorCounter = 0;
  bool isCounterPositive = true;

  Icon get signIcon {
    IconData iconData = isCounterPositive ? Icons.add : Icons.remove;
    double h = MediaQuery.of(context).size.height;
    return Icon(
      iconData,
      color: Theme.of(context).colorScheme.primary,
      size: h * 0.045,
    );
  }

  void updateL4() {
    setState(() {
      if (isCounterPositive) {
        l4Counter++;
      } else if (l4Counter > 0) {
        l4Counter--;
      }
    });
  }

  void updateL2L3() {
    setState(() {
      if (isCounterPositive) {
        l2l3Counter++;
      } else if (l2l3Counter > 0) {
        l2l3Counter--;
      }
    });
  }

  void updateL1() {
    setState(() {
      if (isCounterPositive) {
        l1Counter++;
      } else if (l1Counter > 0) {
        l1Counter--;
      }
    });
  }

  void updateNet() {
    setState(() {
      if (isCounterPositive) {
        netCounter++;
      } else if (netCounter > 0) {
        netCounter--;
      }
    });
  }

  void updateProcessor() {
    setState(() {
      if (isCounterPositive) {
        processorCounter++;
      } else if (processorCounter > 0) {
        processorCounter--;
      }
    });
  }

  void toggleNegative() {
    setState(() {
      isCounterPositive = !isCounterPositive;
    });
  }

  Future<void> _saveDataToDatabase() async {
    try {
      // Update the SQL query to include the notes field.
      final sql = '''
    INSERT INTO [MatchData]
      (team_number, match_number, l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter, notes)
    VALUES
      ('${widget.teamName}', '${widget.matchNumber}', $l4Counter, $l2l3Counter, $l1Counter, $netCounter, $processorCounter, '${_notesController.text}')
    ''';

      final cmd = {
        "type": "query",
        "text": sql,
      };

      if (widget.channel == null) {
        throw Exception('No WebSocket channel available.');
      }

      final encodedJson = jsonEncode(cmd);
      final prefix = '${encodedJson.length}\r\n';
      widget.channel!.sink.add(prefix + encodedJson);

      debugPrint('Successfully sent INSERT command to bridging server: $sql');
    } catch (e, st) {
      debugPrint('Error sending counters to DB: $e\n$st');
    }
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    // Retrieve the logged-in username.
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

  /// Helper: builds a counter button with its label.
  Widget buildCounterButton(
      String label, int counter, VoidCallback onPressed, double buttonSize) {
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
          onPressed: onPressed,
          child: Text('$counter', style: TextStyle(fontSize: buttonSize * 0.3)),
        ),
      ],
    );
  }

  /// Desktop Controls Section: mimics the AutoPage desktop section (without the field view).
  /// Scales to screen size.
  Widget buildControlsSectionDesktop() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double scaleFactor = availableWidth / 1200;

        final double dynamicReefSize = 400 * scaleFactor;
        final double dynamicButtonSize = 80 * scaleFactor;
        final double spacingBetweenCounters = 20 * scaleFactor;
        final double spacingGroupOneTwo = 200 * scaleFactor;
        final double spacingGroupTwoThree = 100 * scaleFactor;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Group 1: Reef image with L4, L2 & L3, L1 counters.
                Row(
                  children: [
                    SizedBox(
                      width: dynamicReefSize,
                      height: dynamicReefSize,
                      child: Image(
                        image: const AssetImage('assets/reef.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildCounterButton(
                            "L4", l4Counter, updateL4, dynamicButtonSize),
                        SizedBox(height: spacingBetweenCounters),
                        buildCounterButton("L2 & L3", l2l3Counter, updateL2L3,
                            dynamicButtonSize),
                        SizedBox(height: spacingBetweenCounters),
                        buildCounterButton(
                            "L1", l1Counter, updateL1, dynamicButtonSize),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: spacingGroupOneTwo),
                // Group 2: Net, Processor counters and +/- toggle.
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildCounterButton(
                        "Net", netCounter, updateNet, dynamicButtonSize),
                    SizedBox(height: spacingBetweenCounters),
                    buildCounterButton("Processor", processorCounter,
                        updateProcessor, dynamicButtonSize),
                    SizedBox(height: spacingBetweenCounters),
                    Column(
                      children: [
                        Text("+/-",
                            style: TextStyle(fontSize: 16 * scaleFactor)),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            maximumSize:
                                Size(dynamicButtonSize, dynamicButtonSize),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: toggleNegative,
                          child: Container(
                            alignment: Alignment.center,
                            child: signIcon,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: spacingGroupTwoThree),
                // Group 3: Excel button (Notes are now at the bottom of the page).
                Column(
                  children: [
                    Text("Excel", style: TextStyle(fontSize: 16 * scaleFactor)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: Size(dynamicButtonSize, dynamicButtonSize),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () {
                        // Navigate to the excel functionality.
                      },
                      child: Icon(Icons.rectangle, size: 24 * scaleFactor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Mobile layout.
  Widget buildMobileLayout() {
    double h = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: h * 0.17,
                  child: const Image(
                    image: AssetImage('assets/reef.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: h * 0.025),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(h * 0.0045),
                      child: Text("L4", style: TextStyle(fontSize: h * 0.045)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.secondary,
                        minimumSize: Size(h * 0.225, h * 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: updateL4,
                      child: Text('$l4Counter',
                          style: TextStyle(fontSize: h * 0.0675)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(h * 0.0045),
                      child: Text("L2 & L3",
                          style: TextStyle(fontSize: h * 0.045)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.secondary,
                        minimumSize: Size(h * 0.225, h * 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: updateL2L3,
                      child: Text('$l2l3Counter',
                          style: TextStyle(fontSize: h * 0.0675)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(h * 0.0045),
                      child: Text("L1", style: TextStyle(fontSize: h * 0.045)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.secondary,
                        minimumSize: Size(h * 0.225, h * 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: updateL1,
                      child: Text('$l1Counter',
                          style: TextStyle(fontSize: h * 0.0675)),
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
                      padding: EdgeInsets.only(bottom: h * 0.0056),
                      child:
                          Text("Net", style: TextStyle(fontSize: h * 0.0225)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.secondary,
                        minimumSize: Size(h * 0.125, h * 0.125),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: updateNet,
                      child: Text('$netCounter',
                          style: TextStyle(fontSize: h * 0.045)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: h * 0.0056),
                      child: Text("Processor",
                          style: TextStyle(fontSize: h * 0.025)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.secondary,
                        minimumSize: Size(h * 0.125, h * 0.125),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: updateProcessor,
                      child: Text('$processorCounter',
                          style: TextStyle(fontSize: h * 0.045)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: h * 0.0055),
                      child: Text("+/-", style: TextStyle(fontSize: h * 0.034)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: Size.square(h * 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: toggleNegative,
                      child: signIcon,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 800;
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            centerTitle: true,
            title: Column(
              children: [
                const Text(
                  "Objective Phase",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_username: Team ${widget.teamName} in match ${widget.matchNumber}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: isDesktop
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: buildControlsSectionDesktop(),
                        )
                      : buildMobileLayout(),
                ),
                // Notes text field added at the bottom (modeled after AutoPage)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: "Notes",
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              foregroundColor: Theme.of(context).colorScheme.secondary,
              iconColor: Theme.of(context).colorScheme.secondary,
            ),
            iconAlignment: IconAlignment.end,
            onPressed: () {
              _saveDataToDatabase();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Endgame(
                    teamName: widget.teamName,
                    channel: widget.channel!,
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
      },
    );
  }
}
