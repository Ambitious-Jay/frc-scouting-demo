import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/auto_table_page.dart';
import 'package:frc1148_2025_scouting_app/preset_comment.dart';
import 'package:frc1148_2025_scouting_app/graphing_page.dart';
import 'package:frc1148_2025_scouting_app/color_scheme.dart';

/// Removes any "frc" prefix and returns only the numeric part.
String normalizeTeamNumber(String rawTeamNumber) {
  final lower = rawTeamNumber.toLowerCase();
  if (lower.startsWith('frc')) {
    return rawTeamNumber.substring(3);
  }
  return rawTeamNumber;
}

/// Parses the team number (after normalization) into an int.
int parseTeamNumberAsInt(String rawTeamNumber) {
  final normalized = normalizeTeamNumber(rawTeamNumber);
  return int.tryParse(normalized) ?? 0;
}

/// Data model for Lead Scout Notes—holds aggregator stats + lead scouting data.
class LeadScoutDataModel {
  // Performance Stats
  final String teamNumber;
  final String teamName;
  final double epa;
  final int rank;
  final String wlr;
  final bool processor;
  final bool net;
  final double cpmAvg;
  final double apmAvg;
  final double coralPerMatch;

  // OPR fields
  final double oprL1;
  final double oprL2;
  final double oprL3;
  final double oprL4;
  final double oprProcessor;
  final double oprNet;
  final double teamOpr; // Overall OPR (from OPR_Score)

  // Aggregator stats from MatchData
  final double l1Min, l1Max, l1Avg;
  final double l23Min, l23Max, l23Avg;
  final double l4Min, l4Max, l4Avg;
  final double netMin, netMax, netAvg;
  final double processorMin, processorMax, processorAvg;

  // Robot Specifications (from PitScoutingData)
  final double robotWeight;
  final String driveType;
  final String motorType;
  final int motorCount;
  final int bumperQuality;
  final String coralIntakeType;
  final String algaeIntakeType;
  final String climbType;

  // Autonomous (from AutoScouting and PitScoutingData)
  final String autonomousCoral;
  final String leaveAutoLine;

  // Lead Scouting Notes
  final String compatibility;
  final String notableFeats;
  final String humanPlayerNetAcc;

  const LeadScoutDataModel({
    required this.teamNumber,
    required this.teamName,
    required this.epa,
    required this.rank,
    required this.wlr,
    required this.processor,
    required this.net,
    required this.cpmAvg,
    required this.apmAvg,
    required this.coralPerMatch,
    required this.oprL1,
    required this.oprL2,
    required this.oprL3,
    required this.oprL4,
    required this.oprProcessor,
    required this.oprNet,
    required this.teamOpr,
    required this.l1Min,
    required this.l1Max,
    required this.l1Avg,
    required this.l23Min,
    required this.l23Max,
    required this.l23Avg,
    required this.l4Min,
    required this.l4Max,
    required this.l4Avg,
    required this.netMin,
    required this.netMax,
    required this.netAvg,
    required this.processorMin,
    required this.processorMax,
    required this.processorAvg,
    required this.robotWeight,
    required this.driveType,
    required this.motorType,
    required this.motorCount,
    required this.bumperQuality,
    required this.coralIntakeType,
    required this.algaeIntakeType,
    required this.climbType,
    required this.autonomousCoral,
    required this.leaveAutoLine,
    required this.compatibility,
    required this.notableFeats,
    required this.humanPlayerNetAcc,
  });

  LeadScoutDataModel copyWith({
    String? teamNumber,
    String? teamName,
    double? epa,
    int? rank,
    String? wlr,
    bool? processor,
    bool? net,
    double? cpmAvg,
    double? apmAvg,
    double? coralPerMatch,
    double? oprL1,
    double? oprL2,
    double? oprL3,
    double? oprL4,
    double? oprProcessor,
    double? oprNet,
    double? teamOpr,
    double? l1Min,
    double? l1Max,
    double? l1Avg,
    double? l23Min,
    double? l23Max,
    double? l23Avg,
    double? l4Min,
    double? l4Max,
    double? l4Avg,
    double? netMin,
    double? netMax,
    double? netAvg,
    double? processorMin,
    double? processorMax,
    double? processorAvg,
    double? robotWeight,
    String? driveType,
    String? motorType,
    int? motorCount,
    int? bumperQuality,
    String? coralIntakeType,
    String? algaeIntakeType,
    String? climbType,
    String? autonomousCoral,
    String? leaveAutoLine,
    String? compatibility,
    String? notableFeats,
    String? humanPlayerNetAcc,
  }) {
    return LeadScoutDataModel(
      teamNumber: teamNumber ?? this.teamNumber,
      teamName: teamName ?? this.teamName,
      epa: epa ?? this.epa,
      rank: rank ?? this.rank,
      wlr: wlr ?? this.wlr,
      processor: processor ?? this.processor,
      net: net ?? this.net,
      cpmAvg: cpmAvg ?? this.cpmAvg,
      apmAvg: apmAvg ?? this.apmAvg,
      coralPerMatch: coralPerMatch ?? this.coralPerMatch,
      oprL1: oprL1 ?? this.oprL1,
      oprL2: oprL2 ?? this.oprL2,
      oprL3: oprL3 ?? this.oprL3,
      oprL4: oprL4 ?? this.oprL4,
      oprProcessor: oprProcessor ?? this.oprProcessor,
      oprNet: oprNet ?? this.oprNet,
      teamOpr: teamOpr ?? this.teamOpr,
      l1Min: l1Min ?? this.l1Min,
      l1Max: l1Max ?? this.l1Max,
      l1Avg: l1Avg ?? this.l1Avg,
      l23Min: l23Min ?? this.l23Min,
      l23Max: l23Max ?? this.l23Max,
      l23Avg: l23Avg ?? this.l23Avg,
      l4Min: l4Min ?? this.l4Min,
      l4Max: l4Max ?? this.l4Max,
      l4Avg: l4Avg ?? this.l4Avg,
      netMin: netMin ?? this.netMin,
      netMax: netMax ?? this.netMax,
      netAvg: netAvg ?? this.netAvg,
      processorMin: processorMin ?? this.processorMin,
      processorMax: processorMax ?? this.processorMax,
      processorAvg: processorAvg ?? this.processorAvg,
      robotWeight: robotWeight ?? this.robotWeight,
      driveType: driveType ?? this.driveType,
      motorType: motorType ?? this.motorType,
      motorCount: motorCount ?? this.motorCount,
      bumperQuality: bumperQuality ?? this.bumperQuality,
      coralIntakeType: coralIntakeType ?? this.coralIntakeType,
      algaeIntakeType: algaeIntakeType ?? this.algaeIntakeType,
      climbType: climbType ?? this.climbType,
      autonomousCoral: autonomousCoral ?? this.autonomousCoral,
      leaveAutoLine: leaveAutoLine ?? this.leaveAutoLine,
      compatibility: compatibility ?? this.compatibility,
      notableFeats: notableFeats ?? this.notableFeats,
      humanPlayerNetAcc: humanPlayerNetAcc ?? this.humanPlayerNetAcc,
    );
  }
}

/// Lead Scout Notes page using dynamic fetching plus aggregator table.
class LeadScoutNotesVisPage extends StatefulWidget {
  final WebSocketService webSocketService;
  final String teamName;
  final String teamNickname;
  final String teamNumber; // e.g. "1148" or "frc1148" (will be normalized)

  const LeadScoutNotesVisPage({
    Key? key,
    required this.webSocketService,
    required this.teamName,
    required this.teamNickname,
    required this.teamNumber,
  }) : super(key: key);

  @override
  State<LeadScoutNotesVisPage> createState() => _LeadScoutNotesVisPageState();
}

class _LeadScoutNotesVisPageState extends State<LeadScoutNotesVisPage> {
  LeadScoutDataModel? leadData;

  @override
  void initState() {
    super.initState();
    _fetchLeadData();
  }

  /// Chain the fetch calls. The final call is _fetchNotesData(...) which fetches
  /// Team Compatibility, Notable Feats, and Human Player Net ACC from LeadScoutingData.
  Future<void> _fetchLeadData() async {
    final String normalized = normalizeTeamNumber(widget.teamNumber);
    LeadScoutDataModel data = await _fetchPerformanceData(normalized);
    data = await _fetchRankData(normalized, data);
    data = await _fetchOPRData(normalized, data);
    data = await _fetchTBAMatchData(normalized, data);
    data = await _fetchMatchDataAggregator(normalized, data);
    data = await _fetchPitData(normalized, data);
    data = await _fetchAutoData(normalized, data);
    // This is where we fetch from LeadScoutingData:
    data = await _fetchNotesData(normalized, data);

    setState(() {
      leadData = data;
    });
  }

  /// 1) Fetch performance data (team name and EPA) from StatsboticsEPA.
  Future<LeadScoutDataModel> _fetchPerformanceData(String teamNum) async {
    final int teamInt = parseTeamNumberAsInt(teamNum);
    final String sql = """
      SELECT team_name, current_EPA
      FROM StatsboticsEPA
      WHERE team = $teamInt
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          completer.complete(rows.isNotEmpty ? rows.first : null);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final row = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    await sub.cancel();

    return LeadScoutDataModel(
      teamNumber: teamNum,
      teamName: row?["team_name"] ?? "Unknown",
      epa: (row?["current_EPA"] ?? 0).toDouble(),
      rank: 0,
      wlr: "0-0-0",
      processor: false,
      net: false,
      cpmAvg: 0,
      apmAvg: 0,
      coralPerMatch: 0,
      // OPR
      oprL1: 0,
      oprL2: 0,
      oprL3: 0,
      oprL4: 0,
      oprProcessor: 0,
      oprNet: 0,
      teamOpr: 0,
      // Aggregator stats
      l1Min: 0,
      l1Max: 0,
      l1Avg: 0,
      l23Min: 0,
      l23Max: 0,
      l23Avg: 0,
      l4Min: 0,
      l4Max: 0,
      l4Avg: 0,
      netMin: 0,
      netMax: 0,
      netAvg: 0,
      processorMin: 0,
      processorMax: 0,
      processorAvg: 0,
      // Pit data
      robotWeight: 0,
      driveType: "",
      motorType: "",
      motorCount: 0,
      bumperQuality: 0,
      coralIntakeType: "",
      algaeIntakeType: "",
      climbType: "",
      // Auto data
      autonomousCoral: "",
      leaveAutoLine: "",
      // Lead scouting
      compatibility: "",
      notableFeats: "",
      humanPlayerNetAcc: "",
    );
  }

  /// 2) Fetch ranking data (rank and win-loss-tie) from EventRankings.
  Future<LeadScoutDataModel> _fetchRankData(
      String teamNum, LeadScoutDataModel base) async {
    final String sql = """
      SELECT rank, win_loss_tie
      FROM EventRankings
      WHERE team_key = 'frc$teamNum'
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          completer.complete(rows.isNotEmpty ? rows.first : null);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final row = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    await sub.cancel();

    if (row == null) return base;
    return base.copyWith(
      rank: row["rank"] ?? 0,
      wlr: row["win_loss_tie"] ?? "0-0-0",
    );
  }

  /// 3) Fetch OPR data (OPR counts + OPR_Score) from the OPR table.
  Future<LeadScoutDataModel> _fetchOPRData(
      String teamNum, LeadScoutDataModel base) async {
    final String sql = """
      SELECT 
        OPR_Score,
        OPR_teleop_trough_count AS oprL1,
        OPR_teleop_reef_bottom_count AS oprL2,
        OPR_teleop_reef_mid_count AS oprL3,
        OPR_teleop_reef_top_count AS oprL4,
        OPR_teleop_coral_count AS oprProcessor,
        OPR_net_algae_count AS oprNet
      FROM OPR
      WHERE Team = '$teamNum'
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          completer.complete(rows.isNotEmpty ? rows.first : null);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final row = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    await sub.cancel();

    if (row == null) return base;

    double safeDouble(dynamic val) =>
        (val == null) ? 0.0 : (val as num).toDouble();

    return base.copyWith(
      teamOpr: safeDouble(row["OPR_Score"]),
      oprL1: safeDouble(row["oprL1"]),
      oprL2: safeDouble(row["oprL2"]),
      oprL3: safeDouble(row["oprL3"]),
      oprL4: safeDouble(row["oprL4"]),
      oprProcessor: safeDouble(row["oprProcessor"]),
      oprNet: safeDouble(row["oprNet"]),
    );
  }

  /// 4) Fetch aggregated TBAMatchScores for CPM and APM.
  Future<LeadScoutDataModel> _fetchTBAMatchData(
      String teamNum, LeadScoutDataModel base) async {
    final String sql = """
      SELECT teleop_coral_count, net_algae_count
      FROM TBAMatchScores
      WHERE team_keys LIKE '%frc$teamNum%'
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<List<Map<String, dynamic>>>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          final List<Map<String, dynamic>> listRows =
              rows.map((r) => Map<String, dynamic>.from(r)).toList();
          completer.complete(listRows);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final rows = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => []);

    await sub.cancel();
    if (rows.isEmpty) return base;

    List<double> coralVals = [];
    List<double> algaeVals = [];

    for (var r in rows) {
      double cVal =
          double.tryParse(r["teleop_coral_count"]?.toString() ?? "") ?? 0;
      if (cVal > 0) coralVals.add(cVal);

      double aVal =
          double.tryParse(r["net_algae_count"]?.toString() ?? "") ?? 0;
      if (aVal > 0) algaeVals.add(aVal);
    }

    double coralAvg = coralVals.isNotEmpty
        ? coralVals.reduce((a, b) => a + b) / coralVals.length
        : 0;
    double algaeAvg = algaeVals.isNotEmpty
        ? algaeVals.reduce((a, b) => a + b) / algaeVals.length
        : 0;

    return base.copyWith(
      cpmAvg: coralAvg,
      apmAvg: algaeAvg,
      coralPerMatch: coralAvg,
    );
  }

  /// 4b) Aggregator from MatchData (L1, L2/3, L4, Net, Processor).
  Future<LeadScoutDataModel> _fetchMatchDataAggregator(
      String teamNum, LeadScoutDataModel base) async {
    final String sql = """
      SELECT l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter
      FROM MatchData
      WHERE team_number = 'frc$teamNum'
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<List<Map<String, dynamic>>>();
    late StreamSubscription sub;
    List<Map<String, dynamic>> rowsResult = [];

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          rowsResult = rows.map((r) => Map<String, dynamic>.from(r)).toList();
          completer.complete(rowsResult);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final rows = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => []);
    await sub.cancel();

    if (rows.isEmpty) return base;

    List<double> l1Vals = [];
    List<double> l23Vals = [];
    List<double> l4Vals = [];
    List<double> netVals = [];
    List<double> procVals = [];

    double parseCounter(dynamic val) {
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    for (var r in rows) {
      double l1v = parseCounter(r["l1Counter"]);
      if (l1v > 0) l1Vals.add(l1v);

      double l23v = parseCounter(r["l2l3Counter"]);
      if (l23v > 0) l23Vals.add(l23v);

      double l4v = parseCounter(r["l4Counter"]);
      if (l4v > 0) l4Vals.add(l4v);

      double netv = parseCounter(r["netCounter"]);
      if (netv > 0) netVals.add(netv);

      double procv = parseCounter(r["processorCounter"]);
      if (procv > 0) procVals.add(procv);
    }

    double computeAvg(List<double> vals) =>
        vals.reduce((a, b) => a + b) / vals.length;
    double getMin(List<double> vals) => vals.reduce((a, b) => a < b ? a : b);
    double getMax(List<double> vals) => vals.reduce((a, b) => a > b ? a : b);

    // L1 aggregator
    double l1Avg = 0, l1Min = 0, l1Max = 0;
    if (l1Vals.isNotEmpty) {
      l1Avg = computeAvg(l1Vals);
      l1Min = getMin(l1Vals);
      l1Max = getMax(l1Vals);
    }

    // L2/3 aggregator
    double l23Avg = 0, l23Min = 0, l23Max = 0;
    if (l23Vals.isNotEmpty) {
      l23Avg = computeAvg(l23Vals);
      l23Min = getMin(l23Vals);
      l23Max = getMax(l23Vals);
    }

    // L4 aggregator
    double l4Avg = 0, l4Min = 0, l4Max = 0;
    if (l4Vals.isNotEmpty) {
      l4Avg = computeAvg(l4Vals);
      l4Min = getMin(l4Vals);
      l4Max = getMax(l4Vals);
    }

    // Net aggregator
    double netAvg = 0, netMin = 0, netMax = 0;
    if (netVals.isNotEmpty) {
      netAvg = computeAvg(netVals);
      netMin = getMin(netVals);
      netMax = getMax(netVals);
    }

    // Processor aggregator
    double procAvg = 0, procMin = 0, procMax = 0;
    if (procVals.isNotEmpty) {
      procAvg = computeAvg(procVals);
      procMin = getMin(procVals);
      procMax = getMax(procVals);
    }

    return base.copyWith(
      l1Avg: l1Avg,
      l1Min: l1Min,
      l1Max: l1Max,
      l23Avg: l23Avg,
      l23Min: l23Min,
      l23Max: l23Max,
      l4Avg: l4Avg,
      l4Min: l4Min,
      l4Max: l4Max,
      netAvg: netAvg,
      netMin: netMin,
      netMax: netMax,
      processorAvg: procAvg,
      processorMin: procMin,
      processorMax: procMax,
    );
  }

  /// 5) Fetch pit scouting data (robot specs, booleans).
  Future<LeadScoutDataModel> _fetchPitData(
      String teamNum, LeadScoutDataModel base) async {
    final String sql = """
      SELECT robot_weight, drive_type, motor_type, motor_count, bumper_quality,
             coral_intake_type, algae_intake_type, climb_type, leaves_start_line,
             processor, net
      FROM PitScoutingData
      WHERE team_number = '$teamNum'
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          completer.complete(rows.isNotEmpty ? rows.first : null);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final row = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    await sub.cancel();

    if (row == null) return base;

    bool parseBool(dynamic val) {
      if (val == null) return false;
      final str = val.toString().toLowerCase();
      return (str == "true" || str == "1" || str == "yes");
    }

    double weight = double.tryParse(row["robot_weight"]?.toString() ?? "") ?? 0;

    return base.copyWith(
      processor: parseBool(row["processor"]),
      net: parseBool(row["net"]),
      robotWeight: weight,
      driveType: row["drive_type"] ?? "",
      motorType: row["motor_type"] ?? "",
      motorCount: row["motor_count"] ?? 0,
      bumperQuality: row["bumper_quality"] ?? 0,
      coralIntakeType: row["coral_intake_type"] ?? "",
      algaeIntakeType: row["algae_intake_type"] ?? "",
      climbType: row["climb_type"] ?? "",
      leaveAutoLine: parseBool(row["leaves_start_line"]) ? "TRUE" : "FALSE",
    );
  }

  /// 6) Fetch autonomous data from AutoScouting.
  Future<LeadScoutDataModel> _fetchAutoData(
      String teamNum, LeadScoutDataModel base) async {
    final String sql = """
      SELECT TOP 1 l4_count
      FROM AutoScouting
      WHERE team_number = '$teamNum'
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          completer.complete(rows.isNotEmpty ? rows.first : null);
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final row = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    await sub.cancel();

    String autoCoral = row != null ? "${row["l4_count"]} L4" : "0 L4";
    return base.copyWith(autonomousCoral: autoCoral);
  }

  /// 7) Fetch lead scouting notes from LeadScoutingData (compatibility, feats, HP net ACC).
  Future<LeadScoutDataModel> _fetchNotesData(
      String teamNum, LeadScoutDataModel base) async {
    final String sql = """
      SELECT compatibility, notable_feats, human_player_net_acc
      FROM LeadScoutingData
      WHERE team_number = 'frc$teamNum'
    """;
    final Map<String, dynamic> queryCmd = {
      "type": "query",
      "text": sql,
    };
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription sub;

    sub = widget.webSocketService.stream!.listen((rawMessage) {
      try {
        final int idx = rawMessage.indexOf('\r\n');
        if (idx < 0) return;
        final int len = int.parse(rawMessage.substring(0, idx));
        final String jsonPart = rawMessage.substring(idx + 2);
        if (jsonPart.length != len) return;
        final Map<String, dynamic> msg = jsonDecode(jsonPart);
        if (msg["type"] == "query") {
          final List<dynamic> rows = msg["rows"];
          if (rows.isNotEmpty) {
            completer.complete(rows.first);
          } else {
            completer.complete(null);
          }
        }
      } catch (e) {
        completer.completeError(e);
      }
    });

    widget.webSocketService.sendLengthPrefixed(queryCmd);

    final row = await completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    await sub.cancel();

    if (row == null) {
      // No lead scouting data found, just return base.
      return base;
    }

    return base.copyWith(
      compatibility: row["compatibility"] ?? "",
      notableFeats: row["notable_feats"] ?? "",
      humanPlayerNetAcc: row["human_player_net_acc"] ?? "",
    );
  }

  /// --- UI Building Functions ---
  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Lead Scout Notes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Team ${widget.teamNumber} "${widget.teamNickname}"',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: leadData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Stats Container (top area)
                buildStatsContainer(width, height),
                const Divider(),
                // Robot specs
                buildRobotSpecificationsContainer(width, height),
                const Divider(),
                // Notes
                buildNotesContainer(width, height),
              ],
            ),
      bottomNavigationBar: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AutoTablePage(
                teamNumber: widget.teamNumber,
                onThemeChanged: (ThemeMode mode) {},
              ),
            ),
          );
        },
        child: const Text("Next", style: TextStyle(color: colors.myOnPrimary)),
      ),
    );
  }

  // Build the top stats container
  Widget buildStatsContainer(double width, double height) {
    final double fontSize = (width * 0.03).clamp(12, 16).toDouble();
    return Container(
      width: width,
      padding: EdgeInsets.all(width * 0.02),
      child: Column(
        children: [
          // Team Name at top
          Container(
            width: width,
            padding: EdgeInsets.symmetric(vertical: height * 0.01),
            child: Text(
              widget.teamName,
              style: TextStyle(
                fontSize: height * 0.025,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: height * 0.01),
          // Row 1: EPA, Rank, WLR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildStatItem("EPA", leadData!.epa, height)),
              Expanded(child: _buildStatItem("Rank", leadData!.rank, height)),
              Expanded(child: _buildStatItem("WLR", leadData!.wlr, height)),
            ],
          ),
          SizedBox(height: height * 0.02),
          // Row 2: Processor, Net
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildStatItem(
                  "Processor",
                  leadData!.processor ? "TRUE" : "FALSE",
                  height,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  "Net",
                  leadData!.net ? "TRUE" : "FALSE",
                  height,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          // Row 3: CPM, APM, Coral Per Match
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildStatItem(
                  "CPM",
                  leadData!.cpmAvg.toStringAsFixed(2),
                  height,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  "APM",
                  leadData!.apmAvg.toStringAsFixed(2),
                  height,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  "Coral Per Match",
                  leadData!.coralPerMatch.toStringAsFixed(2),
                  height,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.03),

          // Aggregator table with columns: Stat, Average, OPR, Min, Max
          Text(
            "Match Data Aggregation (L1, L2/3, L4, Processor, Net)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          SizedBox(height: height * 0.01),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 8.0,
              horizontalMargin: 8.0,
              dataRowHeight: 32.0,
              columns: [
                DataColumn(
                  label: Text("Stat", style: TextStyle(fontSize: fontSize)),
                ),
                DataColumn(
                  label: Text("Average", style: TextStyle(fontSize: fontSize)),
                ),
                DataColumn(
                  label: Text("OPR", style: TextStyle(fontSize: fontSize)),
                ),
                DataColumn(
                  label: Text("Min", style: TextStyle(fontSize: fontSize)),
                ),
                DataColumn(
                  label: Text("Max", style: TextStyle(fontSize: fontSize)),
                ),
              ],
              rows: [
                // L1
                DataRow(cells: [
                  DataCell(Text("L1", style: TextStyle(fontSize: fontSize))),
                  DataCell(Text(
                    leadData!.l1Avg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.oprL1.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.l1Min.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.l1Max.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                ]),
                // L2/3
                DataRow(cells: [
                  DataCell(Text("L2/3", style: TextStyle(fontSize: fontSize))),
                  DataCell(Text(
                    leadData!.l23Avg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    "${leadData!.oprL2.toStringAsFixed(2)} / ${leadData!.oprL3.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.l23Min.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.l23Max.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                ]),
                // L4
                DataRow(cells: [
                  DataCell(Text("L4", style: TextStyle(fontSize: fontSize))),
                  DataCell(Text(
                    leadData!.l4Avg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.oprL4.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.l4Min.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.l4Max.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                ]),
                // Processor
                DataRow(cells: [
                  DataCell(
                      Text("Processor", style: TextStyle(fontSize: fontSize))),
                  DataCell(Text(
                    leadData!.processorAvg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.oprProcessor.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.processorMin.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.processorMax.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                ]),
                // Net
                DataRow(cells: [
                  DataCell(Text("Net", style: TextStyle(fontSize: fontSize))),
                  DataCell(Text(
                    leadData!.netAvg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.oprNet.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.netMin.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                  DataCell(Text(
                    leadData!.netMax.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize),
                  )),
                ]),
              ],
            ),
          ),
          SizedBox(height: height * 0.02),

          // Overall OPR row
          Row(
            children: [
              Expanded(
                child: Text(
                  "Overall OPR: ${leadData!.teamOpr.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Robot Specifications
  Widget buildRobotSpecificationsContainer(double width, double height) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text(
              "Robot Specifications",
              style: TextStyle(
                fontSize: height * 0.025,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Drivetrain Specs
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 5.0),
            child: Text(
              "Drivetrain",
              style: TextStyle(
                  fontSize: height * 0.02, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: _buildStatItem(
                      "Robot weight (lbs)", leadData!.robotWeight, height)),
              Expanded(
                  child: _buildStatItem(
                      "Type of drive", leadData!.driveType, height)),
              Expanded(
                  child: _buildStatItem(
                      "Type of motor", leadData!.motorType, height)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: _buildStatItem(
                      "Number of motors", leadData!.motorCount, height)),
              Expanded(
                  child: _buildStatItem(
                      "Bumper quality", leadData!.bumperQuality, height)),
            ],
          ),
          // Intake / Scoring Specs
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 5.0),
            child: Text(
              "Intake / Scoring",
              style: TextStyle(
                  fontSize: height * 0.02, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: _buildStatItem(
                      "Coral Intake", leadData!.coralIntakeType, height)),
              Expanded(
                  child: _buildStatItem(
                      "Algae Intake", leadData!.algaeIntakeType, height)),
              Expanded(
                  child: _buildStatItem(
                      "Climb Type", leadData!.climbType, height)),
            ],
          ),
          // Autonomous Specs
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 5.0),
            child: Text(
              "Autonomous",
              style: TextStyle(
                  fontSize: height * 0.02, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: _buildStatItem("Coral scored during Auton",
                      leadData!.autonomousCoral, height)),
              Expanded(
                  child: _buildStatItem("Leave AutoLine in Auton",
                      leadData!.leaveAutoLine, height)),
            ],
          ),
        ],
      ),
    );
  }

  // Build the Notes container
  Widget buildNotesContainer(double width, double height) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      child: Column(
        children: [
          // Team Compatibility
          Column(
            children: [
              Container(
                height: height * 0.05,
                alignment: Alignment.center,
                child: const Text(
                  'Team Compatibility',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 30.0),
                child: Text(
                  leadData!.compatibility,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const Divider(),
          // Notable Feats
          Column(
            children: [
              Container(
                height: height * 0.05,
                alignment: Alignment.center,
                child: const Text(
                  'Notable Feats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 30.0),
                child: Text(
                  leadData!.notableFeats,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const Divider(),
          // Human Player Net ACC
          Column(
            children: [
              Container(
                height: height * 0.05,
                alignment: Alignment.center,
                child: const Text(
                  'Human Player Net ACC',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 30.0),
                child: Text(
                  leadData!.humanPlayerNetAcc,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  /// A helper to build a data item cell (label + value).
  Widget _buildStatItem(String label, dynamic value, double height) {
    final textValue = value.toString();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: height * 0.0175),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          textValue,
          style: TextStyle(fontSize: height * 0.02, color: Colors.red),
        ),
      ],
    );
  }
}
