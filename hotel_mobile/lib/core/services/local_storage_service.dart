import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý lưu trữ dữ liệu local bằng SharedPreferences
/// 
/// Chức năng:
/// - Lưu/lấy token xác thực
/// - Lưu/lấy dữ liệu user
/// - Lưu/lấy trạng thái VIP
/// - Lưu/lấy cài đặt người dùng
/// - Xóa tất cả dữ liệu (khi logout)
/// 
/// Lưu ý: Service này sử dụng SharedPreferences - không mã hóa dữ liệu
/// Dữ liệu nhạy cảm nên dùng FlutterSecureStorage thay thế
class LocalStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _vipStatusKey = 'vip_status';
  static const String _settingsKey = 'user_settings';

  /// Lưu JWT token vào SharedPreferences
  /// 
  /// [token] - JWT token từ backend
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Lấy JWT token đã lưu từ SharedPreferences
  /// 
  /// Trả về token nếu có, null nếu chưa lưu
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Xóa JWT token khỏi SharedPreferences (khi logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Lưu dữ liệu user vào SharedPreferences
  /// 
  /// [userData] - Map chứa thông tin user (hiện tại dùng toString() - cần cải thiện thành JSON)
  /// 
  /// Lưu ý: Hiện tại implementation dùng toString(), nên dùng JSON.encode() để serialize đúng cách
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userData.toString());
  }

  /// Lấy dữ liệu user từ SharedPreferences
  /// 
  /// Trả về Map chứa thông tin user, hoặc null nếu chưa lưu
  /// 
  /// Lưu ý: Hiện tại implementation đơn giản, cần cải thiện với JSON parsing
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      // Simple parsing - in real app, use JSON
      return {'user': userDataString};
    }
    return null;
  }

  /// Xóa dữ liệu user khỏi SharedPreferences
  Future<void> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Lưu trạng thái VIP của user
  /// 
  /// [isVip] - true nếu user là VIP, false nếu không
  Future<void> saveVipStatus(bool isVip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vipStatusKey, isVip);
  }

  /// Lấy trạng thái VIP của user
  /// 
  /// Trả về true nếu user là VIP, false nếu không (mặc định false)
  Future<bool> getVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vipStatusKey) ?? false;
  }

  /// Lưu cài đặt người dùng vào SharedPreferences
  /// 
  /// [settings] - Map chứa các cài đặt (hiện tại dùng toString() - cần cải thiện thành JSON)
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toString());
  }

  /// Lấy cài đặt người dùng từ SharedPreferences
  /// 
  /// Trả về Map chứa cài đặt, hoặc null nếu chưa lưu
  /// 
  /// Lưu ý: Hiện tại implementation đơn giản, cần cải thiện với JSON parsing
  Future<Map<String, dynamic>?> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsString = prefs.getString(_settingsKey);
    if (settingsString != null) {
      // Simple parsing - in real app, use JSON
      return {'settings': settingsString};
    }
    return null;
  }

  /// Xóa tất cả dữ liệu trong SharedPreferences (khi logout)
  /// 
  /// Lưu ý: Hành động này không thể hoàn tác, chỉ dùng khi logout
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
