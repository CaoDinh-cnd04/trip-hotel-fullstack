/**
 * Currency Formatter Utility
 * 
 * Format số tiền theo định dạng VND
 */

import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format số tiền sang định dạng VND
  /// 
  /// Example: 1000000 -> "1.000.000 ₫"
  static String format(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} ₫';
  }
  
  static String formatVND(double amount) {
    return format(amount);
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

