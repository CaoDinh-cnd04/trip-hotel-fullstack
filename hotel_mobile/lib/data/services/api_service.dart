import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/hotel.dart';
import '../models/promotion.dart';
import '../models/room.dart';
import '../models/booking.dart';
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

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (object) {
          print('API Log: $object');
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

  // Test connection method
  Future<bool> testConnection() async {
    try {
      print('Testing connection to: ${AppConstants.baseUrl}');
      final response = await _dio.get('/khachsan?limit=1');
      print('Connection test successful: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      if (e is DioException) {
        print('Error type: ${e.type}');
        print('Error message: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      return false;
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

  // ================== PROMOTION CRUD ==================

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
      throw _handleError(e);
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

  // ================== ROOM CRUD ==================

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

      final response = await _dio.get('/phong', queryParameters: queryParams);

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
      final response = await _dio.get('/phong/$id');
      return ApiResponse<Room>.fromJson(
        response.data,
        (data) => Room.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<Room>>> getRoomsByHotel(int hotelId) async {
    try {
      final response = await _dio.get('/khachsan/$hotelId/phong');
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
      final response = await _dio.post('/phong', data: room.toJson());
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
      final response = await _dio.put('/phong/${room.id}', data: room.toJson());
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
      final response = await _dio.delete('/phong/$id');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ================== BOOKING CRUD ==================

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
        '/phieudatphong',
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
      final response = await _dio.get('/phieudatphong/$id');
      return ApiResponse<Booking>.fromJson(
        response.data,
        (data) => Booking.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Booking>> createBooking(Booking booking) async {
    try {
      final response = await _dio.post(
        '/phieudatphong',
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
        '/phieudatphong/${booking.id}',
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

  Future<ApiResponse<String>> cancelBooking(int id) async {
    try {
      final response = await _dio.put('/phieudatphong/$id/cancel');
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
      final response = await _dio.delete('/phieudatphong/$id');
      return ApiResponse<String>.fromJson(
        response.data,
        (data) => data.toString(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ================== ROOM AVAILABILITY ==================

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
        '/phong/available',
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
}
