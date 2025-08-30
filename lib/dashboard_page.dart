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

  @override
  void initState() {
    super.initState();
    _injectFakeUser();
  }

  Future<void> _injectFakeUser() async {
    final prefs = await SharedPreferences.getInstance();
    // Demo user (not a lead scout since no "%")
    await prefs.setString('username', 'scoutUser01');
  }

  Future<String> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Unknown';
  }

  Future<bool> isLeadScout() async {
    final username = await _getUsername();
    return username.contains('%');
  }

  Future<void> _onPitScoutingPressed() async {
    final String teamNumber = _teamController.text.trim();
    if (teamNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team number.')),
      );
      return;
    }

    // Demo mode: just always open pit scouting page
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
        title: const Text('Dashboard (Demo)'),
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
            // 🔹 Next Match button → ScoutMatchList (demo data)
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScoutMatchList(
                        webSocketService: widget.webSocketService,
                        onThemeChanged: widget.onThemeChanged,
                        // if your ScoutMatchList takes data, stub it here
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

            // 🔹 Team number input for pit scouting
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

            // 🔹 Pit Scouting button
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

            // 🔹 Info button → InfoPage
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