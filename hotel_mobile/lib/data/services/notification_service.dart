import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (object) {
          print('📱 Notification API: $object');
        },
      ),
    );

    // Add auth interceptor - automatically get token from BackendAuthService
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Get token from BackendAuthService automatically
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

  void setToken(String token) {
    // Deprecated: Token is now automatically retrieved from BackendAuthService
    // Keeping for backward compatibility
    initialize();
  }

  // Get all notifications for user
  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? unreadOnly,
  }) async {
    try {
      initialize();
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (type != null) queryParams['type'] = type;
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly;

      final response = await _dio.get(
        AppConstants.notificationsEndpoint,
        queryParameters: queryParams,
      );

      return ApiResponse<List<NotificationModel>>.fromJson(response.data, (data) {
        if (data != null && data is List) {
          return data.map((item) => NotificationModel.fromJson(item)).toList();
        }
        return <NotificationModel>[];
      });
    } catch (e) {
      print('❌ Error getting notifications: $e');
      // Return mock data if API fails
      return _getMockNotifications(type, unreadOnly);
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      initialize();
      final response = await _dio.get('${AppConstants.notificationsEndpoint}/unread-count');
      
      if (response.statusCode == 200) {
        return response.data['count'] as int? ?? 0;
      }
    } catch (e) {
      print('❌ Error getting unread count: $e');
    }
    
    // Return mock unread count
    return 0; // Return 0 if no real data available
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      initialize();
      final response = await _dio.put('${AppConstants.notificationsEndpoint}/$notificationId/read');
      
      if (response.statusCode == 200) {
        // Update local cache
        await _updateNotificationInCache(notificationId, isRead: true);
        return true;
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
    
    return false;
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('${AppConstants.notificationsEndpoint}/mark-all-read');
      
      if (response.statusCode == 200) {
        // Update local cache
        await _markAllCachedAsRead();
        return true;
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
    
    return false;
  }

  // Create notification (for admin/hotel manager)
  Future<ApiResponse<NotificationModel>> createNotification({
    required String title,
    required String content,
    required String type,
    String? imageUrl,
    String? actionUrl,
    String? actionText,
    DateTime? expiresAt,
    int? hotelId,
    Map<String, dynamic>? metadata,
    bool sendEmail = true, // Default: send email to users
  }) async {
    try {
      // Ensure service is initialized
      initialize();
      
      final data = {
        'title': title,
        'content': content,
        'type': type,
        'image_url': imageUrl,
        'action_url': actionUrl,
        'action_text': actionText,
        'expires_at': expiresAt?.toIso8601String(),
        'hotel_id': hotelId,
        'metadata': metadata,
        'gui_email': sendEmail, // Add email flag
      };

      final response = await _dio.post(AppConstants.notificationsEndpoint, data: data);

      return ApiResponse<NotificationModel>.fromJson(
        response.data,
        (data) => NotificationModel.fromJson(data),
      );
    } catch (e) {
      print('❌ Error creating notification: $e');
      throw _handleError(e);
    }
  }

  // Get notification by ID
  Future<ApiResponse<NotificationModel>> getNotificationById(int id) async {
    try {
      final response = await _dio.get('${AppConstants.notificationsEndpoint}/$id');
      
      return ApiResponse<NotificationModel>.fromJson(
        response.data,
        (data) => NotificationModel.fromJson(data),
      );
    } catch (e) {
      print('❌ Error getting notification by ID: $e');
      throw _handleError(e);
    }
  }

  // Delete notification
  Future<bool> deleteNotification(int id) async {
    try {
      final response = await _dio.delete('${AppConstants.notificationsEndpoint}/$id');
      
      if (response.statusCode == 200) {
        // Remove from local cache
        await _removeNotificationFromCache(id);
        return true;
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
    
    return false;
  }

  // Cache management methods
  Future<void> _cacheNotifications(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationStrings = notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      await prefs.setStringList('cached_notifications', notificationStrings);
      
      // Update unread count
      final unreadCount = notifications.where((n) => !n.isRead).length;
      await prefs.setInt('cached_unread_count', unreadCount);
    } catch (e) {
      print('❌ Error caching notifications: $e');
    }
  }

  Future<ApiResponse<List<NotificationModel>>> _getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationStrings = prefs.getStringList('cached_notifications') ?? [];
      
      final notifications = notificationStrings
          .map((notificationString) => 
              NotificationModel.fromJson(jsonDecode(notificationString)))
          .toList();

      return ApiResponse<List<NotificationModel>>(
        success: true,
        message: 'Cached notifications loaded',
        data: notifications,
      );
    } catch (e) {
      print('❌ Error getting cached notifications: $e');
      return ApiResponse<List<NotificationModel>>(
        success: false,
        message: 'Failed to load cached notifications',
        data: [],
      );
    }
  }

  Future<int> _getCachedUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('cached_unread_count') ?? 0;
    } catch (e) {
      print('❌ Error getting cached unread count: $e');
      return 0;
    }
  }

  Future<void> _updateNotificationInCache(int notificationId, {required bool isRead}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationStrings = prefs.getStringList('cached_notifications') ?? [];
      
      final updatedNotifications = notificationStrings.map((notificationString) {
        final notification = NotificationModel.fromJson(jsonDecode(notificationString));
        if (notification.id == notificationId) {
          return jsonEncode(notification.copyWith(isRead: isRead).toJson());
        }
        return notificationString;
      }).toList();
      
      await prefs.setStringList('cached_notifications', updatedNotifications);
      
      // Update unread count
      final unreadCount = updatedNotifications
          .map((s) => NotificationModel.fromJson(jsonDecode(s)))
          .where((n) => !n.isRead)
          .length;
      await prefs.setInt('cached_unread_count', unreadCount);
    } catch (e) {
      print('❌ Error updating notification in cache: $e');
    }
  }

  Future<void> _markAllCachedAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationStrings = prefs.getStringList('cached_notifications') ?? [];
      
      final updatedNotifications = notificationStrings.map((notificationString) {
        final notification = NotificationModel.fromJson(jsonDecode(notificationString));
        return jsonEncode(notification.copyWith(isRead: true).toJson());
      }).toList();
      
      await prefs.setStringList('cached_notifications', updatedNotifications);
      await prefs.setInt('cached_unread_count', 0);
    } catch (e) {
      print('❌ Error marking all cached as read: $e');
    }
  }

  Future<void> _removeNotificationFromCache(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationStrings = prefs.getStringList('cached_notifications') ?? [];
      
      final updatedNotifications = notificationStrings.where((notificationString) {
        final notification = NotificationModel.fromJson(jsonDecode(notificationString));
        return notification.id != id;
      }).toList();
      
      await prefs.setStringList('cached_notifications', updatedNotifications);
      
      // Update unread count
      final unreadCount = updatedNotifications
          .map((s) => NotificationModel.fromJson(jsonDecode(s)))
          .where((n) => !n.isRead)
          .length;
      await prefs.setInt('cached_unread_count', unreadCount);
    } catch (e) {
      print('❌ Error removing notification from cache: $e');
    }
  }

  // Mock data methods
  ApiResponse<List<NotificationModel>> _getMockNotifications(String? type, bool? unreadOnly) {
    var notifications = <NotificationModel>[]; // Return empty list if no real data available
    
    // Filter by type
    if (type != null) {
      notifications = notifications.where((n) => n.type == type).toList();
    }
    
    // Filter by read status
    if (unreadOnly == true) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }
    
    return ApiResponse<List<NotificationModel>>(
      success: true,
      message: 'Mock notifications loaded',
      data: notifications,
    );
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
