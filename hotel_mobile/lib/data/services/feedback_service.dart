import 'package:dio/dio.dart';
import '../models/feedback_model.dart';
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

/// Service xử lý phản hồi (feedback) từ người dùng
/// 
/// Chức năng:
/// - Tạo, đọc, cập nhật, xóa phản hồi
/// - Lọc và tìm kiếm phản hồi
/// - Phản hồi của admin cho phản hồi người dùng
/// - Upload hình ảnh kèm phản hồi
/// - Lấy thống kê phản hồi
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  late Dio _dio;
  final BackendAuthService _authService = BackendAuthService();
  
  /// Khởi tạo service với cấu hình Dio
  /// 
  /// Thiết lập interceptors cho logging, authentication và error handling
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // Add auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('✅ Feedback: Added token to header');
        } else {
          print('⚠️ Feedback: No token available');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('Feedback API Error: ${error.message}');
        print('Response: ${error.response?.data}');
        handler.next(error);
      },
    ));
  }

  /// Thiết lập JWT token cho các request
  /// 
  /// [token] - JWT token
  /// 
  /// Lưu ý: Giữ lại để tương thích ngược, nhưng token sẽ được tự động thêm qua interceptor
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Lấy danh sách phản hồi với các bộ lọc
  /// 
  /// [page] - Trang cần lấy (mặc định: 1)
  /// [limit] - Số lượng phản hồi mỗi trang (mặc định: 20)
  /// [status] - Trạng thái phản hồi (pending, resolved, closed, all)
  /// [type] - Loại phản hồi (bug, feature, complaint, all)
  /// [priority] - Độ ưu tiên (1-5)
  /// [userId] - ID người dùng (lọc theo người dùng)
  /// [search] - Từ khóa tìm kiếm
  /// 
  /// Trả về ApiResponse chứa danh sách FeedbackModel
  Future<ApiResponse<List<FeedbackModel>>> getFeedbacks({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    int? priority,
    int? userId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null && status != 'all') queryParams['status'] = status;
      if (type != null && type != 'all') queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority;
      if (userId != null) queryParams['user_id'] = userId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get('/api/v2/feedback', queryParameters: queryParams);

      return ApiResponse<List<FeedbackModel>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => FeedbackModel.fromJson(item)).toList();
        }
        return <FeedbackModel>[];
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy thông tin chi tiết một phản hồi theo ID
  /// 
  /// [id] - ID của phản hồi
  /// 
  /// Trả về ApiResponse chứa FeedbackModel
  Future<ApiResponse<FeedbackModel>> getFeedbackById(int id) async {
    try {
      final response = await _dio.get('/api/v2/feedback/$id');
      return ApiResponse<FeedbackModel>.fromJson(
        response.data,
        (data) => FeedbackModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Tạo phản hồi mới
  /// 
  /// [feedback] - Đối tượng FeedbackModel chứa thông tin phản hồi
  /// 
  /// Trả về ApiResponse chứa FeedbackModel đã được tạo
  Future<ApiResponse<FeedbackModel>> createFeedback(FeedbackModel feedback) async {
    try {
      print('🔄 FeedbackService: Sending POST to /feedback');
      print('📦 Data: ${feedback.toJson()}');
      
      final response = await _dio.post(
        '/api/v2/feedback',
        data: feedback.toJson(),
      );
      
      print('✅ FeedbackService: Response received');
      print('📦 Response data: ${response.data}');
      
      return ApiResponse<FeedbackModel>.fromJson(
        response.data,
        (data) => FeedbackModel.fromJson(data),
      );
    } catch (e) {
      print('❌ FeedbackService: Error occurred');
      print('Error type: ${e.runtimeType}');
      print('Error: $e');
      throw _handleError(e);
    }
  }

  /// Cập nhật thông tin phản hồi
  /// 
  /// [feedback] - Đối tượng FeedbackModel với ID và thông tin cần cập nhật
  /// 
  /// Trả về ApiResponse chứa FeedbackModel đã được cập nhật
  Future<ApiResponse<FeedbackModel>> updateFeedback(FeedbackModel feedback) async {
    try {
      final response = await _dio.put(
        '/api/v2/feedback/${feedback.id}',
        data: feedback.toJson(),
      );
      return ApiResponse<FeedbackModel>.fromJson(
        response.data,
        (data) => FeedbackModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Admin phản hồi lại cho phản hồi của người dùng
  /// 
  /// [feedbackId] - ID của phản hồi cần phản hồi
  /// [response] - Nội dung phản hồi của admin
  /// [status] - Trạng thái mới (pending, resolved, closed)
  /// [priority] - Độ ưu tiên (tùy chọn, 1-5)
  /// 
  /// Trả về ApiResponse chứa FeedbackModel đã được cập nhật
  Future<ApiResponse<FeedbackModel>> respondToFeedback({
    required int feedbackId,
    required String response,
    required String status,
    int? priority,
  }) async {
    try {
      final responseData = <String, dynamic>{
        'admin_response': response,
        'status': status,
        'ngay_phan_hoi': DateTime.now().toIso8601String(),
      };

      if (priority != null) {
        responseData['priority'] = priority;
      }

      final apiResponse = await _dio.put(
        '/api/v2/feedback/$feedbackId/respond',
        data: responseData,
      );

      return ApiResponse<FeedbackModel>.fromJson(
        apiResponse.data,
        (data) => FeedbackModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cập nhật trạng thái của phản hồi
  /// 
  /// [feedbackId] - ID của phản hồi
  /// [status] - Trạng thái mới (pending, resolved, closed)
  /// [note] - Ghi chú về thay đổi trạng thái (tùy chọn)
  /// 
  /// Trả về ApiResponse chứa FeedbackModel đã được cập nhật
  Future<ApiResponse<FeedbackModel>> updateFeedbackStatus({
    required int feedbackId,
    required String status,
    String? note,
  }) async {
    try {
      final responseData = <String, dynamic>{
        'status': status,
        'ngay_cap_nhat': DateTime.now().toIso8601String(),
      };

      if (note != null) {
        responseData['note'] = note;
      }

      final response = await _dio.put(
        '/api/v2/feedback/$feedbackId/status',
        data: responseData,
      );

      return ApiResponse<FeedbackModel>.fromJson(
        response.data,
        (data) => FeedbackModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Xóa phản hồi
  /// 
  /// [id] - ID của phản hồi cần xóa
  /// 
  /// Trả về ApiResponse với thông báo kết quả
  Future<ApiResponse<String>> deleteFeedback(int id) async {
    try {
      final response = await _dio.delete('/api/v2/feedback/$id');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy thống kê về phản hồi
  /// 
  /// [fromDate] - Ngày bắt đầu (tùy chọn)
  /// [toDate] - Ngày kết thúc (tùy chọn)
  /// 
  /// Trả về ApiResponse chứa dữ liệu thống kê (số lượng theo trạng thái, loại, v.v.)
  Future<ApiResponse<Map<String, dynamic>>> getFeedbackStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _dio.get('/api/v2/feedback/statistics', queryParameters: queryParams);
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload hình ảnh kèm phản hồi
  /// 
  /// [imagePaths] - Danh sách đường dẫn file hình ảnh trên thiết bị
  /// 
  /// Trả về ApiResponse chứa danh sách URL của hình ảnh đã upload
  Future<ApiResponse<List<String>>> uploadFeedbackImages(List<String> imagePaths) async {
    try {
      final formData = FormData();
      
      for (int i = 0; i < imagePaths.length; i++) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(imagePaths[i]),
        ));
      }

      final response = await _dio.post('/api/v2/feedback/upload-images', data: formData);
      
      return ApiResponse<List<String>>.fromJson(
        response.data,
        (data) => (data as List).cast<String>(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy danh sách phản hồi của một người dùng cụ thể
  /// 
  /// [userId] - ID của người dùng (bắt buộc)
  /// [page] - Trang cần lấy (mặc định: 1)
  /// [limit] - Số lượng phản hồi mỗi trang (mặc định: 20)
  /// [status] - Lọc theo trạng thái (tùy chọn)
  /// 
  /// Trả về ApiResponse chứa danh sách FeedbackModel
  Future<ApiResponse<List<FeedbackModel>>> getUserFeedbacks({
    required int userId,
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/api/v2/feedback/user/$userId',
        queryParameters: queryParams,
      );

      return ApiResponse<List<FeedbackModel>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => FeedbackModel.fromJson(item)).toList();
        }
        return <FeedbackModel>[];
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Xử lý và chuyển đổi lỗi thành Exception với thông báo tiếng Việt
  /// 
  /// [error] - Lỗi từ DioException hoặc các exception khác
  /// 
  /// Trả về Exception với thông báo lỗi bằng tiếng Việt
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
