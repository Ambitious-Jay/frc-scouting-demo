import 'package:flutter/material.dart';

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
  int l4Counter = 0;
  int l2l3Counter = 0;
  int l1Counter = 0;
  int netCounter = 0;
  int processorCounter = 0;

  void incrementL4() {
    setState(() {
      l4Counter++;
    });
  }

  void incrementL2L3() {
    setState(() {
      l2l3Counter++;
    });
  }

  void incrementL1() {
    setState(() {
      l1Counter++;
    });
  }

  void incrementNet() {
    setState(() {
      netCounter++;
    });
  }

  void incrementProcessor() {
    setState(() {
      processorCounter++;
    });
  }

  void toggleNegative() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Objective Page'),
      ),
      body: Center(
          child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: const Image( //reef photo
                image: AssetImage('assets/reef.png'),
                fit: BoxFit.contain,
              )),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(onPressed: incrementL4, child: const Text("L4")),
              TextButton(onPressed: incrementL2L3, child: const Text("L2/3")),
              TextButton(onPressed: incrementL1, child: const Text("L1")),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(onPressed: incrementNet, child: const Text("Net")),
              TextButton(
                  onPressed: incrementProcessor,
                  child: const Text("Processor")),
            ],
          ),
          TextButton(onPressed: toggleNegative, child: const Text("+/-")),
        ],
      )),
    );
  }
}
