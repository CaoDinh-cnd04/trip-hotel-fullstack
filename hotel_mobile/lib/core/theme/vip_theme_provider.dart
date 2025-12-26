import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/services/backend_auth_service.dart';

/// VIP Theme Provider - Quản lý theme động dựa trên VIP tier
/// 
/// Theme sẽ tự động thay đổi theo VIP level của user:
/// - Bronze (Đồng): Màu nâu/đồng
/// - Silver (Bạc): Màu xám/bạc
/// - Gold (Vàng): Màu vàng
/// - Diamond (Kim Cương): Màu xanh dương/teal
class VipThemeProvider extends ChangeNotifier {
  static const String _vipLevelKey = 'cached_vip_level';
  
  String _vipLevel = 'Bronze'; // Default: Bronze
  bool _isLoading = false;
  
  String get vipLevel => _vipLevel;
  bool get isLoading => _isLoading;
  
  final UserProfileService _userProfileService = UserProfileService();
  final BackendAuthService _authService = BackendAuthService();
  
  VipThemeProvider() {
    _initialize();
  }
  
  /// Khởi tạo VIP theme provider
  Future<void> _initialize() async {
    // Load từ cache trước để hiển thị ngay
    await _loadCachedVipLevel();
    
    // Sau đó load từ API để cập nhật mới nhất
    _loadVipLevelFromApi();
  }
  
  /// Load VIP level từ cache (để hiển thị ngay khi app khởi động)
  Future<void> _loadCachedVipLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLevel = prefs.getString(_vipLevelKey);
      if (cachedLevel != null && cachedLevel.isNotEmpty) {
        _vipLevel = cachedLevel;
        notifyListeners();
        print('✅ [VIP Theme] Loaded cached VIP level: $_vipLevel');
      } else {
        print('ℹ️ [VIP Theme] No cached VIP level found, using default: $_vipLevel');
      }
    } catch (e) {
      print('⚠️ [VIP Theme] Error loading cached VIP level: $e');
    }
  }
  
  /// Load VIP level từ API (cập nhật mới nhất)
  Future<void> _loadVipLevelFromApi() async {
    if (_isLoading) {
      print('ℹ️ [VIP Theme] Already loading VIP level, skipping...');
      return;
    }
    
    try {
      // Chỉ load nếu user đã đăng nhập
      if (!_authService.isSignedIn) {
        print('ℹ️ [VIP Theme] User chưa đăng nhập, giữ VIP level mặc định: $_vipLevel');
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      print('🔄 [VIP Theme] Loading VIP level from API...');
      final response = await _userProfileService.getVipStatus();
      
      print('📡 [VIP Theme] API Response: success=${response.success}, data=${response.data}');
      
      if (response.success && response.data != null) {
        final newLevel = response.data!['vipLevel'] ?? 'Bronze';
        print('📊 [VIP Theme] Current level: $_vipLevel, New level: $newLevel');
        
        if (newLevel != _vipLevel) {
          _vipLevel = newLevel;
          await _saveVipLevelToCache(newLevel);
          notifyListeners();
          print('✅ [VIP Theme] VIP level updated: $_vipLevel → Theme will rebuild');
        } else {
          print('ℹ️ [VIP Theme] VIP level unchanged: $_vipLevel');
        }
      } else {
        print('⚠️ [VIP Theme] API response failed or no data: ${response.message}');
      }
    } catch (e) {
      print('❌ [VIP Theme] Error loading VIP level from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Lưu VIP level vào cache
  Future<void> _saveVipLevelToCache(String level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_vipLevelKey, level);
    } catch (e) {
      print('⚠️ Error saving VIP level to cache: $e');
    }
  }
  
  /// Refresh VIP level từ API (gọi thủ công khi cần)
  Future<void> refreshVipLevel() async {
    await _loadVipLevelFromApi();
  }
  
  /// Set VIP level (dùng cho testing hoặc manual update)
  void setVipLevel(String level) {
    if (_vipLevel != level) {
      _vipLevel = level;
      _saveVipLevelToCache(level);
      notifyListeners();
    }
  }
  
  
  /// Lấy màu chính theo VIP level
  Color get primaryColor => _getPrimaryColor(_vipLevel);
  
  /// Lấy màu phụ theo VIP level
  Color get secondaryColor => _getSecondaryColor(_vipLevel);
  
  /// Lấy màu nền theo VIP level
  Color get backgroundColor => _getBackgroundColor(_vipLevel);
  
  /// Lấy gradient colors theo VIP level
  List<Color> get gradientColors => _getGradientColors(_vipLevel);
  
  // Helper methods để lấy màu theo VIP level
  Color _getPrimaryColor(String level) {
    switch (level) {
      case 'Diamond':
        return const Color(0xFF00BCD4); // Cyan/Teal
      case 'Gold':
        return const Color(0xFFFFB300); // Amber/Gold
      case 'Silver':
        return const Color(0xFF9E9E9E); // Grey
      default: // Bronze
        return const Color(0xFF8B4513); // Brown
    }
  }
  
  Color _getSecondaryColor(String level) {
    switch (level) {
      case 'Diamond':
        return const Color(0xFF0097A7); // Darker cyan
      case 'Gold':
        return const Color(0xFFFF8F00); // Darker amber
      case 'Silver':
        return const Color(0xFF757575); // Darker grey
      default: // Bronze
        return const Color(0xFFA0522D); // Sienna
    }
  }
  
  Color _getBackgroundColor(String level) {
    switch (level) {
      case 'Diamond':
        return const Color(0xFFE0F7FA); // Light cyan
      case 'Gold':
        return const Color(0xFFFFF8E1); // Light amber
      case 'Silver':
        return const Color(0xFFFAFAFA); // Light grey
      default: // Bronze
        return const Color(0xFFF5E6D3); // Light brown
    }
  }
  
  List<Color> _getGradientColors(String level) {
    switch (level) {
      case 'Diamond':
        return [
          const Color(0xFF00BCD4),
          const Color(0xFF0097A7),
        ];
      case 'Gold':
        return [
          const Color(0xFFFFB300),
          const Color(0xFFFF8F00),
        ];
      case 'Silver':
        return [
          const Color(0xFF9E9E9E),
          const Color(0xFF757575),
        ];
      default: // Bronze
        return [
          const Color(0xFF8B4513),
          const Color(0xFFA0522D),
        ];
    }
  }
}

