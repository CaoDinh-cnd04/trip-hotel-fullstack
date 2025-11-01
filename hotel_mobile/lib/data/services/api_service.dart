import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/hotel.dart';
import '../models/promotion.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../models/discount_voucher.dart';
import '../models/hotel_review.dart';
import '../../core/constants/app_constants.dart';

/// Service quản lý tất cả API calls với Backend
/// 
/// Chức năng:
/// - Cấu hình Dio với interceptors (logging, caching, auth)
/// - CRUD operations cho: Hotels, Rooms, Bookings, Promotions, Discounts
/// - Tự động thêm JWT token vào headers
/// - Handle API errors và convert thành Exception messages
/// - Cache API responses để tăng performance
/// 
/// Interceptors:
/// 1. LogInterceptor: Log request/response để debug
/// 2. CacheInterceptor: Cache responses (7 ngày)
/// 3. AuthInterceptor: Tự động thêm "Authorization: Bearer {token}"
///                      Tự động logout nếu 401 Unauthorized
/// 
/// Lưu ý: Dùng Singleton pattern - chỉ có 1 instance
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _token; // JWT token từ Backend

  /// Khởi tạo Dio client với các interceptors
  /// 
  /// Được gọi trong main() trước khi runApp()
  /// 
  /// Setup:
  /// - Base URL, timeouts
  /// - LogInterceptor: Log API requests/responses
  /// - CacheInterceptor: Cache GET requests (7 ngày)
  /// - AuthInterceptor: Thêm Bearer token, handle 401 errors
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

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (object) {
          // API Log: $object
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

  /// [PRIVATE] Load JWT token từ SharedPreferences khi app start
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  /// Lưu JWT token vào memory và SharedPreferences
  /// 
  /// Token sẽ được tự động thêm vào headers của mọi API call
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  /// Xóa token và user data (khi logout hoặc 401 error)
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  /// Kiểm tra có token không (không kiểm tra validity)
  bool get isAuthenticated => _token != null;

  /// [GENERIC] POST request
  /// 
  /// Parameters:
  ///   - endpoint: API endpoint (ví dụ: "/auth/login")
  ///   - data: Request body (JSON)
  /// 
  /// Returns: ApiResponse<dynamic>
  Future<ApiResponse> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// [GENERIC] GET request
  /// 
  /// Parameters:
  ///   - endpoint: API endpoint
  ///   - queryParameters: Query params (ví dụ: {page: 1, limit: 10})
  /// 
  /// Returns: ApiResponse<dynamic>
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

  /// Đăng nhập với email/password
  /// 
  /// API: POST /auth/login
  /// 
  /// Returns: AuthResponse với user + token
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

  /// Đăng ký tài khoản mới
  /// 
  /// API: POST /auth/register
  /// 
  /// Returns: AuthResponse với user + token
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

  /// Gửi email reset mật khẩu
  /// 
  /// API: POST /auth/forgot-password
  /// 
  /// Returns: ApiResponse với success message
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

  /// Lấy danh sách khách sạn (có phân trang + filters)
  /// 
  /// API: GET /khachsan
  /// 
  /// Filters:
  /// - search: Tìm theo tên
  /// - minPrice/maxPrice: Lọc theo giá
  /// - soSao: Lọc theo số sao (1-5)
  /// - viTri: Lọc theo địa điểm
  /// 
  /// Returns: ApiResponse<List<Hotel>>
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
      print('❌ Error getting hotels: $e');
      // Return empty list if API fails
      return ApiResponse<List<Hotel>>(
        success: false,
        message: 'Không thể tải danh sách khách sạn',
        data: [],
      );
    }
  }

  /// Lấy chi tiết khách sạn theo ID
  /// 
  /// API: GET /khachsan/{id}
  /// 
  /// Parameters:
  ///   - withRooms: Có lấy danh sách phòng không (default: false)
  /// 
  /// Returns: ApiResponse<Hotel>
  Future<ApiResponse<Hotel>> getHotelById(int id, {bool withRooms = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (withRooms) {
        queryParams['with_rooms'] = 'true';
      }
      
      final response = await _dio.get(
        '${AppConstants.hotelsEndpoint}/$id',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return ApiResponse<Hotel>.fromJson(
        response.data,
        (data) => Hotel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy danh sách phòng của khách sạn
  /// 
  /// API: GET /api/khachsan/{id}/phong
  /// 
  /// Parameters:
  ///   - hotelId: ID của khách sạn
  ///   - availableFrom: Ngày bắt đầu (optional)
  ///   - availableTo: Ngày kết thúc (optional)
  /// 
  /// Returns: ApiResponse<List<Room>>
  Future<ApiResponse<List<Room>>> getHotelRooms(
    int hotelId, {
    String? availableFrom,
    String? availableTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (availableFrom != null) {
        queryParams['available_from'] = availableFrom;
      }
      if (availableTo != null) {
        queryParams['available_to'] = availableTo;
      }

      final response = await _dio.get(
        '${AppConstants.hotelsEndpoint}/$hotelId/phong',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return ApiResponse<List<Room>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Room.fromJson(item)).toList();
        }
        return <Room>[];
      });
    } catch (e) {
      print('❌ Error getting hotel rooms: $e');
      return ApiResponse<List<Room>>(
        success: false,
        message: 'Không thể tải danh sách phòng',
        data: [],
      );
    }
  }

  /// Tìm kiếm khách sạn theo query + filters
  /// 
  /// API: GET /khachsan/search
  /// 
  /// Parameters:
  ///   - query: Từ khóa tìm kiếm
  ///   - checkIn/checkOut: Ngày checkin/checkout (ISO8601)
  ///   - guests: Số lượng khách
  /// 
  /// Returns: ApiResponse<List<Hotel>>
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

  /// Test kết nối với Backend API
  /// 
  /// Gọi GET /khachsan?limit=1 để check backend có online không
  /// 
  /// Returns: true nếu kết nối thành công, false nếu lỗi
  Future<bool> testConnection() async {
    try {
      // Testing connection to: ${AppConstants.baseUrl}
      final response = await _dio.get('/api/khachsan?limit=1');
      // Connection test successful: ${response.statusCode}
      return response.statusCode == 200;
    } catch (e) {
      // Connection test failed: $e
      if (e is DioException) {
        // Error type: ${e.type}
        // Error message: ${e.message}
        // Response: ${e.response?.data}
      }
      return false;
    }
  }

  /// [PRIVATE] Xử lý lỗi API và convert thành Exception với message dễ hiểu
  /// 
  /// DioException types:
  /// - connectionTimeout/sendTimeout/receiveTimeout → "Kết nối timeout"
  /// - badResponse → Lấy message từ response body
  /// - cancel → "Yêu cầu đã bị hủy"
  /// - unknown → "Không có kết nối internet"
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

  // ================== PROMOTION CRUD ==================

  /// Lấy danh sách khuyến mãi
  /// 
  /// API: GET /khuyenmai
  /// 
  /// Parameters:
  ///   - page: Trang hiện tại
  ///   - limit: Số lượng items/trang
  ///   - active: Lọc theo trạng thái (true=đang hoạt động)
  /// 
  /// Returns: ApiResponse<List<Promotion>>
  Future<ApiResponse<List<Promotion>>> getPromotions({
    int page = 1,
    int limit = 10,
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (active != null) {
        queryParams['active'] = active;
      }

      final response = await _dio.get(
        AppConstants.promotionsEndpoint,
        queryParameters: queryParams,
      );

      return ApiResponse<List<Promotion>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Promotion.fromJson(item)).toList();
        }
        return <Promotion>[];
      });
    } catch (e) {
      print('❌ Error getting promotions: $e');
      if (e is DioException) {
        print('❌ DioException details: ${e.response?.data}');
        if (e.response?.statusCode == 500) {
          print('🔄 Backend error, using mock data...');
        }
      }
      // Return empty list if API fails
      return ApiResponse<List<Promotion>>(
        success: false,
        message: 'Không thể tải danh sách khuyến mãi',
        data: [],
      );
    }
  }

  Future<ApiResponse<Promotion>> getPromotionById(int id) async {
    try {
      final response = await _dio.get('${AppConstants.promotionsEndpoint}/$id');
      return ApiResponse<Promotion>.fromJson(
        response.data,
        (data) => Promotion.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Promotion>> createPromotion(Promotion promotion) async {
    try {
      final response = await _dio.post(
        AppConstants.promotionsEndpoint,
        data: promotion.toJson(),
      );
      return ApiResponse<Promotion>.fromJson(
        response.data,
        (data) => Promotion.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Promotion>> updatePromotion(Promotion promotion) async {
    try {
      final response = await _dio.put(
        '${AppConstants.promotionsEndpoint}/${promotion.id}',
        data: promotion.toJson(),
      );
      return ApiResponse<Promotion>.fromJson(
        response.data,
        (data) => Promotion.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<String>> deletePromotion(int id) async {
    try {
      final response = await _dio.delete('${AppConstants.promotionsEndpoint}/$id');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ================== DISCOUNT CODES (MAGIAMGIA) ==================

  /// Lấy danh sách mã giảm giá
  /// 
  /// API: GET /magiamgia
  /// 
  /// Returns: ApiResponse<List<DiscountVoucher>>
  Future<ApiResponse<List<DiscountVoucher>>> getDiscountCodes({
    int page = 1,
    int limit = 10,
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (active != null) {
        queryParams['active'] = active;
      }

      final response = await _dio.get(
        '/api/magiamgia',
        queryParameters: queryParams,
      );

      return ApiResponse<List<DiscountVoucher>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => DiscountVoucher.fromJson(item)).toList();
        }
        return <DiscountVoucher>[];
      });
    } catch (e) {
      print('❌ Error getting discount codes: $e');
      if (e is DioException) {
        print('❌ DioException details: ${e.response?.data}');
        if (e.response?.statusCode == 500) {
          print('🔄 Backend error, using mock data...');
        }
      }
      // Return mock data if API fails
      return ApiResponse<List<DiscountVoucher>>(
        success: true,
        message: 'Mock discount codes loaded',
        data: [],
      );
    }
  }

  /// Validate mã giảm giá (check còn hạn không, còn lượt sử dụng không)
  /// 
  /// API: POST /magiamgia/validate
  /// 
  /// Returns: ApiResponse<DiscountVoucher> nếu valid, error nếu invalid
  Future<ApiResponse<DiscountVoucher>> validateDiscountCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/magiamgia/validate',
        data: {'code': code},
      );

      return ApiResponse<DiscountVoucher>.fromJson(
        response.data,
        (data) => DiscountVoucher.fromJson(data),
      );
    } catch (e) {
      print('❌ Error validating discount code: $e');
      if (e is DioException) {
        print('❌ DioException details: ${e.response?.data}');
        if (e.response?.statusCode == 500) {
          print('🔄 Backend error, using mock validation...');
        }
      }
      // Return mock validation result
      return ApiResponse<DiscountVoucher>(
        success: false,
        message: 'Mã giảm giá không hợp lệ hoặc đã hết hạn',
        data: null,
      );
    }
  }

  // ================== ROOM CRUD ==================

  /// Lấy danh sách phòng (có filter theo khách sạn)
  /// 
  /// API: GET /phong
  /// 
  /// Returns: ApiResponse<List<Room>>
  Future<ApiResponse<List<Room>>> getRooms({
    int page = 1,
    int limit = 10,
    int? hotelId,
    bool? available,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (hotelId != null) {
        queryParams['khach_san_id'] = hotelId;
      }
      if (available != null) {
        queryParams['available'] = available;
      }

      final response = await _dio.get('/api/phong', queryParameters: queryParams);

      return ApiResponse<List<Room>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Room.fromJson(item)).toList();
        }
        return <Room>[];
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Room>> getRoomById(int id) async {
    try {
      final response = await _dio.get('/api/phong/$id');
      return ApiResponse<Room>.fromJson(
        response.data,
        (data) => Room.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy tất cả phòng của 1 khách sạn
  /// 
  /// API: GET /khachsan/{hotelId}/phong
  /// 
  /// Returns: ApiResponse<List<Room>>
  Future<ApiResponse<List<Room>>> getRoomsByHotel(int hotelId) async {
    try {
      final response = await _dio.get('/api/khachsan/$hotelId/phong');
      return ApiResponse<List<Room>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Room.fromJson(item)).toList();
        }
        return <Room>[];
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Room>> createRoom(Room room) async {
    try {
      final response = await _dio.post('/api/phong', data: room.toJson());
      return ApiResponse<Room>.fromJson(
        response.data,
        (data) => Room.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Room>> updateRoom(Room room) async {
    try {
      final response = await _dio.put('/api/phong/${room.id}', data: room.toJson());
      return ApiResponse<Room>.fromJson(
        response.data,
        (data) => Room.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<String>> deleteRoom(int id) async {
    try {
      final response = await _dio.delete('/api/phong/$id');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ================== BOOKING CRUD ==================

  /// Lấy danh sách booking (có filter theo user ID và trạng thái)
  /// 
  /// API: GET /phieudatphong
  /// 
  /// Returns: ApiResponse<List<Booking>>
  Future<ApiResponse<List<Booking>>> getBookings({
    int page = 1,
    int limit = 10,
    int? userId,
    BookingStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (userId != null) {
        queryParams['nguoi_dung_id'] = userId;
      }
      if (status != null) {
        queryParams['trang_thai'] = status.toString().split('.').last;
      }

      final response = await _dio.get(
        '/api/phieudatphong',
        queryParameters: queryParams,
      );

      return ApiResponse<List<Booking>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Booking.fromJson(item)).toList();
        }
        return <Booking>[];
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Booking>> getBookingById(int id) async {
    try {
      final response = await _dio.get('/api/phieudatphong/$id');
      return ApiResponse<Booking>.fromJson(
        response.data,
        (data) => Booking.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Tạo booking mới
  /// 
  /// API: POST /phieudatphong
  /// 
  /// Returns: ApiResponse<Booking> với booking ID mới
  Future<ApiResponse<Booking>> createBooking(Booking booking) async {
    try {
      final response = await _dio.post(
        '/api/phieudatphong',
        data: booking.toJson(),
      );
      return ApiResponse<Booking>.fromJson(
        response.data,
        (data) => Booking.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Booking>> updateBooking(Booking booking) async {
    try {
      final response = await _dio.put(
        '/api/phieudatphong/${booking.id}',
        data: booking.toJson(),
      );
      return ApiResponse<Booking>.fromJson(
        response.data,
        (data) => Booking.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Hủy booking (update trạng thái thành "cancelled")
  /// 
  /// API: PUT /phieudatphong/{id}/cancel
  /// 
  /// Returns: ApiResponse<String> với success message
  Future<ApiResponse<String>> cancelBooking(int id) async {
    try {
      final response = await _dio.put('/api/phieudatphong/$id/cancel');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<String>> deleteBooking(int id) async {
    try {
      final response = await _dio.delete('/api/phieudatphong/$id');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ================== ROOM AVAILABILITY ==================

  /// Kiểm tra phòng trống trong khoảng thời gian
  /// 
  /// API: GET /phong/available
  /// 
  /// Parameters:
  ///   - hotelId: ID khách sạn
  ///   - checkIn/checkOut: Ngày checkin/checkout
  ///   - guests: Số lượng khách
  /// 
  /// Returns: ApiResponse<List<Room>> - Danh sách phòng còn trống
  Future<ApiResponse<List<Room>>> checkRoomAvailability({
    required int hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    int guests = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'khach_san_id': hotelId,
        'ngay_nhan_phong': checkIn.toIso8601String(),
        'ngay_tra_phong': checkOut.toIso8601String(),
        'so_luong_khach': guests,
      };

      final response = await _dio.get(
        '/api/phong/available',
        queryParameters: queryParams,
      );

      return ApiResponse<List<Room>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Room.fromJson(item)).toList();
        }
        return <Room>[];
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ================== HOTEL REVIEWS ==================

  /// Lấy danh sách đánh giá của một khách sạn (Public - không cần auth)
  /// 
  /// API: GET /api/khachsan/:id/reviews
  /// 
  /// Parameters:
  ///   - hotelId: ID khách sạn
  /// 
  /// Returns: ApiResponse<List<HotelReview>> - Danh sách đánh giá đã được duyệt
  Future<ApiResponse<List<HotelReview>>> getHotelReviews(int hotelId) async {
    try {
      print('📞 Calling API: ${AppConstants.hotelsEndpoint}/$hotelId/reviews');
      final response = await _dio.get('${AppConstants.hotelsEndpoint}/$hotelId/reviews');
      print('📥 API Response status: ${response.statusCode}');
      print('📥 API Response data: ${response.data}');
      
      // Handle different response formats
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        
        // If response has 'data' field
        if (dataMap.containsKey('data')) {
          return ApiResponse<List<HotelReview>>.fromJson(response.data, (data) {
            if (data is List) {
              return data.map((item) => HotelReview.fromJson(item)).toList();
            }
            return <HotelReview>[];
          });
        } 
        // If response is directly a list (unlikely but handle it)
        else if (dataMap.containsKey('success')) {
          return ApiResponse<List<HotelReview>>.fromJson(response.data, (data) {
            if (data is List) {
              return data.map((item) => HotelReview.fromJson(item)).toList();
            }
            return <HotelReview>[];
          });
        }
      }
      
      // Default parsing
      return ApiResponse<List<HotelReview>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => HotelReview.fromJson(item)).toList();
        }
        return <HotelReview>[];
      });
    } catch (e) {
      print('❌ Error in getHotelReviews: $e');
      throw _handleError(e);
    }
  }
}
