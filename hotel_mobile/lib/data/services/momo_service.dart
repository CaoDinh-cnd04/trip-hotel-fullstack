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
import '../../core/services/backend_auth_service.dart';

/// Service xử lý MoMo
class MoMoService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();

  MoMoService() : _dio = Dio(BaseOptions(
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
          print('✅ MoMo: Added token to header');
        } else {
          print('ℹ️ MoMo: Proceeding without authentication token');
        }
        return handler.next(options);
      },
    ));
  }

  /// Tạo payment request đến MoMo
  /// 
  /// Parameters:
  /// - [bookingId]: ID của booking cần thanh toán
  /// - [amount]: Số tiền (VND)
  /// - [orderInfo]: Mô tả đơn hàng
  /// - [extraData]: Dữ liệu bổ sung (optional, base64 encoded)
  /// 
  /// Returns: Object chứa payUrl, deeplink, qrCodeUrl
  Future<Map<String, dynamic>> createPayment({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? extraData,
  }) async {
    try {
      final response = await _dio.post(
        '/momo/create-payment',
        data: {
          'bookingId': bookingId,
          'amount': amount.toInt(), // MoMo yêu cầu số nguyên
          'orderInfo': orderInfo,
          if (extraData != null) 'extraData': extraData,
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
        '/momo/query-transaction',
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

