// Notification API Service
import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'backend_auth_service.dart';
import '../../core/constants/app_constants.dart';

class NotificationServiceApi {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();

  NotificationServiceApi() : _dio = Dio() {
    _dio.options.baseUrl = AppConstants.baseUrl; // Use AppConstants instead of hardcode
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print('📱 NotificationServiceApi: $object'),
    ));
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _authService.authToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Get user notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      print('📞 Calling GET /api/notifications with page=$page, limit=$limit, unreadOnly=$unreadOnly');
      
      final response = await _dio.get(
        '/api/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
          'unreadOnly': unreadOnly,
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      // Handle different response formats
      List<dynamic> dataList = [];
      if (response.data['data'] != null) {
        dataList = response.data['data'] as List;
      } else if (response.data is List) {
        dataList = response.data as List;
      } else if (response.data['notifications'] != null) {
        dataList = response.data['notifications'] as List;
      }

      print('📦 Found ${dataList.length} notifications');

      final notifications = dataList
          .map((json) {
            try {
              return NotificationModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ Error parsing notification: $e\nJSON: $json');
              return null;
            }
          })
          .whereType<NotificationModel>()
          .toList();

      print('✅ Successfully parsed ${notifications.length} notifications');

      return {
        'notifications': notifications,
        'pagination': response.data['pagination'] ?? {
          'page': page,
          'limit': limit,
          'total': notifications.length,
          'totalPages': 1,
        },
      };
    } on DioException catch (e) {
      print('❌ Get notifications error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      throw Exception('Không thể tải thông báo: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      print('📞 Calling GET /api/notifications/unread-count');
      final response = await _dio.get('/api/notifications/unread-count');
      
      print('📥 Unread count response: ${response.data}');
      
      // Handle different response formats
      int count = 0;
      if (response.data['data'] != null && response.data['data']['unread_count'] != null) {
        count = response.data['data']['unread_count'] as int;
      } else if (response.data['unread_count'] != null) {
        count = response.data['unread_count'] as int;
      } else if (response.data['count'] != null) {
        count = response.data['count'] as int;
      }
      
      print('🔔 Unread count: $count');
      return count;
    } on DioException catch (e) {
      print('❌ Get unread count error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      return 0;
    } catch (e) {
      print('❌ Unexpected error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.post('/api/notifications/$notificationId/read');
    } on DioException catch (e) {
      print('❌ Mark as read error: ${e.message}');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead(List<int> notificationIds) async {
    try {
      await Future.wait(
        notificationIds.map((id) => markAsRead(id)),
      );
    } catch (e) {
      print('❌ Mark all as read error: $e');
    }
  }
}

