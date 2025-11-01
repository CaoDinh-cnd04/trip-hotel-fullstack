import 'package:flutter/services.dart';
import 'dart:convert';

/**
 * Service để gọi VNPay Native Android SDK thay vì WebView
 * Sử dụng MethodChannel để giao tiếp với native code
 */
class VnPayNativeService {
  static const MethodChannel _channel = MethodChannel('com.example.hotel_mobile/vnpay');

  /// Mở VNPay Native SDK
  /// 
  /// [paymentUrl] - URL thanh toán từ backend (từ vnpayService.createPaymentUrl)
  /// [tmnCode] - Mã terminal từ VNPay (cần lấy từ config hoặc backend)
  /// [scheme] - Scheme để callback về app (mặc định: "vnpayresult")
  /// [isSandbox] - true nếu là môi trường sandbox, false nếu là production
  /// 
  /// Trả về Map với các thông tin:
  /// - success: bool
  /// - responseCode: String (ví dụ: "00" = thành công)
  /// - transactionNo: String
  /// - amount: String
  /// - orderId: String
  /// - bankCode: String
  /// - payDate: String
  /// - reason: String (nếu thất bại)
  static Future<Map<String, dynamic>> openVnPaySdk({
    required String paymentUrl,
    required String tmnCode,
    String scheme = 'vnpayresult',
    bool isSandbox = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'openVnPaySdk',
        {
          'url': paymentUrl,
          'tmnCode': tmnCode,
          'scheme': scheme,
          'isSandbox': isSandbox,
        },
      );

      // Convert dynamic Map to String Map
      final Map<String, dynamic> convertedResult = {};
      result?.forEach((key, value) {
        convertedResult[key.toString()] = value;
      });

      return convertedResult;
    } on PlatformException catch (e) {
      print('❌ VNPay Native SDK Error: ${e.message}');
      return {
        'success': false,
        'reason': 'platform_error',
        'error': e.message,
      };
    } catch (e) {
      print('❌ VNPay Native SDK Unknown Error: $e');
      return {
        'success': false,
        'reason': 'unknown_error',
        'error': e.toString(),
      };
    }
  }

  /// Kiểm tra xem VNPay Native SDK có sẵn không (chỉ trên Android)
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}



