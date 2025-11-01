import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/review.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_auth_service.dart';

class ReviewService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final BackendAuthService _authService = BackendAuthService();

  Future<ApiResponse<List<Review>>> getMyReviews() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<List<Review>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/user/reviews',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final reviews = data.map((json) => Review.fromJson(json)).toList();
        
        return ApiResponse<List<Review>>(
          success: true,
          data: reviews,
          message: 'Lấy danh sách nhận xét thành công',
        );
      } else {
        return ApiResponse<List<Review>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải nhận xét',
        );
      }
    } catch (e) {
      print('❌ Lỗi ReviewService.getMyReviews: $e');
      // Nếu lỗi 404 hoặc không có dữ liệu, trả về danh sách rỗng
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return ApiResponse<List<Review>>(
          success: true,
          data: [],
          message: 'Không có nhận xét nào',
        );
      }
      return ApiResponse<List<Review>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<void>> createReview({
    required String bookingId,
    required int rating,
    required String content,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.post(
        '/api/user/reviews',
        data: {
          'booking_id': bookingId,
          'rating': rating,
          'content': content,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<void>(
          success: true,
          message: 'Đã tạo nhận xét thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tạo nhận xét',
        );
      }
    } catch (e) {
      print('❌ Lỗi ReviewService.createReview: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<void>> updateReview({
    required String reviewId,
    required int rating,
    required String content,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.put(
        '/api/user/reviews/$reviewId',
        data: {
          'rating': rating,
          'content': content,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Đã cập nhật nhận xét thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi cập nhật nhận xét',
        );
      }
    } catch (e) {
      print('❌ Lỗi ReviewService.updateReview: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<void>> deleteReview(String reviewId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.delete(
        '/api/user/reviews/$reviewId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Đã xóa nhận xét thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi xóa nhận xét',
        );
      }
    } catch (e) {
      print('❌ Lỗi ReviewService.deleteReview: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<Review>> getReview(String reviewId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<Review>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/user/reviews/$reviewId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final review = Review.fromJson(response.data['data']);
        return ApiResponse<Review>(
          success: true,
          data: review,
          message: 'Lấy thông tin nhận xét thành công',
        );
      } else {
        return ApiResponse<Review>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải thông tin nhận xét',
        );
      }
    } catch (e) {
      print('❌ Lỗi ReviewService.getReview: $e');
      return ApiResponse<Review>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

}
