import 'package:dio/dio.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/backend_auth_service.dart';
import 'package:hotel_mobile/core/constants/app_constants.dart';

/// Service để tương tác với API promotion
/// 
/// Chức năng:
/// - Lấy danh sách promotions active
/// - Validate promotion có thể áp dụng cho đơn hàng
/// - Tính toán discount amount từ promotion
class PromotionService {
  final Dio _dio = Dio();
  final BackendAuthService _authService = BackendAuthService();

  /// Lấy danh sách promotions đang active
  /// 
  /// Returns:
  /// - success: true/false
  /// - data: List<Promotion>
  /// - message: string
  Future<Map<String, dynamic>> getActivePromotions() async {
    try {
      final token = await _authService.getToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/api/v2/khuyenmai',
        queryParameters: {'active': 'true'},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final promotions = data.map((json) => Promotion.fromJson(json)).toList();
        
        return {
          'success': true,
          'data': promotions,
          'message': 'Lấy danh sách promotion thành công',
        };
      } else {
        return {
          'success': false,
          'data': [],
          'message': response.data['message'] ?? 'Không thể lấy danh sách promotion',
        };
      }
    } on DioException catch (e) {
      print('❌ DioException in getActivePromotions: ${e.message}');
      return {
        'success': false,
        'data': [],
        'message': e.response?.data['message'] ?? 'Lỗi kết nối server',
      };
    } catch (e) {
      print('❌ Error in getActivePromotions: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  /// Validate promotion có thể áp dụng cho đơn hàng
  /// 
  /// Parameters:
  /// - promotionId: ID của promotion
  /// - orderAmount: Tổng tiền đơn hàng (trước khi giảm giá)
  /// 
  /// Returns:
  /// - success: true/false
  /// - isValid: promotion có hợp lệ không
  /// - discountAmount: số tiền được giảm
  /// - promotion: thông tin promotion
  /// - message: string
  Future<Map<String, dynamic>> validatePromotion({
    required int promotionId,
    required double orderAmount,
  }) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/api/v2/khuyenmai/$promotionId/validate',
        queryParameters: {'tong_tien': orderAmount.toString()},
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final isValid = data['isValid'] == true;
        final discountAmount = (data['discountAmount'] ?? 0).toDouble();
        
        return {
          'success': true,
          'isValid': isValid,
          'discountAmount': discountAmount,
          'promotion': data['promotion'] != null 
              ? Promotion.fromJson(data['promotion']) 
              : null,
          'message': response.data['message'] ?? 'Kiểm tra promotion thành công',
        };
      } else {
        return {
          'success': false,
          'isValid': false,
          'discountAmount': 0.0,
          'promotion': null,
          'message': response.data['message'] ?? 'Không thể kiểm tra promotion',
        };
      }
    } on DioException catch (e) {
      print('❌ DioException in validatePromotion: ${e.message}');
      return {
        'success': false,
        'isValid': false,
        'discountAmount': 0.0,
        'promotion': null,
        'message': e.response?.data['message'] ?? 'Lỗi kết nối server',
      };
    } catch (e) {
      print('❌ Error in validatePromotion: $e');
      return {
        'success': false,
        'isValid': false,
        'discountAmount': 0.0,
        'promotion': null,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  /// Tính discount amount từ promotion (helper method)
  /// 
  /// Parameters:
  /// - promotion: thông tin promotion
  /// - orderAmount: tổng tiền đơn hàng
  /// 
  /// Returns: số tiền được giảm
  double calculateDiscountAmount(Promotion promotion, double orderAmount) {
    // Tính discount theo phần trăm
    double discount = (orderAmount * promotion.phanTramGiam) / 100;
    
    // Áp dụng giảm tối đa (nếu có)
    // Note: Promotion model không có field giamToiDa, 
    // nếu cần thêm field này vào model
    
    return discount;
  }
}

