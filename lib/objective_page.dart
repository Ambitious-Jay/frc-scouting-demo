import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ObjectivePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  /// Accept the WebSocketChannel from main.dart
  final WebSocketChannel? channel;

  const ObjectivePage({
    Key? key,
    required this.onThemeChanged,
    required this.channel,
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

  void toggleNegative() {
    // To do
  }
  Future<void> _saveDataToDatabase() async {
    try {
      // Build an INSERT statement referencing your table and columns
      final sql = '''
        INSERT INTO [Match Data] 
          (l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter)
        VALUES
          ($l4Counter, $l2l3Counter, $l1Counter, $netCounter, $processorCounter)
      ''';

      // Prepare the bridging server message
      final cmd = {
        "type": "query",
        "text": sql,
      };

      // Ensure the channel is available
      if (widget.channel == null) {
        throw Exception('No WebSocket channel available.');
      }

      // Encode "length\r\njson" as the bridging server expects
      final encodedJson = jsonEncode(cmd);
      final prefix = '${encodedJson.length}\r\n';
      widget.channel!.sink.add(prefix + encodedJson);

      // Log that the INSERT command was sent
      debugPrint('Successfully sent INSERT command to bridging server: $sql');
    } catch (e, st) {
      debugPrint('Error sending counters to DB: $e\n$st');
    }
  }

  /// When the widget is disposed, send the counters once
  // @override
  // void dispose() {
  //   _saveDataToDatabase();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objective Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Row(
          children: [
            // Example image on the left side
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: const Image(
                image: AssetImage('assets/reef.png'),
                fit: BoxFit.contain,
              ),
            ),
            // Column with L4, L2/3, L1
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: incrementL4,
                  child: const Text("L4"),
                ),
                TextButton(
                  onPressed: incrementL2L3,
                  child: const Text("L2/3"),
                ),
                TextButton(
                  onPressed: incrementL1,
                  child: const Text("L1"),
                ),
              ],
            ),
            // Column with Net, Processor
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: incrementNet,
                  child: const Text("Net"),
                ),
                TextButton(
                  onPressed: incrementProcessor,
                  child: const Text("Processor"),
                ),
              ],
            ),
            // A button for +/-, if needed
            TextButton(
              onPressed: toggleNegative,
              child: const Text("+/-"),
            ),
          ],
        ),
      ),
    );
  }
}
