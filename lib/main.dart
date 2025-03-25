import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/auto_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/endgame.dart';
import 'package:frc1148_2025_scouting_app/lead_scout_notes_vis_page.dart';
import 'package:frc1148_2025_scouting_app/login_page.dart';
import 'package:frc1148_2025_scouting_app/objective_page.dart';
import 'package:frc1148_2025_scouting_app/pit_scouting_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;
  final WebSocketService _webSocketService = WebSocketService();
  bool _isLoggedIn = false;
  bool _loginChecked = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus().then((_) {
      _webSocketService.connect();
      setState(() {
        _loginChecked = true;
      });
    });
  }

  Future<void> _checkLoginStatus() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    print('[MainApp] User is ${_isLoggedIn ? "" : "not "}logged in.');
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    print('[MainApp] Disposed and disconnected WebSocket.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loginChecked) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      title: 'Scouting Home Page',
      theme: ThemeData.from(colorScheme: lightColorScheme),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme),
      themeMode: themeMode,
      home: AutoPage(
        teamName: "1148",
        teamNickname: "Harvard-Westlake Robotics",
        matchNumber: "1",
        onThemeChanged: (ThemeMode mode) {
          setState(() {
            themeMode = mode;
          });
        },
        webSocketService: _webSocketService,
        channel: _webSocketService.channel!,
      ),

      // home: _isLoggedIn
      //     ? DashboardPage(
      //         channel: _webSocketService.channel,
      //         onThemeChanged: (ThemeMode mode) {
      //           setState(() {
      //             themeMode = mode;
      //           });
      //         },
      //         webSocketService: _webSocketService,
      //         teamName: '',
      //       )
      //     : LoginPage(
      //         channel: _webSocketService.channel,
      //         onThemeChanged: (ThemeMode mode) {
      //           setState(() {
      //             themeMode = mode;
      //           });
      //         },
      //         webSocketService: _webSocketService,
      //       ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
