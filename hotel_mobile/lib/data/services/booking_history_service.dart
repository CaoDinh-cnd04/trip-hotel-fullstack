import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_auth_service.dart';

class BookingHistoryService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();

  BookingHistoryService()
      : _dio = Dio(BaseOptions(
          baseUrl: '${AppConstants.baseUrl}/api',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
          },
        )) {
    // Add interceptor to include token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('✅ Booking: Added token to header');
        } else {
          print('⚠️ Booking: No token available');
        }
        return handler.next(options);
      },
    ));
  }

  /// Tạo booking mới
  Future<BookingModel> createBooking(Map<String, dynamic> bookingData) async {
    try {
      print('📝 Creating booking: $bookingData');
      final response = await _dio.post('/bookings', data: bookingData);
      
      if (response.data['success'] == true) {
        return BookingModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Tạo booking thất bại');
      }
    } catch (e) {
      print('❌ Error creating booking: $e');
      rethrow;
    }
  }

  /// Tạo booking thanh toán tiền mặt
  Future<BookingModel> createCashBooking(Map<String, dynamic> bookingData) async {
    try {
      print('💵 Creating cash booking: $bookingData');
      final response = await _dio.post('/bookings/cash', data: bookingData);
      
      if (response.data['success'] == true) {
        return BookingModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Tạo booking tiền mặt thất bại');
      }
    } catch (e) {
      print('❌ Error creating cash booking: $e');
      rethrow;
    }
  }

  /// Lấy danh sách booking history
  Future<List<BookingModel>> getBookingHistory({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('📖 Fetching booking history...');
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get('/bookings', queryParameters: queryParams);
      
      print('📖 Booking history response status: ${response.statusCode}');
      print('📖 Response data: ${response.data}');
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        print('📖 Found ${data.length} bookings');
        
        final bookings = <BookingModel>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final booking = BookingModel.fromJson(data[i]);
            bookings.add(booking);
          } catch (parseError) {
            print('❌ Error parsing booking $i: $parseError');
            print('📋 Booking data: ${data[i]}');
            // Continue with other bookings instead of failing completely
          }
        }
        
        print('✅ Successfully parsed ${bookings.length} bookings');
        return bookings;
      } else {
        final errorMsg = response.data['message'] ?? 'Lấy lịch sử thất bại';
        print('❌ API returned error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Error fetching booking history: $e');
      if (e is DioException) {
        print('📋 DioException details:');
        print('   - Status code: ${e.response?.statusCode}');
        print('   - Response data: ${e.response?.data}');
        print('   - Request path: ${e.requestOptions.path}');
        
        if (e.response?.statusCode == 401) {
          throw Exception('401: Unauthorized - Vui lòng đăng nhập lại');
        } else if (e.response?.statusCode == 404) {
          throw Exception('404: Không tìm thấy dữ liệu');
        } else if (e.response?.statusCode == 500) {
          throw Exception('500: Lỗi server - Vui lòng thử lại sau');
        }
      }
      rethrow;
    }
  }

  /// Lấy chi tiết booking
  Future<BookingModel> getBookingDetail(int bookingId) async {
    try {
      print('📖 Fetching booking detail: $bookingId');
      final response = await _dio.get('/bookings/$bookingId');
      
      if (response.data['success'] == true) {
        return BookingModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Lấy chi tiết thất bại');
      }
    } catch (e) {
      print('❌ Error fetching booking detail: $e');
      rethrow;
    }
  }

  /// Hủy booking (chỉ trong 5 phút)
  Future<Map<String, dynamic>> cancelBooking(int bookingId, {String? reason}) async {
    try {
      print('❌ Cancelling booking: $bookingId');
      final response = await _dio.post(
        '/bookings/$bookingId/cancel',
        data: {'reason': reason ?? 'Người dùng hủy'},
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Hủy booking thất bại');
      }
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response!.data['message'] ?? 'Hủy booking thất bại');
      }
      rethrow;
    }
  }

  /// Lấy thống kê booking
  Future<Map<String, dynamic>> getBookingStats() async {
    try {
      print('📊 Fetching booking stats...');
      final response = await _dio.get('/bookings/stats');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Lấy thống kê thất bại');
      }
    } catch (e) {
      print('❌ Error fetching booking stats: $e');
      rethrow;
    }
  }
}
