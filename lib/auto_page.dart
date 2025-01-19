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
  bool inProcessorZone = false;
  bool inOppositeZone = false;

  double min(double valOne, double valTwo) {
    return valOne > valTwo ? valTwo : valOne;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double screenPadding = 12;
    const double imageWidthToHeight = 13 / 14;
    final double fieldWidth = min(screenWidth - 2 * screenPadding, 400);
    // const AssetImage bg = AssetImage('assets/reefscape_blue_field.jpg');
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
        body: Container(
            padding: const EdgeInsets.all(screenPadding),
            child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(
                            width: fieldWidth,
                            height: fieldWidth / imageWidthToHeight,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: bg, fit: BoxFit.fitWidth)),
                            )),
                        Checkbox(
                            value: inCenterZone,
                            onChanged: (bool? value) => {
                                  setState(() {
                                    inCenterZone = value!;
                                  })
                                }),
                        Checkbox(
                            value: inProcessorZone,
                            onChanged: (bool? value) => {
                                  setState(() {
                                    inProcessorZone = value!;
                                  })
                                }),
                        Checkbox(
                            value: inOppositeZone,
                            onChanged: (bool? value) => {
                                  setState(() {
                                    inOppositeZone = value!;
                                  })
                                }),
                      ])),
                  const SizedBox(
                      width: 50,
                      height: 1500,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.red),
                      ))
                ]))));
  }
}
