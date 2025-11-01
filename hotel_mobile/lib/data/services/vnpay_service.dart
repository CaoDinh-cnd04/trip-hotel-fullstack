/**
 * VNPay Service - Xử lý thanh toán VNPay trong Flutter
 * 
 * Chức năng:
 * - Tạo payment URL từ backend
 * - Mở trình duyệt/WebView để thanh toán
 * - Xử lý kết quả thanh toán
 * - Query trạng thái giao dịch
 */

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_auth_service.dart';

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
class VNPayService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();

  VNPayService() : _dio = Dio(BaseOptions(
    baseUrl: '${AppConstants.baseUrl}/api/v2',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    // Add interceptor để thêm token vào header (optional - payment không require authentication)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('✅ VNPay: Added token to header');
        } else {
          print('ℹ️ VNPay: Proceeding without authentication token');
        }
        return handler.next(options);
      },
    ));
  }

  /// Tạo URL thanh toán VNPay
  /// 
  /// Parameters:
  /// - [bookingId]: ID của booking cần thanh toán
  /// - [amount]: Số tiền (VND)
  /// - [orderInfo]: Mô tả đơn hàng
  /// - [bankCode]: Mã ngân hàng (optional, nếu muốn chọn ngân hàng cụ thể)
  /// - [bookingData]: Thông tin booking đầy đủ để tạo booking sau payment
  /// 
  /// Returns: Payment URL để mở trong WebView hoặc browser
  Future<String> createPaymentUrl({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? bankCode,
    Map<String, dynamic>? bookingData,
  }) async {
    try {
      final response = await _dio.post(
        '/vnpay/create-payment-url',
        data: {
          'bookingId': bookingId,
          'amount': amount,
          'orderInfo': orderInfo,
          if (bankCode != null) 'bankCode': bankCode,
          if (bookingData != null) 'bookingData': bookingData,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data']['paymentUrl'];
      } else {
        throw Exception(response.data['message'] ?? 'Không thể tạo URL thanh toán');
      }
    } on DioException catch (e) {
      print('❌ DioError creating VNPay payment URL: ${e.message}');
      if (e.response != null) {
        print('❌ Response data: ${e.response?.data}');
        throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối server');
      }
      throw Exception('Không thể kết nối đến server');
    } catch (e) {
      print('❌ Error creating VNPay payment URL: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Lấy danh sách ngân hàng hỗ trợ VNPay
  /// 
  /// Returns: List các ngân hàng với code và name
  Future<List<VNPayBank>> getBankList() async {
    try {
      // Không cần token cho endpoint public này
      final response = await Dio(BaseOptions(
        baseUrl: '${AppConstants.baseUrl}/api/v2',
      )).get('/vnpay/banks');

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
        '/vnpay/query-transaction',
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
}

