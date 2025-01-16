import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/labeled_button.dart';

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
  String counter = "-";

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
      if (isCounterPositive) {
        counter = "-";
      } else {
        counter = "+";
      }
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
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: const Image(
                //reef photo
                image: AssetImage('assets/reef.png'),
                fit: BoxFit.contain,
              )),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //         backgroundColor: Theme.of(context).colorScheme.primary,
              //         foregroundColor: Theme.of(context).colorScheme.secondary,
              //         minimumSize: const Size.square(70),
              //         shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(5))),
              //     onPressed: updateL4,
              //     child: Text('$l4Counter')),
              LabeledButton(
                  label: "L4",
                  buttonContent: l4Counter,
                  functionOnTap: updateL4),
              // ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //         backgroundColor: Theme.of(context).colorScheme.primary,
              //         foregroundColor: Theme.of(context).colorScheme.secondary,
              //         minimumSize: const Size.square(70),
              //         shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(5))),
              //     onPressed: updateL2L3,
              //     child: Text('$l2l3Counter')),
              LabeledButton(
                  label: "L2/L3",
                  buttonContent: l2l3Counter,
                  functionOnTap: updateL2L3),
              // ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //         backgroundColor: Theme.of(context).colorScheme.primary,
              //         foregroundColor: Theme.of(context).colorScheme.secondary,
              //         minimumSize: const Size.square(70),
              //         shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(5))),
              //     onPressed: updateL1,
              //     child: Text('$l1Counter')),
              LabeledButton(
                  label: "L1",
                  buttonContent: l1Counter,
                  functionOnTap: updateL1),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //         backgroundColor: Theme.of(context).colorScheme.primary,
              //         foregroundColor: Theme.of(context).colorScheme.secondary,
              //         minimumSize: const Size.square(70),
              //         shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(5))),
              //     onPressed: updateNet,
              //     child: Text('$netCounter')),
              LabeledButton(
                  label: "Net",
                  buttonContent: netCounter,
                  functionOnTap: updateNet),
              // ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //         backgroundColor: Theme.of(context).colorScheme.primary,
              //         foregroundColor: Theme.of(context).colorScheme.secondary,
              //         minimumSize: const Size.square(70),
              //         shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(5))),
              //     onPressed: updateProcessor,
              //     child: Text('$processorCounter')),
              LabeledButton(
                  label: "Processor",
                  buttonContent: processorCounter,
                  functionOnTap: updateProcessor),
            ],
          ),
          Column(
            children: [
              const Spacer(),
              // ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //         backgroundColor: Theme.of(context).colorScheme.primary,
              //         foregroundColor: Theme.of(context).colorScheme.secondary,
              //         minimumSize: const Size.square(70),
              //         shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(5))),
              //     onPressed: toggleNegative,
              //     child: Text(counter)),
              LabeledButton(
                  label: "Toggle +/-",
                  buttonContent: counter,
                  functionOnTap: toggleNegative),
              const SizedBox(
                height: 20,
              )
            ],
          )
        ],
      )),
    );
  }
}
