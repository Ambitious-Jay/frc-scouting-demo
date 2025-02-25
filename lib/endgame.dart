import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Global variable for hang selection
String Hang = "";

// Map of preset booleans for endgame actions
Map<String, bool> presets = <String, bool>{
  'Part Broke': false,
  'Stopped Moving': false,
  'Fast': false,
  'Good Driving': false,
  'Tippy': false,
  'Accurate Coral': false,
  'Defensive': false,
  'Net Algae': false
};

List<String> keys = presets.keys.toList();

class Endgame extends StatefulWidget {
  const Endgame({
    super.key,
    required this.teamName,
    required this.channel,
    required this.onThemeChanged,
    required this.webSocketService,
  });
  final String teamName;
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;

  @override
  State<Endgame> createState() => _Endgame();
}

class _Endgame extends State<Endgame> {
  /// Submits the endgame data to the SQL server.
  /// Builds an INSERT statement targeting the EndgameData table.
  Future<void> _submitEndgameData() async {
    final sql = '''
      INSERT INTO EndgameData (
        team_number, hang, part_broke, stopped_moving, fast, good_driving, tippy, accurate_coral, defensive, net_algae
      )
      VALUES (
        '${widget.teamName}',
        '$Hang',
        ${presets['Part Broke'] == true ? 1 : 0},
        ${presets['Stopped Moving'] == true ? 1 : 0},
        ${presets['Fast'] == true ? 1 : 0},
        ${presets['Good Driving'] == true ? 1 : 0},
        ${presets['Tippy'] == true ? 1 : 0},
        ${presets['Accurate Coral'] == true ? 1 : 0},
        ${presets['Defensive'] == true ? 1 : 0},
        ${presets['Net Algae'] == true ? 1 : 0}
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
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Endgame"),
            Text(widget.teamName),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: [
            // Hang Dropdown
            SizedBox(
              height: height / 3.5,
              child: Center(
                child: DropdownButtonFormField<String>(
                  value: "No Value Entered/Seen",
                  onChanged: (String? value) {
                    setState(() {
                      Hang = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Hang',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Deep Cage',
                    'Shallow Cage',
                    'Failed Deep Cage',
                    'Failed Shallow Cage',
                    'Did Not Try',
                    "No Value Entered/Seen"
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
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
