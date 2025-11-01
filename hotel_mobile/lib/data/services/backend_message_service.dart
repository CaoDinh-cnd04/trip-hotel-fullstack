import 'package:dio/dio.dart';
import '../models/message.dart';
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';

class BackendMessageService {
  static final BackendMessageService _instance = BackendMessageService._internal();
  factory BackendMessageService() => _instance;
  BackendMessageService._internal();

  late Dio _dio;
  String? _token;

  void initialize() {
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
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (object) {
          print('📨 Backend Message API: $object');
        },
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _token = null;
          }
          handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    _token = token;
  }

  // Get all messages for user
  Future<ApiResponse<List<Message>>> getMessages({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final response = await _dio.get(
        '/api/messages',
        queryParameters: queryParams,
      );

      return ApiResponse<List<Message>>.fromJson(response.data, (data) {
        if (data != null && data is List) {
          return data.map((item) => Message.fromJson(item)).toList();
        }
        return <Message>[];
      });
    } catch (e) {
      print('❌ Error getting messages: $e');
      // Return empty list if API fails
      return ApiResponse<List<Message>>(
        success: false,
        message: 'Không thể tải tin nhắn: ${_getErrorMessage(e)}',
        data: [],
      );
    }
  }

  // Mark message as read
  Future<bool> markAsRead(String messageId) async {
    try {
      final response = await _dio.put('/api/messages/$messageId/read');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error marking message as read: $e');
      return false;
    }
  }

  // Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/api/messages/unread-count');
      
      if (response.statusCode == 200) {
        return response.data['count'] as int? ?? 0;
      }
    } catch (e) {
      print('❌ Error getting unread count: $e');
    }
    
    return 0;
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Kết nối timeout';
        case DioExceptionType.badResponse:
          return error.response?.data?['message'] ?? 'Có lỗi xảy ra';
        case DioExceptionType.cancel:
          return 'Yêu cầu đã bị hủy';
        case DioExceptionType.unknown:
          return 'Không có kết nối internet';
        default:
          return 'Có lỗi xảy ra';
      }
    }
    return error.toString();
  }
}

