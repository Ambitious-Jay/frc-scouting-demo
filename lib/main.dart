import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/scatter_plot.dart';

import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/login_page.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/objective_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

/// Manages the WebSocket connection for the entire app.
/// Opens the connection in initState and closes it in dispose.
/// Passes the WebSocketService to child widgets as needed.
class _MainAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;

  /// Reference to the WebSocketService singleton
  final WebSocketService _webSocketService = WebSocketService();

  /// Tracks if the user is already logged in
  bool _isLoggedIn = false;

  /// Tracks if the login state has been checked
  bool _loginChecked = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus().then((_) {
      // Always ensure WebSocket is connected
      _webSocketService.connect();
      setState(() {
        _loginChecked = true;
      });
    });
  }

  /// Checks the persisted login state
  Future<void> _checkLoginStatus() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    if (_isLoggedIn) {
      print('[MainApp] User is logged in.');
    } else {
      print('[MainApp] User is not logged in.');
    }
  }

  @override
  void dispose() {
    // Always disconnect the WebSocket when disposing the app
    _webSocketService.disconnect();
    print('[MainApp] Disposed and disconnected WebSocket.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while checking login status
    if (!_loginChecked) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // IMPORTANT: Flip the ternary so "logged in" -> Dashboard, "not logged in" -> Login
    return MaterialApp(
      title: 'Scouting Home Page',
      theme: ThemeData.from(colorScheme: lightColorScheme),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme),
      themeMode: themeMode,
      // home: _isLoggedIn
      //     ? ObjectivePage(
      //         channel: _webSocketService.channel,
      //         onThemeChanged: (ThemeMode mode) {
      //           setState(() {
      //             themeMode = mode;
      //           });
      //         },
      //         webSocketService: _webSocketService,
      //       )
      //     : ObjectivePage(
      //         channel: _webSocketService.channel,
      //         onThemeChanged: (ThemeMode mode) {
      //           setState(() {
      //             themeMode = mode;
      //           });
      //         },
      //         webSocketService: _webSocketService,
      //       ),
      home: AutoPage(
        teamName: '',
        id: '',
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
