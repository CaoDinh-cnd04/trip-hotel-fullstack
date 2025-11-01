import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _vipStatusKey = 'vip_status';
  static const String _settingsKey = 'user_settings';

  // Token management
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // User data management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userData.toString());
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      // Simple parsing - in real app, use JSON
      return {'user': userDataString};
    }
    return null;
  }

  Future<void> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // VIP status management
  Future<void> saveVipStatus(bool isVip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vipStatusKey, isVip);
  }

  Future<bool> getVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vipStatusKey) ?? false;
  }

  // Settings management
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toString());
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsString = prefs.getString(_settingsKey);
    if (settingsString != null) {
      // Simple parsing - in real app, use JSON
      return {'settings': settingsString};
    }
    return null;
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
