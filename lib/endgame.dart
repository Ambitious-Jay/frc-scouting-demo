import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';
// import 'entrance.dart';
// import 'sheets_helper.dart';
// import 'auto_form.dart' as af;
// import 'teleop_form.dart' as tf;
import 'color_scheme.dart';

String Hang = "";

Map<String, bool> presets = <String, bool>{
  'Part Broke': false,
  'Stopped Moving': false,
  'Fast': false,
  'Good Driving': false,
  'Tippy': false,
  'Accurate Coral': false,
  'Defensive': false,
  'Net Algae': false
};

List<String> keys = presets.keys.toList();

class Endgame extends StatefulWidget {
  const Endgame({super.key, required this.teamName});
  final String teamName;
  @override
  State<Endgame> createState() => _Endgame();
}

class _Endgame extends State<Endgame> {
  Future<void> _submitSection() async {
    try {
      // print(robotBreak);
      // final sheet = await SheetsHelper.sheetSetup("App results");

      // final firstRow = [defensive, tippiness, robotBreak, tip];
      // print(robotBreak);
      // if (widget.teamName.contains("frc")){
      //   await sheet!.values.insertRowByKey (widget.teamName, firstRow, fromColumn: 14);
      // }
      // else{
      //   await sheet!.values.insertRowByKey (id, firstRow, fromColumn: 14);
      // }
      // //await sheet!.values.insertRowByKey (widget.teamName, firstRow, fromColumn: 13);
    } catch (e) {
      print('Error: $e');
    }
  }

  String id = "";

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Endgame"),
            Text(widget.teamName),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: [
            SizedBox(
              height: height / 3.5,
              child: Center(
                child: DropdownButtonFormField<String>(
                  value: "No Value Entered/Seen",
                  onChanged: (String? value) {
                    Hang = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Hang',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Deep Cage',
                    'Shallow Cage',
                    'Failed Deep Cage',
                    'Failed Shallow Cage',
                    'Did Not Try',
                    "No Value Entered/Seen"
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            SingleChildScrollView(
                child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(width / 50),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.0,
                crossAxisSpacing: width / 50,
                mainAxisSpacing: width / 50,
              ),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                String key = keys[index];
                bool value = presets[key]!;

                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      presets[key] = !value;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      value ? Colors.red : Colors.black,
                    ),
                  ),
                  child: Text(
                    key,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            )),
            const Divider(),
            // ElevatedButton(
            //   onPressed: () async {
            //     // await _submitSection();
            //     // setState(() {
            //     //   Navigator.push(
            //     //     context,
            //     //     MaterialPageRoute
            //     //     (
            //     //       builder: (context) => Entrance(onThemeChanged: (newTheme) {
            //     //     })
            //     //     )
            //     //   );
            //     // });

            //     //     af.autoPath = "";

            //     //     tf.speakerPoints.value = 0;
            //     //     tf.speakerAmpedCounter.value = 0;
            //     //     tf.speakerNotAmpedCounter.value = 0;
            //     //     tf.ampPoints.value = 0;
            //     //     tf.trapPoints.value = 0;
            //     //     tf.missedS.value = 0;
            //     //     tf.missedA.value = 0;
            //     //     tf.missedT.value = 0;
            //     //     tf.tryParkTele = false;
            //     //     tf.messUpParkTele = false;

            //     //     tippiness = 0;
            //     //     tip = false;
            //     //     defensive = false;
            //     //     robotBreak = false;
            //   },
            //   // child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
            // )
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: Theme.of(context).colorScheme.secondary,
          iconColor: Theme.of(context).colorScheme.secondary,
        ),
        iconAlignment: IconAlignment.end,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DashboardPage(
                      webSocketService: WebSocketService(),
                      onThemeChanged: (ThemeMode mode) {
                        setState(() {
                          // var themeMode = mode;
                        });
                      },
                    )),
          );
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Submit'),
      ),
    );
  }
}
