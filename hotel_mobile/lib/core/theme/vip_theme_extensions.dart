import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'vip_theme_provider.dart';

/// Extension để dễ dàng truy cập VIP theme từ BuildContext
extension VipThemeExtension on BuildContext {
  /// Lấy VipThemeProvider từ context
  VipThemeProvider get vipTheme => Provider.of<VipThemeProvider>(this, listen: false);
  
  /// Lấy VipThemeProvider với listen = true (rebuild khi thay đổi)
  VipThemeProvider watchVipTheme() => Provider.of<VipThemeProvider>(this);
  
  /// Lấy màu chính theo VIP level
  Color get vipPrimaryColor => vipTheme.primaryColor;
  
  /// Lấy màu phụ theo VIP level
  Color get vipSecondaryColor => vipTheme.secondaryColor;
  
  /// Lấy màu nền theo VIP level
  Color get vipBackgroundColor => vipTheme.backgroundColor;
  
  /// Lấy gradient colors theo VIP level
  List<Color> get vipGradientColors => vipTheme.gradientColors;
  
  /// Lấy VIP level hiện tại
  String get vipLevel => vipTheme.vipLevel;
  
  /// Refresh VIP level từ API
  Future<void> refreshVipLevel() => vipTheme.refreshVipLevel();
}

