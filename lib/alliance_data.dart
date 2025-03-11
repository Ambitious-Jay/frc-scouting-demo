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
/// new fields for OPR plus aggregator stats for L1, L2/3, L4, Net, Processor.
class TeamDataModel {
  final String teamNumber;

  // From StatsboticsEPA
  final String teamName; // Nickname
  final double epa; // current_EPA
  final double maxEpa; // max_EPA (the "Double" from your board)

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

  // From TBAMatchScores aggregator
  final double cpmAvg;
  final double cpmMin;
  final double cpmMax;
  final double apmAvg;
  final double apmMin;
  final double apmMax;

  // From OPR table
  final double teamOpr; // e.g. "OPR" column

  // From MatchData aggregator for L1, L2/3, L4, Net, Processor
  final double l1Min, l1Max, l1Avg;
  final double l23Min, l23Max, l23Avg;
  final double l4Min, l4Max, l4Avg;
  final double netMin, netMax, netAvg;
  final double processorMin, processorMax, processorAvg;

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
    required this.cpmAvg,
    required this.cpmMin,
    required this.cpmMax,
    required this.apmAvg,
    required this.apmMin,
    required this.apmMax,
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
  // Timer? _autoRefreshTimer;

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

    // Auto refresh every 30 seconds
    // _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    //   _fetchAllTeamData();
    // });
  }

  @override
  void dispose() {
    // _autoRefreshTimer?.cancel();
    super.dispose();
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

    // 1) Existing query for EPA from StatsboticsEPA
    final TeamDataModel partialStats = await _fetchEPAData(normalized);

    // 2) New query for OPR from OPR table
    final TeamDataModel partialOpr =
        await _fetchOPRData(normalized, partialStats);

    // 3) Existing query for rank/WLR from EventRankings
    final TeamDataModel partialRank =
        await _fetchRankData(normalized, partialOpr);

    // 4) Existing query for pit-scouting data
    final TeamDataModel partialPit =
        await _fetchPitData(normalized, partialRank);

    // 5) Existing aggregator for CPM/APM from TBAMatchScores
    final TeamDataModel partialCpmApm =
        await _fetchCpmApm(normalized, partialPit);

    // 6) New aggregator for L1, L2/3, L4, Net, Processor from MatchData
    final TeamDataModel finalData =
        await _fetchMatchDataAggregator(normalized, partialCpmApm);

    setState(() {
      _teamData[index] = finalData;
    });
  }

  // -----------------------------------------------------------
  // Existing queries (unchanged) for EPA, rank, pit, cpm/apm
  // -----------------------------------------------------------

  Future<TeamDataModel> _fetchEPAData(String normalizedTeam) async {
    // same as before
    final int teamInt = parseTeamNumberAsInt(normalizedTeam);
    final String sql = """
      SELECT team_name, current_EPA, max_EPA
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
        cpmAvg: 0,
        cpmMin: 0,
        cpmMax: 0,
        apmAvg: 0,
        apmMin: 0,
        apmMax: 0,
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
      );
    }

    return TeamDataModel(
      teamNumber: normalizedTeam,
      teamName: row["team_name"] ?? "Unknown",
      epa: (row["current_EPA"] ?? 0).toDouble(),
      maxEpa: (row["max_EPA"] ?? 0).toDouble(),
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
      cpmAvg: 0,
      cpmMin: 0,
      cpmMax: 0,
      apmAvg: 0,
      apmMin: 0,
      apmMax: 0,
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
    );
  }

  Future<TeamDataModel> _fetchRankData(
      String normalizedTeam, TeamDataModel base) async {
    // same as before
    final String sql = """
      SELECT rank, win_loss_tie
      FROM EventRankings
      WHERE team_key = '$normalizedTeam'
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
      cpmAvg: base.cpmAvg,
      cpmMin: base.cpmMin,
      cpmMax: base.cpmMax,
      apmAvg: base.apmAvg,
      apmMin: base.apmMin,
      apmMax: base.apmMax,
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
    );
  }

  Future<TeamDataModel> _fetchPitData(
      String normalizedTeam, TeamDataModel base) async {
    // same as before
    final String sql = """
      SELECT processor, net, climb_type, L1, L2, L3, L4, coral_intake_type, algae_intake_type
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
      cpmAvg: base.cpmAvg,
      cpmMin: base.cpmMin,
      cpmMax: base.cpmMax,
      apmAvg: base.apmAvg,
      apmMin: base.apmMin,
      apmMax: base.apmMax,
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
    );
  }

  Future<TeamDataModel> _fetchCpmApm(
      String normalizedTeam, TeamDataModel base) async {
    // same as before
    final String sql = """
      SELECT teleop_coral_count, net_algae_count
      FROM TBAMatchScores
      WHERE team_keys LIKE '%$normalizedTeam%'
    """;
    print("Sending TBAMatchScores aggregator query: $sql");

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
      print("Timeout on TBAMatchScores query for team $normalizedTeam");
      return [];
    });
    await sub.cancel();

    if (rows.isEmpty) return base;

    List<double> coralVals = [];
    List<double> algaeVals = [];
    for (var r in rows) {
      double cVal = 0;
      if (r["teleop_coral_count"] != null) {
        cVal = double.tryParse(r["teleop_coral_count"].toString()) ?? 0;
      }
      if (cVal > 0) coralVals.add(cVal);

      double aVal = 0;
      if (r["net_algae_count"] != null) {
        aVal = double.tryParse(r["net_algae_count"].toString()) ?? 0;
      }
      if (aVal > 0) algaeVals.add(aVal);
    }

    double coralAvg = 0, coralMin = 0, coralMax = 0;
    if (coralVals.isNotEmpty) {
      coralAvg = coralVals.reduce((a, b) => a + b) / coralVals.length;
      coralMin = coralVals.reduce((a, b) => a < b ? a : b);
      coralMax = coralVals.reduce((a, b) => a > b ? a : b);
    }

    double algaeAvg = 0, algaeMin = 0, algaeMax = 0;
    if (algaeVals.isNotEmpty) {
      algaeAvg = algaeVals.reduce((a, b) => a + b) / algaeVals.length;
      algaeMin = algaeVals.reduce((a, b) => a < b ? a : b);
      algaeMax = algaeVals.reduce((a, b) => a > b ? a : b);
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
      cpmAvg: coralAvg,
      cpmMin: coralMin,
      cpmMax: coralMax,
      apmAvg: algaeAvg,
      apmMin: algaeMin,
      apmMax: algaeMax,
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
    );
  }

  // -----------------------------------------------------------
  // NEW query for OPR (like you requested).
  // -----------------------------------------------------------
  Future<TeamDataModel> _fetchOPRData(
      String normalizedTeam, TeamDataModel base) async {
    // OPR table has: Team (nvarchar), OPR (float)
    final String sql = """
      SELECT OPR
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

    double theOpr = 0.0;
    if (row != null && row["OPR"] != null) {
      theOpr = (row["OPR"] as num).toDouble();
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
      cpmAvg: base.cpmAvg,
      cpmMin: base.cpmMin,
      cpmMax: base.cpmMax,
      apmAvg: base.apmAvg,
      apmMin: base.apmMin,
      apmMax: base.apmMax,
      teamOpr: theOpr,
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
    );
  }

  // -----------------------------------------------------------
  // NEW aggregator for L1, L2/3, L4, net, processor from MatchData
  // (non-zero min, max, average).
  // -----------------------------------------------------------
  Future<TeamDataModel> _fetchMatchDataAggregator(
      String normalizedTeam, TeamDataModel base) async {
    // Example: your MatchData table has columns:
    // l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter
    // We'll do a simple aggregator ignoring zeros.
    final String sql = """
      SELECT l4Counter, l2l3Counter, l1Counter, netCounter, processorCounter
      FROM MatchData
      WHERE team_number = '$normalizedTeam'
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

    // If no rows, return base as-is
    if (rows.isEmpty) return base;

    // We'll gather all values into lists, ignoring zeros
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

    // Helper to compute min, max, avg ignoring empty lists
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
      cpmAvg: base.cpmAvg,
      cpmMin: base.cpmMin,
      cpmMax: base.cpmMax,
      apmAvg: base.apmAvg,
      apmMin: base.apmMin,
      apmMax: base.apmMax,
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
    );
  }

  /// Builds a single row of text label + value
  Widget dataRowItem(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(fontSize: fontSize)),
          ),
        ],
      ),
    );
  }

  /// Builds the UI container, matching your whiteboard layout:
  ///  - 3 columns at top (EPA, Double, Rank, WLR) | (Processor, Net, Hang) | (L1, L2, L3, L4, Coral/Algae intake)
  ///  - Then a table with OPR + aggregator for L1, L2/3, L4, Processor, Net
  ///  - Then a table for CPM/APM aggregator
  ///  - Then the 3 buttons (Auto Table, Preset Comments, Graphing)
  Widget buildTeamContainer(TeamDataModel team, double width, double height) {
    final double fontSize = height * 0.018;

    return Container(
      width: width,
      margin: EdgeInsets.all(width * 0.03),
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team # at the top
          Center(
            child: Text(
              "Team ${team.teamNumber}",
              style: TextStyle(
                fontSize: height * 0.028,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: height * 0.015),

          // 3-column row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1 -> EPA, Double, Rank, WLR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dataRowItem("EPA", team.epa.toString(), fontSize),
                    dataRowItem("Double", team.maxEpa.toString(), fontSize),
                    dataRowItem("Rank", team.rank.toString(), fontSize),
                    dataRowItem("WLR", team.wlr, fontSize),
                  ],
                ),
              ),
              // Column 2 -> Processor, Net, Hang
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dataRowItem("Processor", team.processor ? "TRUE" : "FALSE",
                        fontSize),
                    dataRowItem("Net", team.net ? "TRUE" : "FALSE", fontSize),
                    dataRowItem("Hang", team.hang, fontSize),
                  ],
                ),
              ),
              // Column 3 -> L1, L2, L3, L4, Coral/Algae intake
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dataRowItem("L1", team.l1 ? "TRUE" : "FALSE", fontSize),
                    dataRowItem("L2", team.l2 ? "TRUE" : "FALSE", fontSize),
                    dataRowItem("L3", team.l3 ? "TRUE" : "FALSE", fontSize),
                    dataRowItem("L4", team.l4 ? "TRUE" : "FALSE", fontSize),
                    dataRowItem(
                        "Coral intake type", team.coralIntakeType, fontSize),
                    dataRowItem(
                        "Algae intake type", team.algaeIntakeType, fontSize),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: height * 0.02),

          // DataTable for OPR + aggregator for L1, L2/3, L4, Processor, Net
          // (non-zero min, max, average)
          Text(
            "OPR & Aggregator (L1, L2/3, L4, Processor, Net)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          SizedBox(height: height * 0.01),
          DataTable(
            columns: [
              DataColumn(
                  label: Text("Metric", style: TextStyle(fontSize: fontSize))),
              DataColumn(
                  label: Text("OPR", style: TextStyle(fontSize: fontSize))),
              DataColumn(
                  label: Text("Min", style: TextStyle(fontSize: fontSize))),
              DataColumn(
                  label: Text("Max", style: TextStyle(fontSize: fontSize))),
              DataColumn(
                  label: Text("Avg", style: TextStyle(fontSize: fontSize))),
            ],
            rows: [
              // L1 row
              DataRow(cells: [
                DataCell(Text("L1", style: TextStyle(fontSize: fontSize))),
                DataCell(Text("(N/A)",
                    style: TextStyle(
                        fontSize: fontSize))), // OPR doesn't apply to L1
                DataCell(Text(team.l1Min.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l1Max.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l1Avg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
              ]),
              // L2/3 row
              DataRow(cells: [
                DataCell(Text("L2/3", style: TextStyle(fontSize: fontSize))),
                DataCell(Text("(N/A)", style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l23Min.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l23Max.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l23Avg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
              ]),
              // L4 row
              DataRow(cells: [
                DataCell(Text("L4", style: TextStyle(fontSize: fontSize))),
                DataCell(Text("(N/A)", style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l4Min.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l4Max.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.l4Avg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
              ]),
              // Processor row
              DataRow(cells: [
                DataCell(
                    Text("Processor", style: TextStyle(fontSize: fontSize))),
                DataCell(Text("(N/A)", style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.processorMin.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.processorMax.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.processorAvg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
              ]),
              // Net row
              DataRow(cells: [
                DataCell(Text("Net", style: TextStyle(fontSize: fontSize))),
                DataCell(Text("(N/A)", style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.netMin.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.netMax.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.netAvg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
              ]),
            ],
          ),

          SizedBox(height: height * 0.02),

          // Row for OPR alone (if you want it separate)
          dataRowItem("Team OPR", team.teamOpr.toStringAsFixed(2), fontSize),

          SizedBox(height: height * 0.02),

          // DataTable for CPM/APM aggregator
          Text(
            "Coral Per Match (CPM) & Algae Per Match (APM)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          SizedBox(height: height * 0.01),
          DataTable(
            columns: [
              DataColumn(
                  label: Text("Metric", style: TextStyle(fontSize: fontSize))),
              DataColumn(
                  label: Text("Min", style: TextStyle(fontSize: fontSize))),
              DataColumn(
                  label: Text("Max", style: TextStyle(fontSize: fontSize))),
              DataColumn(
                  label: Text("Avg", style: TextStyle(fontSize: fontSize))),
            ],
            rows: [
              DataRow(cells: [
                DataCell(Text("CPM", style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.cpmMin.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.cpmMax.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.cpmAvg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
              ]),
              DataRow(cells: [
                DataCell(Text("APM", style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.apmMin.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.apmMax.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
                DataCell(Text(team.apmAvg.toStringAsFixed(2),
                    style: TextStyle(fontSize: fontSize))),
              ]),
            ],
          ),

          SizedBox(height: height * 0.02),

          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AutoTablePage(
                        teamNumber: team.teamNumber,
                        onThemeChanged: (ThemeMode mode) {},
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Auto Table",
                  style: TextStyle(
                    color: Colors.lightBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PresetComment(
                        teamNumber: team.teamNumber,
                        onThemeChanged: (ThemeMode mode) {},
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Preset Comments",
                  style: TextStyle(
                    color: Colors.lightBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Graphing(),
                    ),
                  );
                },
                child: const Text(
                  "Graphing",
                  style: TextStyle(
                    color: Colors.lightBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                  style: TextStyle(fontSize: height * 0.02),
                ),
              ),
        ],
      ),
      // No Next button—this page is purely for display.
    );
  }
}
