import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/team_search_page.dart';

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
    final Map<String, Map<String, double>> teamData = {
      "254": {
        // The Cheesy Poofs
        "avgAutoPoints": 14.2,
        "avgTeleopPoints": 43.5,
        "avgCycleTime": 11.8,
        "defenseRating": 2.1,
        "autoConsistency": 0.92,
        "climbSuccessRate": 0.95,
        "pickupSuccessRate": 0.98,
        "maxMatchScore": 89,
      },
      "1678": {
        // Citrus Circuits
        "avgAutoPoints": 13.8,
        "avgTeleopPoints": 42.1,
        "avgCycleTime": 12.2,
        "defenseRating": 1.8,
        "autoConsistency": 0.94,
        "climbSuccessRate": 0.90,
        "pickupSuccessRate": 0.95,
        "maxMatchScore": 85,
      },
      "118": {
        // Robonauts
        "avgAutoPoints": 12.5,
        "avgTeleopPoints": 38.4,
        "avgCycleTime": 13.1,
        "defenseRating": 2.4,
        "autoConsistency": 0.88,
        "climbSuccessRate": 0.85,
        "pickupSuccessRate": 0.92,
        "maxMatchScore": 78,
      },
      "148": {
        // Robowranglers
        "avgAutoPoints": 13.2,
        "avgTeleopPoints": 41.8,
        "avgCycleTime": 12.5,
        "defenseRating": 1.5,
        "autoConsistency": 0.91,
        "climbSuccessRate": 0.88,
        "pickupSuccessRate": 0.94,
        "maxMatchScore": 82,
      },
      "2056": {
        // OP Robotics
        "avgAutoPoints": 13.9,
        "avgTeleopPoints": 42.8,
        "avgCycleTime": 11.9,
        "defenseRating": 2.2,
        "autoConsistency": 0.93,
        "climbSuccessRate": 0.92,
        "pickupSuccessRate": 0.96,
        "maxMatchScore": 87,
      },
      "1323": {
        // MadTown Robotics
        "avgAutoPoints": 13.1,
        "avgTeleopPoints": 40.2,
        "avgCycleTime": 12.8,
        "defenseRating": 2.0,
        "autoConsistency": 0.90,
        "climbSuccessRate": 0.87,
        "pickupSuccessRate": 0.93,
        "maxMatchScore": 81,
      },
      "1114": {
        // Simbotics
        "avgAutoPoints": 13.6,
        "avgTeleopPoints": 41.5,
        "avgCycleTime": 12.3,
        "defenseRating": 1.9,
        "autoConsistency": 0.92,
        "climbSuccessRate": 0.89,
        "pickupSuccessRate": 0.94,
        "maxMatchScore": 83,
      },
      "3310": {
        // Black Hawk Robotics
        "avgAutoPoints": 12.8,
        "avgTeleopPoints": 39.7,
        "avgCycleTime": 12.9,
        "defenseRating": 2.3,
        "autoConsistency": 0.89,
        "climbSuccessRate": 0.86,
        "pickupSuccessRate": 0.91,
        "maxMatchScore": 79,
      },
      "971": {
        // Spartan Robotics
        "avgAutoPoints": 13.5,
        "avgTeleopPoints": 41.2,
        "avgCycleTime": 12.4,
        "defenseRating": 1.7,
        "autoConsistency": 0.91,
        "climbSuccessRate": 0.88,
        "pickupSuccessRate": 0.93,
        "maxMatchScore": 82,
      },
      "195": {
        // CyberKnights
        "avgAutoPoints": 13.0,
        "avgTeleopPoints": 40.5,
        "avgCycleTime": 12.6,
        "defenseRating": 2.0,
        "autoConsistency": 0.90,
        "climbSuccessRate": 0.87,
        "pickupSuccessRate": 0.92,
        "maxMatchScore": 80,
      },
      "2767": {
        // Stryke Force
        "avgAutoPoints": 12.9,
        "avgTeleopPoints": 39.8,
        "avgCycleTime": 12.7,
        "defenseRating": 2.2,
        "autoConsistency": 0.89,
        "climbSuccessRate": 0.86,
        "pickupSuccessRate": 0.91,
        "maxMatchScore": 78,
      },
      "33": {
        // Killer Bees
        "avgAutoPoints": 13.3,
        "avgTeleopPoints": 40.9,
        "avgCycleTime": 12.4,
        "defenseRating": 1.8,
        "autoConsistency": 0.90,
        "climbSuccessRate": 0.88,
        "pickupSuccessRate": 0.93,
        "maxMatchScore": 81,
      },
      "1241": {
        // THEORY6
        "avgAutoPoints": 12.7,
        "avgTeleopPoints": 39.2,
        "avgCycleTime": 13.0,
        "defenseRating": 2.1,
        "autoConsistency": 0.88,
        "climbSuccessRate": 0.85,
        "pickupSuccessRate": 0.90,
        "maxMatchScore": 77,
      },
      "2481": {
        // Roboteers
        "avgAutoPoints": 13.1,
        "avgTeleopPoints": 40.1,
        "avgCycleTime": 12.6,
        "defenseRating": 1.9,
        "autoConsistency": 0.89,
        "climbSuccessRate": 0.87,
        "pickupSuccessRate": 0.92,
        "maxMatchScore": 79,
      },
      "225": {
        // TechFire
        "avgAutoPoints": 12.8,
        "avgTeleopPoints": 39.5,
        "avgCycleTime": 12.8,
        "defenseRating": 2.0,
        "autoConsistency": 0.88,
        "climbSuccessRate": 0.86,
        "pickupSuccessRate": 0.91,
        "maxMatchScore": 78,
      },
      "1538": {
        // The Holy Cows
        "avgAutoPoints": 13.0,
        "avgTeleopPoints": 40.3,
        "avgCycleTime": 12.5,
        "defenseRating": 1.8,
        "autoConsistency": 0.89,
        "climbSuccessRate": 0.87,
        "pickupSuccessRate": 0.92,
        "maxMatchScore": 80,
      },
      "3847": {
        // Spectrum
        "avgAutoPoints": 12.6,
        "avgTeleopPoints": 39.0,
        "avgCycleTime": 13.2,
        "defenseRating": 2.2,
        "autoConsistency": 0.87,
        "climbSuccessRate": 0.84,
        "pickupSuccessRate": 0.90,
        "maxMatchScore": 76,
      },
      "3357": {
        // COMETS
        "avgAutoPoints": 12.9,
        "avgTeleopPoints": 39.6,
        "avgCycleTime": 12.9,
        "defenseRating": 2.1,
        "autoConsistency": 0.88,
        "climbSuccessRate": 0.85,
        "pickupSuccessRate": 0.91,
        "maxMatchScore": 77,
      },
      "1023": {
        // Bedford Express
        "avgAutoPoints": 12.7,
        "avgTeleopPoints": 39.3,
        "avgCycleTime": 13.0,
        "defenseRating": 2.0,
        "autoConsistency": 0.87,
        "climbSuccessRate": 0.84,
        "pickupSuccessRate": 0.90,
        "maxMatchScore": 76,
      },
      "2590": {
        // Nemesis
        "avgAutoPoints": 13.2,
        "avgTeleopPoints": 40.7,
        "avgCycleTime": 12.4,
        "defenseRating": 1.9,
        "autoConsistency": 0.90,
        "climbSuccessRate": 0.88,
        "pickupSuccessRate": 0.93,
        "maxMatchScore": 81,
      }
    };
    return MaterialApp(
        title: 'Scouting Home Page',
        theme: ThemeData.from(colorScheme: lightColorScheme),
        darkTheme: ThemeData.from(colorScheme: darkColorScheme),
        themeMode: themeMode,
        home: TeamSearchPage());
  }
}

class MyHomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const MyHomePage(
      {super.key, required this.title, required this.onThemeChanged});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
