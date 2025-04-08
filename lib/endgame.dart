import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/lead_scout_quick_edit_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Global variables for endgame presets
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
  final bool isLeadScout; // New parameter
  final String matchNumber;
  final String teamNickname;

  const Endgame({
    Key? key,
    required this.teamName,
    required this.channel,
    required this.onThemeChanged,
    required this.webSocketService,
    required this.isLeadScout,
    required this.matchNumber,
    required this.teamNickname,
  }) : super(key: key);

  @override
  State<Endgame> createState() => _Endgame();
}

class _Endgame extends State<Endgame> {
  late final TextEditingController _commentsController;
  String _notesValue = "";
  bool _isLoading = false;
  Map<String, dynamic>? pitScoutingData;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();

    // Load all data when the page is initialized
    if (widget.isLeadScout) {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
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

  // Method to load all data and track loading state
  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Only fetch data if the user is a lead scout
      if (widget.isLeadScout) {
        // Fetch lead scouting notes first to make sure it completes
        await _fetchLeadScoutingNotes();

        // Then fetch pit scouting data
        await _fetchPitScoutingData();

        // Force a rebuild to ensure the UI reflects the loaded data
        if (mounted) {
          setState(() {
            // Ensure controller text is updated with fetched notes
            if (_notesValue.isNotEmpty &&
                _commentsController.text != _notesValue) {
              _commentsController.text = _notesValue;
            }
          });
        }

        debugPrint(
            "All data loaded. Notes: '$_notesValue', Controller: '${_commentsController.text}'");
      }
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

  Future<void> _fetchLeadScoutingNotes() async {
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
            _commentsController.text = notes;
          });
        }
      } else {
        debugPrint("No lead scouting notes found for team ${widget.teamName}");
        // Set to empty string if no notes found
        if (mounted) {
          setState(() {
            _notesValue = "";
            _commentsController.text = "";
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
    final String currentNotes = _commentsController.text.trim();

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

  // Method to save capabilities data to the database
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

        // Update the local state to reflect changes
        if (mounted) {
          setState(() {
            pitScoutingData = {
              'team_number': normalizedTeamNumber,
              'robot_weight': robotWeight,
              'drive_type': driveType,
              'motor_type': motorType,
              'motor_count': safeInt(motorCount),
              'bumper_quality': safeInt(bumperQuality),
              'coral_intake_type': coralIntakeType,
              'algae_intake_type': algaeIntakeType,
              'L1': l1.toString(),
              'L2': l2.toString(),
              'L3': l3.toString(),
              'L4': l4.toString(),
              'processor': processor.toString(),
              'net': net.toString(),
              'climb_type': climbType,
              'autonomous_coral_points': safeInt(autonomousCoralPoints),
              'leaves_start_line': leavesStartLine.toString()
            };
          });
        }
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

  Future<void> _submitEndgameData() async {
    final sql = '''
MERGE EndgameData AS target
USING (
  SELECT
    '${widget.teamName}' AS team_number,
    '${widget.matchNumber}' AS match_number,
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
  INSERT (team_number, match_number, attempt_to_park, defense, mechanism_broke, stopped_moving, fast, good_driving, bad_driving,
          tippy, not_tippy, consistent_coral, inaccurate_coral, good_defense, bad_defense, jams_often, fast_climb,
          slow_climb, consistent_auton, inconsistent_auton, net_algae)
  VALUES (source.team_number, source.match_number, source.attempt_to_park, source.defense, source.mechanism_broke, source.stopped_moving,
          source.fast, source.good_driving, source.bad_driving, source.tippy, source.not_tippy, source.consistent_coral,
          source.inaccurate_coral, source.good_defense, source.bad_defense, source.jams_often, source.fast_climb,
          source.slow_climb, source.consistent_auton, source.inconsistent_auton, source.net_algae);
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
    debugPrint('Sent endgame MERGE command: $sql');

    try {
      // Wait for response with timeout
      final success = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (success) {
        debugPrint(
            'Successfully submitted endgame data for ${widget.teamName}');
      } else {
        debugPrint(
            'Timeout or error submitting endgame data for ${widget.teamName}');
      }
    } catch (e) {
      debugPrint('Error submitting endgame data: $e');
    } finally {
      sub.cancel();
    }
  }

  // --- Lead scout layout for Endgame ---
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
          // Left column: Attempt to park and Defense
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
          // Middle column: Preset grid
          Expanded(
            flex: 2,
            child: GridView.builder(
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
          SizedBox(width: dynamicPadding * 2),
          // Right column: Capabilities button and Notes field - only for lead scouts
          Expanded(
            flex: 1,
            child: widget.isLeadScout
                ? Column(
                    children: [
                      SizedBox(height: height * 0.25),
                      SizedBox(height: dynamicPadding),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          minimumSize: Size(
                              dynamicExcelNotesSize, dynamicExcelNotesSize),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null // Disable button while loading
                            : () {
                                // Check if pit data is properly loaded
                                bool isDataComplete = pitScoutingData != null &&
                                    pitScoutingData!
                                        .containsKey('robot_weight') &&
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
                                              Text(
                                                  "Loading capabilities data..."),
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                              size: dynamicFontSize * 0.8,
                              color: _isLoading
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: dynamicPadding / 2),
                            Text(
                              "Capabilities",
                              style: TextStyle(
                                fontSize: dynamicFontSize * 0.6,
                                color: _isLoading ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: dynamicPadding),
                      TextField(
                        controller: _commentsController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: "Notes",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  )
                : Container(), // Empty container if not a lead scout
          ),
        ],
      ),
    );
  }

  // For match scout mode, use a simpler (mobile) layout
  Widget buildMatchScoutEndgameLayout() {
    // Reuse the mobile layout defined below
    return buildMobileLayout(BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
      maxHeight: MediaQuery.of(context).size.height,
    ));
  }

  // Mobile layout for Endgame (match scout layout)
  Widget buildMobileLayout(BoxConstraints constraints) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Center(
      child: ListView(
        children: [
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
      onPressed: _isLoading
          ? null // Disable the button while loading
          : () async {
              // Always submit endgame data
              await _submitEndgameData();

              // Only submit lead scouting notes if the user is a lead scout
              if (widget.isLeadScout) {
                await _submitLeadScoutingNotes();
              }

              // Reset state before navigating
              _resetState();

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
      label: const Text('Next'),
    );
  }

  // Method to reset all state variables
  void _resetState() {
    // Reset global variables
    triedHang = false;
    defensive = false;

    // Reset all preset values
    for (String key in presets.keys) {
      presets[key] = false;
    }

    // Clear text field
    _commentsController.clear();
    _notesValue = "";

    // Reset any other state variables if needed
    if (mounted) {
      setState(() {
        // Any state variables managed by setState should be reset here
      });
    }
  }

  // Also override the didUpdateWidget method to update the controller when needed
  @override
  void didUpdateWidget(Endgame oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the text field if _notesValue changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_commentsController.text != _notesValue) {
        _commentsController.text = _notesValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLeadScout) {
      // Use the full desktop/mobile layout for lead scout mode
      return LayoutBuilder(builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 800;
        final double scaleFactor =
            isDesktop ? constraints.maxWidth / 1200 : 1.0;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            centerTitle: true,
            title: const Text("Endgame Phase",
                style: TextStyle(fontWeight: FontWeight.bold)),
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
              : isDesktop
                  ? buildDesktopLayout(constraints)
                  : buildMobileLayout(constraints),
          bottomNavigationBar: buildBottomNavigationBar(scaleFactor),
        );
      });
    } else {
      // Match scout mode: always show the simpler mobile layout
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          centerTitle: true,
          title: const Text("Endgame Phase",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: buildMatchScoutEndgameLayout(),
        bottomNavigationBar: buildBottomNavigationBar(1.0),
      );
    }
  }
}
