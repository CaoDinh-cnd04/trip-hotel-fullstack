/**
 * MoMo Service - Xử lý thanh toán MoMo trong Flutter
 * 
 * Chức năng:
 * - Tạo payment request từ backend
 * - Mở trình duyệt/WebView để thanh toán
 * - Xử lý kết quả thanh toán
 * - Query trạng thái giao dịch
 */

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/config/payment_config.dart';
import '../../core/services/backend_auth_service.dart';

/// Service xử lý MoMo
class MoMoService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();

  MoMoService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
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
          print('✅ MoMo: Added token to header');
        } else {
          print('ℹ️ MoMo: Proceeding without authentication token');
        }
        return handler.next(options);
      },
    ));
  }

  /// Tạo payment URL từ MoMo (giống VNPay)
  /// 
  /// Parameters:
  /// - [bookingId]: ID của booking cần thanh toán
  /// - [amount]: Số tiền (VND)
  /// - [orderInfo]: Mô tả đơn hàng
  /// - [bookingData]: Thông tin booking để tạo sau khi thanh toán (optional)
  /// 
  /// Returns: Map với paymentUrl, qrCodeUrl, deeplink
  Future<Map<String, dynamic>> createPaymentUrl({
    required int bookingId,
    required double amount,
    required String orderInfo,
    Map<String, dynamic>? bookingData,
  }) async {
    try {
      print('📤 MoMo Service: Gửi request đến ${PaymentConfig.momoCreatePaymentUrlEndpoint}');
      print('📋 MoMo Service: bookingId=$bookingId, amount=${amount.toInt()}');
      print('📋 MoMo Environment: ${PaymentConfig.useMomoSandbox ? "Sandbox" : "Production"}');
      
      final response = await _dio.post(
        PaymentConfig.momoCreatePaymentUrlEndpoint,
        data: {
          'bookingId': bookingId,
          'amount': amount.toInt(), // MoMo yêu cầu số nguyên
          'orderInfo': orderInfo,
          if (bookingData != null) 'bookingData': bookingData,
        },
      );

      print('📥 MoMo Service: Nhận response - status=${response.statusCode}');
      print('📥 MoMo Service: response.data=${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data == null) {
          throw Exception('Server trả về data rỗng');
        }
        if (data['paymentUrl'] == null || data['paymentUrl'].toString().isEmpty) {
          throw Exception('Server trả về payment URL rỗng');
        }
        print('✅ MoMo Service: Payment data nhận được thành công');
        return data as Map<String, dynamic>;
      } else {
        // Lấy error message từ server, ưu tiên message chi tiết
        String errorMsg = response.data['message'] ?? 'Không thể tạo payment URL';
        
        // Nếu có error code, thêm vào message
        if (response.data['error'] != null) {
          final errorCode = response.data['error'];
          if (errorCode == 'INVALID_RETURN_URL') {
            errorMsg = 'MoMo không chấp nhận localhost làm Return URL. Vui lòng set MOMO_RETURN_URL trong file .env với URL công khai.';
          }
        }
        
        print('❌ MoMo Service: Server trả về lỗi: $errorMsg');
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      print('❌ MoMo Service: DioError - ${e.type}');
      print('❌ MoMo Service: Message: ${e.message}');
      print('❌ MoMo Service: Response: ${e.response?.data}');
      print('❌ MoMo Service: Status: ${e.response?.statusCode}');
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối quá thời gian. Vui lòng kiểm tra kết nối mạng và thử lại.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      } else if (e.response != null) {
        final errorMsg = e.response?.data['message'] ?? 
                        e.response?.data['error'] ?? 
                        'Lỗi từ server (${e.response?.statusCode})';
        throw Exception(errorMsg);
      }
      throw Exception('Không thể kết nối đến server. Vui lòng thử lại.');
    } catch (e) {
      print('❌ MoMo Service: Error không xác định: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Tạo payment request đến MoMo (legacy)
  /// 
  /// Parameters:
  /// - [bookingId]: ID của booking cần thanh toán
  /// - [amount]: Số tiền (VND)
  /// - [orderInfo]: Mô tả đơn hàng
  /// - [extraData]: Dữ liệu bổ sung (optional, base64 encoded)
  /// - [bookingData]: Thông tin booking để tạo sau khi thanh toán (optional)
  /// 
  /// Returns: Object chứa payUrl, deeplink, qrCodeUrl
  Future<Map<String, dynamic>> createPayment({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? extraData,
    Map<String, dynamic>? bookingData,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/momo/create-payment', // Legacy endpoint
        data: {
          'bookingId': bookingId,
          'amount': amount.toInt(), // MoMo yêu cầu số nguyên
          'orderInfo': orderInfo,
          if (extraData != null) 'extraData': extraData,
          if (bookingData != null) 'bookingData': bookingData,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Không thể tạo payment request');
      }
    } on DioException catch (e) {
      print('❌ DioError creating MoMo payment: ${e.message}');
      if (e.response != null) {
        print('❌ Response data: ${e.response?.data}');
        throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối server');
      }
      throw Exception('Không thể kết nối đến server');
    } catch (e) {
      print('❌ Error creating MoMo payment: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Query trạng thái giao dịch MoMo
  /// 
  /// Parameters:
  /// - [orderId]: Mã đơn hàng từ MoMo
  /// - [requestId]: Request ID từ MoMo
  /// 
  /// Returns: Map chứa thông tin giao dịch
  Future<Map<String, dynamic>> queryTransaction({
    required String orderId,
    required String requestId,
  }) async {
    try {
      final response = await _dio.post(
        PaymentConfig.momoQueryTransactionEndpoint,
        data: {
          'orderId': orderId,
          'requestId': requestId,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Không thể truy vấn giao dịch');
      }
    } on DioException catch (e) {
      print('❌ DioError querying MoMo transaction: ${e.message}');
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối server');
      }
      throw Exception('Không thể kết nối đến server');
    } catch (e) {
      print('❌ Error querying MoMo transaction: $e');
      rethrow;
    }
  }
}

