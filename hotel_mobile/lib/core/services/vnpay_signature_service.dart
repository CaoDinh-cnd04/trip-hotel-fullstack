/**
 * VNPay Signature Service
 * Xử lý verify signature từ VNPay response
 * Dựa trên package vnpay_payment_flutter và VNPay API documentation
 */

import 'dart:convert';
import 'package:crypto/crypto.dart';

class VNPaySignatureService {
  final String hashSecret;

  VNPaySignatureService({required this.hashSecret});

  /// Verify signature từ VNPay response
  /// 
  /// Parameters:
  /// - params: Map chứa các query parameters từ VNPay return URL
  /// 
  /// Returns: true nếu signature hợp lệ, false nếu không
  /// 
  /// ⚠️ QUAN TRỌNG: Luôn verify signature trước khi xử lý payment result
  bool verifyResponse(Map<String, String> params) {
    try {
      // Lấy signature từ params
      final secureHash = params['vnp_SecureHash'];
      if (secureHash == null || secureHash.isEmpty) {
        print('❌ VNPay Signature: Missing vnp_SecureHash');
        return false;
      }

      // Tạo bản copy của params và xóa signature fields
      final paramsToVerify = Map<String, String>.from(params);
      paramsToVerify.remove('vnp_SecureHash');
      paramsToVerify.remove('vnp_SecureHashType');

      // Sắp xếp params theo thứ tự alphabet (QUAN TRỌNG!)
      final sortedKeys = paramsToVerify.keys.toList()..sort();
      final sortedParams = <String, String>{};
      for (final key in sortedKeys) {
        sortedParams[key] = paramsToVerify[key]!;
      }

      // Tạo query string từ sorted params (không encode)
      final queryString = sortedParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      // Tạo HMAC SHA512 signature
      final key = utf8.encode(hashSecret);
      final bytes = utf8.encode(queryString);
      final hmac = Hmac(sha512, key);
      final digest = hmac.convert(bytes);
      final expectedSignature = digest.toString();

      // So sánh signature
      final isValid = secureHash.toLowerCase() == expectedSignature.toLowerCase();

      if (!isValid) {
        print('❌ VNPay Signature: Invalid signature');
        print('   Expected: ${expectedSignature.substring(0, 40)}...');
        print('   Received: ${secureHash.substring(0, 40)}...');
      } else {
        print('✅ VNPay Signature: Valid');
      }

      return isValid;
    } catch (e) {
      print('❌ VNPay Signature: Error verifying signature: $e');
      return false;
    }
  }

  /// Get response message từ response code
  static String getResponseMessage(String? responseCode) {
    if (responseCode == null) return 'Lỗi không xác định';

    const messages = {
      '00': 'Giao dịch thành công',
      '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ.',
      '09': 'Thẻ/Tài khoản chưa đăng ký InternetBanking.',
      '10': 'Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
      '11': 'Đã hết hạn chờ thanh toán',
      '12': 'Thẻ/Tài khoản bị khóa',
      '13': 'Nhập sai mật khẩu OTP',
      '24': 'Khách hàng hủy giao dịch',
      '51': 'Tài khoản không đủ số dư',
      '65': 'Vượt quá hạn mức giao dịch trong ngày',
      '75': 'Ngân hàng thanh toán đang bảo trì',
      '79': 'Nhập sai mật khẩu thanh toán quá số lần quy định',
      '99': 'Các lỗi khác',
    };

    return messages[responseCode] ?? 'Lỗi không xác định (Code: $responseCode)';
  }

  /// Check nếu response code là thành công
  static bool isSuccess(String? responseCode) {
    return responseCode == '00';
  }
}
