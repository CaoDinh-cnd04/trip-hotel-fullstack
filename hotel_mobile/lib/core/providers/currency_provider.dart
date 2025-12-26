import 'package:flutter/material.dart';
import '../services/currency_service.dart';

/// Currency Provider - Quản lý currency state và notify khi currency thay đổi
/// 
/// Sử dụng Provider để các widget có thể listen và rebuild khi currency thay đổi
class CurrencyProvider extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService.instance;
  
  String get currentCurrency => _currencyService.currentCurrency;
  String get currencyCode => _currencyService.getCurrencyCode();
  String get currencySymbol => _currencyService.getCurrencySymbol();
  
  CurrencyProvider() {
    // Listen to currency changes (nếu có thể)
    // Hiện tại sẽ notify thủ công khi currency thay đổi
  }
  
  /// Set currency và notify listeners
  Future<void> setCurrency(String currency) async {
    await _currencyService.setCurrency(currency);
    notifyListeners();
    print('✅ [CurrencyProvider] Currency changed to: $currency, notifying listeners');
  }
  
  /// Refresh currency từ API và notify listeners
  Future<void> refreshCurrency() async {
    await _currencyService.refreshCurrency();
    notifyListeners();
    print('✅ [CurrencyProvider] Currency refreshed, notifying listeners');
  }
  
  /// Convert VND sang currency hiện tại
  double convertFromVND(double vndAmount) {
    return _currencyService.convertFromVND(vndAmount);
  }
}

