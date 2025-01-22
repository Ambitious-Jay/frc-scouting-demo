// lib/Backend/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _loggedInKey = 'is_logged_in';
  static const String _usernameKey = 'username';

  /// Saves the login state and username.
  static Future<void> logIn(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_usernameKey, username);
    print('[AuthService] User "$username" logged in. Login state saved.');
  }

  /// Clears the login state and username.
  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey) ?? 'Unknown';
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_usernameKey);
    print('[AuthService] User "$username" logged out. Login state cleared.');
  }

  /// Checks if the user is logged in.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_loggedInKey) ?? false;
    print('[AuthService] Checked login status: $loggedIn');
    return loggedIn;
  }

  /// Retrieves the logged-in username.
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    print('[AuthService] Retrieved username: ${username ?? "None"}');
    return username;
  }
}
