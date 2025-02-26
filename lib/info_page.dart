import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/match_list.dart';
import 'package:frc1148_2025_scouting_app/Flexiblescatter_plot.dart';
import 'package:frc1148_2025_scouting_app/team_search_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'login_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';

class InfoPage extends StatelessWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;

  const InfoPage({
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
        builder: (_) => DashboardPage(
          webSocketService: webSocketService,
          onThemeChanged: onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Info Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: () => _logOut(context),
        //     tooltip: 'Log Out',
        //   ),
        // ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: width * 0.9,
              height: height * 0.2,
              margin: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchList(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Match List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.9,
              height: height * 0.2,
              margin: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamSearchPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Team List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.9,
              height: height * 0.2,
              margin: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamSearchPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Graphing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                  ),
                ),
              ),
            ),
            Container(
              width: width * 0.9,
              height: height * 0.2,
              margin: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlexibleScatterPlot(teamData: {},),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Scatter Plot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 54,
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
