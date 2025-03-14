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
  final String matchNumber; // Renamed from id to matchNumber
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;

  @override
  _AutoPageState createState() => _AutoPageState();
}

class _AutoPageState extends State<AutoPage> {
  ThemeMode themeMode = ThemeMode.system;
  String _username = ""; // Define the _username variable
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

  // Using radio buttons for start position
  String? startPos = "Option one";

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
        size: MediaQuery.of(context).size.width * 0.1);
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
    // Retrieve the logged-in username from SharedPreferences via AuthService.
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double screenPadding = 12;
    const double imageWidthToHeight = 1;
    final double fieldWidth = min(screenWidth - 2 * screenPadding, 400);
    final double fieldHeight = fieldWidth / imageWidthToHeight;
    AssetImage bg = isBlue
        ? const AssetImage('assets/reefscape_blue_field.jpg')
        : const AssetImage('assets/reefscape_red_field.jpg');
    AssetImage reefImg = const AssetImage('assets/reef.png');
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
      body: Container(
        padding: const EdgeInsets.all(screenPadding),
        child: SingleChildScrollView(
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
                      top: fieldHeight / 2 - 25,
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
                              onChanged: (bool? value) => {
                                    setState(() {
                                      inCenterZone = value!;
                                    })
                                  })
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
                                      onChanged: (bool? value) => {
                                            setState(() {
                                              inLeftZone = value!;
                                            })
                                          })
                                ]),
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
                                      onChanged: (bool? value) => {
                                            setState(() {
                                              inRightZone = value!;
                                            })
                                          })
                                ]),
                          ],
                        )),
                    Positioned(
                        left: (fieldFlipped ? 1 : 7) * fieldWidth / 8 - 40,
                        top: fieldHeight / 4,
                        child: SizedBox(
                            width: 80,
                            height: fieldHeight / 3 * 2,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
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
                                          })),
                                  SizedBox(
                                      height: max(0, fieldHeight / 4 - 75)),
                                  ListTile(
                                      title: const Text(""),
                                      leading: Radio<String>(
                                          value: "centerStart",
                                          groupValue: startPos,
                                          onChanged: (String? value) {
                                            setState(() {
                                              startPos = value;
                                            });
                                          })),
                                  SizedBox(
                                      height: max(0, fieldHeight / 4 - 75)),
                                  ListTile(
                                      title: const Text(""),
                                      leading: Radio<String>(
                                          value: "leftStart",
                                          groupValue: startPos,
                                          onChanged: (String? value) {
                                            setState(() {
                                              startPos = value;
                                            });
                                          })),
                                ])))
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
                      )),
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
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () =>
                              updateCounter(l4Counter, doIncrement),
                          child: Text('${l4Counter.value}',
                              style: TextStyle(fontSize: screenWidth * 0.10))),
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
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () =>
                              updateCounter(l2l3Counter, doIncrement),
                          child: Text('${l2l3Counter.value}',
                              style: TextStyle(fontSize: screenWidth * 0.10))),
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
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () =>
                              updateCounter(l1Counter, doIncrement),
                          child: Text('${l1Counter.value}',
                              style: TextStyle(fontSize: screenWidth * 0.10))),
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
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () =>
                              updateCounter(netCounter, doIncrement),
                          child: Text('${netCounter.value}',
                              style: TextStyle(fontSize: screenWidth * 0.1))),
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
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () =>
                              updateCounter(processorCounter, doIncrement),
                          child: Text('${processorCounter.value}',
                              style: TextStyle(fontSize: screenWidth * 0.1))),
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
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () {
                            setState(() {
                              doIncrement = !doIncrement;
                            });
                          },
                          child: signIcon),
                    ],
                  ),
                ],
              )
            ],
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
}
