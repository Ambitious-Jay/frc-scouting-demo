import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/endgame.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class IntegerWrapper {
  int value = 0;
  IntegerWrapper(this.value);
}

class ObjectivePage extends StatefulWidget {
  const ObjectivePage({
    Key? key,
    required this.teamName,
    required this.teamNickname,
    required this.matchNumber,
    required this.channel,
    required this.onThemeChanged,
    required this.webSocketService,
    this.isLeadScout = false,
  }) : super(key: key);

  final String teamName;
  final String teamNickname;
  final String matchNumber;
  final WebSocketChannel channel;
  final Function(ThemeMode) onThemeChanged;
  final WebSocketService webSocketService;
  final bool isLeadScout;

  @override
  _ObjectivePageState createState() => _ObjectivePageState();
}

class _ObjectivePageState extends State<ObjectivePage> {
  ThemeMode themeMode = ThemeMode.system;
  String _username = "";
  bool isBlue = true;

  IntegerWrapper l4Counter = IntegerWrapper(0);
  IntegerWrapper l2l3Counter = IntegerWrapper(0);
  IntegerWrapper l1Counter = IntegerWrapper(0);
  IntegerWrapper netCounter = IntegerWrapper(0);
  IntegerWrapper processorCounter = IntegerWrapper(0);

  bool doIncrement = true;
  Map<String, dynamic>? pitScoutingData;
  bool _isLoading = true;

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
    IconData iconData = doIncrement ? Icons.add : Icons.remove;
    return Icon(
      iconData,
      color: Theme.of(context).colorScheme.primary,
      size: MediaQuery.of(context).size.width * 0.05,
    );
  }

  Future<void> _submitObjectiveScoutingData() async {
  final String teamNumberWithPrefix =
      widget.teamName.toLowerCase().startsWith('frc')
          ? widget.teamName
          : 'frc${widget.teamName}';

  final Map<String, dynamic> fakeData = {
    'team': teamNumberWithPrefix,
    'match': widget.matchNumber,
    'scout': _username,
    'L4': l4Counter.value,
    'L2L3': l2l3Counter.value,
    'L1': l1Counter.value,
    'Net': netCounter.value,
    'Processor': processorCounter.value,
  };

  debugPrint("🔹 [FAKE SUBMIT] Objective scouting data: ${jsonEncode(fakeData)}");

  // Simulate async wait
  await Future.delayed(const Duration(milliseconds: 500));
}

  Future<void> _loadAllData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Only fetch pit scouting data if the user is a lead scout
      if (widget.isLeadScout) {
        // Fetch pit scouting data
        await _fetchPitScoutingData();
        
        // Force a rebuild to ensure the UI reflects the loaded data
        if (mounted) {
          setState(() {});
        }
        
        debugPrint("All data loaded. Pit data: ${jsonEncode(pitScoutingData)}");
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error loading data. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // End loading
        });
      }
    }
  }

  Future<void> _fetchPitScoutingData() async {
  debugPrint("🔹 [FAKE FETCH] Returning placeholder pit scouting data...");

  await Future.delayed(const Duration(milliseconds: 500));

  setState(() {
    pitScoutingData = {
      'team_number': widget.teamName,
      'robot_weight': "120",
      'drive_type': "swerve",
      'motor_type': "NEO",
      'motor_count': 8,
      'bumper_quality': 3,
      'coral_intake_type': "ground",
      'algae_intake_type': "over the bumper",
      'L1': "true",
      'L2': "true",
      'L3': "true",
      'L4': "false",
      'processor': "true",
      'net': "false",
      'climb_type': "trap",
      'autonomous_coral_points': 12,
      'leaves_start_line': "true",
    };
  });
}

  // NEW: Method to save capabilities data to the database
  Future<void> _saveCapabilitiesData(
  String robotWeight,
  String driveType,
  String motorType,
  String motorCount,
  String bumperQuality,
  String coralIntakeType,
  String algaeIntakeType,
  String climbType,
  String autonomousCoralPoints,
  bool l1Capability,
  bool l2Capability,
  bool l3Capability,
  bool l4Capability,
  bool processorCapability,
  bool netCapability,
  bool leavesStartLineCapability,
) async {
  final fakeData = {
    'robot_weight': robotWeight,
    'drive_type': driveType,
    'motor_type': motorType,
    'motor_count': motorCount,
    'bumper_quality': bumperQuality,
    'coral_intake_type': coralIntakeType,
    'algae_intake_type': algaeIntakeType,
    'climb_type': climbType,
    'autonomous_coral_points': autonomousCoralPoints,
    'L1': l1Capability,
    'L2': l2Capability,
    'L3': l3Capability,
    'L4': l4Capability,
    'processor': processorCapability,
    'net': netCapability,
    'leaves_start_line': leavesStartLineCapability,
  };

  debugPrint("🔹 [FAKE SAVE] Updated capabilities data: ${jsonEncode(fakeData)}");

  setState(() {
    pitScoutingData = fakeData;
  });

  await Future.delayed(const Duration(milliseconds: 300));
}

  // NEW: Method to show capabilities edit dialog
  void _showCapabilitiesEditDialog() {
    // Make sure we use the already fetched pit scouting data
    debugPrint(
        "Opening capabilities dialog with existing data: ${pitScoutingData != null ? 'data available' : 'no data'}");

    // If no pit data is available, show loading dialog and try to fetch
    if (pitScoutingData == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading capabilities data..."),
                ],
              ),
            ),
          );
        },
      );

      // Try to fetch the data
      _fetchPitScoutingData().then((_) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          if (pitScoutingData != null) {
            // Force a rebuild of the dialog with the new data
            setState(() {}); // Trigger a rebuild of the parent widget
            _showCapabilitiesEditDialog(); // Recursively show dialog with data
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Error loading data. Please try again."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
      return;
    }

    // Create controllers with the data
    final robotWeightController =
        TextEditingController(text: safeString(pitScoutingData!['robot_weight']));
    final driveTypeController =
        TextEditingController(text: safeString(pitScoutingData!['drive_type']));
    final motorTypeController =
        TextEditingController(text: safeString(pitScoutingData!['motor_type']));
    final motorCountController =
        TextEditingController(text: safeString(pitScoutingData!['motor_count']));
    final bumperQualityController =
        TextEditingController(text: safeString(pitScoutingData!['bumper_quality']));
    final coralIntakeTypeController =
        TextEditingController(text: safeString(pitScoutingData!['coral_intake_type']));
    final algaeIntakeTypeController =
        TextEditingController(text: safeString(pitScoutingData!['algae_intake_type']));
    final climbTypeController =
        TextEditingController(text: safeString(pitScoutingData!['climb_type']));
    final autonomousCoralPointsController = TextEditingController(
        text: safeString(pitScoutingData!['autonomous_coral_points']));

    // Set boolean values directly from the data
    bool l1Capability = safeBool(pitScoutingData!['L1']);
    bool l2Capability = safeBool(pitScoutingData!['L2']);
    bool l3Capability = safeBool(pitScoutingData!['L3']);
    bool l4Capability = safeBool(pitScoutingData!['L4']);
    bool processorCapability = safeBool(pitScoutingData!['processor']);
    bool netCapability = safeBool(pitScoutingData!['net']);
    bool leavesStartLineCapability = safeBool(pitScoutingData!['leaves_start_line']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Edit Team ${widget.teamName} Capabilities",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Text inputs for string and numeric fields
                      _buildDialogTextField(
                          robotWeightController, "Robot Weight"),
                      _buildDialogTextField(driveTypeController, "Drive Type"),
                      _buildDialogTextField(motorTypeController, "Motor Type"),
                      _buildDialogTextField(motorCountController, "Motor Count",
                          isNumeric: true),
                      _buildDialogTextField(
                          bumperQualityController, "Bumper Quality (1-10)",
                          isNumeric: true),
                      _buildDialogTextField(
                          coralIntakeTypeController, "Coral Intake Type"),
                      _buildDialogTextField(
                          algaeIntakeTypeController, "Algae Intake Type"),
                      _buildDialogTextField(climbTypeController, "Climb Type"),
                      _buildDialogTextField(
                          autonomousCoralPointsController, "Auto Coral Points",
                          isNumeric: true),

                      const Divider(height: 20),

                      // Checkboxes for boolean fields
                      _buildDialogCheckbox("L1 Capability", l1Capability,
                          (value) {
                        setDialogState(() => l1Capability = value!);
                      }),
                      _buildDialogCheckbox("L2 Capability", l2Capability,
                          (value) {
                        setDialogState(() => l2Capability = value!);
                      }),
                      _buildDialogCheckbox("L3 Capability", l3Capability,
                          (value) {
                        setDialogState(() => l3Capability = value!);
                      }),
                      _buildDialogCheckbox("L4 Capability", l4Capability,
                          (value) {
                        setDialogState(() => l4Capability = value!);
                      }),
                      _buildDialogCheckbox("Processor", processorCapability,
                          (value) {
                        setDialogState(() => processorCapability = value!);
                      }),
                      _buildDialogCheckbox("Net", netCapability, (value) {
                        setDialogState(() => netCapability = value!);
                      }),
                      _buildDialogCheckbox(
                          "Leaves Start Line", leavesStartLineCapability,
                          (value) {
                        setDialogState(() => leavesStartLineCapability = value!);
                      }),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Save the edited data
                              await _saveCapabilitiesData(
                                  robotWeightController.text,
                                  driveTypeController.text,
                                  motorTypeController.text,
                                  motorCountController.text,
                                  bumperQualityController.text,
                                  coralIntakeTypeController.text,
                                  algaeIntakeTypeController.text,
                                  climbTypeController.text,
                                  autonomousCoralPointsController.text,
                                  l1Capability,
                                  l2Capability,
                                  l3Capability,
                                  l4Capability,
                                  processorCapability,
                                  netCapability,
                                  leavesStartLineCapability);
                              
                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Capabilities saved successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // After dialog is closed, refresh the pit scouting data to reflect any changes
      _fetchPitScoutingData().then((_) {
        if (mounted) {
          setState(() {}); // Force a rebuild of the parent widget
        }
      });
    });
  }

  // NEW: Helper methods for dialog building
  Widget _buildDialogTextField(TextEditingController controller, String label,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Widget _buildDialogCheckbox(
      String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  // NEW: Helper functions for safe type conversion
  String safeString(dynamic value) {
    if (value == null) return "";
    return value.toString();
  }

  int safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  bool safeBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    String str = value.toString().toLowerCase();
    return str == "true" || str == "1" || str == "yes";
  }

  @override
  void initState() {
    super.initState();
    AuthService.getUsername().then((value) {
      setState(() {
        _username = value ?? "";
      });
    });

    // Load all data once when the page is initialized
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Column(
          children: [
            const Text("Objective Phase"),
            Text(
              '$_username: Team ${widget.teamName} in match ${widget.matchNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading team data..."),
                ],
              ),
            )
          : widget.isLeadScout
              ? buildLeadScoutLayout(BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height))
              : buildMatchScoutLayout(BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height)),
      bottomNavigationBar: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: Theme.of(context).colorScheme.secondary,
          iconColor: Theme.of(context).colorScheme.secondary,
        ),
        iconAlignment: IconAlignment.end,
        onPressed: _isLoading
            ? null // Disable the button while loading
            : () async {
                await _submitObjectiveScoutingData();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Endgame(
                      teamName: widget.teamName,
                      teamNickname: widget.teamNickname,
                      matchNumber: widget.matchNumber,
                      channel: widget.webSocketService.channel!,
                      onThemeChanged: widget.onThemeChanged,
                      webSocketService: widget.webSocketService,
                      isLeadScout: widget.isLeadScout,
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Next'),
      ),
    );
  }

  Widget buildMatchScoutLayout(BoxConstraints constraints) {
    final double screenWidth = MediaQuery.of(context).size.width;
    AssetImage reefImg = const AssetImage('assets/reef.png');

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: screenWidth * 0.03),
                  SizedBox(
                    width: screenWidth * 0.375,
                    height: screenWidth,
                    child: Image(
                      image: reefImg,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: Text("L4",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize:
                              Size(screenWidth * 0.30, screenWidth * 0.20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () => updateCounter(l4Counter, doIncrement),
                        child: Text('${l4Counter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Text("L2 & L3",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize:
                              Size(screenWidth * 0.30, screenWidth * 0.20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () =>
                            updateCounter(l2l3Counter, doIncrement),
                        child: Text('${l2l3Counter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Text("L1",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize:
                              Size(screenWidth * 0.30, screenWidth * 0.20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () => updateCounter(l1Counter, doIncrement),
                        child: Text('${l1Counter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.10)),
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
                        padding: EdgeInsets.only(bottom: screenWidth * 0.0125),
                        child: Text("Net",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: Size.square(screenWidth * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () => updateCounter(netCounter, doIncrement),
                        child: Text('${netCounter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.1)),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.0125),
                        child: Text("Processor",
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: Size.square(screenWidth * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () =>
                            updateCounter(processorCounter, doIncrement),
                        child: Text('${processorCounter.value}',
                            style: TextStyle(fontSize: screenWidth * 0.1)),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.0125),
                        child: Text("+/-",
                            style: TextStyle(fontSize: screenWidth * 0.075)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          minimumSize: Size.square(screenWidth * 0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: () {
                          setState(() {
                            doIncrement = !doIncrement;
                          });
                        },
                        child: signIcon,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLeadScoutLayout(BoxConstraints constraints) {
    double availableWidth = MediaQuery.of(context).size.width - 24;
    double fieldWidth = min(availableWidth, 400);
    double fieldHeight = fieldWidth;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Left side: Reef image with counters
                    Row(
                      children: [
                        SizedBox(
                          width: fieldWidth / 2,
                          height: fieldHeight / 2,
                          child: Image(
                            image: AssetImage('assets/reef.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildCounterButton(
                                "L4", l4Counter, doIncrement, 80),
                            const SizedBox(height: 20),
                            buildCounterButton(
                                "L2 & L3", l2l3Counter, doIncrement, 80),
                            const SizedBox(height: 20),
                            buildCounterButton(
                                "L1", l1Counter, doIncrement, 80),
                          ],
                        ),
                      ],
                    ),

                    // Right side: Net/Processor counters and +/- button
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildCounterButton("Net", netCounter, doIncrement, 80),
                        const SizedBox(height: 20),
                        buildCounterButton(
                            "Processor", processorCounter, doIncrement, 80),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            const Text("+/-", style: TextStyle(fontSize: 16)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                              ),
                              onPressed: () {
                                setState(() {
                                  doIncrement = !doIncrement;
                                });
                              },
                              child: Center(child: signIcon),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Add the Capabilities button only for lead scouts
                if (widget.isLeadScout) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(150, 100),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: () {
                      // Check if pit data is properly loaded by looking for specific fields
                      bool isDataComplete = pitScoutingData != null &&
                          pitScoutingData!.containsKey('robot_weight') &&
                          pitScoutingData!.containsKey('drive_type');

                      if (!isDataComplete) {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Dialog(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text("Loading capabilities data..."),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        // Try to refetch the data
                        _fetchPitScoutingData().then((_) {
                          // Check if data was successfully loaded
                          if (mounted) {
                            Navigator.of(context).pop(); // Close loading dialog

                            // Double check data was actually loaded
                            if (pitScoutingData != null &&
                                pitScoutingData!.containsKey('robot_weight')) {
                              _showCapabilitiesEditDialog();
                            } else {
                              // Show error if data still not loaded
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Error loading data. Please try again.")),
                              );
                            }
                          }
                        });
                      } else {
                        // Data is already properly loaded, show dialog directly
                        _showCapabilitiesEditDialog();
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.edit_attributes, size: 36),
                        SizedBox(height: 8),
                        Text("Capabilities", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCounterButton(String label, IntegerWrapper counter,
      bool doIncrement, double buttonSize) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(buttonSize * 0.1),
          child: Text(label, style: TextStyle(fontSize: buttonSize * 0.15)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.secondary,
            minimumSize: Size(buttonSize, buttonSize),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          onPressed: () => updateCounter(counter, doIncrement),
          child: Text('${counter.value}',
              style: TextStyle(fontSize: buttonSize * 0.3)),
        ),
      ],
    );
  }
}
