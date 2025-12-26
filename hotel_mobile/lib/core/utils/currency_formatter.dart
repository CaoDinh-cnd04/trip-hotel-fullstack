/**
 * Currency Formatter Utility
 * 
 * Format số tiền theo currency setting của user
 * Hỗ trợ: VND, USD, EUR, JPY
 */

import 'package:intl/intl.dart';
import '../services/currency_service.dart';

class CurrencyFormatter {
  /// Format số tiền theo currency setting hiện tại
  /// 
  /// Example VND: 1000000 -> "1.000.000 ₫"
  /// Example USD: 100 -> "$100.00"
  static String format(double amount) {
    final currencyService = CurrencyService.instance;
    final currencyCode = currencyService.getCurrencyCode();
    final currencySymbol = currencyService.getCurrencySymbol();
    
    // Nếu không phải VND, convert từ VND sang currency khác
    double displayAmount = amount;
    if (currencyCode != 'VND') {
      displayAmount = currencyService.convertFromVND(amount);
    }
    
    switch (currencyCode) {
      case 'USD':
        final formatter = NumberFormat.currency(locale: 'en_US', symbol: currencySymbol, decimalDigits: 2);
        return formatter.format(displayAmount);
      case 'EUR':
        final formatter = NumberFormat.currency(locale: 'de_DE', symbol: currencySymbol, decimalDigits: 2);
        return formatter.format(displayAmount);
      case 'JPY':
        final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: currencySymbol, decimalDigits: 0);
        return formatter.format(displayAmount);
      default: // VND
        final formatter = NumberFormat('#,###', 'vi_VN');
        return '${formatter.format(displayAmount)} $currencySymbol';
    }
  }
  
  /// Format số tiền sang định dạng VND (luôn dùng VND, không convert)
  /// 
  /// Example: 1000000 -> "1.000.000 ₫"
  static String formatVND(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} ₫';
  }

  /// Format số tiền sang định dạng VND (compact)
  /// 
  /// Example: 1000000 -> "1tr"
  static String formatVNDCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '${amount.toStringAsFixed(0)} ₫';
  }

  /// Parse string VND về số
  /// 
  /// Example: "1.000.000 ₫" -> 1000000.0
  static double parseVND(String vndString) {
    final cleaned = vndString
        .replaceAll('₫', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format số tiền USD
  /// 
  /// Example: 100 -> "$100.00"
  static String formatUSD(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return formatter.format(amount);
  }
}

