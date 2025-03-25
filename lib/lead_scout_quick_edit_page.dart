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
  // Intake Types
  String _coralIntakeType = '';
  String _algaeIntakeType = '';

  // Scoring Levels
  bool _levelOne = false;
  bool _levelTwo = false;
  bool _levelThree = false;
  bool _levelFour = false;

  // Additional Capabilities
  bool _processor = false;
  bool _net = false;
  bool _leavesStartLine = false;

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
    _fetchInitialData();
  }

  /// Fetches initial data from the server for the specified team
  Future<void> _fetchInitialData() async {
    final String teamNum = widget.teamName;
    final String sql = """
      SELECT 
        coral_intake_type, 
        algae_intake_type, 
        L1, L2, L3, L4, 
        processor, 
        net, 
        leaves_start_line
      FROM PitScoutingData
      WHERE team_number = '$teamNum'
    """;

    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };

    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          completer.complete(rows.isNotEmpty ? rows.first : null);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    try {
      final row = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      await sub.cancel();

      if (row != null) {
        setState(() {
          // Parse boolean values
          _coralIntakeType = row['coral_intake_type'] ?? '';
          _algaeIntakeType = row['algae_intake_type'] ?? '';

          _levelOne = _parseBool(row['L1']);
          _levelTwo = _parseBool(row['L2']);
          _levelThree = _parseBool(row['L3']);
          _levelFour = _parseBool(row['L4']);

          _processor = _parseBool(row['processor']);
          _net = _parseBool(row['net']);
          _leavesStartLine = _parseBool(row['leaves_start_line']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Helper method to parse boolean values from database
  bool _parseBool(dynamic val) {
    if (val == null) return false;
    final str = val.toString().toLowerCase();
    return (str == "true" || str == "1" || str == "yes");
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
          value: _levelOne,
          onChanged: (value) => setState(() => _levelOne = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Level 2'),
          value: _levelTwo,
          onChanged: (value) => setState(() => _levelTwo = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Level 3'),
          value: _levelThree,
          onChanged: (value) => setState(() => _levelThree = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Level 4'),
          value: _levelFour,
          onChanged: (value) => setState(() => _levelFour = value!),
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
        coral_intake_type = '$_coralIntakeType',
        algae_intake_type = '$_algaeIntakeType',
        L1 = '${_levelOne ? "true" : "false"}',
        L2 = '${_levelTwo ? "true" : "false"}',
        L3 = '${_levelThree ? "true" : "false"}',
        L4 = '${_levelFour ? "true" : "false"}',
        processor = '${_processor ? "true" : "false"}',
        net = '${_net ? "true" : "false"}',
        leaves_start_line = '${_leavesStartLine ? "true" : "false"}'
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
              currentValue: _coralIntakeType,
              options: _coralIntakeOptions,
              onChanged: (value) => setState(() => _coralIntakeType = value!),
            ),
            const SizedBox(height: 16),

            // Algae Intake Type Dropdown
            _buildIntakeDropdown(
              title: 'Algae Intake Type:',
              currentValue: _algaeIntakeType,
              options: _algaeIntakeOptions,
              onChanged: (value) => setState(() => _algaeIntakeType = value!),
            ),
            const SizedBox(height: 16),

            // Scoring Levels Checkboxes
            _buildScoringLevelsCheckbox(),
            const SizedBox(height: 16),

            // Can score in processor
            _buildCheckboxTile(
              title: 'Can score in processor:',
              value: _processor,
              onChanged: (value) => setState(() => _processor = value!),
            ),

            // Can score into net
            _buildCheckboxTile(
              title: 'Can score into net:',
              value: _net,
              onChanged: (value) => setState(() => _net = value!),
            ),

            // Can robot move off of starting line during Autonomous
            _buildCheckboxTile(
              title: 'Can robot move off of starting line during Autonomous:',
              value: _leavesStartLine,
              onChanged: (value) => setState(() => _leavesStartLine = value!),
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
