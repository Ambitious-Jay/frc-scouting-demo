import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frc1148_2025_scouting_app/auto_table_page.dart';
import 'package:frc1148_2025_scouting_app/graphing_page.dart';
import 'package:frc1148_2025_scouting_app/preset_comment.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'color_scheme.dart';

/// Removes "frc" prefix if present, returning just the numeric part.
/// e.g. "frc1148" -> "1148"
String normalizeTeamNumber(String rawTeamNumber) {
  final lower = rawTeamNumber.toLowerCase();
  if (lower.startsWith('frc')) {
    return rawTeamNumber.substring(3);
  }
  return rawTeamNumber;
}

/// If StatsboticsEPA.team is numeric, parse the normalized team number to int.
int parseTeamNumberAsInt(String rawTeamNumber) {
  final normalized = normalizeTeamNumber(rawTeamNumber);
  return int.tryParse(normalized) ?? 0;
}

/// A model that holds all data you want to display for a team, including
/// aggregator stats, OPR fields, rank, WLR, etc.
class TeamDataModel {
  final String teamNumber;
  final String teamName; // from StatsboticsEPA

  // From StatsboticsEPA
  final double epa; // current_EPA
  final double maxEpa; // max_EPA

  // From EventRankings
  final int rank;
  final String wlr; // e.g. "7-0-0"

  // From PitScoutingData
  final bool processor; // Boolean
  final bool net; // Boolean
  final String hang; // e.g. "shallow" or "deep"
  final bool l1;
  final bool l2;
  final bool l3;
  final bool l4;
  final String coralIntakeType; // "Coral intake type"
  final String algaeIntakeType; // "Algae intake type"
  final bool leavesAuto; // from leaves_start_line

  // CPM/APM (averages only)
  final double cpmAvg;
  final double apmAvg;

  // Overall OPR
  final double teamOpr;

  // Aggregator from MatchData for L1, L2/3, L4, Net, Processor
  final double l1Min, l1Max, l1Avg;
  final double l23Min, l23Max, l23Avg;
  final double l4Min, l4Max, l4Avg;
  final double netMin, netMax, netAvg;
  final double processorMin, processorMax, processorAvg;

  // OPR fields for each row
  final double oprL1;
  final double oprL2;
  final double oprL3;
  final double oprL4;
  final double oprProcessor;
  final double oprNet;

  const TeamDataModel({
    required this.teamNumber,
    required this.teamName,
    required this.epa,
    required this.maxEpa,
    required this.rank,
    required this.wlr,
    required this.processor,
    required this.net,
    required this.hang,
    required this.l1,
    required this.l2,
    required this.l3,
    required this.l4,
    required this.coralIntakeType,
    required this.algaeIntakeType,
    required this.leavesAuto,
    required this.cpmAvg,
    required this.apmAvg,
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
    required this.oprL1,
    required this.oprL2,
    required this.oprL3,
    required this.oprL4,
    required this.oprProcessor,
    required this.oprNet,
  });
}

class AllianceData extends StatefulWidget {
  final String allianceNames;
  final WebSocketService webSocketService;

  const AllianceData({
    Key? key,
    required this.allianceNames,
    required this.webSocketService,
  }) : super(key: key);

  @override
  State<AllianceData> createState() => _AllianceDataState();
}

class _AllianceDataState extends State<AllianceData> {
  late List<String> _teamNumbers; // e.g. ["1148","254","1678"]
  List<TeamDataModel?> _teamData = [null, null, null];

  @override
  void initState() {
    super.initState();
    // Split allianceNames into exactly 3 teams
    _teamNumbers =
        widget.allianceNames.split(',').map((s) => s.trim()).toList();
    while (_teamNumbers.length < 3) {
      _teamNumbers.add("0");
    }
    if (_teamNumbers.length > 3) {
      _teamNumbers = _teamNumbers.sublist(0, 3);
    }

    // Initial fetch
    _fetchAllTeamData();
  }

  /// Fetch data for all 3 teams in the alliance
  Future<void> _fetchAllTeamData() async {
    for (int i = 0; i < _teamNumbers.length; i++) {
      await _fetchTeamData(_teamNumbers[i], i);
    }
  }

  /// Combines queries from multiple tables for a single team
  Future<void> _fetchTeamData(String teamNumber, int index) async {
    if (teamNumber.isEmpty || teamNumber == "0") return;
    final String normalized = normalizeTeamNumber(teamNumber);

    // 1) Query for EPA from StatsboticsEPA
    final TeamDataModel partialStats = await _fetchEPAData(normalized);

    // 2) Query for OPR from OPR table
    final TeamDataModel partialOpr =
        await _fetchOPRData(normalized, partialStats);

    // 3) Query for rank/WLR from EventRankings
    final TeamDataModel partialRank =
        await _fetchRankData(normalized, partialOpr);

    // 4) Query for pit-scouting data (NO "frc" prefix)
    final TeamDataModel partialPit =
        await _fetchPitData(normalized, partialRank);

    // 5) Aggregator for CPM/APM from TBAMatchScores (avg only)
    final TeamDataModel finalData =
        await _fetchCpmApm(normalized, partialPit);

    // 6) Aggregator for L1, L2/3, L4, Net, Processor from MatchData
    final TeamDataModel finalData2 =
        await _fetchMatchDataAggregator(normalized, finalData);

    setState(() {
      _teamData[index] = finalData2;
    });
  }

  // -----------------------------------------------------------
  // 1) EPA Data (still numeric in DB)
  // -----------------------------------------------------------
  Future<TeamDataModel> _fetchEPAData(String normalizedTeam) async {
    final int teamInt = parseTeamNumberAsInt(normalizedTeam);
    final String sql = """
      SELECT team_name, total_epa, norm_epa_max
      FROM StatsboticsEPA
      WHERE team = $teamInt
    """;
    print("Sending StatsboticsEPA query: $sql");

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
          final rows = msg["rows"] as List<dynamic>;
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

    final row = await completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () {
      print("Timeout on StatsboticsEPA query for team $normalizedTeam");
      return null;
    });
    await sub.cancel();

    if (row == null) {
      // Return a default TeamDataModel with zero or default values
      return TeamDataModel(
        teamNumber: normalizedTeam,
        teamName: "Unknown",
        epa: 0.0,
        maxEpa: 0.0,
        rank: 0,
        wlr: "0-0-0",
        processor: false,
        net: false,
        hang: "none",
        l1: false,
        l2: false,
        l3: false,
        l4: false,
        coralIntakeType: "none",
        algaeIntakeType: "none",
        leavesAuto: false,
        cpmAvg: 0,
        apmAvg: 0,
        teamOpr: 0.0,
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
        oprL1: 0.0,
        oprL2: 0.0,
        oprL3: 0.0,
        oprL4: 0.0,
        oprProcessor: 0.0,
        oprNet: 0.0,
      );
    }

    return TeamDataModel(
      teamNumber: normalizedTeam,
      teamName: row["team_name"] ?? "Unknown",
      epa: (row["total_epa"] ?? 0).toDouble(),
      maxEpa: (row["norm_epa_max"] ?? 0).toDouble(),
      rank: 0,
      wlr: "0-0-0",
      processor: false,
      net: false,
      hang: "none",
      l1: false,
      l2: false,
      l3: false,
      l4: false,
      coralIntakeType: "none",
      algaeIntakeType: "none",
      leavesAuto: false,
      cpmAvg: 0,
      apmAvg: 0,
      teamOpr: 0.0,
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
      oprL1: 0.0,
      oprL2: 0.0,
      oprL3: 0.0,
      oprL4: 0.0,
      oprProcessor: 0.0,
      oprNet: 0.0,
    );
  }

  // -----------------------------------------------------------
  // 2) OPR Data (including L1, L2, L3, L4, Processor, Net)
  // -----------------------------------------------------------
  Future<TeamDataModel> _fetchOPRData(
      String normalizedTeam, TeamDataModel base) async {
    final String sql = """
      SELECT 
        OPR_Score,
        OPR_teleop_trough_count        AS oprL1,
        OPR_teleop_reef_bottom_count   AS oprL2,
        OPR_teleop_reef_mid_count      AS oprL3,
        OPR_teleop_reef_top_count      AS oprL4,
        OPR_teleop_coral_count         AS oprProcessor,
        OPR_net_algae_count            AS oprNet
      FROM OPR
      WHERE Team = '$normalizedTeam'
    """;
    print("Sending OPR query: $sql");

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
          final rows = msg["rows"] as List<dynamic>;
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

    final row = await completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () {
      print("Timeout on OPR query for team $normalizedTeam");
      return null;
    });
    await sub.cancel();

    if (row == null) {
      // If no OPR found, return base as-is
      return base;
    }

    double safeDouble(dynamic val) =>
        (val == null) ? 0.0 : (val as num).toDouble();

    final double oprScore = safeDouble(row["OPR_Score"]);
    final double oprL1 = safeDouble(row["oprL1"]);
    final double oprL2 = safeDouble(row["oprL2"]);
    final double oprL3 = safeDouble(row["oprL3"]);
    final double oprL4 = safeDouble(row["oprL4"]);
    final double oprProcessor = safeDouble(row["oprProcessor"]);
    final double oprNet = safeDouble(row["oprNet"]);

    return TeamDataModel(
      teamNumber: base.teamNumber,
      teamName: base.teamName,
      epa: base.epa,
      maxEpa: base.maxEpa,
      rank: base.rank,
      wlr: base.wlr,
      processor: base.processor,
      net: base.net,
      hang: base.hang,
      l1: base.l1,
      l2: base.l2,
      l3: base.l3,
      l4: base.l4,
      coralIntakeType: base.coralIntakeType,
      algaeIntakeType: base.algaeIntakeType,
      leavesAuto: base.leavesAuto,
      cpmAvg: base.cpmAvg,
      apmAvg: base.apmAvg,
      teamOpr: oprScore, // store the overall OPR
      l1Min: base.l1Min,
      l1Max: base.l1Max,
      l1Avg: base.l1Avg,
      l23Min: base.l23Min,
      l23Max: base.l23Max,
      l23Avg: base.l23Avg,
      l4Min: base.l4Min,
      l4Max: base.l4Max,
      l4Avg: base.l4Avg,
      netMin: base.netMin,
      netMax: base.netMax,
      netAvg: base.netAvg,
      processorMin: base.processorMin,
      processorMax: base.processorMax,
      processorAvg: base.processorAvg,
      oprL1: oprL1,
      oprL2: oprL2,
      oprL3: oprL3,
      oprL4: oprL4,
      oprProcessor: oprProcessor,
      oprNet: oprNet,
    );
  }

  // -----------------------------------------------------------
  // 3) Ranking Data (frc prefix for the DB)
  // -----------------------------------------------------------
  Future<TeamDataModel> _fetchRankData(
      String normalizedTeam, TeamDataModel base) async {
    final String sql = """
      SELECT rank, win_loss_tie
      FROM EventRankings
      WHERE team_key = 'frc$normalizedTeam'
    """;
    print("Sending EventRankings query: $sql");

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
          final rows = msg["rows"] as List<dynamic>;
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

    final row = await completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () {
      print("Timeout on EventRankings query for team $normalizedTeam");
      return null;
    });
    await sub.cancel();

    if (row == null) return base;
    return TeamDataModel(
      teamNumber: base.teamNumber,
      teamName: base.teamName,
      epa: base.epa,
      maxEpa: base.maxEpa,
      rank: row["rank"] ?? 0,
      wlr: row["win_loss_tie"] ?? "0-0-0",
      processor: base.processor,
      net: base.net,
      hang: base.hang,
      l1: base.l1,
      l2: base.l2,
      l3: base.l3,
      l4: base.l4,
      coralIntakeType: base.coralIntakeType,
      algaeIntakeType: base.algaeIntakeType,
      leavesAuto: base.leavesAuto,
      cpmAvg: base.cpmAvg,
      apmAvg: base.apmAvg,
      teamOpr: base.teamOpr,
      l1Min: base.l1Min,
      l1Max: base.l1Max,
      l1Avg: base.l1Avg,
      l23Min: base.l23Min,
      l23Max: base.l23Max,
      l23Avg: base.l23Avg,
      l4Min: base.l4Min,
      l4Max: base.l4Max,
      l4Avg: base.l4Avg,
      netMin: base.netMin,
      netMax: base.netMax,
      netAvg: base.netAvg,
      processorMin: base.processorMin,
      processorMax: base.processorMax,
      processorAvg: base.processorAvg,
      oprL1: base.oprL1,
      oprL2: base.oprL2,
      oprL3: base.oprL3,
      oprL4: base.oprL4,
      oprProcessor: base.oprProcessor,
      oprNet: base.oprNet,
    );
  }

  // -----------------------------------------------------------
  // 4) Pit Scouting Data (NO "frc" prefix)
  // -----------------------------------------------------------
  Future<TeamDataModel> _fetchPitData(
      String normalizedTeam, TeamDataModel base) async {
    final String sql = """
      SELECT 
        processor, 
        net, 
        climb_type, 
        L1, 
        L2, 
        L3, 
        L4, 
        coral_intake_type, 
        algae_intake_type,
        leaves_start_line
      FROM PitScoutingData
      WHERE team_number = '$normalizedTeam'
    """;
    print("Sending PitScoutingData query: $sql");

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
          final rows = msg["rows"] as List<dynamic>;
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

    final row = await completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () {
      print("Timeout on PitScoutingData query for team $normalizedTeam");
      return null;
    });
    await sub.cancel();

    if (row == null) return base;

    bool parseBool(dynamic val) {
      if (val == null) return false;
      final str = val.toString().toLowerCase();
      return (str == "true" || str == "1" || str == "yes");
    }

    return TeamDataModel(
      teamNumber: base.teamNumber,
      teamName: base.teamName,
      epa: base.epa,
      maxEpa: base.maxEpa,
      rank: base.rank,
      wlr: base.wlr,
      processor: parseBool(row["processor"]),
      net: parseBool(row["net"]),
      hang: (row["climb_type"] ?? "none").toString(),
      l1: parseBool(row["L1"]),
      l2: parseBool(row["L2"]),
      l3: parseBool(row["L3"]),
      l4: parseBool(row["L4"]),
      coralIntakeType: row["coral_intake_type"] ?? "none",
      algaeIntakeType: row["algae_intake_type"] ?? "none",
      leavesAuto: parseBool(row["leaves_start_line"]),
      cpmAvg: base.cpmAvg,
      apmAvg: base.apmAvg,
      teamOpr: base.teamOpr,
      l1Min: base.l1Min,
      l1Max: base.l1Max,
      l1Avg: base.l1Avg,
      l23Min: base.l23Min,
      l23Max: base.l23Max,
      l23Avg: base.l23Avg,
      l4Min: base.l4Min,
      l4Max: base.l4Max,
      l4Avg: base.l4Avg,
      netMin: base.netMin,
      netMax: base.netMax,
      netAvg: base.netAvg,
      processorMin: base.processorMin,
      processorMax: base.processorMax,
      processorAvg: base.processorAvg,
      oprL1: base.oprL1,
      oprL2: base.oprL2,
      oprL3: base.oprL3,
      oprL4: base.oprL4,
      oprProcessor: base.oprProcessor,
      oprNet: base.oprNet,
    );
  }

  /// 5) CPM/APM Aggregation (only average) - "frc" prefix in LIKE
  /// For CPM, sum l1Counter, l2l3Counter, and l4Counter for each match and average over the number of rows returned.
  /// For APM, sum netCounter and processorCounter for each match and average similarly.
  Future<TeamDataModel> _fetchCpmApm(
      String normalizedTeam, TeamDataModel base) async {
    final String sql = """
      SELECT l1Counter, l2l3Counter, l4Counter, netCounter, processorCounter
      FROM MatchData
      WHERE team_number = 'frc$normalizedTeam'
    """;
    print("Sending MatchData aggregator query: $sql");

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

    final rows = await completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () {
      print("Timeout on MatchData query for team $normalizedTeam");
      return [];
    });
    await sub.cancel();

    if (rows.isEmpty) return base;

    double totalTeleop = 0;
    double totalAP = 0;
    for (var r in rows) {
      double l1 = double.tryParse(r["l1Counter"]?.toString() ?? "0") ?? 0;
      double l23 = double.tryParse(r["l2l3Counter"]?.toString() ?? "0") ?? 0;
      double l4 = double.tryParse(r["l4Counter"]?.toString() ?? "0") ?? 0;
      double net = double.tryParse(r["netCounter"]?.toString() ?? "0") ?? 0;
      double processor = double.tryParse(r["processorCounter"]?.toString() ?? "0") ?? 0;
      totalTeleop += (l1 + l23 + l4);
      totalAP += (net + processor);
    }
    int numMatches = rows.length;
    double teleopAvg = numMatches > 0 ? totalTeleop / numMatches : 0;
    double apAvg = numMatches > 0 ? totalAP / numMatches : 0;

    return TeamDataModel(
      teamNumber: base.teamNumber,
      teamName: base.teamName,
      epa: base.epa,
      maxEpa: base.maxEpa,
      rank: base.rank,
      wlr: base.wlr,
      processor: base.processor,
      net: base.net,
      hang: base.hang,
      l1: base.l1,
      l2: base.l2,
      l3: base.l3,
      l4: base.l4,
      coralIntakeType: base.coralIntakeType,
      algaeIntakeType: base.algaeIntakeType,
      leavesAuto: base.leavesAuto,
      cpmAvg: teleopAvg,
      apmAvg: apAvg,
      teamOpr: base.teamOpr,
      l1Min: base.l1Min,
      l1Max: base.l1Max,
      l1Avg: base.l1Avg,
      l23Min: base.l23Min,
      l23Max: base.l23Max,
      l23Avg: base.l23Avg,
      l4Min: base.l4Min,
      l4Max: base.l4Max,
      l4Avg: base.l4Avg,
      netMin: base.netMin,
      netMax: base.netMax,
      netAvg: base.netAvg,
      processorMin: base.processorMin,
      processorMax: base.processorMax,
      processorAvg: base.processorAvg,
      oprL1: base.oprL1,
      oprL2: base.oprL2,
      oprL3: base.oprL3,
      oprL4: base.oprL4,
      oprProcessor: base.oprProcessor,
      oprNet: base.oprNet,
    );
  }

  // -----------------------------------------------------------
  // 6) Aggregator from MatchData for L1, L2/3, L4, Net, Processor (frc prefix)
  // -----------------------------------------------------------
  Future<TeamDataModel> _fetchMatchDataAggregator(
      String normalizedTeam, TeamDataModel base) async {
    final String sql = """
      SELECT l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter
      FROM MatchData
      WHERE team_number = 'frc$normalizedTeam'
    """;
    print("Sending MatchData aggregator query: $sql");

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

    final rows = await completer.future.timeout(const Duration(seconds: 5),
        onTimeout: () {
      print("Timeout on MatchData aggregator query for team $normalizedTeam");
      return [];
    });
    await sub.cancel();

    if (rows.isEmpty) return base;

    List<double> l1Vals = [];
    List<double> l23Vals = [];
    List<double> l4Vals = [];
    List<double> netVals = [];
    List<double> procVals = [];

    for (var r in rows) {
      double parseCounter(dynamic val) {
        if (val == null) return 0;
        return double.tryParse(val.toString()) ?? 0;
      }

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

    double l1Avg = 0, l1Min = 0, l1Max = 0;
    if (l1Vals.isNotEmpty) {
      l1Avg = computeAvg(l1Vals);
      l1Min = getMin(l1Vals);
      l1Max = getMax(l1Vals);
    }

    double l23Avg = 0, l23Min = 0, l23Max = 0;
    if (l23Vals.isNotEmpty) {
      l23Avg = computeAvg(l23Vals);
      l23Min = getMin(l23Vals);
      l23Max = getMax(l23Vals);
    }

    double l4Avg = 0, l4Min = 0, l4Max = 0;
    if (l4Vals.isNotEmpty) {
      l4Avg = computeAvg(l4Vals);
      l4Min = getMin(l4Vals);
      l4Max = getMax(l4Vals);
    }

    double netAvg = 0, netMin = 0, netMax = 0;
    if (netVals.isNotEmpty) {
      netAvg = computeAvg(netVals);
      netMin = getMin(netVals);
      netMax = getMax(netVals);
    }

    double procAvg = 0, procMin = 0, procMax = 0;
    if (procVals.isNotEmpty) {
      procAvg = computeAvg(procVals);
      procMin = getMin(procVals);
      procMax = getMax(procVals);
    }

    return TeamDataModel(
      teamNumber: base.teamNumber,
      teamName: base.teamName,
      epa: base.epa,
      maxEpa: base.maxEpa,
      rank: base.rank,
      wlr: base.wlr,
      processor: base.processor,
      net: base.net,
      hang: base.hang,
      l1: base.l1,
      l2: base.l2,
      l3: base.l3,
      l4: base.l4,
      coralIntakeType: base.coralIntakeType,
      algaeIntakeType: base.algaeIntakeType,
      leavesAuto: base.leavesAuto,
      cpmAvg: base.cpmAvg,
      apmAvg: base.apmAvg,
      teamOpr: base.teamOpr,
      l1Min: l1Min,
      l1Max: l1Max,
      l1Avg: l1Avg,
      l23Min: l23Min,
      l23Max: l23Max,
      l23Avg: l23Avg,
      l4Min: l4Min,
      l4Max: l4Max,
      l4Avg: l4Avg,
      netMin: netMin,
      netMax: netMax,
      netAvg: netAvg,
      processorMin: procMin,
      processorMax: procMax,
      processorAvg: procAvg,
      oprL1: base.oprL1,
      oprL2: base.oprL2,
      oprL3: base.oprL3,
      oprL4: base.oprL4,
      oprProcessor: base.oprProcessor,
      oprNet: base.oprNet,
    );
  }

  /// Builds a single row item (label, value) in a flexible row.
  Widget dataItem(String label, String value, double fontSize) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Text(
              "$label: ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
            Flexible(
              child: Text(value, style: TextStyle(fontSize: fontSize)),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the UI container for a single team's data
  Widget buildTeamContainer(TeamDataModel team, double width, double height) {
    // Adjust font size based on width, clamped to [12..16].
    final double fontSize = (width * 0.03).clamp(12, 16).toDouble();

    return Container(
      width: width,
      margin: EdgeInsets.all(width * 0.03),
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team # + name
            Center(
              child: Text(
                "Team ${team.teamNumber} - ${team.teamName}",
                style: TextStyle(
                  fontSize: (width * 0.04).clamp(14, 20).toDouble(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: height * 0.015),

            // Row 1: EPA, Rank, WLR
            Row(
              children: [
                dataItem("EPA", team.epa.toStringAsFixed(2), fontSize),
                dataItem("Rank", team.rank.toString(), fontSize),
                dataItem("WLR", team.wlr, fontSize),
              ],
            ),
            // Row 2: Processor, Net, Hang
            Row(
              children: [
                dataItem(
                    "Processor", team.processor ? "TRUE" : "FALSE", fontSize),
                dataItem("Net", team.net ? "TRUE" : "FALSE", fontSize),
                dataItem("Hang", team.hang, fontSize),
              ],
            ),
            // Row 3: L1, L2, L3
            Row(
              children: [
                dataItem("L1", team.l1 ? "TRUE" : "FALSE", fontSize),
                dataItem("L2", team.l2 ? "TRUE" : "FALSE", fontSize),
                dataItem("L3", team.l3 ? "TRUE" : "FALSE", fontSize),
              ],
            ),
            // Row 4: L4, Coral Intake, Algae Intake
            Row(
              children: [
                dataItem("L4", team.l4 ? "TRUE" : "FALSE", fontSize),
                dataItem("Coral Intake", team.coralIntakeType, fontSize),
                dataItem("Algae Intake", team.algaeIntakeType, fontSize),
              ],
            ),
            // Row 5: Leaves Auto, CPM (avg), APM (avg)
            Row(
              children: [
                dataItem("Leaves Auto", team.leavesAuto ? "TRUE" : "FALSE",
                    fontSize),
                dataItem("CPM", team.cpmAvg.toStringAsFixed(2), fontSize),
                dataItem("APM", team.apmAvg.toStringAsFixed(2), fontSize),
              ],
            ),

            SizedBox(height: height * 0.02),

            // Aggregator table for L1, L2/3, L4, Processor, Net
            // Columns: Stat, Average, OPR, Min, Max
            Text(
              "Match Data Aggregation (L1, L2/3, L4, Processor, Net)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
            SizedBox(height: height * 0.01),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                // Reducing spacing to prevent overflow
                columnSpacing: 8.0,
                horizontalMargin: 8.0,
                dataRowHeight: 32.0,
                columns: [
                  DataColumn(
                      label:
                          Text("Stat", style: TextStyle(fontSize: fontSize))),
                  DataColumn(
                      label: Text("Average",
                          style: TextStyle(fontSize: fontSize))),
                  DataColumn(
                      label: Text("OPR", style: TextStyle(fontSize: fontSize))),
                  DataColumn(
                      label: Text("Min", style: TextStyle(fontSize: fontSize))),
                  DataColumn(
                      label: Text("Max", style: TextStyle(fontSize: fontSize))),
                ],
                rows: [
                  // L1
                  DataRow(cells: [
                    DataCell(Text("L1", style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l1Avg.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.oprL1.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l1Min.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l1Max.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  // L2/3
                  DataRow(cells: [
                    DataCell(
                        Text("L2/3", style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l23Avg.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    // OPR for L2/3 is "L2 OPR / L3 OPR"
                    DataCell(Text(
                      "${team.oprL2.toStringAsFixed(2)} / ${team.oprL3.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: fontSize),
                    )),
                    DataCell(Text(team.l23Min.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l23Max.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  // L4
                  DataRow(cells: [
                    DataCell(Text("L4", style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l4Avg.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.oprL4.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l4Min.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.l4Max.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  // Processor
                  DataRow(cells: [
                    DataCell(Text("Processor",
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.processorAvg.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.oprProcessor.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.processorMin.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.processorMax.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                  // Net
                  DataRow(cells: [
                    DataCell(Text("Net", style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.netAvg.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.oprNet.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.netMin.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                    DataCell(Text(team.netMax.toStringAsFixed(2),
                        style: TextStyle(fontSize: fontSize))),
                  ]),
                ],
              ),
            ),

            SizedBox(height: height * 0.02),

            // Overall OPR (if you want to show it separately)
            Row(
              children: [
                dataItem(
                    "Overall OPR", team.teamOpr.toStringAsFixed(2), fontSize),
              ],
            ),

            SizedBox(height: height * 0.02),

            // Buttons row -> replaced Row with Wrap to avoid overflow
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AutoTablePage(
                          teamNumber: team.teamNumber,
                          onThemeChanged: (ThemeMode mode) {},
                          webSocketService: widget.webSocketService,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: TextStyle(fontSize: fontSize),
                  ),
                  child: const Text("Auto Table"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PresetComment(
                          teamNumber: team.teamNumber,
                          teamName: team.teamName,
                          onThemeChanged: (ThemeMode mode) {},
                          webSocketService: widget.webSocketService,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                  child: const Text("Preset Comments"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Graphing(initialTeam: team.teamNumber),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                  child: const Text("Graphing"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Alliance Info"),
            Text(widget.allianceNames),
          ],
        ),
      ),
      body: ListView(
        children: [
          for (int i = 0; i < 3; i++)
            if (_teamData[i] != null)
              buildTeamContainer(_teamData[i]!, width, height)
            else
              Container(
                margin: EdgeInsets.all(width * 0.03),
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Loading data for team ${_teamNumbers[i]}...",
                  style: TextStyle(
                      fontSize: (width * 0.03).clamp(12, 16).toDouble()),
                ),
              ),
        ],
      ),
    );
  }
}
