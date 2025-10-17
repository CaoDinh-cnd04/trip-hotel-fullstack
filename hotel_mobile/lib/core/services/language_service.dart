import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('vi'); // Default to Vietnamese
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  bool get isVietnamese => _currentLocale.languageCode == 'vi';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('vi'), // Vietnamese
    Locale('en'), // English
  ];
  
  LanguageService() {
    _loadLanguage();
  }
  
  /// Load saved language from SharedPreferences
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
  
  /// Change language and save to SharedPreferences
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
  
  /// Toggle between Vietnamese and English
  Future<void> toggleLanguage() async {
    final newLanguageCode = isVietnamese ? 'en' : 'vi';
    await changeLanguage(newLanguageCode);
  }
  
  /// Set Vietnamese language
  Future<void> setVietnamese() async {
    await changeLanguage('vi');
  }
  
  /// Set English language
  Future<void> setEnglish() async {
    await changeLanguage('en');
  }
  
  /// Get language display name
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
  
  /// Get current language display name
  String get currentLanguageDisplayName {
    return getLanguageDisplayName(_currentLocale.languageCode);
  }
}
