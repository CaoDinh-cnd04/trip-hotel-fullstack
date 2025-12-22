import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../models/notification_model.dart' as NotificationModelVN;
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';
import 'email_notification_service.dart';

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
        onRequest: (options, handler) async {
          // Get token from BackendAuthService automatically (async)
          final token = await _backendAuthService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('✅ NotificationService: Added token to header');
          } else {
            print('⚠️ NotificationService: No token available');
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

      print('📞 Calling GET ${AppConstants.notificationsEndpoint} with params: $queryParams');
      final response = await _dio.get(
        AppConstants.notificationsEndpoint,
        queryParameters: queryParams,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data type: ${response.data.runtimeType}');
      print('📥 Full response data: ${response.data}');
      
      // Backend trả về: { success: true, data: [...], pagination: {...} }
      // Hoặc có thể trả về trực tiếp array
      List<dynamic> dataList = [];
      if (response.data['data'] != null) {
        if (response.data['data'] is List) {
          dataList = response.data['data'] as List;
        } else {
          print('⚠️ Response data is not a List: ${response.data['data'].runtimeType}');
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      } else {
        print('⚠️ Response does not contain data field and is not a List');
      }
      
      print('📦 Found ${dataList.length} notifications in response');
      if (dataList.isNotEmpty) {
        print('📦 First notification sample keys: ${(dataList[0] as Map).keys.toList()}');
        print('📦 First notification sample: ${dataList[0]}');
        print('📦 First notification visible: ${(dataList[0] as Map)['visible'] ?? (dataList[0] as Map)['hien_thi'] ?? (dataList[0] as Map)['is_visible']}');
      } else {
        print('⚠️ No notifications in response data');
      }

      // Helper functions
      String mapType(String? type) {
        if (type == null) return 'promotion';
        switch (type.toLowerCase()) {
          case 'ưu đãi':
          case 'promotion':
            return 'promotion';
          case 'phòng mới':
          case 'new_room':
            return 'new_room';
          case 'chương trình app':
          case 'app_program':
            return 'app_program';
          case 'đặt phòng thành công':
          case 'booking_success':
            return 'booking_success';
          case 'general':
          case 'system':
          default:
            return 'promotion'; // Default to promotion for general/system types
        }
      }
      
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        try {
          if (value is String) {
            return DateTime.parse(value);
          } else if (value is DateTime) {
            return value;
          }
        } catch (e) {
          print('⚠️ Error parsing date: $value');
        }
        return null;
      }
      
      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        return null;
      }
      
      bool parseBool(dynamic value) {
        if (value == null) return false;
        if (value is bool) return value;
        if (value is int) return value == 1 || value != 0; // SQL Server BIT: 1 = true, 0 = false
        if (value is String) {
          final lower = value.toLowerCase().trim();
          return lower == 'true' || lower == '1' || lower == 'yes';
        }
        // SQL Server có thể trả về object với property value
        if (value is Map && value.containsKey('value')) {
          return parseBool(value['value']);
        }
        return false;
      }

      // Parse notifications từ dataList trực tiếp
      final notifications = <NotificationModel>[];
      for (var item in dataList) {
        try {
          if (item is Map<String, dynamic>) {
            final itemId = parseInt(item['id'] ?? item['ma_thong_bao']);
            final itemTitle = item['tieu_de'] ?? item['title'] ?? '';
            print('📋 Parsing notification: $itemId - $itemTitle');
            print('📋 Notification fields: ${item.keys.toList()}');
            
            // Kiểm tra visible field - chỉ parse notification nếu visible = true
            // Backend có thể trả về: visible, hien_thi, hoặc is_visible
            // SQL Server BIT có thể trả về dạng object hoặc int
            final visibleValue = item['visible'] ?? item['hien_thi'] ?? item['is_visible'];
            final isVisible = parseBool(visibleValue ?? true); // Default true nếu không có field
            print('📋 Notification visible field: $visibleValue (type: ${visibleValue.runtimeType}) -> parsed: $isVisible');
            
            if (!isVisible) {
              print('⚠️ Skipping notification ${itemId} - not visible (visible=$visibleValue, parsed=$isVisible)');
              continue;
            }
            
            print('✅ Notification ${itemId} is visible, proceeding to parse...');
            
            // Kiểm tra expiration date
            final expiresAt = parseDate(item['ngay_het_han'] ?? item['expires_at']);
            if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
              print('⚠️ Skipping notification ${itemId} - expired (expires_at=$expiresAt)');
              continue;
            }
            
            // Helper để safe toString
            String? safeToString(dynamic value) {
              if (value == null) return null;
              return value.toString();
            }
            
            // Tạo NotificationModel từ field tiếng Việt hoặc tiếng Anh
            final notification = NotificationModel(
              id: itemId ?? 0,
              title: itemTitle.toString(),
              content: (item['noi_dung'] ?? item['content'] ?? '').toString(),
              type: mapType(item['loai_thong_bao'] ?? item['type']),
              imageUrl: safeToString(item['url_hinh_anh'] ?? item['image_url']),
              actionUrl: safeToString(item['url_hanh_dong'] ?? item['action_url']),
              actionText: safeToString(item['van_ban_nut'] ?? item['action_text']),
              isRead: parseBool(item['da_doc'] ?? item['is_read']),
              createdAt: parseDate(item['ngay_tao'] ?? item['created_at']) ?? DateTime.now(),
              expiresAt: expiresAt,
              senderName: safeToString(item['nguoi_tao'] ?? item['sender_name']),
              senderType: safeToString(item['loai_nguoi_gui'] ?? item['sender_type']),
              hotelId: parseInt(item['khach_san_id'] ?? item['hotel_id']),
            );
            
            notifications.add(notification);
            print('✅ Parsed notification: ${notification.id} - ${notification.title} (type: ${notification.type})');
          } else {
            print('⚠️ Item is not a Map: ${item.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('❌ Error parsing notification: $e');
          print('❌ Stack trace: $stackTrace');
          print('❌ Item data: $item');
        }
      }
      
      print('✅ Successfully parsed ${notifications.length} out of ${dataList.length} notifications');
      
      return ApiResponse<List<NotificationModel>>(
        success: response.data['success'] ?? true,
        message: response.data['message'] ?? 'Success',
        data: notifications,
      );
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

      final notificationResponse = ApiResponse<NotificationModel>.fromJson(
        response.data,
        (data) => NotificationModel.fromJson(data),
      );

      // Nếu tạo thông báo thành công và sendEmail = true, gửi email hàng loạt
      if (notificationResponse.success && sendEmail) {
        try {
          await _sendBulkEmailNotification(
            title: title,
            content: content,
            type: type,
            imageUrl: imageUrl,
            actionUrl: actionUrl,
            hotelId: hotelId,
          );
        } catch (e) {
          print('⚠️ Error sending bulk email notification: $e');
          // Không throw error vì thông báo đã được tạo thành công
        }
      }

      return notificationResponse;
    } catch (e) {
      print('❌ Error creating notification: $e');
      throw _handleError(e);
    }
  }

  /// Gửi email thông báo hàng loạt đến tất cả người dùng
  Future<void> _sendBulkEmailNotification({
    required String title,
    required String content,
    required String type,
    String? imageUrl,
    String? actionUrl,
    int? hotelId,
  }) async {
    try {
      // Import EmailNotificationService
      final emailService = EmailNotificationService();
      emailService.initialize();

      // Xác định template type và data dựa trên notification type
      String templateType = 'general_notification';
      Map<String, dynamic> emailData = {
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'action_url': actionUrl,
      };

      if (type == 'new_room' || type == 'promotion') {
        templateType = 'new_promotion';
        emailData['promotion_title'] = title;
        emailData['promotion_description'] = content;
        emailData['promotion_image_url'] = imageUrl;
        emailData['promotion_id'] = hotelId; // Có thể là promotion ID
      }

      // Gửi email hàng loạt
      final emailResult = await emailService.sendBulkNotificationEmail(
        subject: title,
        templateType: templateType,
        data: emailData,
      );

      if (emailResult['success'] == true) {
        print('✅ Đã gửi email thông báo đến ${emailResult['sent_count']} người dùng');
      } else {
        print('⚠️ Gửi email thất bại: ${emailResult['message']}');
      }
    } catch (e) {
      print('❌ Lỗi gửi email hàng loạt: $e');
      // Không throw để không ảnh hưởng đến việc tạo thông báo
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
