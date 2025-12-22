import 'package:flutter/foundation.dart';

/// Class chứa cấu hình Facebook Authentication
/// 
/// Chức năng:
/// - Chứa App ID của Facebook
/// - Khởi tạo Facebook Auth SDK (tự động trên mobile, cần config trên web)
/// 
/// Lưu ý:
/// - App ID được hardcode, nên di chuyển sang environment variables trong production
/// - Facebook Auth SDK tự động khởi tạo với flutter_facebook_auth 6.2.0+
class FacebookAuthConfig {
  /// Facebook App ID (nên di chuyển sang environment variables trong production)
  static const String appId = '1361581552264816';

  /// Khởi tạo Facebook Authentication SDK
  /// 
  /// Quy trình:
  /// - Web: Facebook SDK tự động khởi tạo với cấu hình từ config
  /// - Mobile: Facebook Auth tự động sẵn sàng (không cần init thủ công)
  /// 
  /// Lưu ý: Với flutter_facebook_auth 6.2.0+, không cần gọi webInitialize() nữa
  /// SDK sẽ tự động khởi tạo
  static Future<void> initialize() async {
    // Với phiên bản flutter_facebook_auth 6.2.0, không cần webInitialize nữa
    // Facebook Auth sẽ tự động khởi tạo với cấu hình từ file config
    try {
      // Chỉ cần print log để xác nhận initialization
      if (kIsWeb) {
        // ignore: avoid_print
        print('🔵 Facebook Web SDK ready (auto-initialized)');
      } else {
        // ignore: avoid_print
        print('🔵 Facebook Auth ready (mobile)');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Facebook Auth init error: $e');
    }
  }
}
