import 'package:dio/dio.dart';
import 'dart:io';
import '../models/api_response.dart';
import '../models/hotel_registration.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_auth_service.dart';

/// Service xử lý các chức năng cho chủ khách sạn
/// 
/// Bao gồm:
/// - Đăng ký khách sạn mới
/// - Lấy danh sách khách sạn của chủ sở hữu
/// - Lấy thống kê khách sạn
class HotelOwnerService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final BackendAuthService _authService = BackendAuthService();

  /// Gửi đơn đăng ký khách sạn lên server
  /// 
  /// [registration] - Thông tin đăng ký khách sạn bao gồm hình ảnh
  /// 
  /// Trả về ApiResponse chứa kết quả đăng ký (thành công/thất bại)
  Future<ApiResponse<Map<String, dynamic>>> submitHotelRegistration(
    HotelRegistration registration,
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      // Prepare form data
      final formData = FormData();
      
      // Add text fields
      formData.fields.addAll([
        MapEntry('hotel_name', registration.hotelName),
        MapEntry('address', registration.address),
        MapEntry('province', registration.province),
        MapEntry('district', registration.district),
        MapEntry('phone', registration.phone),
        MapEntry('email', registration.email),
        MapEntry('description', registration.description),
        MapEntry('website', registration.website),
        MapEntry('star_rating', registration.starRating.toString()),
      ]);

      // Add images
      for (int i = 0; i < registration.images.length; i++) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              registration.images[i].path,
              filename: 'hotel_image_$i.jpg',
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/api/hotel-owner/register-hotel',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: response.data['message'] ?? 'Đăng ký khách sạn thành công',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi đăng ký khách sạn',
        );
      }
    } catch (e) {
      print('❌ Lỗi HotelOwnerService.submitHotelRegistration: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Lấy danh sách tất cả khách sạn của chủ sở hữu hiện tại
  /// 
  /// Trả về danh sách khách sạn dưới dạng ApiResponse
  /// Yêu cầu đăng nhập (JWT token)
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyHotels() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/hotel-owner/my-hotels',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
          message: 'Lấy danh sách khách sạn thành công',
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi lấy danh sách khách sạn',
        );
      }
    } catch (e) {
      print('❌ Lỗi HotelOwnerService.getMyHotels: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Lấy thống kê về khách sạn của chủ sở hữu
  /// 
  /// Bao gồm: số lượt đặt, doanh thu, đánh giá, v.v.
  /// Trả về ApiResponse chứa dữ liệu thống kê
  Future<ApiResponse<Map<String, dynamic>>> getHotelStats() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/hotel-owner/stats',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: 'Lấy thống kê thành công',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi lấy thống kê',
        );
      }
    } catch (e) {
      print('❌ Lỗi HotelOwnerService.getHotelStats: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }
}
