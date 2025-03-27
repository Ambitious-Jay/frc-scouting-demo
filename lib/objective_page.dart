import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/endgame.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class IntegerWrapper {
  int value = 0;
  IntegerWrapper(this.value);
}

class ObjectivePage extends StatefulWidget {
  const ObjectivePage({
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
  _ObjectivePageState createState() => _ObjectivePageState();
}

class _ObjectivePageState extends State<ObjectivePage> {
  ThemeMode themeMode = ThemeMode.system;
  String _username = "";
  bool isBlue = true;

  IntegerWrapper l4Counter = IntegerWrapper(0);
  IntegerWrapper l2l3Counter = IntegerWrapper(0);
  IntegerWrapper l1Counter = IntegerWrapper(0);
  IntegerWrapper netCounter = IntegerWrapper(0);
  IntegerWrapper processorCounter = IntegerWrapper(0);

  bool doIncrement = true;
  Map<String, dynamic>? pitScoutingData;
  bool _isLoading = true;

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

  Future<void> _submitObjectiveScoutingData() async {
    final String teamNumberWithPrefix =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName
            : 'frc${widget.teamName}';

    final sql = '''
      INSERT INTO MatchData (
        team_number, match_number, l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter
      )
      VALUES (
        '${teamNumberWithPrefix}', '${widget.matchNumber}',
        ${l4Counter.value}, ${l2l3Counter.value}, ${l1Counter.value},
        ${netCounter.value}, ${processorCounter.value}
      )
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
    debugPrint('Sent objective scouting INSERT command: $sql');

    try {
      // Wait for response with timeout
      final success = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (success) {
        debugPrint(
            'Successfully submitted objective scouting data for ${widget.teamName}');
      } else {
        debugPrint(
            'Timeout or error submitting objective scouting data for ${widget.teamName}');
      }
    } catch (e) {
      debugPrint('Error submitting objective scouting data: $e');
    } finally {
      sub.cancel();
    }
  }

  // NEW: Method to fetch pit scouting data
  Future<void> _fetchPitScoutingData() async {
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

        // Guard against empty or "null" responses
        if (jsonPart.trim().isEmpty || jsonPart.trim() == "null") {
          return;
        }

        if (jsonPart.length != len) return;

        // Extra validation to prevent format errors
        try {
          final Map<String, dynamic> msg = jsonDecode(jsonPart);
          if (msg["type"] == "query") {
            final List<dynamic> rows = msg["rows"];
            if (rows.isNotEmpty) {
              debugPrint(
                  "Received pit scouting data: ${jsonEncode(rows.first)}");
              completer.complete(rows.first);
            } else {
              completer.complete(null);
            }
          }
        } catch (e) {
          debugPrint("Error processing pit scouting data JSON: $e");
          completer.completeError(e);
        }
      } catch (e) {
        debugPrint("Error parsing WebSocket message: $e");
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(cmd);

    try {
      final row = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      // Create default data map
      final Map<String, dynamic> defaultData = {
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

      if (row != null) {
        // Create a sanitized map by merging the response with defaults
        final sanitizedData = Map<String, dynamic>.from(defaultData);

        // Update with values from the response, with proper type conversion
        row.forEach((key, value) {
          sanitizedData[key] = value;
        });

        if (mounted) {
          setState(() {
            pitScoutingData = sanitizedData;
            debugPrint(
                "Updated pit scouting data in state: ${jsonEncode(sanitizedData)}");
          });
        }
      } else {
        debugPrint("No pit scouting data found, using defaults");
        if (mounted) {
          setState(() {
            pitScoutingData = defaultData;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching pit scouting data: $e");
      // Initialize with defaults on error
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

  // NEW: Method to save capabilities data to the database
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

  // NEW: Method to show capabilities edit dialog
  void _showCapabilitiesEditDialog() {
    // Make sure we use the already fetched pit scouting data
    debugPrint(
        "Opening capabilities dialog with existing data: ${pitScoutingData != null ? 'data available' : 'no data'}");

    // If no pit data is available (shouldn't happen since we load at init), use empty defaults
    final Map<String, dynamic> dataToUse = pitScoutingData ??
        {
          'team_number': widget.teamName,
          'robot_weight': "",
          'drive_type': "",
          'motor_type': "",
          'motor_count': 0,
          'bumper_quality': 0,
          'coral_intake_type': "",
          'algae_intake_type': "",
          'L1': false,
          'L2': false,
          'L3': false,
          'L4': false,
          'processor': false,
          'net': false,
          'climb_type': "",
          'autonomous_coral_points': 0,
          'leaves_start_line': false
        };

    // Create controllers with the data
    final robotWeightController =
        TextEditingController(text: safeString(dataToUse['robot_weight']));
    final driveTypeController =
        TextEditingController(text: safeString(dataToUse['drive_type']));
    final motorTypeController =
        TextEditingController(text: safeString(dataToUse['motor_type']));
    final motorCountController =
        TextEditingController(text: safeString(dataToUse['motor_count']));
    final bumperQualityController =
        TextEditingController(text: safeString(dataToUse['bumper_quality']));
    final coralIntakeTypeController =
        TextEditingController(text: safeString(dataToUse['coral_intake_type']));
    final algaeIntakeTypeController =
        TextEditingController(text: safeString(dataToUse['algae_intake_type']));
    final climbTypeController =
        TextEditingController(text: safeString(dataToUse['climb_type']));
    final autonomousCoralPointsController = TextEditingController(
        text: safeString(dataToUse['autonomous_coral_points']));

    // Set boolean values directly from the data
    bool l1Capability = safeBool(dataToUse['L1']);
    bool l2Capability = safeBool(dataToUse['L2']);
    bool l3Capability = safeBool(dataToUse['L3']);
    bool l4Capability = safeBool(dataToUse['L4']);
    bool processorCapability = safeBool(dataToUse['processor']);
    bool netCapability = safeBool(dataToUse['net']);
    bool leavesStartLineCapability = safeBool(dataToUse['leaves_start_line']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        setState(() => l1Capability = value!);
                      }),
                      _buildDialogCheckbox("L2 Capability", l2Capability,
                          (value) {
                        setState(() => l2Capability = value!);
                      }),
                      _buildDialogCheckbox("L3 Capability", l3Capability,
                          (value) {
                        setState(() => l3Capability = value!);
                      }),
                      _buildDialogCheckbox("L4 Capability", l4Capability,
                          (value) {
                        setState(() => l4Capability = value!);
                      }),
                      _buildDialogCheckbox("Processor", processorCapability,
                          (value) {
                        setState(() => processorCapability = value!);
                      }),
                      _buildDialogCheckbox("Net", netCapability, (value) {
                        setState(() => netCapability = value!);
                      }),
                      _buildDialogCheckbox(
                          "Leaves Start Line", leavesStartLineCapability,
                          (value) {
                        setState(() => leavesStartLineCapability = value!);
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
                            onPressed: () {
                              // Save the edited data
                              _saveCapabilitiesData(
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
      _fetchPitScoutingData();
    });
  }

  // NEW: Helper methods for dialog building
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

  // NEW: Helper functions for safe type conversion
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

  // NEW: Load all data
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Only fetch pit scouting data if the user is a lead scout
      if (widget.isLeadScout) {
        // Fetch pit scouting data
        await _fetchPitScoutingData();
        debugPrint("All data loaded. Pit data: ${jsonEncode(pitScoutingData)}");
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // End loading
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });

    // Load all data once when the page is initialized
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Column(
          children: [
            const Text("Objective Phase"),
            Text(
              '$_username: Team ${widget.teamName} in match ${widget.matchNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
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
                await _submitObjectiveScoutingData();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Endgame(
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
        label: const Text('Submit'),
      ),
    );
  }

  Widget buildMatchScoutLayout(BoxConstraints constraints) {
    final double screenWidth = MediaQuery.of(context).size.width;
    AssetImage reefImg = const AssetImage('assets/reef.png');

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
    double availableWidth = MediaQuery.of(context).size.width - 24;
    double fieldWidth = min(availableWidth, 400);
    double fieldHeight = fieldWidth;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Left side: Reef image with counters
                    Row(
                      children: [
                        SizedBox(
                          width: fieldWidth / 2,
                          height: fieldHeight / 2,
                          child: Image(
                            image: AssetImage('assets/reef.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildCounterButton(
                                "L4", l4Counter, doIncrement, 80),
                            const SizedBox(height: 20),
                            buildCounterButton(
                                "L2 & L3", l2l3Counter, doIncrement, 80),
                            const SizedBox(height: 20),
                            buildCounterButton(
                                "L1", l1Counter, doIncrement, 80),
                          ],
                        ),
                      ],
                    ),

                    // Right side: Net/Processor counters and +/- button
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
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
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
                  ],
                ),

                // Add the Capabilities button only for lead scouts
                if (widget.isLeadScout) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(150, 100),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: () {
                      // Check if pit data is properly loaded by looking for specific fields
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
                          // Check if data was successfully loaded
                          if (mounted) {
                            Navigator.of(context).pop(); // Close loading dialog

                            // Double check data was actually loaded
                            if (pitScoutingData != null &&
                                pitScoutingData!.containsKey('robot_weight')) {
                              _showCapabilitiesEditDialog();
                            } else {
                              // Show error if data still not loaded
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Error loading data. Please try again.")),
                              );
                            }
                          }
                        });
                      } else {
                        // Data is already properly loaded, show dialog directly
                        _showCapabilitiesEditDialog();
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.edit_attributes, size: 36),
                        SizedBox(height: 8),
                        Text("Capabilities", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
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
}
