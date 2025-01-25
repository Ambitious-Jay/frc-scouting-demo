import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';

class AutoTablePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const AutoTablePage({
    Key? key,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<AutoTablePage> createState() => _AutoTablePageState();
}

class _AutoTablePageState extends State<AutoTablePage> {
  ThemeMode themeMode = ThemeMode.system;
  List<String> startDataList = ["L", "L", "R", "L", "C", "L"];
  List<String> zoneDataList = ["R", "C", "C", "L", "R", "L"];
  List<String> coralDataList = [
    "L4: 2, L2/L3: 0, L1: 0",
    "L4: 0, L2/L3: 1, L1: 3",
    "L4: 0, L2/L3: 0, L1: 0",
    "L4: 1, L2/L3: 1, L1: 0",
    "L4: 1, L2/L3: 0, L1: 5",
    "L4: 1, L2/L3: 3, L1: 0"
  ];
  GridView grid = GridView.count(
    crossAxisCount: 3,
    children: const <Text>[],
  );

  GridView makeGridView() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    List<Padding> toMakeGrid = <Padding>[];
    for (int i = 0; i < startDataList.length; i++) {
      toMakeGrid.add(Padding(
          // padding: EdgeInsets.only(
          //     right: width * 0.015, top: width * 0.015, bottom: width * 0.015),

          padding: EdgeInsets.all(width * 0.015),
          child: Text(
            startDataList[i],
            style: TextStyle(fontSize: height * 0.05),
            textAlign: TextAlign.center,
          )));
      toMakeGrid.add(Padding(
          padding: EdgeInsets.all(width * 0.015),
          child: Text(
            zoneDataList[i],
            style: TextStyle(fontSize: height * 0.05),
            textAlign: TextAlign.center,
          )));
      toMakeGrid.add(Padding(
          padding: EdgeInsets.all(width * 0.025),
          child: Text(
            coralDataList[i],
            style: TextStyle(fontSize: height * 0.025),
            // textAlign: TextAlign.center,
          )));
    }
    return GridView.count(
      mainAxisSpacing: 0,
      padding: EdgeInsets.zero,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      children: toMakeGrid,
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    grid = makeGridView();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Auto Table'),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Start",
                  style: TextStyle(fontSize: width * 0.075),
                ),
                Text(
                  "Zone",
                  style: TextStyle(fontSize: width * 0.075),
                ),
                Text(
                  "Coral",
                  style: TextStyle(fontSize: width * 0.075),
                ),
              ],
            ),
            const Divider(),
            Expanded(child: grid)
          ],
        ));
  }
}
