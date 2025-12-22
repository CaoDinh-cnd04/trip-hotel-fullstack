import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý lưu trữ dữ liệu local bằng SharedPreferences
/// 
/// Chức năng:
/// - Lưu/lấy access token và refresh token
/// - Lưu/lấy user ID và email
/// - Lưu/lấy các giá trị generic (string, bool, int)
/// - Xóa tất cả dữ liệu (khi logout)
/// 
/// Khác với LocalStorageService:
/// - Service này tập trung vào token management (access + refresh)
/// - Hỗ trợ generic storage methods cho các loại dữ liệu khác
/// 
/// Lưu ý: Service này sử dụng SharedPreferences - không mã hóa dữ liệu
/// Dữ liệu nhạy cảm nên dùng FlutterSecureStorage thay thế
class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';

  /// Lưu access token vào SharedPreferences
  /// 
  /// [token] - Access token từ backend (JWT)
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
  }

  /// Lấy access token từ SharedPreferences
  /// 
  /// Trả về token nếu có, null nếu chưa lưu
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Xóa access token khỏi SharedPreferences (khi logout hoặc token hết hạn)
  Future<void> removeAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
  }

  /// Lưu refresh token vào SharedPreferences
  /// 
  /// [token] - Refresh token từ backend (dùng để lấy access token mới)
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRefreshToken, token);
  }

  /// Lấy refresh token từ SharedPreferences
  /// 
  /// Trả về token nếu có, null nếu chưa lưu
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  /// Lưu user ID vào SharedPreferences
  /// 
  /// [userId] - ID của user từ backend
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  /// Lấy user ID từ SharedPreferences
  /// 
  /// Trả về user ID nếu có, null nếu chưa lưu
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Lưu email của user vào SharedPreferences
  /// 
  /// [email] - Email của user
  Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  /// Lấy email của user từ SharedPreferences
  /// 
  /// Trả về email nếu có, null nếu chưa lưu
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Xóa tất cả dữ liệu trong SharedPreferences (khi logout)
  /// 
  /// Lưu ý: Hành động này không thể hoàn tác, chỉ dùng khi logout
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Lưu giá trị string với key tùy chỉnh
  /// 
  /// [key] - Key để lưu dữ liệu
  /// [value] - Giá trị string cần lưu
  /// 
  /// Dùng cho các dữ liệu không có method riêng (ví dụ: preferences, settings)
  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Lấy giá trị string với key tùy chỉnh
  /// 
  /// [key] - Key của dữ liệu cần lấy
  /// 
  /// Trả về giá trị string nếu có, null nếu chưa lưu
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Lưu giá trị boolean với key tùy chỉnh
  /// 
  /// [key] - Key để lưu dữ liệu
  /// [value] - Giá trị boolean cần lưu
  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Lấy giá trị boolean với key tùy chỉnh
  /// 
  /// [key] - Key của dữ liệu cần lấy
  /// 
  /// Trả về giá trị boolean nếu có, null nếu chưa lưu
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  /// Lưu giá trị integer với key tùy chỉnh
  /// 
  /// [key] - Key để lưu dữ liệu
  /// [value] - Giá trị integer cần lưu
  Future<void> saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Lấy giá trị integer với key tùy chỉnh
  /// 
  /// [key] - Key của dữ liệu cần lấy
  /// 
  /// Trả về giá trị integer nếu có, null nếu chưa lưu
  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }
}

