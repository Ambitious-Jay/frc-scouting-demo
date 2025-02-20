import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/endgame.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class ObjectivePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  /// Accept the WebSocketChannel from main.dart
  final WebSocketChannel? channel;

  const ObjectivePage({
    Key? key,
    required this.onThemeChanged,
    required this.channel,
    required WebSocketService webSocketService,
  }) : super(key: key);

  @override
  State<ObjectivePage> createState() => _ObjectivePageState();
}

class _ObjectivePageState extends State<ObjectivePage> {
  ThemeMode themeMode = ThemeMode.system;

  // counters
  int l4Counter = 0;
  int l2l3Counter = 0;
  int l1Counter = 0;
  int netCounter = 0;
  int processorCounter = 0;
  bool isCounterPositive = true;

  // Use height as the scaling base for all sizes
  Icon get signIcon {
    IconData iconData = isCounterPositive ? Icons.add : Icons.remove;
    double h = MediaQuery.of(context).size.height;
    return Icon(
      iconData,
      color: Theme.of(context).colorScheme.primary,
      size: h * 0.045,
    );
  }

  // Update counter methods
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

  /// Save data to database
  Future<void> _saveDataToDatabase() async {
    try {
      // Build an INSERT statement referencing your table and columns
      final sql = '''
        INSERT INTO [Match Data]
          (l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter)
        VALUES
          ($l4Counter, $l2l3Counter, $l1Counter, $netCounter, $processorCounter)
      ''';

      // Prepare the bridging server message
      final cmd = {
        "type": "query",
        "text": sql,
      };

      // Ensure the channel is available
      if (widget.channel == null) {
        throw Exception('No WebSocket channel available.');
      }

      // Encode "length\r\njson" as the bridging server expects
      final encodedJson = jsonEncode(cmd);
      final prefix = '${encodedJson.length}\r\n';
      widget.channel!.sink.add(prefix + encodedJson);

      debugPrint('Successfully sent INSERT command to bridging server: $sql');
    } catch (e, st) {
      debugPrint('Error sending counters to DB: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the screen height as our size basis
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Objective Page'),
      ),
      // Wrap in SafeArea and SingleChildScrollView to help on smaller devices
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Row(
                  children: [
                    // Reef image sized using height as the basis
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
          _saveDataToDatabase;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Endgame(teamName: "fake team name",), // placeholder until backend works
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Submit'),
      ),
    );
  }
}
