import 'package:dio/dio.dart';
import '../models/admin_kpi_model.dart';
import '../models/user_model.dart';
import '../models/application_model.dart';
import '../../core/constants/app_constants.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  late Dio _dio;
  static String get baseUrl => AppConstants.baseUrl;

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
      onError: (error, handler) {
        print('Admin API Error: ${error.message}');
        print('Response: ${error.response?.data}');
        handler.next(error);
      },
    ));
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Dashboard API
  Future<AdminKpiModel> getDashboardKpi() async {
    try {
      final response = await _dio.get('/dashboard/kpi');
      return AdminKpiModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // User Management APIs
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

      final response = await _dio.get('/users', queryParameters: queryParams);
      
      final List<dynamic> usersJson = response.data['data'] ?? response.data;
      return usersJson.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/users', data: userData);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      final response = await _dio.put('/users/$id', data: userData);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> updateUserRole(String id, String chucVu) async {
    try {
      final response = await _dio.put('/users/$id/role', data: {
        'chuc_vu': chucVu,
      });
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> updateUserStatus(String id, String trangThai) async {
    try {
      final response = await _dio.put('/users/$id/status', data: {
        'trang_thai': trangThai,
      });
      return UserModel.fromJson(response.data);
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

      final response = await _dio.get('/applications', queryParameters: queryParams);
      
      final List<dynamic> applicationsJson = response.data['data'] ?? response.data;
      return applicationsJson.map((json) => ApplicationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApplicationModel> getApplicationById(String id) async {
    try {
      final response = await _dio.get('/applications/$id');
      return ApplicationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApplicationModel> approveApplication(String id, {String? ghiChu}) async {
    try {
      final response = await _dio.put('/applications/$id/approve', data: {
        'ghi_chu': ghiChu,
      });
      return ApplicationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApplicationModel> rejectApplication(String id, String lyDoTuChoi) async {
    try {
      final response = await _dio.put('/applications/$id/reject', data: {
        'ly_do_tu_choi': lyDoTuChoi,
      });
      return ApplicationModel.fromJson(response.data);
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

      final response = await _dio.get('/hotels', queryParameters: queryParams);
      
      final List<dynamic> hotelsJson = response.data['data'] ?? response.data;
      return hotelsJson.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getHotelById(String id) async {
    try {
      final response = await _dio.get('/hotels/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteHotel(String id) async {
    try {
      await _dio.delete('/hotels/$id');
    } on DioException catch (e) {
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

      final response = await _dio.get('/statistics', queryParameters: queryParams);
      return response.data;
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
