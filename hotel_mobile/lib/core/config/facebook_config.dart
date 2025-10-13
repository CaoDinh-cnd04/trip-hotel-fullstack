import 'package:flutter/foundation.dart';

class FacebookAuthConfig {
  static const String appId = '1361581552264816';

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
