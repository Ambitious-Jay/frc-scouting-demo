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
  // Controller for the comments text field.
  late final TextEditingController _commentsController;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitEndgameData() async {
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

  /// Mobile layout: a single ListView stacking the rows vertically.
  Widget buildMobileLayout(BoxConstraints constraints) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Center(
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
          // Grid of preset buttons (remains in the ListView so is scrollable)
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
    );
  }

  /// Desktop layout: three columns arranged in a Row.
  Widget buildDesktopLayout(BoxConstraints constraints) {
    final double availableWidth = constraints.maxWidth;
    final double scaleFactor = availableWidth / 1200;
    double height = MediaQuery.of(context).size.height;
    final double dynamicFontSize = 30 * scaleFactor;
    final double dynamicButtonSize = 100 * scaleFactor;
    final double dynamicIconSize = 44 * scaleFactor;
    final double dynamicPadding = (availableWidth / 50) * scaleFactor;
    final double dynamicExcelNotesSize = 100 * scaleFactor;

    return Padding(
      padding: EdgeInsets.all(dynamicPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: "Attempt to park?" and "Defense?" arranged vertically.
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Attempt to park section.
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Attempt to park?",
                      style: TextStyle(fontSize: dynamicFontSize),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: dynamicPadding / 2),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          triedHang = !triedHang;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        minimumSize: Size(dynamicButtonSize, dynamicButtonSize),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: triedHang
                          ? Icon(
                              Icons.done,
                              size: dynamicIconSize,
                              color: Colors.white,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                SizedBox(height: dynamicPadding),
                // Defense section.
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Defense?",
                      style: TextStyle(fontSize: dynamicFontSize),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: dynamicPadding / 2),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          defensive = !defensive;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        minimumSize: Size(dynamicButtonSize, dynamicButtonSize),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: defensive
                          ? Icon(
                              Icons.done,
                              size: dynamicIconSize,
                              color: Colors.white,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: dynamicPadding * 2),
          // Middle Column: Grid of preset buttons wrapped in Expanded so it scrolls.
          Expanded(
            flex: 2,
            child: Expanded(
              child: GridView.builder(
                // Removed shrinkWrap and NeverScrollableScrollPhysics to allow scrolling.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: dynamicPadding,
                  mainAxisSpacing: dynamicPadding,
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: dynamicFontSize * 0.6,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: dynamicPadding * 2),
          // Right Column: Excel button with a comments text field underneath.
          Expanded(
            flex: 1,
            child: Column(
              children: [
                SizedBox(
                  height: height * 0.25,
                ),

                SizedBox(height: dynamicPadding),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize:
                        Size(dynamicExcelNotesSize, dynamicExcelNotesSize),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to Excel functionality.
                  },
                  child: Text("Capabilities",
                      style: TextStyle(fontSize: dynamicFontSize * 0.6)),
                ),
                SizedBox(height: dynamicPadding),
                // Comments text field added underneath Excel.
                TextField(
                  controller: _commentsController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: "Comments",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomNavigationBar(double scaleFactor) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.secondary,
        iconColor: Theme.of(context).colorScheme.secondary,
        minimumSize: Size(double.infinity, 60 * scaleFactor),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth >= 800;
      final double scaleFactor = isDesktop ? constraints.maxWidth / 1200 : 1.0;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          centerTitle: true,
          title: const Text(
            "Endgame Phase",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: isDesktop
            ? buildDesktopLayout(constraints)
            : buildMobileLayout(constraints),
        bottomNavigationBar: buildBottomNavigationBar(scaleFactor),
      );
    });
  }
}
