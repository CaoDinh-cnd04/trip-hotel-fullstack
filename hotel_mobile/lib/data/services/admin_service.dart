import 'package:dio/dio.dart';
import '../models/admin_kpi_model.dart';
import '../models/user_model.dart';
import '../models/application_model.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

/// Service dành cho Admin Dashboard
/// 
/// Chức năng:
/// - Dashboard KPI (thống kê tổng quan)
/// - Quản lý Users (CRUD, phân quyền)
/// - Quản lý Hotel Applications (duyệt/từ chối đăng ký KS)
/// - Quản lý Hotels (CRUD khách sạn)
/// - Quản lý Bookings (xem, hủy bookings của users)
/// - Quản lý System Settings
/// 
/// Requires: Admin role + JWT token
class AdminService {
  // Singleton pattern
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  late Dio _dio;
  static String get baseUrl => AppConstants.baseUrl;
  final BackendAuthService _backendAuthService = BackendAuthService();

  /// Khởi tạo Dio với interceptors
  /// 
  /// Setup:
  /// - LogInterceptor: Debug requests/responses
  /// - AuthInterceptor: Tự động thêm JWT token
  /// - ErrorInterceptor: Handle API errors
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
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

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token to all requests
        final token = _backendAuthService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('Admin API Error: ${error.message}');
        print('Response: ${error.response?.data}');
        handler.next(error);
      },
    ));
  }

  /// Thiết lập JWT token cho các request admin
  /// 
  /// [token] - JWT token từ BackendAuthService
  /// 
  /// Lưu ý: Token cũng được tự động thêm qua interceptor
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Lấy KPI cho Admin Dashboard
  /// 
  /// API: GET /api/v2/admin/dashboard/kpi
  /// 
  /// Returns: AdminKpiModel với thống kê:
  /// - Tổng số users, hotels, bookings
  /// - Doanh thu tháng này, tăng trưởng
  /// - Bookings mới, pending reviews
  Future<AdminKpiModel> getDashboardKpi() async {
    try {
      print('📊 Calling API: ${baseUrl}/api/v2/admin/dashboard/kpi');
      final response = await _dio.get('/api/v2/admin/dashboard/kpi');
      print('✅ Dashboard KPI response: ${response.data}');
      return AdminKpiModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      print('❌ Dashboard KPI error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Lấy danh sách users (có filter + pagination)
  /// 
  /// API: GET /api/v2/admin/users
  /// 
  /// Filters:
  /// - chucVu: Lọc theo role (Admin/Manager/User)
  /// - search: Tìm theo tên hoặc email
  /// 
  /// Returns: List<UserModel>
  Future<List<UserModel>> getUsers({
    String? chucVu,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (chucVu != null && chucVu != 'all') queryParams['chuc_vu'] = chucVu;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      print('🔍 Fetching users with params: $queryParams');
      final response = await _dio.get('/api/v2/admin/users', queryParameters: queryParams);
      
      print('📦 Response data type: ${response.data.runtimeType}');
      print('📦 Response data keys: ${response.data is Map ? response.data.keys : "not a map"}');
      
      final dynamic responseData = response.data;
      final List<dynamic> usersJson;
      
      if (responseData is Map && responseData.containsKey('data')) {
        // Safe cast using List.from() instead of 'as'
        final dataField = responseData['data'];
        if (dataField is List) {
          usersJson = List<dynamic>.from(dataField);
          print('✅ Found ${usersJson.length} users in response.data.data');
        } else {
          print('❌ response.data.data is not a List, it is: ${dataField.runtimeType}');
          return [];
        }
      } else if (responseData is List) {
        usersJson = List<dynamic>.from(responseData);
        print('✅ Found ${usersJson.length} users in response.data directly');
      } else {
        print('❌ Unexpected response structure: $responseData');
        return [];
      }
      
      print('🔄 Parsing ${usersJson.length} users...');
      final users = usersJson.map((json) {
        try {
          return UserModel.fromJson(json);
        } catch (e) {
          print('❌ Error parsing user: $json');
          print('❌ Parse error: $e');
          rethrow;
        }
      }).toList();
      
      print('✅ Successfully parsed ${users.length} users');
      return users;
    } on DioException catch (e) {
      print('❌ DioException in getUsers: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Generic error in getUsers: $e');
      rethrow;
    }
  }
  
  /// Lấy danh sách users với thông tin phân trang (dùng cho infinite scroll)
  /// 
  /// [page] - Trang cần lấy (mặc định: 1)
  /// [limit] - Số lượng users mỗi trang (mặc định: 20)
  /// [chucVu] - Lọc theo vai trò (tùy chọn)
  /// [search] - Tìm kiếm theo tên hoặc email (tùy chọn)
  /// 
  /// Trả về Map chứa:
  /// - 'users': Danh sách UserModel
  /// - 'page', 'totalPages', 'total': Thông tin phân trang
  Future<Map<String, dynamic>> getUsersPaginated({
    int page = 1,
    int limit = 20,
    String? chucVu,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (chucVu != null && chucVu != 'all') queryParams['chuc_vu'] = chucVu;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      print('🔍 Fetching users (paginated) - page $page, limit $limit');
      final response = await _dio.get('/api/v2/admin/users', queryParameters: queryParams);
      
      final dynamic responseData = response.data;
      
      // Parse users list
      final List<dynamic> usersJson;
      if (responseData is Map && responseData.containsKey('data')) {
        final dataField = responseData['data'];
        if (dataField is List) {
          usersJson = List<dynamic>.from(dataField);
        } else {
          usersJson = [];
        }
      } else if (responseData is List) {
        usersJson = List<dynamic>.from(responseData);
      } else {
        usersJson = [];
      }
      
      final users = usersJson.map((json) => UserModel.fromJson(json)).toList();
      
      // Parse pagination info
      final pagination = responseData is Map && responseData.containsKey('pagination')
          ? responseData['pagination']
          : {'page': page, 'limit': limit, 'total': users.length, 'totalPages': 1};
      
      print('✅ Loaded ${users.length} users, page $page/${pagination['totalPages'] ?? pagination['pages'] ?? 1}');
      
      return {
        'users': users,
        'page': pagination['page'] ?? page,
        'totalPages': pagination['totalPages'] ?? pagination['pages'] ?? 1,
        'total': pagination['total'] ?? users.length,
      };
    } on DioException catch (e) {
      print('❌ Error in getUsersPaginated: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Lấy thông tin chi tiết một user theo ID
  /// 
  /// [id] - ID của user cần lấy
  /// 
  /// Trả về UserModel
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _dio.get('/api/v2/admin/users/$id');
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Tạo user mới
  /// 
  /// [userData] - Map chứa thông tin user (tên, email, password, chucVu, v.v.)
  /// 
  /// Trả về UserModel của user đã được tạo
  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    try {
      print('📤 Creating user: $userData');
      final response = await _dio.post('/api/v2/admin/users', data: userData);
      print('✅ User created: ${response.data}');
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      print('❌ Create user error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Cập nhật toàn bộ thông tin user
  /// 
  /// [id] - ID của user cần cập nhật
  /// [userData] - Map chứa thông tin cần cập nhật
  /// 
  /// Trả về UserModel đã được cập nhật
  Future<UserModel> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      print('📤 Updating user $id: $userData');
      final response = await _dio.put('/api/v2/admin/users/$id', data: userData);
      print('✅ User updated: ${response.data}');
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      print('❌ Update user error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Xóa user
  /// 
  /// [id] - ID của user cần xóa
  Future<void> deleteUser(String id) async {
    try {
      print('🗑️ Deleting user: $id');
      await _dio.delete('/api/v2/admin/users/$id');
      print('✅ User deleted successfully');
    } on DioException catch (e) {
      print('❌ Delete user error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Chỉ cập nhật vai trò của user
  /// 
  /// [id] - ID của user
  /// [chucVu] - Vai trò mới (Admin, Manager, User)
  /// 
  /// Trả về UserModel đã được cập nhật
  Future<UserModel> updateUserRole(String id, String chucVu) async {
    try {
      final response = await _dio.put('/api/v2/admin/users/$id', data: {
        'chuc_vu': chucVu,
      });
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Cập nhật trạng thái của user (active/inactive)
  /// 
  /// [id] - ID của user
  /// [trangThai] - Trạng thái mới (1: active, 0: inactive)
  /// 
  /// Trả về UserModel đã được cập nhật
  Future<UserModel> updateUserStatus(String id, int trangThai) async {
    try {
      final response = await _dio.put('/api/v2/admin/users/$id/status', data: {
        'trang_thai': trangThai,
      });
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Application Review APIs
  Future<List<ApplicationModel>> getApplications({
    String? trangThai,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (trangThai != null && trangThai != 'all') {
        queryParams['trang_thai'] = trangThai;
      }

      final response = await _dio.get('/api/v2/admin/applications', queryParameters: queryParams);
      
      final List<dynamic> applicationsJson = response.data['data'] ?? response.data;
      return applicationsJson.map((json) => ApplicationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApplicationModel> getApplicationById(String id) async {
    try {
      final response = await _dio.get('/api/v2/admin/applications/$id');
      return ApplicationModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApplicationModel> approveApplication(String id, {String? ghiChu}) async {
    try {
      final response = await _dio.put('/api/v2/admin/applications/$id/approve', data: {
        'ghi_chu': ghiChu,
      });
      return ApplicationModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApplicationModel> rejectApplication(String id, String lyDoTuChoi) async {
    try {
      final response = await _dio.put('/api/v2/admin/applications/$id/reject', data: {
        'ly_do_tu_choi': lyDoTuChoi,
      });
      return ApplicationModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Hotel Management APIs
  Future<List<Map<String, dynamic>>> getHotels({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get('/api/v2/khachsan', queryParameters: queryParams);
      
      final List<dynamic> hotelsJson = response.data['data'] ?? response.data;
      return hotelsJson.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getHotelById(String id) async {
    try {
      final response = await _dio.get('/api/v2/khachsan/$id');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update hotel
  Future<Map<String, dynamic>> updateHotel(String id, Map<String, dynamic> hotelData) async {
    try {
      print('📤 Updating hotel $id: $hotelData');
      final response = await _dio.put('/api/v2/khachsan/$id', data: hotelData);
      print('✅ Hotel updated: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('❌ Update hotel error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Delete hotel (soft delete)
  Future<void> deleteHotel(String id) async {
    try {
      print('🗑️ Deleting hotel: $id');
      await _dio.delete('/api/v2/khachsan/$id');
      print('✅ Hotel deleted successfully');
    } on DioException catch (e) {
      print('❌ Delete hotel error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  // System Statistics APIs
  Future<Map<String, dynamic>> getSystemStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _dio.get('/api/v2/admin/stats', queryParameters: queryParams);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get roles
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await _dio.get('/api/v2/admin/roles');
      final List<dynamic> rolesJson = response.data['data'] ?? response.data;
      return rolesJson.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error handling
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối timeout. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu timeout. Vui lòng thử lại.';
      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu timeout. Vui lòng thử lại.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Lỗi server';
        return 'Lỗi $statusCode: $message';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      case DioExceptionType.connectionError:
        return 'Lỗi kết nối. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.badCertificate:
        return 'Lỗi chứng chỉ SSL.';
      case DioExceptionType.unknown:
        return 'Lỗi không xác định: ${error.message}';
    }
  }
}
