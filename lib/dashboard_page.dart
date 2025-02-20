import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:frc1148_2025_scouting_app/info_page.dart';
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AutoPage(
                        teamName: "1148",
                        id: "Andrew"
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Decrease the rounding
                  ),
                ),
                child: const Text(
                  'Next Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(5),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Decrease the rounding
                  ),
                ),
                child: const Text(
                  'Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
