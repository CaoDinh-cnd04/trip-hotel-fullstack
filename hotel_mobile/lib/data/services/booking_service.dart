import 'package:dio/dio.dart';
import '../models/phieu_dat_phong_model.dart';
import '../models/kpi_model.dart';
import 'email_notification_service.dart';
import '../../core/constants/app_constants.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  late Dio _dio;
  final EmailNotificationService _emailService = EmailNotificationService();
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
        // API Error: ${error.message}
        // Response: ${error.response?.data}
        handler.next(error);
      },
    ));

    // Initialize email service
    _emailService.initialize();
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _emailService.setAuthToken(token);
  }

  // Dashboard API
  Future<KpiModel> getDashboardKpi() async {
    try {
      final response = await _dio.get('/dashboard/kpi');
      return KpiModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Booking Management APIs
  Future<List<PhieuDatPhongModel>> getBookings({
    String? status,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _dio.get('/bookings', queryParameters: queryParams);
      
      final List<dynamic> bookingsJson = response.data['data'] ?? response.data;
      return bookingsJson.map((json) => PhieuDatPhongModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PhieuDatPhongModel> getBookingById(String id) async {
    try {
      final response = await _dio.get('/bookings/$id');
      return PhieuDatPhongModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PhieuDatPhongModel> updateBookingStatus(String id, String status) async {
    try {
      final response = await _dio.put('/bookings/$id/status', data: {
        'status': status,
      });
      final updatedBooking = PhieuDatPhongModel.fromJson(response.data);
      
      // Gửi email thông báo khi xác nhận đặt phòng
      if (status == 'confirmed') {
        _sendBookingConfirmationEmail(updatedBooking);
      } else if (status == 'cancelled') {
        // Có thể thêm logic gửi email hủy đặt phòng nếu cần
        // Booking cancelled, email notification can be sent if needed
      }
      
      return updatedBooking;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<PhieuDatPhongModel> updateBooking(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/bookings/$id', data: data);
      return PhieuDatPhongModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      await _dio.delete('/bookings/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get upcoming bookings (next 5)
  Future<List<PhieuDatPhongModel>> getUpcomingBookings() async {
    try {
      final response = await _dio.get('/bookings/upcoming');
      final List<dynamic> bookingsJson = response.data['data'] ?? response.data;
      return bookingsJson.map((json) => PhieuDatPhongModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get booking statistics
  Future<Map<String, dynamic>> getBookingStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _dio.get('/bookings/statistics', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Room Management APIs
  Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final response = await _dio.get('/rooms');
      final List<dynamic> roomsJson = response.data['data'] ?? response.data;
      return roomsJson.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getRoomById(String id) async {
    try {
      final response = await _dio.get('/rooms/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateRoom(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/rooms/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Promotions APIs
  Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      final response = await _dio.get('/promotions');
      final List<dynamic> promotionsJson = response.data['data'] ?? response.data;
      return promotionsJson.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/promotions', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updatePromotion(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/promotions/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deletePromotion(String id) async {
    try {
      await _dio.delete('/promotions/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Email notification methods
  Future<void> _sendBookingConfirmationEmail(PhieuDatPhongModel booking) async {
    try {
      final success = await _emailService.sendBookingConfirmationEmail(booking);
      if (success) {
        // ✅ Email xác nhận đặt phòng đã được gửi thành công đến ${booking.email}
      } else {
        // ❌ Gửi email xác nhận đặt phòng thất bại cho ${booking.email}
      }
    } catch (e) {
      // ❌ Lỗi khi gửi email xác nhận đặt phòng: $e
    }
  }

  Future<void> sendBookingCancellationEmail(PhieuDatPhongModel booking, String lyDoHuy) async {
    try {
      final success = await _emailService.sendBookingCancellationEmail(booking, lyDoHuy);
      if (success) {
        // ✅ Email hủy đặt phòng đã được gửi thành công đến ${booking.email}
      } else {
        // ❌ Gửi email hủy đặt phòng thất bại cho ${booking.email}
      }
    } catch (e) {
      // ❌ Lỗi khi gửi email hủy đặt phòng: $e
    }
  }

  Future<void> sendCheckInReminderEmail(PhieuDatPhongModel booking) async {
    try {
      final success = await _emailService.sendCheckInReminderEmail(booking);
      if (success) {
        // ✅ Email nhắc nhở check-in đã được gửi thành công đến ${booking.email}
      } else {
        // ❌ Gửi email nhắc nhở check-in thất bại cho ${booking.email}
      }
    } catch (e) {
      // ❌ Lỗi khi gửi email nhắc nhở check-in: $e
    }
  }

  Future<void> sendReviewRequestEmail(PhieuDatPhongModel booking) async {
    try {
      final success = await _emailService.sendReviewRequestEmail(booking);
      if (success) {
        // ✅ Email yêu cầu đánh giá đã được gửi thành công đến ${booking.email}
      } else {
        // ❌ Gửi email yêu cầu đánh giá thất bại cho ${booking.email}
      }
    } catch (e) {
      // ❌ Lỗi khi gửi email yêu cầu đánh giá: $e
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
