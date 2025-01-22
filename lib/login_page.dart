// lib/login_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:frc1148_2025_scouting_app/Backend/auth_service.dart';
import 'package:frc1148_2025_scouting_app/Backend/websocket_service.dart';
import 'package:frc1148_2025_scouting_app/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  final WebSocketService webSocketService;
  final Function(ThemeMode) onThemeChanged;

  const LoginPage({
    Key? key,
    required this.webSocketService,
    required this.onThemeChanged,
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

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _hasResponded = false; // To prevent multiple responses

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller for the lock icon
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Define the animation (from 0 to 1)
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Listen to the WebSocket stream
    widget.webSocketService.stream.listen(
      (rawMessage) {
        if (_hasResponded) return; // Prevent multiple responses
        _hasResponded = true;
        print('[LoginPage] Received from server: $rawMessage');
        _handleServerMessage(rawMessage);
      },
      onError: (err) {
        print('[LoginPage] WebSocket error during login: $err');
        setState(() {
          _status = LoginStatus.failure;
        });
      },
      onDone: () {
        print('[LoginPage] WebSocket connection closed during login.');
        setState(() {
          _status = LoginStatus.failure;
        });
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Sends the SQL query to check the name
  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    setState(() {
      _status = LoginStatus.loading;
      _hasResponded = false;
    });

    // Construct the SQL query
    final sql = "SELECT name FROM Names WHERE name = '$name'";

    // Prepare the query command
    final queryCmd = {
      "type": "query",
      "text": sql,
    };

    try {
      // Send the query via WebSocketService
      widget.webSocketService.sendLengthPrefixed(queryCmd);
      print('[LoginPage] Sent login query: $sql');
    } catch (e) {
      print('[LoginPage] Error sending login message: $e');
      setState(() {
        _status = LoginStatus.failure;
      });
    }
  }

  /// Handles the server's response to the login query
  void _handleServerMessage(String raw) async {
    try {
      final i = raw.indexOf('\r\n');
      if (i <= 0) return;
      final len = int.parse(raw.substring(0, i));
      final jsonPart = raw.substring(i + 2);
      if (jsonPart.length == len) {
        final decoded = jsonDecode(jsonPart);
        _processDecoded(decoded);
      } else {
        print('[LoginPage] Received message length mismatch: Expected $len, got ${jsonPart.length}');
        setState(() {
          _status = LoginStatus.failure;
        });
      }
    } catch (e) {
      print('[LoginPage] Error handling server message during login: $e');
      setState(() {
        _status = LoginStatus.failure;
      });
    }
  }

  /// Processes the decoded JSON response
  void _processDecoded(dynamic msg) async {
    if (msg is! Map) return;
    final type = msg["type"];

    switch (type) {
      case "query":
        final rows = msg["rows"];
        if (rows == null || (rows is List && rows.isEmpty)) {
          // No matching name found
          setState(() {
            _status = LoginStatus.failure;
          });
        } else {
          // Name found
          setState(() {
            _status = LoginStatus.success;
          });
          _animationController.forward();

          final username = _nameController.text.trim();

          // Save login state
          await AuthService.logIn(username);

          // Navigate to DashboardPage after a short delay to show animation
          Future.delayed(const Duration(milliseconds: 600), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(
                  webSocketService: widget.webSocketService,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            );
          });
        }
        break;

      case "error":
        print('[LoginPage] Server error during login: ${msg["error"]}');
        setState(() {
          _status = LoginStatus.failure;
        });
        break;

      default:
        print('[LoginPage] Unknown message type during login: $type');
        setState(() {
          _status = LoginStatus.failure;
        });
        break;
    }
  }

  /// Builds the animated lock/check icon
  Widget _buildAnimatedIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: _status == LoginStatus.success
          ? Icon(
              Icons.check_circle,
              key: const ValueKey('check'),
              color: Colors.green,
              size: 100,
            )
          : Icon(
              Icons.lock,
              key: const ValueKey('lock'),
              color: Colors.blue,
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
            mainAxisAlignment: MainAxisAlignment.center,
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
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
              if (_status == LoginStatus.failure) ...[
                const SizedBox(height: 20),
                const Text(
                  'Login failed. Please check your name and try again.',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
