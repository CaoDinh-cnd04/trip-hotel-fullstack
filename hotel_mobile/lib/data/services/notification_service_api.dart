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

  /// Lấy danh sách thông báo của người dùng với phân trang
  /// 
  /// [page] - Trang cần lấy (mặc định: 1)
  /// [limit] - Số lượng thông báo mỗi trang (mặc định: 20)
  /// [unreadOnly] - Chỉ lấy thông báo chưa đọc nếu true
  /// 
  /// Trả về Map chứa:
  /// - 'notifications': Danh sách NotificationModel
  /// - 'pagination': Thông tin phân trang
  /// - 'requiresAuth': true nếu cần đăng nhập
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final token = _authService.authToken;
      
      // Nếu không có token, dùng endpoint public (chỉ lấy thông báo chung)
      final endpoint = token != null 
          ? '/api/notifications'           // Personal notifications (requires auth)
          : '/api/notifications/public';   // Public notifications only
      
      print('📞 Calling GET $endpoint with page=$page, limit=$limit, unreadOnly=$unreadOnly');
      print('🔑 Token: ${token != null ? 'Available' : 'Not available - using public endpoint'}');
      
      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (token != null) 'unreadOnly': unreadOnly, // Only for authenticated users
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
              if (json is Map<String, dynamic>) {
                // Sử dụng fromJson với safe parsing
                // Sử dụng fromJsonCustom để xử lý cả field tiếng Việt và tiếng Anh
                return NotificationModel.fromJsonCustom(json);
              } else {
                print('⚠️ Notification item is not a Map: ${json.runtimeType}');
                return null;
              }
            } catch (e, stackTrace) {
              print('❌ Error parsing notification: $e');
              print('❌ Stack trace: $stackTrace');
              print('❌ JSON: $json');
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
        'requiresAuth': token == null, // Flag to show login prompt if needed
      };
    } on DioException catch (e) {
      print('❌ Get notifications error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      
      // Nếu 401 (Unauthorized), return empty list với flag requiresAuth
      if (e.response?.statusCode == 401) {
        print('⚠️ Unauthorized - returning empty list for guest user');
        return {
          'notifications': <NotificationModel>[],
          'pagination': {
            'page': page,
            'limit': limit,
            'total': 0,
            'totalPages': 0,
          },
          'requiresAuth': true,
        };
      }
      
      throw Exception('Không thể tải thông báo: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Lấy số lượng thông báo chưa đọc của người dùng
  /// 
  /// Trả về số lượng thông báo chưa đọc (0 nếu có lỗi hoặc chưa đăng nhập)
  Future<int> getUnreadCount() async {
    try {
      final token = _authService.authToken;
      
      // Unread count chỉ có cho authenticated users
      if (token == null) {
        print('ℹ️ No token - returning 0 unread count for guest user');
        return 0;
      }
      
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
      
      // Return 0 for guest users (401 error)
      if (e.response?.statusCode == 401) {
        print('ℹ️ Unauthorized - returning 0 for guest user');
      }
      
      return 0;
    } catch (e) {
      print('❌ Unexpected error getting unread count: $e');
      return 0;
    }
  }

  /// Đánh dấu một thông báo là đã đọc
  /// 
  /// [notificationId] - ID của thông báo cần đánh dấu
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.post('/api/notifications/$notificationId/read');
    } on DioException catch (e) {
      print('❌ Mark as read error: ${e.message}');
    }
  }

  /// Đánh dấu tất cả thông báo trong danh sách là đã đọc
  /// 
  /// [notificationIds] - Danh sách ID của các thông báo cần đánh dấu
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

