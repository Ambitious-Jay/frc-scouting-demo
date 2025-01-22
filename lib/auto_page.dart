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
  bool isBlue = true;
  bool inCenterZone = false;
  bool fieldFlipped = false;
  bool inLeftZone = false;
  bool inRightZone = false;

  double min(double valOne, double valTwo) {
    return valOne > valTwo ? valTwo : valOne;
  }
  double max(double valOne, double valTwo) {
    return valOne > valTwo ? valOne : valTwo;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double screenPadding = 12;
    const double imageWidthToHeight = 13 / 14;
    final double fieldWidth = min(screenWidth - 2 * screenPadding, 400);
    final double fieldHeight = fieldWidth / imageWidthToHeight;
    // const AssetImage bg = AssetImage('assets/reefscape_blue_field.jpg');
    AssetImage bg = isBlue
        ? const AssetImage('assets/reefscape_blue_field.jpg')
        : const AssetImage('assets/reefscape_red_field.jpg');
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
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  fieldFlipped = !fieldFlipped;
                });
              },
              icon: const Icon(Icons.rotate_90_degrees_ccw),
            ),
          ],
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
                            height: fieldHeight,
                            child: Transform.rotate(
                              angle: fieldFlipped ? 3.14159265 : 0,
                              child: DecoratedBox(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: bg, fit: BoxFit.fitWidth)),
                              )
                            ),
                        ),
                        Positioned(
                            top: fieldHeight / 2 - 25,
                            right: (fieldFlipped ? fieldWidth * 4 / 5 : fieldWidth / 4) - 25,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text("Center"),
                                  Checkbox(
                                      value: inCenterZone,
                                      onChanged: (bool? value) => {
                                            setState(() {
                                              inCenterZone = value!;
                                            })
                                          })
                                ])),
                        Positioned(
                          left: fieldWidth / 4,
                          top: fieldHeight / 4 - 25,
                          // top: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children:[
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text("Left"),
                                  Checkbox(
                                    value: inLeftZone,
                                    onChanged: (bool? value) => {
                                      setState(() {
                                        inLeftZone = value!;
                                      })
                                    }
                                  )
                                ]
                              ),
                              SizedBox(
                                height: max(0, fieldHeight * 5 / 12 - 50)
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text("Right"),
                                  Checkbox(
                                    value: inRightZone,
                                    onChanged: (bool? value) => {
                                      setState(() {
                                        inRightZone = value!;
                                      })
                                    }
                                  )
                                ]
                              ),
                            ]
                          )
                        ),
                        // Positioned(
                        //     top: fieldHeight / 4 - 36,
                        //     left: fieldWidth / 4,
                        //     child: Column(
                        //         mainAxisAlignment: MainAxisAlignment.end,
                        //         crossAxisAlignment: CrossAxisAlignment.center,
                        //         children: [
                        //           const Text("Left"),
                        //           Checkbox(
                        //               value: inLeftZone,
                        //               onChanged: (bool? value) => {
                        //                     setState(() {
                        //                       inLeftZone = value!;
                        //                     })
                        //                   })
                        //         ])),
                        // Positioned(
                        //     top: 3 * fieldHeight / 4 - 36,
                        //     left: fieldWidth / 4,
                        //     child: Column(
                        //         mainAxisAlignment: MainAxisAlignment.end,
                        //         crossAxisAlignment: CrossAxisAlignment.center,
                        //         children: [
                        //           const Text("Right"),
                        //           Checkbox(
                        //               value: inRightZone,
                        //               onChanged: (bool? value) => {
                        //                     setState(() {
                        //                       inRightZone = value!;
                        //                     })
                        //                   })
                        //         ])),
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
