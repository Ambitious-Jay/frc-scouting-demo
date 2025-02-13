import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;

  const LoginPage({
    Key? key,
    required this.webSocketService,
    required this.onThemeChanged,
    WebSocketChannel? channel,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

enum LoginStatus { idle, loading, success, failure }

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  LoginStatus _status = LoginStatus.idle;

  bool _hasResponded = false; // Avoid double-handling the same server response

  late AnimationController _animationController;
  late Animation<double> _animation;

  /// Subscription to the WebSocket's broadcast stream
  StreamSubscription<dynamic>? _wsSubscription;

  @override
  void initState() {
    super.initState();

    // 1) Ensure we have an active WebSocket connection (in case we manually disconnected earlier).
    widget.webSocketService.connect();

    // 2) Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 3) Listen to the WebSocket stream. If null, it's still connecting.
    final s = widget.webSocketService.stream;
    if (s == null) {
      print(
          '[LoginPage] No WebSocket stream yet. Possibly still connecting...');
      return;
    }

    _wsSubscription = s.listen(
      (rawMessage) {
        if (!mounted) return;
        if (_hasResponded) return;
        _handleServerMessage(rawMessage);
      },
      onError: (err) {
        // Catch any WebSocket-level error (e.g., "unable to connect")
        if (!mounted) return;
        print('[LoginPage] WebSocket error: $err');
        _showError('WebSocket error: $err');
      },
      onDone: () {
        // Called if the server closes or the socket is lost
        if (!mounted) return;
        print('[LoginPage] WebSocket connection closed during login.');
        _showError('Connection closed unexpectedly.');
      },
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Attempt to log in by sending a query to the server
  Future<void> _attemptLogin() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    setState(() {
      _status = LoginStatus.loading;
      _hasResponded = false; // Let the next incoming message be processed
    });

    final sql = "SELECT name FROM Names WHERE name = '$name'";
    final queryCmd = {
      "type": "query",
      "text": sql,
    };

    // Wrap sending in a try/catch in case the WebSocket is null or fails
    try {
      widget.webSocketService.sendLengthPrefixed(queryCmd);
      print('[LoginPage] Sent login query: $sql');
    } catch (e) {
      print('[LoginPage] Error sending query: $e');
      _showError('Error sending query to server: $e');
    }
  }

  /// Handles the "length\r\njson" format from the server
  void _handleServerMessage(String raw) {
    print('[LoginPage] Received from server: $raw');
    _hasResponded = true;

    try {
      final idx = raw.indexOf('\r\n');
      if (idx <= 0) {
        _showError('Server data missing CRLF delimiter.');
        return;
      }
      final len = int.parse(raw.substring(0, idx));
      final jsonPart = raw.substring(idx + 2);

      if (jsonPart.length != len) {
        print('[LoginPage] Mismatch: expected $len, got ${jsonPart.length}');
        _showError('Server sent malformed data.');
        return;
      }

      final decoded = jsonDecode(jsonPart);
      _processDecoded(decoded);
    } catch (e) {
      print('[LoginPage] Error parsing server message: $e');
      _showError('Error parsing server message: $e');
    }
  }

  /// Processes the decoded JSON from the server
  void _processDecoded(dynamic msg) async {
    if (!mounted) return;
    if (msg is! Map) return;

    final type = msg["type"];
    switch (type) {
      case "query":
        // Typically means we got our login query results
        final rows = msg["rows"];
        if (rows == null || (rows is List && rows.isEmpty)) {
          _showError('No matching name found. Please try again.');
        } else {
          // Success
          setState(() => _status = LoginStatus.success);
          _animationController.forward();

          final username = _nameController.text.trim();
          await AuthService.logIn(username);

          // Let the user see the success check icon for 0.6s
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardPage(
                  webSocketService: widget.webSocketService,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            );
          });
        }
        break;

      case "error":
        // The server might respond with { "type": "error", "error": "some message" }
        final errMsg = msg["error"] ?? 'Unknown server error.';
        _showError('Server error: $errMsg');
        break;

      case "ok":
        // Possibly from the "open" command. Not needed for the login logic.
        print('[LoginPage] Received "ok" from server (ignored).');
        break;

      default:
        _showError('Unknown response type from server: $type');
        break;
    }
  }

  /// Shows an error via SnackBar, resets _status after 3s
  void _showError(String errorText) {
    setState(() => _status = LoginStatus.failure);

    // Show a SnackBar for 3 seconds
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorText),
        duration: const Duration(seconds: 3),
      ),
    );

    // After 3s, clear the error
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _status = LoginStatus.idle);
    });
  }

  Widget _buildAnimatedIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: _status == LoginStatus.success
          ? const Icon(
              Icons.check_circle,
              key: ValueKey('check'),
              color: Colors.green,
              size: 100,
            )
          : const Icon(
              Icons.lock,
              key: ValueKey('lock'),
              color: Colors.red,
              size: 100,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildAnimatedIcon(),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter your name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  enabled: _status != LoginStatus.loading,
                  // Allow pressing Enter/Done to submit:
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) => _attemptLogin(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _status == LoginStatus.loading ? null : _attemptLogin,
                child: _status == LoginStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
