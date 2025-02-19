import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';
import 'package:frc1148_2025_scouting_app/scroll_controller.dart';

String Combatability =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.';
String Feats =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.';
String HPlayer =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec placerat sollicitudin ex a porttitor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Aliquam at tellus ut nulla tincidunt gravida a non sapien. Curabitur eu magna sit amet leo scelerisque maximus in at mi. Morbi laoreet nulla ante, tristique sodales neque malesuada vel. Sed fermentum ultrices ullamcorper. Vestibulum gravida volutpat tellus vel ornare. Cras non convallis turpis. Vestibulum feugiat luctus lobortis. Integer vehicula porta dolor.';

final ScrollController compatibilityController = ScrollController();
final ScrollController featsController = ScrollController();
final ScrollController hPlayerController = ScrollController();

class LeadScoutNotesVisPage extends StatefulWidget {
  const LeadScoutNotesVisPage({super.key, required this.teamName});
  final String teamName;

  @override
  State<LeadScoutNotesVisPage> createState() => _LeadScoutNotesVisPage();
}

class _LeadScoutNotesVisPage extends State<LeadScoutNotesVisPage> {
  Future<void> setUp() async {}

  Widget buildStatItem(String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: height * 0.0175),
        ),
        const SizedBox(height: 4),
        Text(
          "NUM",
          style: TextStyle(
            fontSize: height * 0.02,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget buildStatsContainer(double width, double height) {
    return Container(
      width: width,
      height: height * 1 / 3,
      alignment: AlignmentDirectional.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("Coral Per Match", height)),
                Expanded(child: buildStatItem("High OPR Count", height)),
                Expanded(child: buildStatItem("Middle OPR Count", height)),
                Expanded(child: buildStatItem("Low OPR Count", height)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("Algae Per Match", height)),
                Expanded(child: buildStatItem("Net OPR Count", height)),
                Expanded(child: buildStatItem("Processor OPR Count", height)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildStatItem("Deep Cage %", height)),
                Expanded(child: buildStatItem("Shallow Cage %", height)),
                Expanded(
                    child: Column(
                  children: [
                    Expanded(
                      // child: Text(
                      //   "Auto Table",
                      //   style: TextStyle(fontSize: height * 0.0175),
                      // ),
                      child: ElevatedButton(
                        onPressed: () async {},
                        child: const Text("Auto Table",
                            style: TextStyle(
                                color: Colors.lightBlue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.lightBlue)),
                      ),
                    ),
                    Expanded(
                      // child: Text(
                      //   "Preset Comments",
                      //   style: TextStyle(fontSize: height * 0.0175),
                      // ),
                      child: ElevatedButton(
                        onPressed: () async {},
                        child: const Text("Preset Comments",
                            style: TextStyle(
                                color: Colors.lightBlue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.lightBlue)),
                      ),
                    ),
                  ],
                ))
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.teamName),
        ),
        body: Center(
          child: ListView(
            children: [
              buildStatsContainer(width, height),

              const Divider(),

              // First Row
              SizedBox(
                height: height * 0.3,
                width: width,
                child: Column(
                  children: [
                    Container(
                      height: height * 0.05,
                      width: width,
                      alignment: Alignment.center,
                      child: const Text(
                        'Compatibility',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller:
                            compatibilityController, // 🔴 FIX: Attach the controller
                        child: SingleChildScrollView(
                          controller:
                              compatibilityController, // 🔴 FIX: Attach the controller
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10.0),
                            child: Text(
                              Combatability,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Second Row
              SizedBox(
                height: height * 0.3,
                width: width,
                child: Column(
                  children: [
                    Container(
                      height: height * 0.05,
                      width: width,
                      alignment: Alignment.center,
                      child: const Text(
                        'Notable Feats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller:
                            featsController, // 🔴 FIX: Attach the controller
                        child: SingleChildScrollView(
                          controller:
                              featsController, // 🔴 FIX: Attach the controller
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10.0),
                            child: Text(
                              Feats,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Third Row
              SizedBox(
                height: height * 0.3,
                width: width,
                child: Column(
                  children: [
                    Container(
                      height: height * 0.05,
                      width: width,
                      alignment: Alignment.center,
                      child: const Text(
                        'Human Player Net ACC',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller:
                            hPlayerController, // 🔴 FIX: Attach the controller
                        child: SingleChildScrollView(
                          controller:
                              hPlayerController, // 🔴 FIX: Attach the controller
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10.0),
                            child: Text(
                              HPlayer,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Container(
              //   width: width,
              //   height: height * 1 / 13,
              //   //color Colors.amber[300],
              //   alignment: AlignmentDirectional.center,
              // ),
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
              //   },
              //   child: const Text("Next",
              //       style: TextStyle(color: colors.myOnPrimary)),
              // )
            ],
          ),
        ),
        bottomNavigationBar: ElevatedButton(
          onPressed: () async {
            // await _submitSection();
            // setState(() {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute
            //     (
            //       builder: (context) => Entrance(onThemeChanged: (newTheme) {
            //     })
            //     )
            //   );
            // });
          },
          child:
              const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
        ));
  }
}
