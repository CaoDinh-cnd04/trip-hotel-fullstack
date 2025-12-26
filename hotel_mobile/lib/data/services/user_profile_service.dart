import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import '../../core/constants/app_constants.dart';
import '../services/backend_auth_service.dart';

/// Service quản lý profile người dùng
/// 
/// Chức năng:
/// - Lấy thông tin profile
/// - Lấy thông tin VIP status
/// - Cập nhật profile
class UserProfileService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();

  UserProfileService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    // Thêm interceptor để tự động thêm token vào header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Lấy token từ BackendAuthService
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 UserProfileService: Added token to header');
        } else {
          print('⚠️ UserProfileService: No token available - request may fail');
        }
        return handler.next(options);
      },
    ));
  }

  /// Lấy thông tin profile của người dùng hiện tại
  /// 
  /// Yêu cầu đăng nhập (JWT token)
  /// 
  /// Trả về ApiResponse chứa đối tượng User
  Future<ApiResponse<User>> getUserProfile() async {
    try {
      print('🚀 Lấy thông tin user profile...');
      
      final response = await _dio.get(
        '/api/user/profile',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Lấy user profile thành công');
        
        return ApiResponse<User>(
          success: true,
          message: data['message'] ?? 'Lấy thông tin user thành công',
          data: User.fromJson(data['data']),
        );
      } else {
        print('❌ Lỗi lấy user profile: ${response.statusCode}');
        return ApiResponse<User>(
          success: false,
          message: 'Lỗi lấy thông tin user: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception lấy user profile: $e');
      return ApiResponse<User>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Lấy thông tin VIP status của user
  Future<ApiResponse<Map<String, dynamic>>> getVipStatus() async {
    try {
      print('🚀 Lấy thông tin VIP status...');
      
      // Lấy token từ BackendAuthService
      final token = await _authService.getToken();
      
      if (token == null || token.isEmpty) {
        print('❌ Không có token, cần đăng nhập');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Vui lòng đăng nhập để xem thông tin VIP',
        );
      }
      
      print('🔑 Token: ${token.substring(0, 20)}...');
      
      final response = await _dio.get(
        '/api/user/vip-status',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500, // Cho phép 401, 404
        ),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          print('✅ Lấy VIP status thành công: ${data['data']}');
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: data['message'] ?? 'Lấy thông tin VIP thành công',
            data: data['data'],
          );
        } else {
          print('❌ Response không có data: ${data}');
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: data['message'] ?? 'Không thể tải thông tin VIP',
          );
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - Token không hợp lệ hoặc hết hạn');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại',
        );
      } else if (response.statusCode == 404) {
        print('❌ User không tìm thấy');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Không tìm thấy thông tin user',
        );
      } else {
        print('❌ Lỗi lấy VIP status: ${response.statusCode}');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Lỗi lấy thông tin VIP: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ DioException lấy VIP status: ${e.type}');
      print('❌ Error: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối internet hoặc backend server đã chạy chưa.',
        );
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Kết nối timeout. Vui lòng thử lại sau.',
        );
      } else if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMsg = e.response!.data?['message'] ?? 'Lỗi không xác định';
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Lỗi: $errorMsg (${statusCode})',
        );
      }
      
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: ${e.message ?? "Không thể tải thông tin VIP"}',
      );
    } catch (e) {
      print('❌ Exception lấy VIP status: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi không xác định: $e',
      );
    }
  }

  /// Cập nhật thông tin user (alias for updateUserProfile)
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    return updateUserProfile(name: name, phone: phone, address: address);
  }

  /// Cập nhật thông tin user
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    try {
      print('🚀 Cập nhật thông tin user...');
      
      // Kiểm tra token trước khi gửi request
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ Không có token để cập nhật profile');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Vui lòng đăng nhập để cập nhật thông tin',
        );
      }
      
      print('🔑 Token available: ${token.substring(0, 20)}...');
      
      final response = await _dio.put(
        '/api/user/profile',
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Cập nhật profile thành công');
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'] ?? 'Cập nhật thông tin thành công',
          data: data['data'],
        );
      } else {
        print('❌ Lỗi cập nhật profile: ${response.statusCode}');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Lỗi cập nhật thông tin: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception cập nhật profile: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Xóa tài khoản
  Future<ApiResponse<bool>> deleteAccount() async {
    try {
      print('🚀 Xóa tài khoản...');
      
      final response = await _dio.delete(
        '/api/user/account',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Xóa tài khoản thành công');
        
        return ApiResponse<bool>(
          success: true,
          message: data['message'] ?? 'Xóa tài khoản thành công',
          data: true,
        );
      } else {
        print('❌ Lỗi xóa tài khoản: ${response.statusCode}');
        return ApiResponse<bool>(
          success: false,
          message: 'Lỗi xóa tài khoản: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception xóa tài khoản: $e');
      return ApiResponse<bool>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Lấy thông tin cài đặt user
  Future<ApiResponse<Map<String, dynamic>>> getUserSettings() async {
    try {
      print('🚀 Lấy cài đặt user...');
      
      // Lấy token từ BackendAuthService
      final token = await _authService.getToken();
      
      if (token == null || token.isEmpty) {
        print('❌ Không có token để lấy cài đặt');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }
      
      final response = await _dio.get(
        '/api/user/settings',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Lấy cài đặt thành công: ${data['data']}');
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'] ?? 'Lấy cài đặt thành công',
          data: data['data'],
        );
      } else {
        print('❌ Lỗi lấy cài đặt: ${response.statusCode}');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Lỗi lấy cài đặt: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception lấy cài đặt: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Cập nhật cài đặt user
  Future<ApiResponse<Map<String, dynamic>>> updateUserSettings({
    String? language,
    String? currency,
    String? distanceUnit,
    String? priceDisplay,
    bool? notificationsEnabled,
  }) async {
    try {
      print('🚀 Cập nhật cài đặt user...');
      
      // Lấy token từ BackendAuthService
      final token = await _authService.getToken();
      
      if (token == null || token.isEmpty) {
        print('❌ Không có token để cập nhật cài đặt');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }
      
      final response = await _dio.put(
        '/api/user/settings',
        data: {
          if (language != null) 'language': language,
          if (currency != null) 'currency': currency,
          if (distanceUnit != null) 'distance_unit': distanceUnit,
          if (priceDisplay != null) 'price_display': priceDisplay,
          if (notificationsEnabled != null) 'notifications_enabled': notificationsEnabled,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Cập nhật cài đặt thành công');
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'] ?? 'Cập nhật cài đặt thành công',
          data: data['data'],
        );
      } else {
        print('❌ Lỗi cập nhật cài đặt: ${response.statusCode}');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Lỗi cập nhật cài đặt: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception cập nhật cài đặt: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Tích điểm thủ công cho các booking đã thanh toán
  Future<ApiResponse<Map<String, dynamic>>> addPointsForPaidBookings() async {
    try {
      print('🚀 Tích điểm thủ công cho các booking đã thanh toán...');
      
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Vui lòng đăng nhập',
        );
      }
      
      final response = await _dio.post(
        '/api/user/vip-status/add-points-for-bookings',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('✅ Tích điểm thành công: ${data['data']}');
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: data['message'] ?? 'Tích điểm thành công',
            data: data['data'],
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: data['message'] ?? 'Tích điểm thất bại',
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Lỗi: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception tích điểm thủ công: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi: $e',
      );
    }
  }

  /// Cập nhật cài đặt nhận email thông báo
  Future<bool> updateEmailNotificationPreference(bool enabled) async {
    try {
      print('📧 Cập nhật cài đặt email thông báo: $enabled');
      
      final token = await _authService.getToken();
      
      if (token == null || token.isEmpty) {
        print('❌ Không có token, cần đăng nhập');
        return false;
      }
      
      final response = await _dio.put(
        '/api/v2/nguoidung/email-notification-preference',
        data: {'nhan_thong_bao_email': enabled},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Cập nhật cài đặt email thành công');
        return true;
      } else {
        print('❌ Lỗi cập nhật: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception cập nhật email preference: $e');
      return false;
    }
  }
}
