import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

class LeadScoutQuickEdit extends StatefulWidget {
  final String teamName;
  final WebSocketChannel channel;
  final WebSocketService webSocketService;

  const LeadScoutQuickEdit({
    Key? key,
    required this.teamName,
    required this.channel,
    required this.webSocketService,
  }) : super(key: key);

  @override
  _LeadScoutQuickEdit createState() => _LeadScoutQuickEdit();
}

class _LeadScoutQuickEdit extends State<LeadScoutQuickEdit> {
  late TextEditingController _robotWeightController;
  late TextEditingController _driveTypeController;
  late TextEditingController _motorTypeController;
  late TextEditingController _motorCountController;
  late TextEditingController _bumperQualityController;
  late TextEditingController _coralIntakeTypeController;
  late TextEditingController _algaeIntakeTypeController;
  late TextEditingController _climbTypeController;
  late TextEditingController _autonomousCoralPointsController;

  bool l1 = false;
  bool l2 = false;
  bool l3 = false;
  bool l4 = false;
  bool processor = false;
  bool net = false;
  bool leavesStartLine = false;

  Map<String, dynamic>? pitScoutingData;

  // Loading state
  // IF YOU WANT TO TEST THIS BUT DON'T HAVE CONNECTION TO SERVER
  // CHANGE THIS TO FALSE
  bool _isLoading = true;

  // Options for dropdowns
  final List<String> _coralIntakeOptions = [
    'Direct',
    'Funnel',
    'Ground',
    'Direct/Ground',
    'Funnel/Ground',
    'None'
  ];

  final List<String> _algaeIntakeOptions = ['Ground', 'Reef', 'Both', 'None'];

  @override
  void initState() {
    super.initState();
    _robotWeightController = TextEditingController();
    _driveTypeController = TextEditingController();
    _motorTypeController = TextEditingController();
    _motorCountController = TextEditingController();
    _bumperQualityController = TextEditingController();
    _coralIntakeTypeController = TextEditingController();
    _algaeIntakeTypeController = TextEditingController();
    _climbTypeController = TextEditingController();
    _autonomousCoralPointsController = TextEditingController();

    _fetchPitScoutingData();
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

  Future<void> _fetchPitScoutingData() async {
    // For PitScoutingData, remove 'frc' prefix if present
    final String normalizedTeamNumber =
        widget.teamName.toLowerCase().startsWith('frc')
            ? widget.teamName.substring(3)
            : widget.teamName;

    // Explicitly select all needed fields
    final sql = """
      SELECT 
        team_number, 
        robot_weight, 
        drive_type, 
        motor_type, 
        motor_count, 
        bumper_quality, 
        coral_intake_type, 
        algae_intake_type, 
        L1, 
        L2, 
        L3, 
        L4, 
        processor, 
        net, 
        climb_type, 
        autonomous_coral_points, 
        leaves_start_line
      FROM PitScoutingData
      WHERE team_number='$normalizedTeamNumber'
    """;

    final cmd = {"type": "query", "text": sql};
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

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
        debugPrint("QuickEdit PitScoutingData response: ${jsonPart}");

        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          if (rows.isNotEmpty) {
            debugPrint("QuickEdit got PitScoutingData rows: ${rows.first}");
            completer.complete(rows.first);
          } else {
            debugPrint("QuickEdit no PitScoutingData found");
            completer.complete(null);
          }
        }
      } catch (e, stackTrace) {
        debugPrint("QuickEdit error processing PitScoutingData response: $e");
        debugPrint("Stack trace: $stackTrace");
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(cmd);
    debugPrint("QuickEdit sent PitScoutingData query: $sql");

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
        debugPrint("QuickEdit raw pitScoutingData: ${jsonEncode(row)}");

        // Create a sanitized map by merging the response with defaults
        final sanitizedData = Map<String, dynamic>.from(defaultData);

        // Update the map with values from the response, with proper type conversion
        row.forEach((key, value) {
          sanitizedData[key] = value != null ? value.toString() : "";
        });

        debugPrint(
            "QuickEdit sanitized pitScoutingData: ${jsonEncode(sanitizedData)}");

        setState(() {
          pitScoutingData = sanitizedData;

          // Populate controllers with data
          _robotWeightController.text =
              safeString(sanitizedData['robot_weight']);
          _driveTypeController.text = safeString(sanitizedData['drive_type']);
          _motorTypeController.text = safeString(sanitizedData['motor_type']);
          _motorCountController.text = safeString(sanitizedData['motor_count']);
          _bumperQualityController.text =
              safeString(sanitizedData['bumper_quality']);
          _coralIntakeTypeController.text =
              safeString(sanitizedData['coral_intake_type']);
          _algaeIntakeTypeController.text =
              safeString(sanitizedData['algae_intake_type']);
          _climbTypeController.text = safeString(sanitizedData['climb_type']);
          _autonomousCoralPointsController.text =
              safeString(sanitizedData['autonomous_coral_points']);

          // Set boolean values
          l1 = safeBool(sanitizedData['L1']);
          l2 = safeBool(sanitizedData['L2']);
          l3 = safeBool(sanitizedData['L3']);
          l4 = safeBool(sanitizedData['L4']);
          processor = safeBool(sanitizedData['processor']);
          net = safeBool(sanitizedData['net']);
          leavesStartLine = safeBool(sanitizedData['leaves_start_line']);
        });
      } else {
        // Initialize with defaults if no data returned
        debugPrint("QuickEdit no data found, using defaults");
        setState(() {
          pitScoutingData = defaultData;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("QuickEdit error fetching pit scouting data: $e");
      debugPrint("Stack trace: $stackTrace");
    } finally {
      sub.cancel();
    }
  }

  /// Builds a dropdown for intake type selection
  Widget _buildIntakeDropdown({
    required String title,
    required String currentValue,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          isExpanded: true,
          value: currentValue.isNotEmpty ? currentValue : null,
          hint: const Text('Select Type'),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Builds a checkbox for boolean options
  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  /// Builds a multi-select checkbox for scoring levels
  Widget _buildScoringLevelsCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Scoring Levels',
            style: TextStyle(fontWeight: FontWeight.bold)),
        CheckboxListTile(
          title: const Text('Level 1'),
          value: l1,
          onChanged: (value) => setState(() => l1 = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Level 2'),
          value: l2,
          onChanged: (value) => setState(() => l2 = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Level 3'),
          value: l3,
          onChanged: (value) => setState(() => l3 = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Level 4'),
          value: l4,
          onChanged: (value) => setState(() => l4 = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  /// Submits the quick edit pit scouting data
  void _submitQuickEditData() {
    final sql = '''
      UPDATE PitScoutingData 
      SET 
        coral_intake_type = '$_coralIntakeTypeController.text',
        algae_intake_type = '$_algaeIntakeTypeController.text',
        L1 = '${l1 ? "true" : "false"}',
        L2 = '${l2 ? "true" : "false"}',
        L3 = '${l3 ? "true" : "false"}',
        L4 = '${l4 ? "true" : "false"}',
        processor = '${processor ? "true" : "false"}',
        net = '${net ? "true" : "false"}',
        leaves_start_line = '${leavesStartLine ? "true" : "false"}'
      WHERE team_number = '${widget.teamName}'
    ''';

    final cmd = {
      "type": "query",
      "text": sql,
    };

    try {
      // Send the WebSocket command to update the database
      widget.channel.sink
          .add('${jsonEncode(cmd).length}\r\n${jsonEncode(cmd)}');
      Navigator.of(context).pop(); // Close the dialog
    } catch (e) {
      // Handle potential errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return AlertDialog(
      title: Text('Lead Scout Quick Edit: ${widget.teamName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coral Intake Type Dropdown
            _buildIntakeDropdown(
              title: 'Coral Intake Type:',
              currentValue: _coralIntakeTypeController.text,
              options: _coralIntakeOptions,
              onChanged: (value) =>
                  setState(() => _coralIntakeTypeController.text = value!),
            ),
            const SizedBox(height: 16),

            // Algae Intake Type Dropdown
            _buildIntakeDropdown(
              title: 'Algae Intake Type:',
              currentValue: _algaeIntakeTypeController.text,
              options: _algaeIntakeOptions,
              onChanged: (value) =>
                  setState(() => _algaeIntakeTypeController.text = value!),
            ),
            const SizedBox(height: 16),

            // Scoring Levels Checkboxes
            _buildScoringLevelsCheckbox(),
            const SizedBox(height: 16),

            // Can score in processor
            _buildCheckboxTile(
              title: 'Can score in processor:',
              value: processor,
              onChanged: (value) => setState(() => processor = value!),
            ),

            // Can score into net
            _buildCheckboxTile(
              title: 'Can score into net:',
              value: net,
              onChanged: (value) => setState(() => net = value!),
            ),

            // Can robot move off of starting line during Autonomous
            _buildCheckboxTile(
              title: 'Can robot move off of starting line during Autonomous:',
              value: leavesStartLine,
              onChanged: (value) => setState(() => leavesStartLine = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitQuickEditData,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

// Usage example:
// showDialog(
//   context: context,
//   builder: (context) => LeadScoutQuickEditDialog(
//     teamName: 'TeamNumber',
//     channel: webSocketChannel,
//   ),
// );
