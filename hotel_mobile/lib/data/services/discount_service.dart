import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

/// Service xử lý mã giảm giá
/// 
/// Chức năng:
/// - Validate mã giảm giá
/// - Lấy danh sách mã giảm giá có sẵn
/// - Kiểm tra điều kiện áp dụng (số tiền tối thiểu, khách sạn, địa điểm)
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

  /// Xác thực mã giảm giá
  /// 
  /// [code] - Mã giảm giá cần xác thực (bắt buộc)
  /// [orderAmount] - Tổng số tiền đơn hàng (bắt buộc)
  /// [hotelId] - ID khách sạn (tùy chọn - mã giảm giá có thể áp dụng cho tất cả)
  /// [locationId] - ID địa điểm (tùy chọn - mã giảm giá có thể áp dụng cho tất cả)
  /// 
  /// Trả về Map chứa:
  /// - success: true/false
  /// - message: Thông báo kết quả
  /// - code, discountAmount, discountType, discountValue, description (nếu hợp lệ)
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
      
      final responseData = e.response?.data;
      final errorMessage = responseData?['message'] ?? 'Lỗi không xác định';
      
      if (e.response?.statusCode == 401) {
        // Token không hợp lệ, hết hạn, hoặc chưa đăng nhập
        return {
          'success': false,
          'message': errorMessage.contains('Token') 
              ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại'
              : (errorMessage.contains('đăng nhập') 
                  ? errorMessage 
                  : 'Vui lòng đăng nhập để sử dụng mã giảm giá'),
          'requiresLogin': true,
        };
      } else if (e.response?.statusCode == 400) {
        return {
          'success': false,
          'message': errorMessage,
        };
      } else if (e.response?.statusCode == 500) {
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        return {
          'success': false,
          'message': errorMessage.isNotEmpty 
              ? errorMessage 
              : 'Lỗi kết nối. Vui lòng kiểm tra internet',
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

  /// Lấy danh sách mã giảm giá có sẵn cho người dùng
  /// 
  /// Trả về danh sách các mã giảm giá đang hoạt động
  /// Mỗi item chứa: code, description, discountType, discountValue, conditions, v.v.
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

  /// Tìm mã giảm giá có giá trị cao nhất cho đơn hàng
  /// 
  /// [orderAmount] - Tổng số tiền đơn hàng
  /// [hotelId] - ID khách sạn (tùy chọn)
  /// [locationId] - ID địa điểm (tùy chọn)
  /// 
  /// Trả về Map chứa code và discountAmount của mã có giá trị cao nhất,
  /// hoặc null nếu không có mã nào hợp lệ
  Future<Map<String, dynamic>?> findBestDiscountCode({
    required double orderAmount,
    int? hotelId,
    int? locationId,
  }) async {
    try {
      print('🔍 Finding best discount code for order: $orderAmount');
      
      // Lấy danh sách mã giảm giá có sẵn
      final availableDiscounts = await getAvailableDiscounts();
      
      if (availableDiscounts.isEmpty) {
        print('ℹ️ No available discount codes');
        return null;
      }
      
      print('📋 Found ${availableDiscounts.length} available discount codes');
      
      // Validate từng mã và tính discount amount
      Map<String, dynamic>? bestDiscount;
      double maxDiscountAmount = 0;
      
      for (final discount in availableDiscounts) {
        final code = discount['code'] as String?;
        if (code == null || code.isEmpty) continue;
        
        try {
          // Validate mã giảm giá
          final validationResult = await validateDiscountCode(
            code: code,
            orderAmount: orderAmount,
            hotelId: hotelId,
            locationId: locationId,
          );
          
          if (validationResult['success'] == true) {
            final discountAmount = (validationResult['discountAmount'] ?? 0).toDouble();
            
            print('   ✅ Code $code: ${discountAmount.toStringAsFixed(0)}₫');
            
            // Chọn mã có discount amount cao nhất
            if (discountAmount > maxDiscountAmount) {
              maxDiscountAmount = discountAmount;
              bestDiscount = {
                'code': code,
                'discountAmount': discountAmount,
                'discountType': validationResult['discountType'],
                'discountValue': validationResult['discountValue'],
                'description': validationResult['description'],
              };
            }
          } else {
            print('   ❌ Code $code: ${validationResult['message']}');
          }
        } catch (e) {
          print('   ⚠️ Error validating code $code: $e');
          continue;
        }
      }
      
      if (bestDiscount != null) {
        print('🏆 Best discount code: ${bestDiscount['code']} - ${bestDiscount['discountAmount']}₫');
      } else {
        print('ℹ️ No valid discount code found for this order');
      }
      
      return bestDiscount;
    } catch (e) {
      print('❌ Error finding best discount code: $e');
      return null;
    }
  }
}

