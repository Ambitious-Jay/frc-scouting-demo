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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Objective Page'),
      ),
      body: const Center(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image(image: AssetImage('assets/reef.png')),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("mimimi l4"),
              Text("mimimi l2 and l3"),
              Text("mimimi trough")
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [Text("mimimi net"), Text("mimimi processor")],
          ),
          Text("mimimi negative toggle")
        ],
      )),
    );
  }
}
