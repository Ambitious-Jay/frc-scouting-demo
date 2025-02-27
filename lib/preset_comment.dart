import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/scroll_controller.dart';

class PresetComment extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const PresetComment({
    Key? key,
    required this.onThemeChanged, required String teamNumber,
  }) : super(key: key);

  @override
  State<PresetComment> createState() => _PresetCommentState();
}

class _PresetCommentState extends State<PresetComment> {
  ThemeMode themeMode = ThemeMode.system;
  Map<String, int> map = <String, int>{
    'consistent scorer': 15,
    'excellent defense': 8,
    'reliable autonomous': 12,
    'fast cycle time': 10,
    'strong pusher': 7,
    'accurate shooter': 14,
    'great endgame': 11,
    'solid driver': 9,
    'good team player': 13,
    'adaptable strategy': 6,
    'communicates well': 8,
    'follows alliance plan': 7,
    'strategic positioning': 5,
    'robust intake': 9,
    'efficient mechanism': 11,
    'stable platform': 8,
    'quick repairs': 4,
    'innovative design': 6,
    'inconsistent shooting': 3,
    'mechanical issues': 5,
    'slow cycle time': 4,
    'weak defense': 2,
    'unreliable autonomous': 3,
    'poor communication': 2,
    'game changer': 7,
    'clutch player': 5,
    'key defender': 6,
    'score enabler': 8,
    'field awareness': 9,
    'robust build': 10,
    'compact design': 7,
    'modular systems': 5,
    'easy repairs': 6,
    'weight optimized': 4,
  };

  // method to convert convert map into sorted list
  List makeList() {
    List commentsList = map.entries.toList();
    commentsList.sort((a, b) => b.value.compareTo(a.value));
    return commentsList;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    List commentsList = makeList();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Preset Comments'),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(height * 0.005),
              child: Text(
                "Comments by frequency",
                style: TextStyle(fontSize: height * 0.0375),
              ),
            ),
            const Divider(),
            Padding(
              padding: EdgeInsets.all(height * 0.005),
              child: Row(
                children: [
                  Expanded(
                    child: (Text("Comment",
                        style: TextStyle(fontSize: width * 0.0625))),
                  ),
                  Text(
                    "Frequency",
                    style: TextStyle(fontSize: width * 0.0625),
                    textAlign: TextAlign.right,
                  )
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: commentsList.length,
                controller: AdjustableScrollController(15), // will need to be tested on real, scrollable phone
                itemBuilder: (context, index) {
                  final entry = commentsList[index];
                  return Column(
                    children: [
                      Card(
                          child: Padding(
                        padding: EdgeInsets.all(width * 0.01),
                        child: Row(
                          children: [
                            Expanded(
                              child: (Text(entry.key,
                                  style: TextStyle(fontSize: width * 0.0625))),
                            ),
                            Text(
                              entry.value.toString(),
                              style: TextStyle(fontSize: width * 0.0625),
                              textAlign: TextAlign.right,
                            )
                          ],
                        ),
                      )),
                      const Divider(
                        color: Colors.white,
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ));
  }
}
