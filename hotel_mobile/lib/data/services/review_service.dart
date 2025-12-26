import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/review.dart';
import '../../core/constants/app_constants.dart';
import '../services/backend_auth_service.dart';

/// Service quản lý đánh giá/nhận xét khách sạn
/// 
/// Chức năng:
/// - Lấy danh sách đánh giá của user
/// - Tạo đánh giá mới cho booking
/// - Cập nhật đánh giá đã tạo
/// - Xóa đánh giá
class ReviewService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final BackendAuthService _authService = BackendAuthService();

  /// Lấy danh sách đánh giá của người dùng hiện tại
  /// 
  /// Yêu cầu đăng nhập (JWT token)
  /// 
  /// Trả về ApiResponse chứa danh sách Review
  /// Trả về danh sách rỗng nếu không có đánh giá nào
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

  /// Tạo đánh giá mới cho một booking
  /// 
  /// [bookingId] - ID của booking cần đánh giá (bắt buộc)
  /// [rating] - Điểm đánh giá từ 1-5 (bắt buộc)
  /// [content] - Nội dung đánh giá (bắt buộc)
  /// [serviceRatings] - Đánh giá các dịch vụ (tùy chọn): 
  ///   Format cũ: { "amenity_id": rating }
  ///   Format mới: { "amenity_id": { "rating": 5, "comment": "...", "images": [...] } }
  /// [imageUrls] - Danh sách URL ảnh đã upload (tùy chọn)
  /// 
  /// Yêu cầu đăng nhập (JWT token)
  /// 
  /// Trả về ApiResponse với kết quả tạo đánh giá
  Future<ApiResponse<void>> createReview({
    required String bookingId,
    required int rating,
    required String content,
    Map<String, dynamic>? serviceRatings,
    List<String>? imageUrls,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      // Chuẩn bị dữ liệu
      // Gửi service ratings và images riêng biệt để backend có thể lưu vào 2 bảng
      final requestData = <String, dynamic>{
        'booking_id': bookingId,
        'rating': rating,
        'content': content,
      };

      // Thêm service ratings nếu có (sẽ lưu vào bảng dich_vu_reviews)
      if (serviceRatings != null && serviceRatings.isNotEmpty) {
        requestData['service_ratings'] = serviceRatings;
      }

      // Thêm image URLs nếu có (sẽ lưu vào bảng danh_gia)
      if (imageUrls != null && imageUrls.isNotEmpty) {
        requestData['images'] = imageUrls;
      }

      final response = await _dio.post(
        '/api/user/reviews',
        data: requestData,
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

  /// Cập nhật đánh giá đã tạo
  /// 
  /// [reviewId] - ID của đánh giá cần cập nhật (bắt buộc)
  /// [rating] - Điểm đánh giá mới từ 1-5 (bắt buộc)
  /// [content] - Nội dung đánh giá mới (bắt buộc)
  /// 
  /// Yêu cầu đăng nhập (JWT token)
  /// 
  /// Trả về ApiResponse với kết quả cập nhật
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

  /// Xóa đánh giá
  /// 
  /// [reviewId] - ID của đánh giá cần xóa
  /// 
  /// Yêu cầu đăng nhập (JWT token)
  /// 
  /// Trả về ApiResponse với kết quả xóa
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

  /// Lấy thông tin chi tiết một đánh giá theo ID
  /// 
  /// [reviewId] - ID của đánh giá cần lấy
  /// 
  /// Yêu cầu đăng nhập (JWT token)
  /// 
  /// Trả về ApiResponse chứa Review
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
