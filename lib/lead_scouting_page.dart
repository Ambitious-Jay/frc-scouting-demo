import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

String compatibility = "";
String notableFeats = "";
String humanPlayerNetAcc = "";

class LeadScoutingPage extends StatefulWidget {
  const LeadScoutingPage({
    super.key,
    required this.teamName, // for lead scouting, this should be the alliance (e.g., "red" or "blue")
    required this.id, // match identifier, e.g., "qm1"
    required this.channel,
    required this.onThemeChanged,
    required this.webSocketService,
  });
  final String teamName;
  final String id;
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;

  @override
  State<LeadScoutingPage> createState() => _LeadScoutingPage();
}

class _LeadScoutingPage extends State<LeadScoutingPage> {
  // Store the logged-in username.
  String _username = "";

  @override
  void initState() {
    super.initState();
    // Retrieve username from AuthService.
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });
  }

  /// Submits the lead scouting data to the SQL server.
  /// Builds an INSERT statement targeting the LeadScoutingData table.
  Future<void> _submitLeadScoutingData() async {
    final sql = '''
      INSERT INTO LeadScouting (
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
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Lead Scouting Phase",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$_username: ${widget.teamName} in Match ${widget.id}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                teamName: widget.teamName,
                // teamNickname: widget.teamNickname,
                // id: widget.id,
                channel: widget.channel, //!
                onThemeChanged: widget.onThemeChanged,
                webSocketService: widget.webSocketService,
              ),
            ),
          );
        },
        child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
      ),
    );
  }
}
