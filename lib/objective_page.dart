import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
// import 'package:frc1148_2025_scouting_app/labeled_button.dart';

class ObjectivePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const ObjectivePage({
    Key? key,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<ObjectivePage> createState() => _ObjectivePageState();
}

class _ObjectivePageState extends State<ObjectivePage> {
  ThemeMode themeMode = ThemeMode.system;
  // counters
  int l4Counter = 0;
  int l2l3Counter = 0;
  int l1Counter = 0;
  int netCounter = 0;
  int processorCounter = 0;
  bool isCounterPositive = true;

  // method to get toggle icon
  Icon get signIcon {
    IconData iconData;
    if (isCounterPositive) {
      iconData = Icons.add;
    } else {
      iconData = Icons.remove;
    }
    return Icon(iconData,
        color: Theme.of(context).colorScheme.primary,
        size: MediaQuery.of(context).size.width * 0.1);
  }

  //methods to update counters up or down based on negative toggle
  void updateL4() {
    setState(() {
      if (isCounterPositive) {
        l4Counter++;
      } else if (l4Counter > 0) {
        l4Counter--;
      }
    });
  }

  void updateL2L3() {
    setState(() {
      if (isCounterPositive) {
        l2l3Counter++;
      } else if (l2l3Counter > 0) {
        l2l3Counter--;
      }
    });
  }

  void updateL1() {
    setState(() {
      if (isCounterPositive) {
        l1Counter++;
      } else if (l1Counter > 0) {
        l1Counter--;
      }
    });
  }

  void updateNet() {
    setState(() {
      if (isCounterPositive) {
        netCounter++;
      } else if (netCounter > 0) {
        netCounter--;
      }
    });
  }

  void updateProcessor() {
    setState(() {
      if (isCounterPositive) {
        processorCounter++;
      } else if (processorCounter > 0) {
        processorCounter--;
      }
    });
  }

  void toggleNegative() {
    setState(() {
      isCounterPositive = !isCounterPositive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Objective Page'),
      ),
      body: Center(
          child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.375,
                  child: const Image(
                    //reef photo
                    image: AssetImage('assets/reef.png'),
                    fit: BoxFit.contain,
                  )),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.05,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // SizedBox(
                  //   height: MediaQuery.of(context).size.height * 0.05,
                  // ),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.01),
                    child: Text("L4",
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.1)),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          // minimumSize: const Size.square(70),
                          minimumSize: Size(
                              MediaQuery.of(context).size.width * 0.5,
                              MediaQuery.of(context).size.height * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: updateL4,
                      child: Text('$l4Counter',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.15))),
                  // LabeledButton(
                  //     label: "L4",
                  //     buttonContent: l4Counter,
                  //     functionOnTap: updateL4),
                  // const Spacer(),
                  // SizedBox(
                  //   height: MediaQuery.of(context).size.height * 0.075,
                  // ),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.01),
                    child: Text("L2 & L3",
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.1)),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          // minimumSize: const Size.square(70),
                          minimumSize: Size(
                              MediaQuery.of(context).size.width * 0.5,
                              MediaQuery.of(context).size.height * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: updateL2L3,
                      child: Text('$l2l3Counter',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.15))),
                  // LabeledButton(
                  //     label: "L2/L3",
                  //     buttonContent: l2l3Counter,
                  //     functionOnTap: updateL2L3),
                  // const Spacer(),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.01),
                    child: Text("L1",
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.1)),
                  ),
                  // SizedBox(
                  //   height: MediaQuery.of(context).size.height * 0.075,
                  // ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          // minimumSize: const Size.square(70),
                          minimumSize: Size(
                              MediaQuery.of(context).size.width * 0.5,
                              MediaQuery.of(context).size.height * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: updateL1,
                      child: Text('$l1Counter',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.15))),
                  // LabeledButton(
                  //     label: "L1",
                  //     buttonContent: l1Counter,
                  //     functionOnTap: updateL1),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.075,
                  ),
                ],
              ),
            ],
          ),
          // SizedBox(
          //   height: MediaQuery.of(context).size.height * 0.0375,
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.width * 0.0125),
                    child: Text("Net",
                        style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width * 0.05)),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: Size(
                              MediaQuery.of(context).size.height * 0.125,
                              MediaQuery.of(context).size.height * 0.125),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: updateNet,
                      child: Text('$netCounter',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.1))),
                ],
              ),
              // LabeledButton(
              //     label: "Net",
              //     buttonContent: netCounter,
              //     functionOnTap: updateNet),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.width * 0.0125),
                    child: Text("Processor",
                        style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width * 0.05)),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: Size(
                              MediaQuery.of(context).size.height * 0.125,
                              MediaQuery.of(context).size.height * 0.125),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: updateProcessor,
                      child: Text('$processorCounter',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.1))),
                ],
              ),
              // LabeledButton(
              //     label: "Processor",
              //     buttonContent: processorCounter,
              //     functionOnTap: updateProcessor),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.width * 0.0125),
                    child: Text("+/-",
                        style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width * 0.075)),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          minimumSize: Size.square(
                            MediaQuery.of(context).size.height * 0.1,
                          ),
                          // minimumSize: Size(
                          //     MediaQuery.of(context).size.height * 0.075,
                          //     MediaQuery.of(context).size.height * 0.075),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: toggleNegative,
                      child: signIcon),
                ],
              ),
            ],
          )
        ],
      )),
      bottomNavigationBar: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            // shape: RectangleBorder(
            //   borderRadius: BorderRadius.zero, // Makes it completely rectangular
            // ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            foregroundColor: Theme.of(context).colorScheme.secondary,
            iconColor: Theme.of(context).colorScheme.secondary),
        iconAlignment: IconAlignment.end,
        onPressed: () {
          // PLACEHOLDER
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Submit'),
      ),
    );
  }
}
