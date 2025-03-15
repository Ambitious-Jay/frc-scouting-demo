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
  'Net Algae': false,
};

List<String> keys = presets.keys.toList();

class Endgame extends StatefulWidget {
  final String teamName;
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;

  const Endgame({
    Key? key,
    required this.teamName,
    required this.channel,
    required this.onThemeChanged,
    required this.webSocketService,
  }) : super(key: key);

  @override
  State<Endgame> createState() => _Endgame();
}

class _Endgame extends State<Endgame> {
  Future<void> _submitEndgameData() async {
    // Build the MSSQL MERGE statement for upsert based on team_number.
    final sql = '''
MERGE EndgameData AS target
USING (
  SELECT
    '${widget.teamName}' AS team_number,
    ${triedHang ? 1 : 0} AS attempt_to_park,
    ${defensive ? 1 : 0} AS defense,
    ${presets['Mechanism Broke']! ? 1 : 0} AS mechanism_broke,
    ${presets['Stopped Moving']! ? 1 : 0} AS stopped_moving,
    ${presets['Fast']! ? 1 : 0} AS fast,
    ${presets['Good Driving']! ? 1 : 0} AS good_driving,
    ${presets['Bad Driving']! ? 1 : 0} AS bad_driving,
    ${presets['Tippy']! ? 1 : 0} AS tippy,
    ${presets['Not Tippy']! ? 1 : 0} AS not_tippy,
    ${presets['Consistent Coral']! ? 1 : 0} AS consistent_coral,
    ${presets['Inaccurate Coral']! ? 1 : 0} AS inaccurate_coral,
    ${presets['Good Defense']! ? 1 : 0} AS good_defense,
    ${presets['Bad Defense']! ? 1 : 0} AS bad_defense,
    ${presets['Jams Often']! ? 1 : 0} AS jams_often,
    ${presets['Fast Climb']! ? 1 : 0} AS fast_climb,
    ${presets['Slow Climb']! ? 1 : 0} AS slow_climb,
    ${presets['Consistent Auton']! ? 1 : 0} AS consistent_auton,
    ${presets['Inconsistent Auton']! ? 1 : 0} AS inconsistent_auton,
    ${presets['Net Algae']! ? 1 : 0} AS net_algae
) AS source
ON (target.team_number = source.team_number)
WHEN MATCHED THEN
  UPDATE SET
    attempt_to_park = target.attempt_to_park + source.attempt_to_park,
    defense = target.defense + source.defense,
    mechanism_broke = target.mechanism_broke + source.mechanism_broke,
    stopped_moving = target.stopped_moving + source.stopped_moving,
    fast = target.fast + source.fast,
    good_driving = target.good_driving + source.good_driving,
    bad_driving = target.bad_driving + source.bad_driving,
    tippy = target.tippy + source.tippy,
    not_tippy = target.not_tippy + source.not_tippy,
    consistent_coral = target.consistent_coral + source.consistent_coral,
    inaccurate_coral = target.inaccurate_coral + source.inaccurate_coral,
    good_defense = target.good_defense + source.good_defense,
    bad_defense = target.bad_defense + source.bad_defense,
    jams_often = target.jams_often + source.jams_often,
    fast_climb = target.fast_climb + source.fast_climb,
    slow_climb = target.slow_climb + source.slow_climb,
    consistent_auton = target.consistent_auton + source.consistent_auton,
    inconsistent_auton = target.inconsistent_auton + source.inconsistent_auton,
    net_algae = target.net_algae + source.net_algae
WHEN NOT MATCHED THEN
  INSERT (team_number, attempt_to_park, defense, mechanism_broke, stopped_moving, fast, good_driving, bad_driving,
          tippy, not_tippy, consistent_coral, inaccurate_coral, good_defense, bad_defense, jams_often, fast_climb,
          slow_climb, consistent_auton, inconsistent_auton, net_algae)
  VALUES (source.team_number, source.attempt_to_park, source.defense, source.mechanism_broke, source.stopped_moving,
          source.fast, source.good_driving, source.bad_driving, source.tippy, source.not_tippy, source.consistent_coral,
          source.inaccurate_coral, source.good_defense, source.bad_defense, source.jams_often, source.fast_climb,
          source.slow_climb, source.consistent_auton, source.inconsistent_auton, source.net_algae);
''';

    final cmd = {
      "type": "query",
      "text": sql,
    };

    final encodedJson = jsonEncode(cmd);
    final prefix = '${encodedJson.length}\r\n';

    try {
      widget.channel.sink.add(prefix + encodedJson);
      debugPrint('Successfully sent endgame MERGE command: $sql');
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: const Text(
          "Endgame Phase",
          style: TextStyle(fontWeight: FontWeight.bold),
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
              ),
            ),
            const Divider(),
            // Grid of preset buttons
            GridView.builder(
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
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
          _submitEndgameData();
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
