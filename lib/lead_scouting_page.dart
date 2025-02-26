import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

String compatibility = "";
String notableFeats = "";
String humanPlayerNetAcc = "";

class LeadScoutingPage extends StatefulWidget {
  const LeadScoutingPage({
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
  State<LeadScoutingPage> createState() => _LeadScoutingPage();
}

class _LeadScoutingPage extends State<LeadScoutingPage> {
  /// Submits the lead scouting data to the SQL server.
  /// Builds an INSERT statement targeting the LeadScoutingData table.
  Future<void> _submitLeadScoutingData() async {
    final sql = '''
      INSERT INTO LeadScoutingData (
        team_number, compatibility, notable_feats, human_player_net_acc
      )
      VALUES (
        '${widget.teamName}',
        '$compatibility',
        '$notableFeats',
        '$humanPlayerNetAcc'
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
      debugPrint('Successfully sent lead scouting INSERT command: $sql');
    } catch (e, st) {
      debugPrint('Error sending lead scouting data to DB: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.teamName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compatibility Field
            SizedBox(
              height: height * 0.3,
              width: width,
              child: Column(
                children: [
                  Container(
                    height: height * 0.05,
                    width: width,
                    alignment: Alignment.center,
                    child: const Text(
                      'Compatibility',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: null,
                      onChanged: (String value) {
                        setState(() {
                          compatibility = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Notable Feats Field
            SizedBox(
              height: height * 0.3,
              width: width,
              child: Column(
                children: [
                  Container(
                    height: height * 0.05,
                    width: width,
                    alignment: Alignment.center,
                    child: const Text(
                      'Notable Feats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: null,
                      onChanged: (String value) {
                        setState(() {
                          notableFeats = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Human Player Net ACC Field
            SizedBox(
              height: height * 0.3,
              width: width,
              child: Column(
                children: [
                  Container(
                    height: height * 0.05,
                    width: width,
                    alignment: Alignment.center,
                    child: const Text(
                      'Human Player Net ACC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: null,
                      onChanged: (String value) {
                        setState(() {
                          humanPlayerNetAcc = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () async {
          await _submitLeadScoutingData();
        },
        child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
      ),
    );
  }
}
