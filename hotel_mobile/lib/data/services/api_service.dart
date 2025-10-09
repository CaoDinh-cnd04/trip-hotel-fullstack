import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/hotel.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

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

    // Add cache interceptor
    _dio.interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: MemCacheStore(),
          policy: CachePolicy.request,
          hitCacheOnErrorExcept: [401, 403],
          maxStale: const Duration(days: 7),
          priority: CachePriority.normal,
          cipher: null,
          keyBuilder: CacheOptions.defaultCacheKeyBuilder,
          allowPostMethod: false,
        ),
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
          }
          handler.next(error);
        },
      ),
    );

    // Load saved token
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  bool get isAuthenticated => _token != null;

  // Generic POST method
  Future<ApiResponse> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic GET method
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Authentication APIs
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<String>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        AppConstants.forgotPasswordEndpoint,
        data: {'email': email},
      );
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Hotel APIs
  Future<ApiResponse<List<Hotel>>> getHotels({
    int page = 1,
    int limit = 10,
    String? search,
    int? minPrice,
    int? maxPrice,
    int? soSao,
    String? viTri,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice;
      }
      if (soSao != null) {
        queryParams['soSao'] = soSao;
      }
      if (viTri != null && viTri.isNotEmpty) {
        queryParams['viTri'] = viTri;
      }

      final response = await _dio.get(
        AppConstants.hotelsEndpoint,
        queryParameters: queryParams,
      );

      return ApiResponse<List<Hotel>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Hotel.fromJson(item)).toList();
        }
        return <Hotel>[];
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Hotel>> getHotelById(int id) async {
    try {
      final response = await _dio.get('${AppConstants.hotelsEndpoint}/$id');
      return ApiResponse<Hotel>.fromJson(
        response.data,
        (data) => Hotel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<Hotel>>> searchHotels({
    required String query,
    String? checkIn,
    String? checkOut,
    int? guests,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
      };

      if (checkIn != null) queryParams['checkIn'] = checkIn;
      if (checkOut != null) queryParams['checkOut'] = checkOut;
      if (guests != null) queryParams['guests'] = guests;

      final response = await _dio.get(
        AppConstants.searchHotelsEndpoint,
        queryParameters: queryParams,
      );

      return ApiResponse<List<Hotel>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Hotel.fromJson(item)).toList();
        }
        return <Hotel>[];
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
