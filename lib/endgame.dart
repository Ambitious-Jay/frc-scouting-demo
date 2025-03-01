import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Global variables for endgame/pit scouting presets
bool triedHang = false;
bool defensive = false;

Map<String, bool> presets = <String, bool>{
  'Mechanism Broke': false,
  'Stopped Moving': false,
  'Fast': false,
  'Good Driving': false,
  'Bad Driving': false,
  'Tippy': false,
  'Not Tippy': false,
  'Consistent Coral': false,
  'Inaccurate Coral': false,
  'Good Defense': false,
  'Bad Defense': false,
  'Jams Often': false,
  'Fast Climb': false,
  'Slow Climb': false,
  'Consistent Auton': false,
  'Inconsistent Auton': false,
  'Net Algae': false, // Added key for net_algae
};

List<String> keys = presets.keys.toList();

class Endgame extends StatefulWidget {
  final String teamName;
  final String teamNickname;
  final String id;
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;

  const Endgame({
    Key? key,
    required this.teamName,
    required this.teamNickname,
    required this.id,
    required this.channel,
    required this.onThemeChanged,
    required this.webSocketService,
  }) : super(key: key);

  @override
  State<Endgame> createState() => _Endgame();
}

class _Endgame extends State<Endgame> {
  String _username = "";

  Future<void> _submitEndgameData() async {
    // Build the SQL query to insert endgame data.
    // Note: We convert booleans to integers (1 for true, 0 for false).
    final sql = '''
      INSERT INTO EndgameData (
        team_number, attempt_to_park, part_broke, stopped_moving, fast, good_driving, tippy, accurate_coral, defensive, net_algae
      )
      VALUES (
        '${widget.teamName}',
        ${triedHang ? 1 : 0},
        ${presets['Mechanism Broke'] == true ? 1 : 0},
        ${presets['Stopped Moving'] == true ? 1 : 0},
        ${presets['Fast'] == true ? 1 : 0},
        ${presets['Good Driving'] == true ? 1 : 0},
        ${presets['Tippy'] == true ? 1 : 0},
        ${presets['Consistent Coral'] == true ? 1 : 0},
        ${presets['Good Defense'] == true ? 1 : 0},
        ${presets.containsKey('Net Algae') && presets['Net Algae'] == true ? 1 : 0}
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
      debugPrint('Successfully sent endgame INSERT command: $sql');
    } catch (e, st) {
      debugPrint('Error sending endgame data to DB: $e\n$st');
    }
  }

  @override
  void initState() {
    super.initState();
    // Retrieve the logged-in username from AuthService.
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width  = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Endgame Phase",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$_username: Team ${widget.teamName} in match ${widget.id}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: [
            // Attempt to Park Row
            SizedBox(
              height: height / 3.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    "Attempt to park?",
                    style: TextStyle(fontSize: 30),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        triedHang = !triedHang;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(100, 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: triedHang
                        ? const Icon(
                            Icons.done,
                            size: 44,
                            color: Colors.white,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Defense Row
            SizedBox(
                height: height / 3.5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      "Defense?",
                      style: TextStyle(fontSize: 30),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          defensive = !defensive;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size(100, 100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: defensive
                          ? const Icon(
                              Icons.done,
                              size: 44,
                              color: Colors.white,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                )),
            const Divider(),
            // Grid of preset buttons
            SingleChildScrollView(
              child: GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(width / 50),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: width / 50,
                  mainAxisSpacing: width / 50,
                ),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  String key = keys[index];
                  bool value = presets[key]!;
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        presets[key] = !value;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        value ? Colors.red : Colors.black,
                      ),
                    ),
                    child: Text(
                      key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
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
          await _submitEndgameData();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                teamName: widget.teamName,
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
