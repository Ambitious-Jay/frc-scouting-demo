import 'package:flutter/material.dart';

class AutoPage extends StatefulWidget {
  const AutoPage(
      {Key? key,
      required this.teamName,
      // required this.onThemeChanged,
      required this.id})
      : super(key: key);

  // final Function(ThemeMode) onThemeChanged;
  final String teamName;
  final String id;

  @override
  _AutoPageState createState() => _AutoPageState();
}

class _AutoPageState extends State<AutoPage> {
  ThemeMode themeMode = ThemeMode.system;
  bool inCenterZone = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    const AssetImage bg = AssetImage('assets/reefscape_blue_field.jpg');
    return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: Column(
            children: [
              const Text(
                "Auto Phase",
              ),
              Text("${widget.id} is watching team ${widget.teamName}"),
            ],
          ),
        ),
        body: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 370,
                height: 370,
                decoration: const BoxDecoration(
                image: DecorationImage(
                  image: bg,
                  fit: BoxFit.fill,
                ),
              )),
              // const SizedBox(
              //     width: 150,
              //     height: 150,
              //     child: DecoratedBox(
              //         decoration: BoxDecoration(
              //             color: Color.fromARGB(255, 128, 128, 128)))),
              // const SizedBox(
              //     width: 100,
              //     height: 100,
              //     child: DecoratedBox(
              //         decoration: BoxDecoration(
              //             color: Color.fromARGB(255, 255, 255, 255)))),
            ]),
          ),
          Checkbox(
            value: inCenterZone,
            onChanged: (bool? value) {
              setState(() {
                inCenterZone = value!;
              });
            },
          ),
        ]));
  }
}
