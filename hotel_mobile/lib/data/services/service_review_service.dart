import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/service_review.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

/// Service quản lý đánh giá dịch vụ/tiện ích từ SQL Server
/// 
/// Chức năng:
/// - Lấy danh sách đánh giá theo dịch vụ
/// - Tạo đánh giá mới cho dịch vụ
/// - Lấy hình ảnh dịch vụ từ database
/// - Tính điểm đánh giá trung bình
class ServiceReviewService {
  static final ServiceReviewService _instance = ServiceReviewService._internal();
  factory ServiceReviewService() => _instance;
  ServiceReviewService._internal();

  late Dio _dio;
  final BackendAuthService _backendAuthService = BackendAuthService();
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) {
          print('📧 Service Review API: $object');
        },
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _backendAuthService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            print('⚠️ Unauthorized - token may be expired');
          }
          handler.next(error);
        },
      ),
    );
    
    _initialized = true;
  }

  /// Lấy danh sách đánh giá của một dịch vụ
  /// 
  /// API: GET /api/v2/dichvu/{serviceName}/reviews
  /// 
  /// Parameters:
  ///   - serviceName: Tên dịch vụ (ví dụ: "Spa", "Hồ bơi", "Nhà hàng")
  ///   - hotelId: ID khách sạn (optional)
  ///   - page: Trang hiện tại (default: 1)
  ///   - limit: Số lượng items/trang (default: 20)
  /// 
  /// Returns: ApiResponse<List<ServiceReview>>
  Future<ApiResponse<List<ServiceReview>>> getServiceReviews({
    required String serviceName,
    int? hotelId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      initialize();
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (hotelId != null) {
        queryParams['hotel_id'] = hotelId;
      }

      final response = await _dio.get(
        '/api/v2/dichvu/$serviceName/reviews',
        queryParameters: queryParams,
      );

      return ApiResponse<List<ServiceReview>>.fromJson(response.data, (data) {
        if (data != null && data is List) {
          return data.map((item) => ServiceReview.fromJson(item)).toList();
        }
        return <ServiceReview>[];
      });
    } catch (e) {
      print('❌ Error getting service reviews: $e');
      // Return empty list if API fails
      return ApiResponse<List<ServiceReview>>(
        success: false,
        message: 'Không thể tải đánh giá dịch vụ',
        data: [],
      );
    }
  }

  /// Lấy hình ảnh của một dịch vụ
  /// 
  /// API: GET /api/v2/dichvu/{serviceName}/images
  /// 
  /// Parameters:
  ///   - serviceName: Tên dịch vụ
  ///   - hotelId: ID khách sạn (optional)
  /// 
  /// Returns: ApiResponse<List<String>> - Danh sách URL hình ảnh
  Future<ApiResponse<List<String>>> getServiceImages({
    required String serviceName,
    int? hotelId,
  }) async {
    try {
      initialize();
      
      final queryParams = <String, dynamic>{};
      if (hotelId != null) {
        queryParams['hotel_id'] = hotelId;
      }

      final response = await _dio.get(
        '/api/v2/dichvu/$serviceName/images',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return ApiResponse<List<String>>.fromJson(response.data, (data) {
        if (data != null && data is List) {
          return data.map((item) => item.toString()).toList();
        }
        return <String>[];
      });
    } catch (e) {
      print('❌ Error getting service images: $e');
      return ApiResponse<List<String>>(
        success: false,
        message: 'Không thể tải hình ảnh dịch vụ',
        data: [],
      );
    }
  }

  /// Tạo đánh giá mới cho dịch vụ
  /// 
  /// API: POST /api/v2/dichvu/reviews
  /// 
  /// Parameters:
  ///   - serviceName: Tên dịch vụ
  ///   - hotelId: ID khách sạn
  ///   - rating: Điểm đánh giá (1-5)
  ///   - comment: Nội dung đánh giá
  ///   - images: Danh sách URL hình ảnh (optional)
  /// 
  /// Returns: ApiResponse<ServiceReview>
  Future<ApiResponse<ServiceReview>> createServiceReview({
    required String serviceName,
    required int hotelId,
    required double rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      initialize();
      
      final data = {
        'service_name': serviceName,
        'hotel_id': hotelId,
        'rating': rating,
        'comment': comment,
        if (images != null && images.isNotEmpty) 'images': images,
      };

      final response = await _dio.post(
        '/api/v2/dichvu/reviews',
        data: data,
      );

      return ApiResponse<ServiceReview>.fromJson(
        response.data,
        (data) => ServiceReview.fromJson(data),
      );
    } catch (e) {
      print('❌ Error creating service review: $e');
      throw _handleError(e);
    }
  }

  /// Lấy điểm đánh giá trung bình của dịch vụ
  /// 
  /// API: GET /api/v2/dichvu/{serviceName}/rating
  /// 
  /// Returns: ApiResponse<Map<String, dynamic>> với averageRating và reviewCount
  Future<ApiResponse<Map<String, dynamic>>> getServiceRating({
    required String serviceName,
    int? hotelId,
  }) async {
    try {
      initialize();
      
      final queryParams = <String, dynamic>{};
      if (hotelId != null) {
        queryParams['hotel_id'] = hotelId;
      }

      final response = await _dio.get(
        '/api/v2/dichvu/$serviceName/rating',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      print('❌ Error getting service rating: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Không thể tải điểm đánh giá',
        data: {'averageRating': 0.0, 'reviewCount': 0},
      );
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Kết nối timeout, vui lòng thử lại');
        case DioExceptionType.badResponse:
          final message = error.response?.data?['message'] ?? 'Có lỗi xảy ra';
          return Exception(message);
        case DioExceptionType.cancel:
          return Exception('Yêu cầu đã bị hủy');
        case DioExceptionType.unknown:
          return Exception('Không có kết nối internet');
        default:
          return Exception('Có lỗi xảy ra, vui lòng thử lại');
      }
    }
    return Exception('Có lỗi xảy ra: ${error.toString()}');
  }
}

