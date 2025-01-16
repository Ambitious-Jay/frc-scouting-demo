import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/objective_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scouting Home Page',
      theme: ThemeData.from(colorScheme: lightColorScheme),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme),
      themeMode: themeMode,
      home: ObjectivePage(
        key: const Key('objective_page'),
        onThemeChanged: (ThemeMode mode) {
          setState(() {
            themeMode = mode;
          });
        },
      ),
    );
  }
}
