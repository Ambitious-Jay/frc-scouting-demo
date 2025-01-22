import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
// import 'package:frc1148_2025_scouting_app/labeled_button.dart';

class PresetComment extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const PresetComment({
    Key? key,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<PresetComment> createState() => _PresetCommentState();
}

class _PresetCommentState extends State<PresetComment> {
  ThemeMode themeMode = ThemeMode.system;
  // Map<String, int> map = {};
  Map<String, int> map = <String, int>{
    'crazy': 2,
    'fun': 7,
    'trash': 1,
    'happy': 0,
    'stupid': 3,
    'boring': 1,
    'strong': 1,
  };

  List makeList() {
    List commentsList = map.entries.toList();
    commentsList.sort((a, b) => b.value.compareTo(a.value));
    return commentsList;
  }

  @override
  Widget build(BuildContext context) {
    List commentsList = makeList();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Preset Comments'),
        ),
        body: Column(
          children: [
            const Text("Comments by frequency"),
            Expanded(
              child: ListView.builder(
                itemCount: commentsList.length,
                itemBuilder: (context, index) {
                  final entry = commentsList[index];
                  return Column(
                    children: [
                      Card(
                        child: Row(
                          children: [
                            Text(entry.key),
                            const VerticalDivider(
                              color: Colors.white,
                            ),
                            Text(entry.value.toString())
                          ],
                        ),
                      ),
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
