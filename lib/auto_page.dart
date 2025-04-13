import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/lead_scout_quick_edit_page.dart';
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
    // For AutoScouting data, we need to add 'frc' prefix if not present
    final String teamNumberWithPrefix =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName
            : 'frc${widget.teamName}';

    final sql = '''
      MERGE AutoScouting AS target
      USING (
        SELECT 
          '${teamNumberWithPrefix}' AS team_number, 
          '${widget.matchNumber}' AS match_number, 
          '${startPos ?? ""}' AS start_position, 
          ${l4Counter.value} AS l4_count, 
          ${l2l3Counter.value} AS l2_l3_count, 
          ${l1Counter.value} AS l1_count,
          ${netCounter.value} AS net_count, 
          ${processorCounter.value} AS processor_count,
          ${inCenterZone ? 1 : 0} AS in_center_zone, 
          ${inLeftZone ? 1 : 0} AS in_left_zone, 
          ${inRightZone ? 1 : 0} AS in_right_zone,
          ${isBlue ? 1 : 0} AS is_blue, 
          ${fieldFlipped ? 1 : 0} AS field_flipped
      ) AS source
      ON (target.team_number = source.team_number AND target.match_number = source.match_number)
      WHEN MATCHED THEN
        UPDATE SET
          start_position = source.start_position,
          l4_count = source.l4_count,
          l2_l3_count = source.l2_l3_count,
          l1_count = source.l1_count,
          net_count = source.net_count,
          processor_count = source.processor_count,
          in_center_zone = source.in_center_zone,
          in_left_zone = source.in_left_zone,
          in_right_zone = source.in_right_zone,
          is_blue = source.is_blue,
          field_flipped = source.field_flipped
      WHEN NOT MATCHED THEN
        INSERT (
          team_number, match_number, start_position, l4_count, l2_l3_count, l1_count,
          net_count, processor_count, in_center_zone, in_left_zone, in_right_zone, is_blue, field_flipped
        )
        VALUES (
          source.team_number, source.match_number, source.start_position, source.l4_count, source.l2_l3_count, source.l1_count,
          source.net_count, source.processor_count, source.in_center_zone, source.in_left_zone, source.in_right_zone, source.is_blue, source.field_flipped
        );
    ''';

    final cmd = {"type": "query", "text": sql};

    // Create a completer to handle the response
    final completer = Completer<bool>();
    late StreamSubscription sub;

    // Set up a listener for the response
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
          // Successfully received response for the query
          completer.complete(true);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    // Send the command
    widget.webSocketService.sendLengthPrefixed(cmd);
    debugPrint('Sent auto scouting MERGE command: $sql');

    try {
      // Wait for response with timeout
      final success = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (success) {
        debugPrint(
            'Successfully submitted auto scouting data for ${widget.teamName}');
      } else {
        debugPrint(
            'Timeout or error submitting auto scouting data for ${widget.teamName}');
      }
    } catch (e) {
      debugPrint('Error submitting auto scouting data: $e');
    } finally {
      sub.cancel();
    }
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
    // Get the current text from the controller
    final String currentNotes = _notesController.text.trim();

    // Update the state variable to ensure it matches what the user entered
    _notesValue = currentNotes;

    // Escape single quotes in notes to prevent SQL injection
    final String escapedNotes = currentNotes.replaceAll("'", "''");

    debugPrint("Submitting notes: '$currentNotes'");

    // Add 'frc' prefix to team number for LeadScoutingData table
    final String teamNumberWithPrefix =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName
            : 'frc${widget.teamName}';

    final sql = '''
    MERGE LeadScoutingData AS target
    USING (SELECT '$teamNumberWithPrefix' AS team_number, '$escapedNotes' AS notes) AS source
    ON (target.team_number = source.team_number)
    WHEN MATCHED THEN
      UPDATE SET notes = source.notes
    WHEN NOT MATCHED THEN
      INSERT (team_number, notes)
      VALUES (source.team_number, source.notes);
    ''';

    final cmd = {"type": "query", "text": sql};

    // Create a completer to handle the response
    final completer = Completer<bool>();
    late StreamSubscription sub;

    // Set up a listener for the response
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
          // Successfully received response for the query
          completer.complete(true);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    // Send the command
    widget.webSocketService.sendLengthPrefixed(cmd);
    debugPrint('Sent lead scouting notes MERGE command: $sql');

    try {
      // Wait for response with timeout
      final success = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (success) {
        debugPrint(
            'Successfully submitted lead scouting notes for ${widget.teamName}');
      } else {
        debugPrint(
            'Timeout or error submitting lead scouting notes for ${widget.teamName}');
      }
    } catch (e) {
      debugPrint('Error submitting lead scouting notes: $e');
    } finally {
      sub.cancel();
    }
  }

  Future<void> _submitPitScoutingData() async {
    // For PitScoutingData, remove 'frc' prefix if present
    final String normalizedTeamNumber =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName.substring(3)
            : widget.teamName;

    // Helper functions for safe type conversion
    String safeString(dynamic value) => value != null ? value.toString() : "";
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    final sql = '''
  MERGE PitScoutingData AS target
  USING (SELECT
    '$normalizedTeamNumber' AS team_number,
      '${safeString(pitScoutingData?['robot_weight'])}' AS robot_weight,
      '${safeString(pitScoutingData?['drive_type'])}' AS drive_type,
      '${safeString(pitScoutingData?['motor_type'])}' AS motor_type,
      ${safeInt(pitScoutingData?['motor_count'])} AS motor_count,
      ${safeInt(pitScoutingData?['bumper_quality'])} AS bumper_quality,
      '${safeString(pitScoutingData?['coral_intake_type'])}' AS coral_intake_type,
      '${safeString(pitScoutingData?['algae_intake_type'])}' AS algae_intake_type,
      '${safeString(pitScoutingData?['L1'])}' AS L1,
      '${safeString(pitScoutingData?['L2'])}' AS L2,
      '${safeString(pitScoutingData?['L3'])}' AS L3,
      '${safeString(pitScoutingData?['L4'])}' AS L4,
      '${safeString(pitScoutingData?['processor'])}' AS processor,
      '${safeString(pitScoutingData?['net'])}' AS net,
      '${safeString(pitScoutingData?['climb_type'])}' AS climb_type,
      ${safeInt(pitScoutingData?['autonomous_coral_points'])} AS autonomous_coral_points,
      '${safeString(pitScoutingData?['leaves_start_line'])}' AS leaves_start_line
  ) AS source
  ON (target.team_number = source.team_number)
  WHEN MATCHED THEN
    UPDATE SET
      robot_weight = source.robot_weight,
      drive_type = source.drive_type,
      motor_type = source.motor_type,
      motor_count = source.motor_count,
      bumper_quality = source.bumper_quality,
      coral_intake_type = source.coral_intake_type,
      algae_intake_type = source.algae_intake_type,
      L1 = source.L1,
      L2 = source.L2,
      L3 = source.L3,
      L4 = source.L4,
      processor = source.processor,
      net = source.net,
      climb_type = source.climb_type,
      autonomous_coral_points = source.autonomous_coral_points,
      leaves_start_line = source.leaves_start_line
  WHEN NOT MATCHED THEN
    INSERT (team_number, robot_weight, drive_type, motor_type, motor_count, bumper_quality, coral_intake_type, algae_intake_type, L1, L2, L3, L4, processor, net, climb_type, autonomous_coral_points, leaves_start_line)
    VALUES (source.team_number, source.robot_weight, source.drive_type, source.motor_type, source.motor_count, source.bumper_quality, source.coral_intake_type, source.algae_intake_type, source.L1, source.L2, source.L3, source.L4, source.processor, source.net, source.climb_type, source.autonomous_coral_points, source.leaves_start_line);
    ''';

    final cmd = {"type": "query", "text": sql};

    // Create a completer to handle the response
    final completer = Completer<bool>();
    late StreamSubscription sub;

    // Set up a listener for the response
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
          // Successfully received response for the query
          completer.complete(true);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    // Send the command
    widget.webSocketService.sendLengthPrefixed(cmd);
    debugPrint('Sent pit scouting MERGE command: $sql');

    try {
      // Wait for response with timeout
      final success = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (success) {
        debugPrint(
            'Successfully submitted pit scouting data for ${widget.teamName}');
      } else {
        debugPrint(
            'Timeout or error submitting pit scouting data for ${widget.teamName}');
      }
    } catch (e) {
      debugPrint('Error submitting pit scouting data: $e');
    } finally {
      sub.cancel();
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
                      left: (fieldFlipped ? 1 : 7) * fieldWidth / 8 - 40,
                      top: fieldHeight / 4,
                      child: SizedBox(
                        width: 120,
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
              width: 120,
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
                          style: TextStyle(fontSize: 14, color: Colors.black)),
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
                          style: TextStyle(fontSize: 14, color: Colors.black)),
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
                          style: TextStyle(fontSize: 14, color: Colors.black)),
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
                                    _showCapabilitiesEditDialog();
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
                              _showCapabilitiesEditDialog();
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

  // Method to show capabilities edit dialog
  void _showCapabilitiesEditDialog() {
    // Make sure we use the already fetched pit scouting data
    debugPrint(
        "Opening capabilities dialog with existing data: ${pitScoutingData != null ? 'data available' : 'no data'}");

    // If no pit data is available, show loading dialog and try to fetch
    if (pitScoutingData == null) {
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

      // Try to fetch the data
      _fetchPitScoutingData().then((_) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          if (pitScoutingData != null) {
            // Force a rebuild of the dialog with the new data
            setState(() {}); // Trigger a rebuild of the parent widget
            _showCapabilitiesEditDialog(); // Recursively show dialog with data
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Error loading data. Please try again."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
      return;
    }

    // Create controllers with the data
    final robotWeightController = TextEditingController(
        text: safeString(pitScoutingData!['robot_weight']));
    final driveTypeController =
        TextEditingController(text: safeString(pitScoutingData!['drive_type']));
    final motorTypeController =
        TextEditingController(text: safeString(pitScoutingData!['motor_type']));
    final motorCountController = TextEditingController(
        text: safeString(pitScoutingData!['motor_count']));
    final bumperQualityController = TextEditingController(
        text: safeString(pitScoutingData!['bumper_quality']));
    final coralIntakeTypeController = TextEditingController(
        text: safeString(pitScoutingData!['coral_intake_type']));
    final algaeIntakeTypeController = TextEditingController(
        text: safeString(pitScoutingData!['algae_intake_type']));
    final climbTypeController =
        TextEditingController(text: safeString(pitScoutingData!['climb_type']));
    final autonomousCoralPointsController = TextEditingController(
        text: safeString(pitScoutingData!['autonomous_coral_points']));

    // Set boolean values directly from the data
    bool l1Capability = safeBool(pitScoutingData!['L1']);
    bool l2Capability = safeBool(pitScoutingData!['L2']);
    bool l3Capability = safeBool(pitScoutingData!['L3']);
    bool l4Capability = safeBool(pitScoutingData!['L4']);
    bool processorCapability = safeBool(pitScoutingData!['processor']);
    bool netCapability = safeBool(pitScoutingData!['net']);
    bool leavesStartLineCapability =
        safeBool(pitScoutingData!['leaves_start_line']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Edit Team ${widget.teamName} Capabilities",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Text inputs for string and numeric fields
                      _buildDialogTextField(
                          robotWeightController, "Robot Weight"),
                      _buildDialogTextField(driveTypeController, "Drive Type"),
                      _buildDialogTextField(motorTypeController, "Motor Type"),
                      _buildDialogTextField(motorCountController, "Motor Count",
                          isNumeric: true),
                      _buildDialogTextField(
                          bumperQualityController, "Bumper Quality (1-10)",
                          isNumeric: true),
                      _buildDialogTextField(
                          coralIntakeTypeController, "Coral Intake Type"),
                      _buildDialogTextField(
                          algaeIntakeTypeController, "Algae Intake Type"),
                      _buildDialogTextField(climbTypeController, "Climb Type"),
                      _buildDialogTextField(
                          autonomousCoralPointsController, "Auto Coral Points",
                          isNumeric: true),

                      const Divider(height: 20),

                      // Checkboxes for boolean fields
                      _buildDialogCheckbox("L1 Capability", l1Capability,
                          (value) {
                        setDialogState(() => l1Capability = value!);
                      }),
                      _buildDialogCheckbox("L2 Capability", l2Capability,
                          (value) {
                        setDialogState(() => l2Capability = value!);
                      }),
                      _buildDialogCheckbox("L3 Capability", l3Capability,
                          (value) {
                        setDialogState(() => l3Capability = value!);
                      }),
                      _buildDialogCheckbox("L4 Capability", l4Capability,
                          (value) {
                        setDialogState(() => l4Capability = value!);
                      }),
                      _buildDialogCheckbox("Processor", processorCapability,
                          (value) {
                        setDialogState(() => processorCapability = value!);
                      }),
                      _buildDialogCheckbox("Net", netCapability, (value) {
                        setDialogState(() => netCapability = value!);
                      }),
                      _buildDialogCheckbox(
                          "Leaves Start Line", leavesStartLineCapability,
                          (value) {
                        setDialogState(
                            () => leavesStartLineCapability = value!);
                      }),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Save the edited data
                              await _saveCapabilitiesData(
                                  robotWeightController.text,
                                  driveTypeController.text,
                                  motorTypeController.text,
                                  motorCountController.text,
                                  bumperQualityController.text,
                                  coralIntakeTypeController.text,
                                  algaeIntakeTypeController.text,
                                  climbTypeController.text,
                                  autonomousCoralPointsController.text,
                                  l1Capability,
                                  l2Capability,
                                  l3Capability,
                                  l4Capability,
                                  processorCapability,
                                  netCapability,
                                  leavesStartLineCapability);

                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Capabilities saved successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // After dialog is closed, refresh the pit scouting data to reflect any changes
      _fetchPitScoutingData().then((_) {
        if (mounted) {
          setState(() {}); // Force a rebuild of the parent widget
        }
      });
    });
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
    // For PitScoutingData, remove 'frc' prefix if present
    final String normalizedTeamNumber =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName.substring(3)
            : widget.teamName;

    final sql = '''
    MERGE PitScoutingData AS target
    USING (SELECT
      '$normalizedTeamNumber' AS team_number,
      '$robotWeight' AS robot_weight,
      '$driveType' AS drive_type,
      '$motorType' AS motor_type,
      ${safeInt(motorCount)} AS motor_count,
      ${safeInt(bumperQuality)} AS bumper_quality,
      '$coralIntakeType' AS coral_intake_type,
      '$algaeIntakeType' AS algae_intake_type,
      '${l1.toString()}' AS L1,
      '${l2.toString()}' AS L2,
      '${l3.toString()}' AS L3,
      '${l4.toString()}' AS L4,
      '${processor.toString()}' AS processor,
      '${net.toString()}' AS net,
      '$climbType' AS climb_type,
      ${safeInt(autonomousCoralPoints)} AS autonomous_coral_points,
      '${leavesStartLine.toString()}' AS leaves_start_line
    ) AS source
    ON (target.team_number = source.team_number)
    WHEN MATCHED THEN
      UPDATE SET
        robot_weight = source.robot_weight,
        drive_type = source.drive_type,
        motor_type = source.motor_type,
        motor_count = source.motor_count,
        bumper_quality = source.bumper_quality,
        coral_intake_type = source.coral_intake_type,
        algae_intake_type = source.algae_intake_type,
        L1 = source.L1,
        L2 = source.L2,
        L3 = source.L3,
        L4 = source.L4,
        processor = source.processor,
        net = source.net,
        climb_type = source.climb_type,
        autonomous_coral_points = source.autonomous_coral_points,
        leaves_start_line = source.leaves_start_line
    WHEN NOT MATCHED THEN
      INSERT (team_number, robot_weight, drive_type, motor_type, motor_count, bumper_quality, coral_intake_type, algae_intake_type, L1, L2, L3, L4, processor, net, climb_type, autonomous_coral_points, leaves_start_line)
      VALUES (source.team_number, source.robot_weight, source.drive_type, source.motor_type, source.motor_count, source.bumper_quality, source.coral_intake_type, source.algae_intake_type, source.L1, source.L2, source.L3, source.L4, source.processor, source.net, source.climb_type, source.autonomous_coral_points, source.leaves_start_line);
    ''';

    final cmd = {"type": "query", "text": sql};

    // Create a completer to handle the response
    final completer = Completer<bool>();
    late StreamSubscription sub;

    // Set up a listener for the response
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
          // Successfully received response for the query
          completer.complete(true);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    // Send the command
    widget.webSocketService.sendLengthPrefixed(cmd);
    debugPrint('Sent pit scouting MERGE command: $sql');

    try {
      // Wait for response with timeout
      final success = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (success) {
        debugPrint(
            'Successfully submitted pit scouting data for ${widget.teamName}');
      } else {
        debugPrint(
            'Timeout or error submitting pit scouting data for ${widget.teamName}');
      }
    } catch (e) {
      debugPrint('Error submitting pit scouting data: $e');
    } finally {
      sub.cancel();
    }
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
