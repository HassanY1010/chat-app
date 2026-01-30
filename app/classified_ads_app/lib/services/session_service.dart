import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SessionService {
  static final SessionService instance = SessionService._internal();
  SessionService._internal();

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Initialize the service (should be called in main.dart)
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  /// Get authentication token
  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  /// Save user data
  Future<void> saveUser(User user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Get user data
  User? getUser() {
    final String? userData = _prefs.getString(_keyUser);
    if (userData == null) return null;
    try {
      return User.fromJson(jsonDecode(userData));
    } catch (e) {
      return null;
    }
  }

  /// Clear session (Logout)
  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
  }

  /// Check if session exists
  bool hasSession() {
    return getToken() != null && getUser() != null;
  }
}
