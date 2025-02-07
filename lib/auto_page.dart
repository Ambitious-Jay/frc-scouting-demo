import 'package:flutter/material.dart';

class IntegerWrapper {
  int value = 0;
  IntegerWrapper(this.value);
}

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
  bool inLeftZone = false;
  bool inRightZone = false;
  bool fieldFlipped = false;

  IntegerWrapper l4Counter = IntegerWrapper(0);
  IntegerWrapper l2l3Counter = IntegerWrapper(0);
  IntegerWrapper l1Counter = IntegerWrapper(0);
  IntegerWrapper netCounter = IntegerWrapper(0);
  IntegerWrapper processorCounter = IntegerWrapper(0);

  bool doIncrement = true;

  double min(double valOne, double valTwo) {
    return valOne > valTwo ? valTwo : valOne;
  }

  double max(double valOne, double valTwo) {
    return valOne > valTwo ? valOne : valTwo;
  }

  void updateCounter(IntegerWrapper counter, bool doIncrement) {
    setState(() {
      int inc = doIncrement ? 1 : -1;
      if (counter.value + inc >= 0) {
        counter.value += inc;
      }
    });
  }

  Icon get signIcon {
    IconData iconData;
    if (doIncrement) {
      iconData = Icons.add;
    } else {
      iconData = Icons.remove;
    }
    return Icon(iconData,
        color: Theme.of(context).colorScheme.primary,
        size: MediaQuery.of(context).size.width * 0.1);
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
    AssetImage reefImg = const AssetImage('assets/reef.png');
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
                              )),
                        ),
                        Positioned(
                            top: fieldHeight / 2 - 25,
                            right: (fieldFlipped
                                    ? fieldWidth * 4 / 5
                                    : fieldWidth / 4) -
                                25,
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
                            left: (fieldFlipped ? 2 : 1) * fieldWidth / 3 - 25,
                            top: fieldHeight / 4 - 25,
                            // top: 0,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Text("Left"),
                                        Checkbox(
                                            value: inLeftZone,
                                            onChanged: (bool? value) => {
                                                  setState(() {
                                                    inLeftZone = value!;
                                                  })
                                                })
                                      ]),
                                  SizedBox(height: fieldHeight / 2 - 50),
                                  Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Text("Right"),
                                        Checkbox(
                                            value: inRightZone,
                                            onChanged: (bool? value) => {
                                                  setState(() {
                                                    inRightZone = value!;
                                                  })
                                                })
                                      ]),
                                ])),
                      ])),
                  Row(
                    children: [
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.375,
                          child: Image(
                            //reef photo
                            image: reefImg,
                            fit: BoxFit.contain,
                          )),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.05,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.01),
                            child: Text("L4",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.1)),
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
                                      MediaQuery.of(context).size.height *
                                          0.15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5))),
                              onPressed: () =>
                                  updateCounter(l4Counter, doIncrement),
                              child: Text('${l4Counter.value}',
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.15))),
                          Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.01),
                            child: Text("L2 & L3",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.1)),
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
                                      MediaQuery.of(context).size.height *
                                          0.15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5))),
                              onPressed: () =>
                                  updateCounter(l2l3Counter, doIncrement),
                              child: Text('${l2l3Counter.value}',
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.15))),
                          Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.01),
                            child: Text("L1",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.1)),
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  minimumSize: Size(
                                      MediaQuery.of(context).size.width * 0.5,
                                      MediaQuery.of(context).size.height *
                                          0.15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5))),
                              onPressed: () =>
                                  updateCounter(l1Counter, doIncrement),
                              child: Text('${l1Counter.value}',
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.15))),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.075,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.width * 0.0125),
                            child: Text("Net",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.05)),
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  minimumSize: Size(
                                      MediaQuery.of(context).size.height *
                                          0.125,
                                      MediaQuery.of(context).size.height *
                                          0.125),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5))),
                              onPressed: () =>
                                  updateCounter(netCounter, doIncrement),
                              child: Text('${netCounter.value}',
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.1))),
                        ],
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.width * 0.0125),
                            child: Text("Processor",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.05)),
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  minimumSize: Size(
                                      MediaQuery.of(context).size.height *
                                          0.125,
                                      MediaQuery.of(context).size.height *
                                          0.125),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5))),
                              onPressed: () =>
                                  updateCounter(processorCounter, doIncrement),
                              child: Text('${processorCounter.value}',
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.1))),
                        ],
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.width * 0.0125),
                            child: Text("+/-",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.075)),
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
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5))),
                              onPressed: () {
                                setState(() {
                                  doIncrement = !doIncrement;
                                });
                              },
                              child: signIcon),
                        ],
                      ),
                    ],
                  )
                ]))));
  }
}
