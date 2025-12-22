import 'package:flutter/material.dart';
import '../models/service_review.dart';
import '../models/api_response.dart';
import 'service_review_service.dart';

/// Service cung cấp dữ liệu cho các dịch vụ/tiện ích từ SQL Server
/// 
/// Bao gồm:
/// - Hình ảnh dịch vụ (từ database)
/// - Đánh giá dịch vụ (từ database)
/// - Thông tin chi tiết dịch vụ
class ServiceDataService {
  static final ServiceDataService _instance = ServiceDataService._internal();
  factory ServiceDataService() => _instance;
  ServiceDataService._internal();

  final ServiceReviewService _reviewService = ServiceReviewService();

  /// Lấy hình ảnh dịch vụ từ database
  /// 
  /// [serviceName] - Tên dịch vụ: "Spa", "Hồ bơi", "Nhà hàng", "WiFi miễn phí", "Bãi đỗ xe", "Gần trung tâm"
  /// [hotelId] - ID khách sạn (optional)
  /// 
  /// Returns: Future<List<String>> - Danh sách URL hình ảnh từ database
  Future<List<String>> getServiceImages(String serviceName, {int? hotelId}) async {
    try {
      _reviewService.initialize();
      final response = await _reviewService.getServiceImages(
        serviceName: serviceName,
        hotelId: hotelId,
      );
      
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
      
      // Fallback: trả về danh sách rỗng nếu không có dữ liệu
      return [];
    } catch (e) {
      print('⚠️ Error getting service images from API: $e');
      return [];
    }
  }

  /// Lấy hình ảnh mẫu (fallback khi không có dữ liệu từ database)
  List<String> _getDefaultServiceImages(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'spa':
        return [
          'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800',
          'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800',
          'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=800',
        ];
      case 'hồ bơi':
      case 'pool':
        return [
          'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800',
          'https://images.unsplash.com/photo-1583212292454-1fe6229603b7?w=800',
          'https://images.unsplash.com/photo-1551524164-6cf77f5e1f64?w=800',
        ];
      case 'nhà hàng':
      case 'restaurant':
        return [
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
        ];
      case 'wifi miễn phí':
      case 'wifi':
        return [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
          'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800',
        ];
      case 'bãi đỗ xe':
      case 'parking':
        return [
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        ];
      case 'gần trung tâm':
      case 'city center':
        return [
          'https://images.unsplash.com/photo-1449824913935-9a10a0e1a47b?w=800',
          'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800',
        ];
      default:
        return [
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        ];
    }
  }

  /// Lấy đánh giá dịch vụ từ database
  /// 
  /// [serviceName] - Tên dịch vụ
  /// [hotelId] - ID khách sạn (optional)
  /// [page] - Trang hiện tại (default: 1)
  /// [limit] - Số lượng items/trang (default: 20)
  /// 
  /// Returns: Future<ApiResponse<List<ServiceReview>>>
  Future<ApiResponse<List<ServiceReview>>> getServiceReviews({
    required String serviceName,
    int? hotelId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _reviewService.initialize();
      return await _reviewService.getServiceReviews(
        serviceName: serviceName,
        hotelId: hotelId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      print('⚠️ Error getting service reviews from API: $e');
      return ApiResponse<List<ServiceReview>>(
        success: false,
        message: 'Không thể tải đánh giá',
        data: [],
      );
    }
  }

  /// Lấy đánh giá mẫu (fallback - deprecated, chỉ dùng khi không có API)
  @Deprecated('Use getServiceReviews() instead')
  List<ServiceReview> getMockServiceReviews(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'spa':
        return [
          ServiceReview(
            id: 1,
            serviceName: serviceName,
            userName: 'Nguyễn Thị Lan',
            userAvatar: 'https://i.pravatar.cc/150?img=1',
            rating: 5.0,
            comment: 'Spa tuyệt vời! Không gian rất thư giãn, nhân viên chuyên nghiệp. Massage rất tốt, tôi cảm thấy hoàn toàn thư giãn sau buổi trị liệu.',
            reviewDate: DateTime.now().subtract(const Duration(days: 2)),
            images: [
              'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400',
            ],
          ),
          ServiceReview(
            id: 2,
            serviceName: serviceName,
            userName: 'Trần Văn Minh',
            userAvatar: 'https://i.pravatar.cc/150?img=2',
            rating: 4.5,
            comment: 'Dịch vụ spa chất lượng cao. Giá cả hợp lý, không gian đẹp. Chỉ có điều hơi đông vào cuối tuần.',
            reviewDate: DateTime.now().subtract(const Duration(days: 5)),
          ),
          ServiceReview(
            id: 3,
            serviceName: serviceName,
            userName: 'Lê Thị Hoa',
            userAvatar: 'https://i.pravatar.cc/150?img=3',
            rating: 5.0,
            comment: 'Tuyệt vời! Đã thử nhiều dịch vụ spa nhưng đây là nơi tốt nhất. Nhân viên rất tận tâm và chuyên nghiệp.',
            reviewDate: DateTime.now().subtract(const Duration(days: 10)),
          ),
          ServiceReview(
            id: 4,
            serviceName: serviceName,
            userName: 'Phạm Đức Anh',
            userAvatar: 'https://i.pravatar.cc/150?img=4',
            rating: 4.0,
            comment: 'Spa đẹp, không gian thoáng mát. Dịch vụ massage tốt nhưng giá hơi cao một chút.',
            reviewDate: DateTime.now().subtract(const Duration(days: 15)),
          ),
        ];

      case 'hồ bơi':
      case 'pool':
        return [
          ServiceReview(
            id: 5,
            serviceName: serviceName,
            userName: 'Hoàng Thị Mai',
            userAvatar: 'https://i.pravatar.cc/150?img=5',
            rating: 5.0,
            comment: 'Hồ bơi rất đẹp và sạch sẽ! Nước trong xanh, có khu vực cho trẻ em. Nhân viên thường xuyên vệ sinh. Rất thích!',
            reviewDate: DateTime.now().subtract(const Duration(days: 1)),
            images: [
              'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400',
            ],
          ),
          ServiceReview(
            id: 6,
            serviceName: serviceName,
            userName: 'Vũ Văn Tuấn',
            userAvatar: 'https://i.pravatar.cc/150?img=6',
            rating: 4.5,
            comment: 'Hồ bơi lớn, có view đẹp. Nước sạch, nhiệt độ vừa phải. Có ghế tắm nắng và ô che nắng. Tuy nhiên hơi đông vào buổi chiều.',
            reviewDate: DateTime.now().subtract(const Duration(days: 3)),
          ),
          ServiceReview(
            id: 7,
            serviceName: serviceName,
            userName: 'Đỗ Thị Linh',
            userAvatar: 'https://i.pravatar.cc/150?img=7',
            rating: 5.0,
            comment: 'Hồ bơi tuyệt vời! Con tôi rất thích. Có khu vực nông cho trẻ em, rất an toàn. Sẽ quay lại!',
            reviewDate: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ];

      case 'nhà hàng':
      case 'restaurant':
        return [
          ServiceReview(
            id: 8,
            serviceName: serviceName,
            userName: 'Bùi Văn Hùng',
            userAvatar: 'https://i.pravatar.cc/150?img=8',
            rating: 4.5,
            comment: 'Nhà hàng đẹp, không gian sang trọng. Đồ ăn ngon, đa dạng. Phục vụ nhanh và chuyên nghiệp. Giá cả hợp lý.',
            reviewDate: DateTime.now().subtract(const Duration(days: 2)),
            images: [
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
            ],
          ),
          ServiceReview(
            id: 9,
            serviceName: serviceName,
            userName: 'Ngô Thị Nga',
            userAvatar: 'https://i.pravatar.cc/150?img=9',
            rating: 5.0,
            comment: 'Buffet sáng rất phong phú! Đồ ăn tươi ngon, nhiều lựa chọn. Nhân viên phục vụ nhiệt tình. Rất hài lòng!',
            reviewDate: DateTime.now().subtract(const Duration(days: 4)),
          ),
          ServiceReview(
            id: 10,
            serviceName: serviceName,
            userName: 'Lý Văn Đức',
            userAvatar: 'https://i.pravatar.cc/150?img=10',
            rating: 4.0,
            comment: 'Nhà hàng ổn, đồ ăn ngon nhưng giá hơi cao. Không gian đẹp, view tốt. Phục vụ chậm một chút vào giờ cao điểm.',
            reviewDate: DateTime.now().subtract(const Duration(days: 8)),
          ),
        ];

      case 'wifi miễn phí':
      case 'wifi':
        return [
          ServiceReview(
            id: 11,
            serviceName: serviceName,
            userName: 'Đặng Thị Hương',
            userAvatar: 'https://i.pravatar.cc/150?img=11',
            rating: 4.5,
            comment: 'WiFi nhanh và ổn định! Tín hiệu tốt ở mọi nơi trong khách sạn. Rất tiện cho công việc.',
            reviewDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
          ServiceReview(
            id: 12,
            serviceName: serviceName,
            userName: 'Phan Văn Long',
            userAvatar: 'https://i.pravatar.cc/150?img=12',
            rating: 5.0,
            comment: 'WiFi miễn phí và tốc độ cao! Không bị gián đoạn, phù hợp cho streaming và làm việc online.',
            reviewDate: DateTime.now().subtract(const Duration(days: 6)),
          ),
        ];

      case 'bãi đỗ xe':
      case 'parking':
        return [
          ServiceReview(
            id: 13,
            serviceName: serviceName,
            userName: 'Võ Văn Sơn',
            userAvatar: 'https://i.pravatar.cc/150?img=13',
            rating: 4.0,
            comment: 'Bãi đỗ xe rộng rãi, có bảo vệ 24/7. An toàn và tiện lợi. Có thể đỗ xe miễn phí cho khách lưu trú.',
            reviewDate: DateTime.now().subtract(const Duration(days: 3)),
          ),
          ServiceReview(
            id: 14,
            serviceName: serviceName,
            userName: 'Trương Thị Loan',
            userAvatar: 'https://i.pravatar.cc/150?img=14',
            rating: 4.5,
            comment: 'Bãi đỗ xe tiện lợi, gần lối vào. Có camera an ninh, yên tâm để xe. Nhân viên hỗ trợ nhiệt tình.',
            reviewDate: DateTime.now().subtract(const Duration(days: 9)),
          ),
        ];

      case 'gần trung tâm':
      case 'city center':
        return [
          ServiceReview(
            id: 15,
            serviceName: serviceName,
            userName: 'Hồ Văn Nam',
            userAvatar: 'https://i.pravatar.cc/150?img=15',
            rating: 5.0,
            comment: 'Vị trí tuyệt vời! Chỉ cách trung tâm 5 phút đi bộ. Gần nhiều điểm tham quan, nhà hàng, mua sắm. Rất tiện lợi!',
            reviewDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ServiceReview(
            id: 16,
            serviceName: serviceName,
            userName: 'Lưu Thị Phương',
            userAvatar: 'https://i.pravatar.cc/150?img=16',
            rating: 4.5,
            comment: 'Vị trí đẹp, gần trung tâm nhưng vẫn yên tĩnh. Dễ dàng di chuyển đến các địa điểm du lịch. Rất hài lòng!',
            reviewDate: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];

      default:
        return [];
    }
  }

  /// Tính điểm đánh giá trung bình từ database
  /// 
  /// [serviceName] - Tên dịch vụ
  /// [hotelId] - ID khách sạn (optional)
  /// 
  /// Returns: Future<Map<String, dynamic>> với averageRating và reviewCount
  Future<Map<String, dynamic>> getServiceRating({
    required String serviceName,
    int? hotelId,
  }) async {
    try {
      _reviewService.initialize();
      final response = await _reviewService.getServiceRating(
        serviceName: serviceName,
        hotelId: hotelId,
      );
      
      if (response.success && response.data != null) {
        return response.data!;
      }
      
      return {'averageRating': 0.0, 'reviewCount': 0};
    } catch (e) {
      print('⚠️ Error getting service rating from API: $e');
      return {'averageRating': 0.0, 'reviewCount': 0};
    }
  }

  /// Tạo đánh giá mới cho dịch vụ
  /// 
  /// [serviceName] - Tên dịch vụ
  /// [hotelId] - ID khách sạn
  /// [rating] - Điểm đánh giá (1-5)
  /// [comment] - Nội dung đánh giá
  /// [images] - Danh sách URL hình ảnh (optional)
  /// 
  /// Returns: Future<ApiResponse<ServiceReview>>
  Future<ApiResponse<ServiceReview>> createServiceReview({
    required String serviceName,
    required int hotelId,
    required double rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      _reviewService.initialize();
      return await _reviewService.createServiceReview(
        serviceName: serviceName,
        hotelId: hotelId,
        rating: rating,
        comment: comment,
        images: images,
      );
    } catch (e) {
      print('⚠️ Error creating service review: $e');
      return ApiResponse<ServiceReview>(
        success: false,
        message: 'Không thể tạo đánh giá',
      );
    }
  }
}

