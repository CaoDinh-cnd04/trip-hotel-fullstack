/**
 * VNPay Service - Xử lý thanh toán VNPay trong Flutter
 * 
 * Tự implement logic tạo payment URL (không dùng package bên thứ 3)
 * Dựa trên VNPay API documentation và backend implementation
 * 
 * Chức năng:
 * - Tạo payment URL trực tiếp từ Flutter (không cần backend API)
 * - Verify signature từ VNPay response
 * - Mở trình duyệt/WebView để thanh toán
 * - Xử lý kết quả thanh toán
 * - Query trạng thái giao dịch
 */

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/config/payment_config.dart';
import '../../core/services/backend_auth_service.dart';
import '../../core/services/vnpay_signature_service.dart';

/// Model cho Bank (ngân hàng VNPay)
class VNPayBank {
  final String code;
  final String name;

  VNPayBank({
    required this.code,
    required this.name,
  });

  factory VNPayBank.fromJson(Map<String, dynamic> json) {
    return VNPayBank(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// Service xử lý VNPay
/// Tự implement logic tạo payment URL (không dùng package)
class VNPayService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();
  
  // VNPay Signature Service để verify response
  late final VNPaySignatureService _signatureService;

  VNPayService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    // Khởi tạo VNPay Signature Service với hash secret từ PaymentConfig
    _signatureService = VNPaySignatureService(
      hashSecret: PaymentConfig.vnpayHashSecret,
    );
    
    // Add interceptor để thêm token vào header (cho các API khác)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Format date theo format VNPay (yyyyMMddHHmmss)
  String _formatDate(DateTime date) {
    return DateFormat('yyyyMMddHHmmss').format(date);
  }

  /// Sanitize order info (loại bỏ ký tự đặc biệt)
  String _sanitizeOrderInfo(String orderInfo) {
    // VNPay chỉ chấp nhận: a-z, A-Z, 0-9, và các ký tự: - . _ ~
    return orderInfo.replaceAll(RegExp(r'[^a-zA-Z0-9\-._~]'), '');
  }

  /// Sort object theo thứ tự alphabet (giống backend)
  Map<String, String> _sortObject(Map<String, String> obj) {
    final sortedKeys = obj.keys.toList()..sort();
    final sorted = <String, String>{};
    for (final key in sortedKeys) {
      sorted[key] = obj[key]!;
    }
    return sorted;
  }

  /// Tạo query string từ params (không encode)
  String _createQueryString(Map<String, String> params) {
    return params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  /// Tạo URL thanh toán VNPay TRỰC TIẾP từ Flutter
  /// 
  /// Parameters:
  /// - [bookingId]: ID của booking cần thanh toán
  /// - [amount]: Số tiền (VND)
  /// - [orderInfo]: Mô tả đơn hàng
  /// - [bankCode]: Mã ngân hàng (optional, nếu muốn chọn ngân hàng cụ thể)
  /// - [bookingData]: Thông tin booking đầy đủ để lưu vào backend (optional)
  /// - [ipAddr]: IP address của client (optional, sẽ tự detect)
  /// 
  /// Returns: Map với paymentUrl và orderId
  Future<Map<String, dynamic>> createPaymentUrl({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? bankCode,
    Map<String, dynamic>? bookingData,
    String? ipAddr,
  }) async {
    try {
      print('📤 VNPay Service: Tạo payment URL trực tiếp từ Flutter');
      print('📋 VNPay Service: bookingId=$bookingId, amount=$amount');
      
      // Tạo order ID unique
      final now = DateTime.now();
      final orderId = 'BOOKING_${bookingId}_${now.millisecondsSinceEpoch}';
      
      // Lấy IP address (nếu không có, dùng default)
      final clientIp = ipAddr ?? '127.0.0.1';
      
      // Return URL - phải là public URL (không phải localhost)
      // Lấy từ backend API
      final returnUrl = await _getReturnUrl();
      
      if (returnUrl.contains('localhost') || returnUrl.contains('127.0.0.1')) {
        throw Exception('VNPay Sandbox không chấp nhận localhost làm Return URL. Vui lòng cấu hình Return URL công khai trong backend .env file.');
      }
      
      // Format dates
      final createDate = _formatDate(now);
      final expireDate = _formatDate(now.add(const Duration(minutes: 15)));
      
      // Tạo params theo đúng format VNPay
      final vnpParams = <String, String>{
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': PaymentConfig.vnpayTmnCode,
        'vnp_Amount': (amount * 100).toInt().toString(), // VNPay yêu cầu * 100
        'vnp_CurrCode': 'VND',
        'vnp_TxnRef': orderId,
        'vnp_OrderInfo': _sanitizeOrderInfo(orderInfo),
        'vnp_OrderType': 'billpayment',
        'vnp_Locale': 'vn',
        'vnp_ReturnUrl': returnUrl,
        'vnp_IpAddr': clientIp,
        'vnp_CreateDate': createDate,
        'vnp_ExpireDate': expireDate,
      };
      
      // Thêm bankCode nếu có
      if (bankCode != null && bankCode.trim().isNotEmpty) {
        vnpParams['vnp_BankCode'] = bankCode.trim();
      }
      
      // Sắp xếp params theo thứ tự alphabet (QUAN TRỌNG!)
      final sortedParams = _sortObject(vnpParams);
      
      // Tạo query string từ sorted params (không encode)
      final signData = _createQueryString(sortedParams);
      
      // Tạo HMAC SHA512 signature
      final key = utf8.encode(PaymentConfig.vnpayHashSecret);
      final bytes = utf8.encode(signData);
      final hmac = Hmac(sha512, key);
      final digest = hmac.convert(bytes);
      final signature = digest.toString();
      
      // Thêm signature vào params
      sortedParams['vnp_SecureHash'] = signature;
      
      // Tạo URL cuối cùng
      final queryString = _createQueryString(sortedParams);
      final baseUrl = PaymentConfig.useVnpaySandbox 
          ? PaymentConfig.vnpaySandboxUrl 
          : PaymentConfig.vnpayProductionUrl;
      final paymentUrl = '$baseUrl?$queryString';
      
      print('✅ VNPay Service: Payment URL đã được tạo thành công');
      print('📋 VNPay Service: Order ID: $orderId');
      print('📋 VNPay Service: Return URL: $returnUrl');
      print('📋 VNPay Service: Signature: ${signature.substring(0, 40)}...');
      
      // Lưu booking data vào backend (nếu có) - để backend xử lý sau khi payment success
      if (bookingData != null) {
        try {
          await _savePaymentInfo(bookingId, orderId, amount, bookingData);
        } catch (e) {
          print('⚠️ VNPay Service: Không thể lưu payment info vào backend: $e');
          // Không throw error, vẫn tiếp tục với payment
        }
      }
      
      return {
        'paymentUrl': paymentUrl,
        'orderId': orderId,
      };
    } catch (e) {
      print('❌ VNPay Service: Error tạo payment URL: $e');
      rethrow;
    }
  }
  
  /// Lấy Return URL từ backend hoặc config
  /// ⚠️ QUAN TRỌNG: Return URL phải là public URL (không phải localhost)
  Future<String> _getReturnUrl() async {
    try {
      // Thử lấy từ backend API để lấy Return URL đã được config
      // Backend sẽ trả về Return URL từ .env (đã là public URL)
      try {
        final response = await _dio.get('/api/v2/vnpay/config');
        
        // Nếu backend trả về error về localhost
        if (response.statusCode == 400 && response.data['error'] == 'INVALID_RETURN_URL') {
          final errorData = response.data;
          throw Exception(
            '${errorData['message']}\n\n'
            '${errorData['hint'] ?? ''}\n\n'
            'Ví dụ: ${errorData['example'] ?? ''}'
          );
        }
        
        if (response.data['success'] == true && response.data['data'] != null) {
          final returnUrl = response.data['data']['returnUrl'];
          if (returnUrl != null && !returnUrl.contains('localhost') && !returnUrl.contains('127.0.0.1')) {
            print('✅ VNPay Service: Lấy Return URL từ backend: $returnUrl');
            return returnUrl;
          } else {
            throw Exception('Backend trả về Return URL là localhost. Vui lòng cấu hình VNP_RETURN_URL trong file .env của backend với public URL và restart backend server.');
          }
        }
      } on DioException catch (e) {
        if (e.response != null && e.response!.statusCode == 400) {
          final errorData = e.response!.data;
          throw Exception(
            '${errorData['message'] ?? 'Lỗi cấu hình VNPay'}\n\n'
            '${errorData['hint'] ?? ''}\n\n'
            'Ví dụ: ${errorData['example'] ?? ''}'
          );
        }
        print('⚠️ VNPay Service: Không thể lấy Return URL từ backend: ${e.message}');
        rethrow;
      } catch (e) {
        print('⚠️ VNPay Service: Error lấy Return URL từ backend: $e');
        rethrow;
      }
      
      // Fallback: Dùng backend base URL (phải là public URL)
      final baseUrl = AppConstants.baseUrl;
      final returnUrl = '$baseUrl/api/payment/vnpay-return';
      
      // Kiểm tra nếu là localhost
      if (returnUrl.contains('localhost') || returnUrl.contains('127.0.0.1')) {
        throw Exception(
          'Backend URL đang là localhost.\n\n'
          'Vui lòng:\n'
          '1. Cấu hình VNP_RETURN_URL trong file .env của backend với public URL\n'
          '2. Hoặc cập nhật AppConstants.baseUrl trong Flutter với public URL\n'
          '3. Restart backend server sau khi cập nhật .env'
        );
      }
      
      return returnUrl;
    } catch (e) {
      print('❌ VNPay Service: Error lấy Return URL: $e');
      rethrow;
    }
  }
  
  /// Lưu thông tin payment vào backend (để backend xử lý IPN và tạo booking)
  Future<void> _savePaymentInfo(
    int bookingId,
    String orderId,
    double amount,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final token = await _authService.getToken();
      await _dio.post(
        '/api/v2/vnpay/save-payment-info',
        data: {
          'bookingId': bookingId,
          'orderId': orderId,
          'amount': amount,
          'bookingData': bookingData,
        },
        options: token != null ? Options(
          headers: {'Authorization': 'Bearer $token'},
        ) : null,
      );
      print('✅ VNPay Service: Đã lưu payment info vào backend');
    } catch (e) {
      print('⚠️ VNPay Service: Không thể lưu payment info: $e');
      // Không throw, chỉ log warning
    }
  }

  /// Lấy danh sách ngân hàng hỗ trợ VNPay
  /// 
  /// Returns: List các ngân hàng với code và name
  Future<List<VNPayBank>> getBankList() async {
    try {
      // Không cần token cho endpoint public này
      final response = await Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
      )).get(PaymentConfig.vnpayGetBanksEndpoint);

      if (response.data['success'] == true) {
        final List<dynamic> banks = response.data['data'];
        return banks.map((bank) => VNPayBank.fromJson(bank)).toList();
      } else {
        throw Exception('Không thể lấy danh sách ngân hàng');
      }
    } on DioException catch (e) {
      print('❌ DioError getting VNPay bank list: ${e.message}');
      // Return default banks nếu API fail
      return _getDefaultBanks();
    } catch (e) {
      print('❌ Error getting VNPay bank list: $e');
      return _getDefaultBanks();
    }
  }

  /// Query trạng thái giao dịch VNPay
  /// 
  /// Parameters:
  /// - [orderId]: Mã đơn hàng từ VNPay
  /// - [transDate]: Ngày giao dịch (format: yyyyMMddHHmmss)
  /// 
  /// Returns: Map chứa thông tin giao dịch
  Future<Map<String, dynamic>> queryTransaction({
    required String orderId,
    required String transDate,
  }) async {
    try {
      final response = await _dio.post(
        PaymentConfig.vnpayQueryTransactionEndpoint,
        data: {
          'orderId': orderId,
          'transDate': transDate,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Không thể truy vấn giao dịch');
      }
    } on DioException catch (e) {
      print('❌ DioError querying VNPay transaction: ${e.message}');
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối server');
      }
      throw Exception('Không thể kết nối đến server');
    } catch (e) {
      print('❌ Error querying VNPay transaction: $e');
      rethrow;
    }
  }

  /// Danh sách ngân hàng mặc định (fallback)
  List<VNPayBank> _getDefaultBanks() {
    return [
      VNPayBank(code: 'VNPAYQR', name: 'Cổng thanh toán VNPAYQR'),
      VNPayBank(code: 'VNBANK', name: 'Thanh toán qua ứng dụng hỗ trợ VNPAYQR'),
      VNPayBank(code: 'INTCARD', name: 'Thanh toán qua thẻ quốc tế'),
      VNPayBank(code: 'VIETCOMBANK', name: 'Vietcombank'),
      VNPayBank(code: 'VIETINBANK', name: 'VietinBank'),
      VNPayBank(code: 'BIDV', name: 'BIDV'),
      VNPayBank(code: 'AGRIBANK', name: 'Agribank'),
      VNPayBank(code: 'TECHCOMBANK', name: 'Techcombank'),
      VNPayBank(code: 'ACB', name: 'ACB'),
      VNPayBank(code: 'VPBANK', name: 'VPBank'),
      VNPayBank(code: 'MBBANK', name: 'MB Bank'),
      VNPayBank(code: 'SACOMBANK', name: 'Sacombank'),
    ];
  }

  /// Get signature service (để verify response)
  VNPaySignatureService get signatureService => _signatureService;
}
