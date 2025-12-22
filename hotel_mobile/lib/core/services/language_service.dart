import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý ngôn ngữ của ứng dụng
/// 
/// Chức năng:
/// - Quản lý locale hiện tại (vi, en)
/// - Lưu/tải ngôn ngữ từ SharedPreferences
/// - Thay đổi ngôn ngữ và thông báo listeners
/// - Hỗ trợ toggle giữa tiếng Việt và tiếng Anh
/// 
/// Sử dụng ChangeNotifier để thông báo khi ngôn ngữ thay đổi
/// Các widget có thể listen để tự động cập nhật khi ngôn ngữ thay đổi
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  /// Locale hiện tại (mặc định: tiếng Việt)
  Locale _currentLocale = const Locale('vi');
  
  /// Lấy locale hiện tại
  Locale get currentLocale => _currentLocale;
  
  /// Lấy language code hiện tại (vi hoặc en)
  String get currentLanguageCode => _currentLocale.languageCode;
  
  /// Kiểm tra xem đang dùng tiếng Việt không
  bool get isVietnamese => _currentLocale.languageCode == 'vi';
  
  /// Kiểm tra xem đang dùng tiếng Anh không
  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// Danh sách các ngôn ngữ được hỗ trợ
  static const List<Locale> supportedLocales = [
    Locale('vi'), // Vietnamese
    Locale('en'), // English
  ];
  
  LanguageService() {
    // Tự động load ngôn ngữ đã lưu khi khởi tạo
    _loadLanguage();
  }

  /// Tải ngôn ngữ đã lưu từ SharedPreferences
  /// 
  /// Nếu có ngôn ngữ đã lưu, sẽ cập nhật _currentLocale và notify listeners
  /// Nếu không có hoặc lỗi, giữ nguyên mặc định (tiếng Việt)
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      // If error, keep default language (Vietnamese)
    }
  }
  
  /// Thay đổi ngôn ngữ và lưu vào SharedPreferences
  /// 
  /// [languageCode] - Mã ngôn ngữ (vi hoặc en)
  /// 
  /// Quy trình:
  /// 1. Kiểm tra ngôn ngữ có được hỗ trợ không
  /// 2. Cập nhật _currentLocale
  /// 3. Notify listeners để cập nhật UI
  /// 4. Lưu vào SharedPreferences để lần sau tự động load
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLocales.any((locale) => locale.languageCode == languageCode)) {
      return;
    }
    
    _currentLocale = Locale(languageCode);
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Chuyển đổi giữa tiếng Việt và tiếng Anh
  /// 
  /// Nếu hiện tại là tiếng Việt → chuyển sang tiếng Anh
  /// Nếu hiện tại là tiếng Anh → chuyển sang tiếng Việt
  Future<void> toggleLanguage() async {
    final newLanguageCode = isVietnamese ? 'en' : 'vi';
    await changeLanguage(newLanguageCode);
  }
  
  /// Đặt ngôn ngữ là tiếng Việt
  Future<void> setVietnamese() async {
    await changeLanguage('vi');
  }

  /// Đặt ngôn ngữ là tiếng Anh
  Future<void> setEnglish() async {
    await changeLanguage('en');
  }

  /// Lấy tên hiển thị của ngôn ngữ
  /// 
  /// [languageCode] - Mã ngôn ngữ (vi hoặc en)
  /// 
  /// Trả về: "Tiếng Việt" hoặc "English"
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      default:
        return languageCode.toUpperCase();
    }
  }
  
  /// Lấy tên hiển thị của ngôn ngữ hiện tại
  /// 
  /// Trả về: "Tiếng Việt" hoặc "English" tùy theo locale hiện tại
  String get currentLanguageDisplayName {
    return getLanguageDisplayName(_currentLocale.languageCode);
  }
}
