import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  static Future<String?> getToken() async {
    final user = await getUser();
    return user?['token'];
  }

  static Future<String?> getRole() async {
    final user = await getUser();
    return user?['role'];
  }

}
