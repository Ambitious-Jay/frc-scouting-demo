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

class DashboardPage extends StatelessWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;
  final String teamName;

  const DashboardPage({
    Key? key,
    required this.webSocketService,
    required this.onThemeChanged,
    required this.teamName,
    WebSocketChannel? channel,
  }) : super(key: key);

  Future<void> _logOut(BuildContext context) async {
    await AuthService.logOut();
    webSocketService.disconnect();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          webSocketService: webSocketService,
          onThemeChanged: onThemeChanged,
        ),
      ),
    );
  }

  // Helper function to retrieve the user id from SharedPreferences
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? 'Unknown';
  }

  Future<bool> isLeadScout() async {
    final userId = await _getUserId();
    return userId.contains('%');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final TextEditingController _teamController = TextEditingController();
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
            // "Next Match" button
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
                onPressed: () async {
                  final userId = await _getUserId();
                  if (await isLeadScout()) {
                    // await the Future<bool>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeadScoutingPage(
                          teamName: "1148",
                          channel: webSocketService.channel!,
                          onThemeChanged: onThemeChanged,
                          webSocketService: webSocketService,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScoutMatchList(
                          id: userId,
                          channel: webSocketService.channel!,
                          onThemeChanged: onThemeChanged,
                          webSocketService: webSocketService,
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
            // Team number input
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
                onPressed: () {
                  String teamName = _teamController.text.trim();
                  if (teamName.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PitScouting(
                          teamName: teamName,
                          channel: webSocketService.channel!,
                          webSocketService: webSocketService,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a team number.'),
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
            // Info button
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InfoPage(
                        onThemeChanged: onThemeChanged,
                        webSocketService: webSocketService,
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
