import 'package:flutter/material.dart';

import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'login_page.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';

class DashboardPage extends StatelessWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;

  const DashboardPage({
    Key? key,
    required this.webSocketService,
    required this.onThemeChanged,
  }) : super(key: key);

  /// Logs out the user by clearing the login state and navigating to LoginPage
  Future<void> _logOut(BuildContext context) async {
    await AuthService.logOut();

    // Close the WebSocket connection
    webSocketService.disconnect();

    // Navigate to LoginPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          webSocketService: webSocketService,
          onThemeChanged: onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the username if needed
    // This can be displayed or used as per your requirements

    return Scaffold(
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
      body: Center(
        child: Text(
          'Welcome to the Dashboard!',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
