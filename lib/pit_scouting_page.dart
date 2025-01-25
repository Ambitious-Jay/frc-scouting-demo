import 'package:flutter/gestures.dart'; // For TapGestureRecognizer
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'color_scheme.dart';

// general
String robotWeight = "";
String driveType = "";
List<String> driveOptions = ['Swerve', 'Tank', 'Mechanum', 'Other'];
String motorType = "";
int motorNum = 0;

// intake
bool intakeStation = false;
bool coralGround = false;
bool algaeGround = false; // not pushing
bool algaeReefControlled = false; // not just knocking it off
String bumperQuality = ""; // subjective

// scoring
bool levelOne = false;
bool levelTwo = false;
bool levelThree = false;
bool levelFour = false;
bool processor = false;
bool net = false;
String climbType = "";
List<String> climbOptions = ['Shallow', 'Deep', 'No Hang'];

// auto
int coralPoints = 0;
// something for what side they start on?
bool leavesStartLine = false;

// ================================================

class PitScouting extends StatefulWidget {
  const PitScouting({super.key, required this.teamName});
  final String teamName;
  @override
  State<PitScouting> createState() => _PitScouting();
}

class _PitScouting extends State<PitScouting> {
  late TextEditingController _controller1;
  late TextEditingController _controller2;
  late TextEditingController _controller3;
  late TextEditingController _controller4;
  late TextEditingController _controller5;
  late TextEditingController _controller6;
  final List<String> entries = <String>[
    'Robot weight (lbs): ',
    'Type of drive: ',
    'Type of motor: ',
    'Number of motors: ',
    'Bumper quality: ',
    // ---
    'Can pick up coral from Coral Station: ',
    'Can pick up coral from ground: ',
    'Can pick up algae from ground (not just pushing): ',
    'Can remove algae from reef (controlled, not just knocking off): ',
    // ---
    'Can score coral onto L1: ',
    'Can score coral onto L2: ',
    'Can score coral onto L3: ', 
    'Can score coral onto L4: ', 
    'Can score in processor: ',
    'Can score into net: ',
    'Type of Climb: ',
    // ---
    'Coral scored during Autonomous: ',
    'Can robot move off of starting line during Autonomous: ',
  ];

  void initState() {
    super.initState();
    _controller1 = TextEditingController();
    _controller2 = TextEditingController();
    _controller3 = TextEditingController();
    _controller4 = TextEditingController();
    _controller5 = TextEditingController();
    _controller6 = TextEditingController();
  }

  /*Future<void> _submitForm(column, row) async {
    try {
      final sheet = await SheetsHelper.sheetSetup('PitScouting');
      // Writing data
      final firstRow = [
        robotWeight,
        CapablityOne,
        CapablityTwo,
        bumperQuality,
        fieldCapability,
        climb,
        trap,
        ground,
        source,
        robotSpeed,
        numMotors,
        scoreInSpeaker,
        howTheyPass,
        intakeType,
        driveType
      ];
      await sheet!.values
          .insertRowByKey(widget.teamName, firstRow, fromColumn: 2);
      // prints [index, letter, number, label]
      print(await sheet.values.row(1));
    } catch (e) {
      print('Error: $e');
    }
  }*/

  // void _takePicture() async {
  //   final cameras = await availableCameras();
  //   final firstCamera = cameras.first;

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => tp.take_picture(camera: firstCamera),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pit Scouting",
          // ignore: deprecated_member_use
          textScaleFactor: 1.5,
        ),
        elevation: 21,
      ),
      body: Center(
          child: ListView(
        children: <Widget>[
          Container(
            width: 0,
            height: 60,
            color: Colors.white10,
          ),

          Center(
            child: RichText(
              text: TextSpan(
                children: <TextSpan>[
                  const TextSpan(
                    text: 'link to ',
                    style: TextStyle(color: Colors.black87),
                  ),
                  TextSpan(
                    text: 'Robot Pictures Folder',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launch(
                            'https://drive.google.com/drive/folders/17r61d7tOUQLiKA4cnEW15pXioTIKt-yK?usp=drive_link'); // REPLACE WITH 2025 
                      },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[0],
                    textScaleFactor: 1.5,
                  ),
                  SizedBox( // ========================= ROBOT WEIGHT ========
                    width: width / 3,
                    child: TextField(
                      controller: _controller1,
                      onChanged: (String value) {
                        setState(() {
                          robotWeight = value;
                        });
                        print("Current value: $value");
                      },

                      // decoration: const InputDecoration(
                      //   enabledBorder: UnderlineInputBorder(
                      //     borderSide: BorderSide(color: Colors.red)
                      //   ),
                      //   disabledBorder: UnderlineInputBorder(
                      //     borderSide: BorderSide(color: Colors.red)
                      //   ),
                      //   focusedBorder: UnderlineInputBorder(
                      //     borderSide: BorderSide( )
                      //   ),
                      // ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox( // ==================================== drive type ==============
            height: height / 3.5,
            child: Center( 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(entries[13], textScaleFactor: 1.5),
                  DropdownButton<String>(
                    value: driveType.isNotEmpty ? driveType : null,
                    hint: Text('Select Intake Type'),
                    items: driveOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        driveType = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox( // STOPPED HERE ------------------------------------
            height: height / 3.5,
            //color: Colors.red[400],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[1],
                    textScaleFactor: 1.5,
                  ),
                  Checkbox(
                    value: ,
                    //color: Colors.amber[700],
                    onChanged: (newValue) {
                      setState(() {
                        CapablityOne = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[2],
                    textScaleFactor: 1.5,
                  ),
                  Checkbox(
                    value: CapablityTwo,
                    //color: Colors.amber[700],
                    onChanged: (newValue) {
                      setState(() {
                        CapablityTwo = newValue!;
                      });
                    },
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[3],
                    textScaleFactor: 1.5,
                  ),
                  SizedBox(
                    width: width / 3,
                    child: TextField(
                      controller: _controller2,
                      onChanged: (String value) {
                        setState(() {
                          bumperQuality = value;
                        });
                        print("Current value: $value");
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[4],
                    textScaleFactor: 1.5,
                  ),
                  Checkbox(
                    value: fieldCapability,
                    //color: Colors.amber[700],
                    onChanged: (newValue) {
                      setState(() {
                        fieldCapability = newValue!;
                      });
                    },
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[400],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[5],
                    textScaleFactor: 1.5,
                  ),
                  Checkbox(
                    value: climb,
                    //color: Colors.amber[700],
                    onChanged: (newValue) {
                      setState(() {
                        climb = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[400],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[6],
                    textScaleFactor: 1.5,
                  ),
                  Checkbox(
                    value: trap,
                    //color: Colors.amber[700],
                    onChanged: (newValue) {
                      setState(() {
                        trap = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[400],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[7],
                    textScaleFactor: 1.5,
                  ),
                  Checkbox(
                    value: ground,
                    //color: Colors.amber[700],
                    onChanged: (newValue) {
                      setState(() {
                        ground = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            //color: Colors.red[400],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    entries[8],
                    textScaleFactor: 1.5,
                  ),
                  Checkbox(
                    value: source,
                    //color: Colors.amber[700],
                    onChanged: (newValue) {
                      setState(() {
                        source = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(entries[9], textScaleFactor: 1.5),
                  SizedBox(
                    width: width / 3,
                    child: TextField(
                      controller: _controller3,
                      onChanged: (String value) {
                        setState(() {
                          robotSpeed = value;
                        });
                        print("Current value: $value");
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(entries[10], textScaleFactor: 1.5),
                SizedBox(
                  width: width / 3,
                  child: TextField(
                    controller: _controller4,
                    onChanged: (String value) {
                      setState(() {
                        numMotors = value;
                      });
                    },
                  ),
                ),
              ],
            )),
          ),
          SizedBox(
            height: height / 3.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(entries[11], textScaleFactor: 1.5),
                  SizedBox(
                    width: width / 3,
                    child: TextField(
                      controller: _controller5,
                      onChanged: (String value) {
                        setState(() {
                          scoreInSpeaker = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(entries[12], textScaleFactor: 1.5),
                  SizedBox(
                    width: width / 3,
                    child: TextField(
                      controller: _controller6,
                      onChanged: (String value) {
                        setState(() {
                          howTheyPass = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(entries[14], textScaleFactor: 1.5),
                  DropdownButton<String>(
                    value: driveType.isNotEmpty ? driveType : null,
                    hint: Text('Select Drive Type'),
                    items: driveOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        driveType = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: height / 3.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(entries[13], textScaleFactor: 1.5),
                  DropdownButton<String>(
                    value: intakeType.isNotEmpty ? intakeType : null,
                    hint: Text('Select Intake Type'),
                    items: intakeOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        intakeType = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Container (
          //   height: height / 10,
          //   width: width,
          //   //color: Colors.red ,
          //   alignment: Alignment.center,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text("Your team is: "),
          //       Text("$results"),
          //       IconButton(
          //         onPressed: (){
          //           teamAsker(test);
          //         },
          //         icon: const Icon (Icons.refresh)
          //       )
          //     ],
          //   )
          // ),

          // ElevatedButton(
          //   onPressed: _takePicture,
          //   child: const Icon(Icons.camera_alt),
          // ),

          ElevatedButton( // SUBMISSION BUTTON =============================
            onPressed: () async {
              // await _submitForm(0, 0);

              // await updateTeamUColumn(widget.teamName);

              // robotWeight = "";
              // CapablityOne = false;
              // CapablityTwo = false;
              // bumperQuality = "";
              // fieldCapability = false;
              // climb = false;
              // trap = false;
              // ground = false;
              // source = false;
              // robotSpeed = "";
              // numMotors = "";
              // scoreInSpeaker = "";
              // howTheyPass = "";
              // intakeType = "";
              // driveType = "";

              // Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //         builder: (context) =>
              //             Entrance(onThemeChanged: (newTheme) {})));
            },
            child: const Icon(Icons.send, color: colors.myOnPrimary),
          )
        ],
      )),
    );
  }
}