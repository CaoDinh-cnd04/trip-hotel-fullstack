import 'package:dio/dio.dart';
import '../models/feedback_model.dart';
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  late Dio _dio;
  final BackendAuthService _authService = BackendAuthService();
  
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

  // Set authorization token (kept for backward compatibility)
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Get all feedbacks with filters
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

      final response = await _dio.get('/feedback', queryParameters: queryParams);

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

  // Get feedback by ID
  Future<ApiResponse<FeedbackModel>> getFeedbackById(int id) async {
    try {
      final response = await _dio.get('/feedback/$id');
      return ApiResponse<FeedbackModel>.fromJson(
        response.data,
        (data) => FeedbackModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Create new feedback
  Future<ApiResponse<FeedbackModel>> createFeedback(FeedbackModel feedback) async {
    try {
      print('🔄 FeedbackService: Sending POST to /feedback');
      print('📦 Data: ${feedback.toJson()}');
      
      final response = await _dio.post(
        '/feedback',
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

  // Update feedback
  Future<ApiResponse<FeedbackModel>> updateFeedback(FeedbackModel feedback) async {
    try {
      final response = await _dio.put(
        '/feedback/${feedback.id}',
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

  // Admin response to feedback
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
        '/feedback/$feedbackId/respond',
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

  // Update feedback status
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
        '/feedback/$feedbackId/status',
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

  // Delete feedback
  Future<ApiResponse<String>> deleteFeedback(int id) async {
    try {
      final response = await _dio.delete('/feedback/$id');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get feedback statistics
  Future<ApiResponse<Map<String, dynamic>>> getFeedbackStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _dio.get('/feedback/statistics', queryParameters: queryParams);
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Upload feedback images
  Future<ApiResponse<List<String>>> uploadFeedbackImages(List<String> imagePaths) async {
    try {
      final formData = FormData();
      
      for (int i = 0; i < imagePaths.length; i++) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(imagePaths[i]),
        ));
      }

      final response = await _dio.post('/feedback/upload-images', data: formData);
      
      return ApiResponse<List<String>>.fromJson(
        response.data,
        (data) => (data as List).cast<String>(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get user's feedbacks
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
        '/feedback/user/$userId',
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
