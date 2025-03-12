import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:frc1148_2025_scouting_app/info_page.dart';
import 'package:frc1148_2025_scouting_app/lead_scouting_page.dart';
import 'package:frc1148_2025_scouting_app/pit_scouting_page.dart';
import 'package:frc1148_2025_scouting_app/scout_match_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'login_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';

class DashboardPage extends StatefulWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;
  final String teamName; // may be used for pit scouting

  const DashboardPage({
    Key? key,
    required this.webSocketService,
    required this.onThemeChanged,
    required this.teamName,
    WebSocketChannel? channel,
  }) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _teamController = TextEditingController();

  Future<String> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Unknown';
  }

  /// Determines if the user is a lead scout.
  /// (For example, if the username contains '%')
  Future<bool> isLeadScout() async {
    final username = await _getUsername();
    return username.contains('%');
  }

  /// Checks if the team has already been pit-scouted.
  /// Returns true if a record exists.
  Future<bool> _teamAlreadyPitScouted(String teamNumber) async {
    // Build query to check if the team has been pitscouted.
    final String sql =
        "SELECT TOP 1 team_number FROM PitScoutingData WHERE team_number = '$teamNumber'";
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };

    // We'll use a completer to wait for a one‑off response.
    final completer = Completer<bool>();

    // Create a one‑time subscription to the WebSocket stream.
    final subscription = widget.webSocketService.stream?.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return; // invalid message
        final String lenStr = rawMessage.substring(0, idx);
        final int len = int.parse(lenStr);
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          // If rows is not empty, the team has already been pitscouted.
          completer.complete(rows.isNotEmpty);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    // Send the query
    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final result = await completer.future;
    subscription?.cancel();
    return result;
  }

  Future<void> _onPitScoutingPressed() async {
    final String teamNumber = _teamController.text.trim();
    if (teamNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team number.')),
      );
      return;
    }
    try {
      bool already = await _teamAlreadyPitScouted(teamNumber);
      if (already) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team $teamNumber has already been pit scouted.')),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PitScouting(
              teamName: teamNumber,
              channel: widget.webSocketService.channel!,
              webSocketService: widget.webSocketService,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking pit scouting status: $e')),
      );
    }
  }

  Future<void> _logOut(BuildContext context) async {
    await AuthService.logOut();
    widget.webSocketService.disconnect();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          webSocketService: widget.webSocketService,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logOut(context),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 24, left: 36, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "Next Match" button remains as before.
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
                onPressed: () async {
                  final username = await _getUsername();
                  if (await isLeadScout()) {
                    // Navigate to lead scouting page.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeadScoutingPage(
                          teamName: "red", // for example, lead scouts watch the "red" alliance
                          matchNumber: "qm1", // default match number; adjust as needed
                          // channel: widget.webSocketService.channel!,
                          onThemeChanged: widget.onThemeChanged,
                          webSocketService: widget.webSocketService,
                        ),
                      ),
                    );
                  } else {
                    // Navigate to ScoutMatchList.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScoutMatchList(
                          webSocketService: widget.webSocketService,
                          onThemeChanged: widget.onThemeChanged,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  side: BorderSide(
                    color: colorScheme.secondary,
                    width: 8.0,
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: height / 16),
            // Team number input for pit scouting.
            TextField(
              controller: _teamController,
              decoration: InputDecoration(
                labelText: 'Enter Team Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: width * 0.03,
                  vertical: height * 0.015,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: height / 24),
            // Pit Scouting button
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
                onPressed: _onPitScoutingPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  side: BorderSide(
                    color: colorScheme.secondary,
                    width: 8.0,
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pit Scouting',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: height / 16),
            // Info button remains unchanged.
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InfoPage(
                        onThemeChanged: widget.onThemeChanged,
                        webSocketService: widget.webSocketService,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  side: BorderSide(
                    color: colorScheme.secondary,
                    width: 8.0,
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
