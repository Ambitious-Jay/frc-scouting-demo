import 'package:flutter/material.dart';
import 'color_scheme.dart';

class TeamStatsList extends StatefulWidget {
  const TeamStatsList({super.key, required this.teamName});
  final String teamName;
  @override
  State<TeamStatsList> createState() => _TeamStatsList();
}

class _TeamStatsList extends State<TeamStatsList> {
  Future<void> _submitSection() async {
    try {} catch (e) {
      print('Error: $e');
    }
  }

  //custom container to cut out repetitive code (This is 100% something Claude cooked up I can't deny)
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
                        child: const Text("Auto Table", style: TextStyle(color: Colors.lightBlue,decoration: TextDecoration.underline, decorationColor: Colors.lightBlue)),
                      ),
                    ),
                    Expanded(
                      // child: Text(
                      //   "Preset Comments",
                      //   style: TextStyle(fontSize: height * 0.0175),
                      // ),
                      child: ElevatedButton(
                        onPressed: () async {},
                        child: const Text("Preset Comments", style: TextStyle(color: Colors.lightBlue,decoration:TextDecoration.underline, decorationColor: Colors.lightBlue)),
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
        title: Column(
          children: [
            const Text("Alliance Info"),
            Text(widget.teamName),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            buildStatsContainer(width, height),
            const Divider(),
            buildStatsContainer(width, height),
            const Divider(),
            buildStatsContainer(width, height),
          ],
        ),
      ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () async {},
        child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
      ),
    );
  }
}
