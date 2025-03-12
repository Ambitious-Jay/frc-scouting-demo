import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/endgame.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

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

  // counters
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
      final sql = '''
    INSERT INTO [MatchData]
      (team_number, match_number, l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter)
    VALUES
      ('${widget.teamName}', '${widget.matchNumber}', $l4Counter, $l2l3Counter, $l1Counter, $netCounter, $processorCounter)
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
    // Retrieve the logged-in username from SharedPreferences via AuthService.
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
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
            // Updated title: Show the username, team, and match.
            Text(
              '$_username: Team ${widget.teamName} in match ${widget.matchNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                // (Rest of your UI remains unchanged)
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
                          child:
                              Text("L4", style: TextStyle(fontSize: h * 0.045)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                          child:
                              Text("L1", style: TextStyle(fontSize: h * 0.045)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                        SizedBox(height: h * 0.075),
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
                          child: Text("Net",
                              style: TextStyle(fontSize: h * 0.0225)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                          child: Text("+/-",
                              style: TextStyle(fontSize: h * 0.034)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
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
        ),
      ),
      bottomNavigationBar: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
                // teamNickname: widget.teamNickname,
                // matchNumber: widget.matchNumber,
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
  }
}
