import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
import 'package:frc1148_2025_scouting_app/login_page.dart';

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

  // Fake user data for testing
  String _fakeTeamName = "Andrew Jo";

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
    // 🔹 Instead of calling AuthService, force logged in
    // _isLoggedIn = await AuthService.isLoggedIn();
    await Future.delayed(const Duration(milliseconds: 500)); // fake network delay
    _isLoggedIn = true; // always logged in during testing

    print('[MainApp] Fake login applied. User is logged in as $_fakeTeamName');
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
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      title: 'Scouting Home Page',
      theme: ThemeData.from(colorScheme: lightColorScheme),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme),
      themeMode: themeMode,
      home: _isLoggedIn
          ? DashboardPage(
              channel: _webSocketService.channel,
              onThemeChanged: (ThemeMode mode) {
                setState(() {
                  themeMode = mode;
                });
              },
              webSocketService: _webSocketService,
              teamName: _fakeTeamName, // inject fake user/team data
            )
          : LoginPage(
              channel: _webSocketService.channel,
              onThemeChanged: (ThemeMode mode) {
                setState(() {
                  themeMode = mode;
                });
              },
              webSocketService: _webSocketService,
            ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}