import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/services/backend_auth_service.dart';

/// Currency Service - Quản lý currency setting của user
/// 
/// Currency được lưu:
/// - Trong SharedPreferences (local cache)
/// - Trong backend user_settings (persistent)
/// 
/// Format: "₫ | VND", "$ | USD", "€ | EUR", "¥ | JPY"
class CurrencyService {
  static const String _currencyKey = 'user_currency';
  static const String _defaultCurrency = '₫ | VND';
  
  final UserProfileService _userProfileService = UserProfileService();
  final BackendAuthService _authService = BackendAuthService();
  
  static CurrencyService? _instance;
  static CurrencyService get instance {
    _instance ??= CurrencyService();
    return _instance!;
  }
  
  String? _currentCurrency;
  
  /// Lấy currency hiện tại (từ cache hoặc default)
  String get currentCurrency => _currentCurrency ?? _defaultCurrency;
  
  /// Khởi tạo currency service
  /// Load currency từ cache trước, sau đó load từ API nếu user đã đăng nhập
  Future<void> initialize() async {
    await _loadCachedCurrency();
    if (_authService.isSignedIn) {
      _loadCurrencyFromApi();
    }
  }
  
  /// Load currency từ cache
  Future<void> _loadCachedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCurrency = prefs.getString(_currencyKey);
      if (cachedCurrency != null && cachedCurrency.isNotEmpty) {
        _currentCurrency = cachedCurrency;
        print('✅ [Currency] Loaded cached currency: $_currentCurrency');
      } else {
        _currentCurrency = _defaultCurrency;
        print('ℹ️ [Currency] No cached currency, using default: $_currentCurrency');
      }
    } catch (e) {
      print('⚠️ [Currency] Error loading cached currency: $e');
      _currentCurrency = _defaultCurrency;
    }
  }
  
  /// Load currency từ API
  Future<void> _loadCurrencyFromApi() async {
    try {
      if (!_authService.isSignedIn) {
        print('ℹ️ [Currency] User chưa đăng nhập, giữ currency mặc định');
        return;
      }
      
      print('🔄 [Currency] Loading currency from API...');
      final response = await _userProfileService.getUserSettings();
      
      if (response.success && response.data != null) {
        final currency = response.data!['currency'] ?? _defaultCurrency;
        if (currency != _currentCurrency) {
          _currentCurrency = currency;
          await _saveCurrencyToCache(currency);
          print('✅ [Currency] Currency updated from API: $_currentCurrency');
        } else {
          print('ℹ️ [Currency] Currency unchanged: $_currentCurrency');
        }
      }
    } catch (e) {
      print('⚠️ [Currency] Error loading currency from API: $e');
    }
  }
  
  /// Lưu currency vào cache
  Future<void> _saveCurrencyToCache(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency);
    } catch (e) {
      print('⚠️ [Currency] Error saving currency to cache: $e');
    }
  }
  
  /// Set currency (dùng khi user chọn currency mới)
  Future<void> setCurrency(String currency) async {
    if (_currentCurrency != currency) {
      _currentCurrency = currency;
      await _saveCurrencyToCache(currency);
      
      // Lưu vào backend nếu user đã đăng nhập
      if (_authService.isSignedIn) {
        try {
          await _userProfileService.updateUserSettings(currency: currency);
          print('✅ [Currency] Currency saved to backend: $currency');
        } catch (e) {
          print('⚠️ [Currency] Error saving currency to backend: $e');
        }
      }
    }
  }
  
  /// Refresh currency từ API
  Future<void> refreshCurrency() async {
    await _loadCurrencyFromApi();
  }
  
  /// Lấy currency code (VND, USD, EUR, JPY)
  String getCurrencyCode() {
    final currency = currentCurrency;
    if (currency.contains('VND')) return 'VND';
    if (currency.contains('USD')) return 'USD';
    if (currency.contains('EUR')) return 'EUR';
    if (currency.contains('JPY')) return 'JPY';
    return 'VND'; // Default
  }
  
  /// Lấy currency symbol (₫, $, €, ¥)
  String getCurrencySymbol() {
    final currency = currentCurrency;
    if (currency.contains('VND')) return '₫';
    if (currency.contains('USD')) return '\$';
    if (currency.contains('EUR')) return '€';
    if (currency.contains('JPY')) return '¥';
    return '₫'; // Default
  }
  
  /// Convert VND sang currency khác (tỷ giá tạm thời, có thể cập nhật từ API)
  double convertFromVND(double vndAmount) {
    final code = getCurrencyCode();
    switch (code) {
      case 'USD':
        return vndAmount / 25000; // 1 USD = 25,000 VND (tỷ giá mẫu)
      case 'EUR':
        return vndAmount / 27000; // 1 EUR = 27,000 VND (tỷ giá mẫu)
      case 'JPY':
        return vndAmount / 170; // 1 JPY = 170 VND (tỷ giá mẫu)
      default: // VND
        return vndAmount;
    }
  }
}

