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
    try {
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
          const Text ("Alliance Info",),
          Text(widget.teamName),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            Container(
              width: width,
              height: height*4/13,
              //color Colors.amber[300],
              alignment: AlignmentDirectional.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text("Coral Per Match"),
                      Text("High OPR count"),
                      Text("Middle OPR count"),
                      Text("Low OPR count")],
                  ),
                  Column(
                    children: [
                      Text("Coral Per Match"),
                      Text("High OPR count"),
                      Text("Middle OPR count"),
                      Text("Low OPR count")],
                  ),
                  Column(
                    children: [
                      Text("Deep Cage %"),
                      Text("Shallow Cage %"),
                      Text("Preset Comments Link")],
                  ),
                ],
              ),
            ),
            const Divider(),
            Container(
              width: width,
              height: height*4/13,
              //color Colors.amber[300],
              alignment: AlignmentDirectional.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text("Coral Per Match"),
                      Text("High OPR count"),
                      Text("Middle OPR count"),
                      Text("Low OPR count")],
                  ),
                  Column(
                    children: [
                      Text("Coral Per Match"),
                      Text("High OPR count"),
                      Text("Middle OPR count"),
                      Text("Low OPR count")],
                  ),
                  Column(
                    children: [
                      Text("Deep Cage %"),
                      Text("Shallow Cage %"),
                      Text("Preset Comments Link")],
                  ),
                ],
              ),
            ),
            const Divider(),
            Container(
              width: width,
              height: height*4/13,
              //color Colors.amber[300],
              alignment: AlignmentDirectional.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text("Coral Per Match"),
                      Text("High OPR count"),
                      Text("Middle OPR count"),
                      Text("Low OPR count")],
                  ),
                  Column(
                    children: [
                      Text("Coral Per Match"),
                      Text("High OPR count"),
                      Text("Middle OPR count"),
                      Text("Low OPR count")],
                  ),
                  Column(
                    children: [
                      Text("Deep Cage %"),
                      Text("Shallow Cage %"),
                      Text("Preset Comments Link")],
                  ),
                ],
              ),
            ),
            const Divider(),
            Container(
              width: width,
              height: height*1/13,
              //color Colors.amber[300],
              alignment: AlignmentDirectional.center,
            ),
            ElevatedButton(
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
              child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
            )
          ],
      )   
    )
    );
  }
}
