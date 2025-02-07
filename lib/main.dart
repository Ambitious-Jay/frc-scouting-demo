import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/scatter_plot.dart';

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
        "avgAutoPoints": 14.2, // Average points scored in auto
        "avgTeleopPoints": 43.5, // Average points scored in teleop
        "avgCycleTime": 11.8, // Average time per game piece cycle
        "defenseRating": 2.1, // Subjective defense rating (1-3)
        "autoConsistency": 0.92, // Standard deviation of auto performance
        "climbSuccessRate": 0.95, // Percentage of successful climbs
        "pickupSuccessRate": 0.98, // Percentage of successful piece pickups
        "maxMatchScore": 89, // Highest single match score
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
    };
    return MaterialApp(
      title: 'Scouting Home Page',
      theme: ThemeData.from(colorScheme: lightColorScheme),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme),
      themeMode: themeMode,
      home: FlexibleScatterPlot(
        teamData: teamData,
      ),
    );
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
