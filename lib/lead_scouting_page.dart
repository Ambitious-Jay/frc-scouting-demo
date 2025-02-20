import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/scroll_controller.dart';

String CombatabilityOne = '';
String CombatabilityTwo = '';
String CombatabilityThree = '';

String FeatsOne = '';
String FeatsTwo = '';
String FeatsThree = '';

String HPlayerOne = '';
String HPlayerTwo = '';
String HPlayerThree = '';

class LeadScoutingPage extends StatefulWidget {
  const LeadScoutingPage({super.key, required this.teamName});
  final String teamName;

  @override
  State<LeadScoutingPage> createState() => _LeadScoutingPage();
}

class _LeadScoutingPage extends State<LeadScoutingPage> {
  Future<void> setUp() async {
    List<String> teams = widget.teamName.split(' ');
    String robotOne = teams[1].substring(0, teams[1].length - 1);
    String robotTwo = teams[2].substring(0, teams[2].length - 1);
    String robotThree = teams[3];
    List<String> teamNames = [robotOne, robotTwo, robotThree];
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
  appBar: AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Text(widget.teamName),
  ),
  body: SingleChildScrollView(  // Wrap the entire body in a scroll view
    child: Column(
      children: [
        // First Row
        SizedBox(
          height: height * 0.3,
          width: width,
          child: Column(
            children: [
              Container(
                height: height * 0.05,
                width: width,
                alignment: Alignment.center,
                child: const Text(
                  'Compatibility',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: null,
                      onChanged: (String value) {
                        setState(() {
                          CombatabilityThree = value;
                        });
                      },
                    ),
                  ),
            ],
          ),
        ),
        const Divider(),

        // Second Row
        SizedBox(
          height: height * 0.3,
          width: width,
          child: Column(
            children: [
              Container(
                height: height * 0.05,
                width: width,
                alignment: Alignment.center,
                child: const Text(
                  'Notable Feats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: null,
                      onChanged: (String value) {
                        setState(() {
                          CombatabilityThree = value;
                        });
                      },
                    ),
                  ),
            ],
          ),
        ),
        const Divider(),

        // Third Row
        SizedBox(
          height: height * 0.3,
          width: width,
          child: Column(
            children: [
              Container(
                height: height * 0.05,
                width: width,
                alignment: Alignment.center,
                child: const Text(
                  'Human Player Net ACC',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: null,
                      onChanged: (String value) {
                        setState(() {
                          CombatabilityThree = value;
                        });
                      },
                    ),
                  ),
            ],
          ),
        ),
      ],
    ),
  ),
  bottomNavigationBar: ElevatedButton(
    onPressed: () async {
      // await _submitSection();
      // setState(() {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => Entrance(onThemeChanged: (newTheme) {
      //     })
      //     )
      //   );
      // });
    },
    child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
  ),
);

  }
}
