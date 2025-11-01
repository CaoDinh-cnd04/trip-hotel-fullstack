import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

class DiscountService {
  static final DiscountService _instance = DiscountService._internal();
  factory DiscountService() => _instance;
  
  final BackendAuthService _authService = BackendAuthService();
  
  late Dio _dio;
  
  DiscountService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    
    // Add auth token interceptor
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

  /// Validate mã giảm giá
  /// 
  /// Parameters:
  /// - code: Mã giảm giá cần validate
  /// - orderAmount: Tổng số tiền đơn hàng
  /// - hotelId: ID khách sạn (không bắt buộc - mã giảm giá áp dụng cho tất cả)
  /// - locationId: ID địa điểm (không bắt buộc - mã giảm giá áp dụng cho tất cả)
  /// 
  /// Returns:
  /// - success: true/false
  /// - message: Thông báo
  /// - data: {code, discountAmount, ...} nếu hợp lệ
  Future<Map<String, dynamic>> validateDiscountCode({
    required String code,
    required double orderAmount,
    int? hotelId,
    int? locationId,
  }) async {
    try {
      print('📝 Validating discount code: $code for order: $orderAmount, hotelId: $hotelId, locationId: $locationId');

      final response = await _dio.post(
        '/api/v2/discount/validate',
        data: {
          'code': code.toUpperCase(),
          'orderAmount': orderAmount,
          if (hotelId != null) 'hotelId': hotelId,
          if (locationId != null) 'locationId': locationId,
        },
      );

      print('✅ Discount validation response: ${response.data}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        return {
          'success': true,
          'message': response.data['message'] ?? 'Mã giảm giá hợp lệ',
          'code': data['code'] ?? code.toUpperCase(),
          'discountAmount': (data['discountAmount'] ?? 0).toDouble(),
          'discountType': data['discountType'] ?? 'percentage',
          'discountValue': (data['discountValue'] ?? 0).toDouble(),
          'description': data['description'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Mã giảm giá không hợp lệ',
        };
      }
    } on DioException catch (e) {
      print('❌ Dio error validating discount: $e');
      print('   Status code: ${e.response?.statusCode}');
      print('   Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Vui lòng đăng nhập để sử dụng mã giảm giá',
          'requiresLogin': true,
        };
      } else if (e.response?.statusCode == 400) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Thông tin không hợp lệ',
        };
      } else if (e.response?.statusCode == 500) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Lỗi server. Vui lòng thử lại sau',
        };
      } else {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Lỗi kết nối. Vui lòng kiểm tra internet',
        };
      }
    } catch (e) {
      print('❌ Error validating discount: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi. Vui lòng thử lại',
      };
    }
  }

  /// Lấy danh sách mã giảm giá có sẵn
  Future<List<Map<String, dynamic>>> getAvailableDiscounts() async {
    try {
      print('📝 Getting available discount codes');

      final response = await _dio.get('/api/v2/discount/available');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting available discounts: $e');
      return [];
    }
  }
}

