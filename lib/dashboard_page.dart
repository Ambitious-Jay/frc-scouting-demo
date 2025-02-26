import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:frc1148_2025_scouting_app/info_page.dart';
import 'package:frc1148_2025_scouting_app/pit_scouting_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'login_page.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'login_page.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';

class DashboardPage extends StatelessWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;

  const DashboardPage({
    Key? key,
    required this.webSocketService,
    required this.onThemeChanged,
    WebSocketChannel? channel,
    required String teamName,
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
      body: 
      Padding(
        padding: const EdgeInsets.only(top: 24, left: 36, right: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AutoPage(teamName: "1148", id: "Andrew",
                        channel: webSocketService.channel!,
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next Match',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ),
            SizedBox(height: height/16),
            TextField(
              controller: _teamController,
              decoration: InputDecoration(
                labelText: 'Enter Team Number',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: width * 0.03, vertical: height * 0.015),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: height/24),
            SizedBox(
              height: height / 6,
              child: ElevatedButton(
                onPressed: () {
                  String teamName = _teamController.text.trim();
                  if (teamName.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PitScouting(teamName: teamName,
                        channel: webSocketService.channel!,
                        webSocketService: webSocketService,),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a team number.')),
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
                    borderRadius:
                        BorderRadius.circular(8), // Decrease the rounding
                  ),
                ),
                child: const Text(
                  'Pit Scouting',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: height/16),
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
                    borderRadius:
                        BorderRadius.circular(8), // Decrease the rounding
                  ),
                ),
                child: const Text(
                  'Info',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              )
            )
          ],
        ),
    ));
  }
}
