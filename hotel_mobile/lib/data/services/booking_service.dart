import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/room.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_auth_service.dart';

/// Service quản lý đặt phòng khách sạn
/// 
/// Chức năng:
/// - Tạo booking mới
/// - Lấy danh sách bookings của user
/// - Hủy booking
/// - Xem chi tiết booking
/// - Check phòng available trong khoảng thời gian
/// 
/// Fallback: Trả về mock data nếu backend offline
class BookingService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final BackendAuthService _authService = BackendAuthService();

  /// Tạo booking mới
  /// 
  /// Gọi API: POST /api/user/bookings
  /// 
  /// Requires: JWT token (user phải đăng nhập)
  /// 
  /// Returns: ApiResponse<Map> với booking ID
  Future<ApiResponse<Map<String, dynamic>>> createBooking({
    required String hotelId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int rooms,
    required int adults,
    required int children,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.post(
        '/api/user/bookings',
        data: {
          'hotel_id': hotelId,
          'check_in_date': checkInDate.toIso8601String(),
          'check_out_date': checkOutDate.toIso8601String(),
          'rooms': rooms,
          'adults': adults,
          'children': children,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: 'Đặt phòng thành công',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.createBooking: $e');
      // Return success with mock data when API fails
      return ApiResponse<Map<String, dynamic>>(
        success: true,
        data: {
          'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
          'hotel_id': hotelId,
          'check_in_date': checkInDate.toIso8601String(),
          'check_out_date': checkOutDate.toIso8601String(),
          'rooms': rooms,
          'adults': adults,
          'children': children,
          'status': 'confirmed',
          'created_at': DateTime.now().toIso8601String(),
        },
        message: 'Đặt phòng thành công (Demo mode)',
      );
    }
  }

  /// Lấy danh sách bookings của user hiện tại
  /// 
  /// Gọi API: GET /api/user/bookings
  /// 
  /// Requires: JWT token
  /// 
  /// Returns: List bookings của user
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyBookings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/user/bookings',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
          message: 'Lấy danh sách đặt phòng thành công',
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.getMyBookings: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getBooking(String bookingId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/user/bookings/$bookingId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: 'Lấy thông tin đặt phòng thành công',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải thông tin đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.getBooking: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<void>> cancelBooking(String bookingId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.put(
        '/api/user/bookings/$bookingId/cancel',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Hủy đặt phòng thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi hủy đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.cancelBooking: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<void>> updateBooking({
    required String bookingId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? rooms,
    int? adults,
    int? children,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final data = <String, dynamic>{};
      if (checkInDate != null) data['check_in_date'] = checkInDate.toIso8601String();
      if (checkOutDate != null) data['check_out_date'] = checkOutDate.toIso8601String();
      if (rooms != null) data['rooms'] = rooms;
      if (adults != null) data['adults'] = adults;
      if (children != null) data['children'] = children;

      final response = await _dio.put(
        '/api/user/bookings/$bookingId',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Cập nhật đặt phòng thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi cập nhật đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.updateBooking: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  // Additional methods for hotel manager screens
  Future<ApiResponse<Map<String, dynamic>>> getDashboardKpi() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/v2/hotel-manager/dashboard',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: 'Lấy KPI thành công',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải KPI',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.getDashboardKpi: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getUpcomingBookings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/v2/hotel-manager/hotel/bookings',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
          message: 'Lấy danh sách đặt phòng sắp tới thành công',
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.getUpcomingBookings: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getBookings() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/v2/hotel-manager/hotel/bookings',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
          message: 'Lấy danh sách đặt phòng thành công',
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.getBookings: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<void>> updateBookingStatus(String bookingId, String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.put(
        '/api/hotel-manager/bookings/$bookingId/status',
        data: {'status': status},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Cập nhật trạng thái đặt phòng thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi cập nhật trạng thái',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.updateBookingStatus: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<void>> sendBookingCancellationEmail(String bookingId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.post(
        '/api/hotel-manager/bookings/$bookingId/send-cancellation-email',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Gửi email hủy đặt phòng thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi gửi email',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.sendBookingCancellationEmail: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<List<Room>>> getRooms(int hotelId, {
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    try {
      print('🏨 Đang lấy danh sách phòng cho khách sạn ID: $hotelId');
      
      // Call new availability API with real-time status
      final queryParams = <String, dynamic>{};
      if (checkInDate != null) {
        queryParams['check_in'] = checkInDate.toIso8601String().split('T')[0];
      }
      if (checkOutDate != null) {
        queryParams['check_out'] = checkOutDate.toIso8601String().split('T')[0];
      }
      
      final response = await _dio.get(
        '/api/hotels/$hotelId/room-availability',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        print('✅ Lấy được ${data.length} phòng với trạng thái realtime từ API');
        
        if (response.data['summary'] != null) {
          print('📊 Summary: ${response.data['summary']}');
        }
        
        if (data.isEmpty) {
          print('⚠️ Không có phòng nào cho khách sạn này');
          return ApiResponse<List<Room>>(
            success: true,
            data: [],
            message: 'Khách sạn chưa có phòng nào',
          );
        }
        
        final rooms = data.map((json) {
          print('🔍 Room: ${json['ma_phong']} - ${json['trang_thai_text']}');
          return Room.fromJson(json);
        }).toList();
        
        print('✅ Parse được ${rooms.length} phòng (${rooms.where((r) => r.isAvailable == true).length} còn trống)');
        return ApiResponse<List<Room>>(
          success: true,
          data: rooms,
          message: 'Lấy danh sách phòng thành công',
        );
      } else {
        print('❌ API response không thành công: ${response.data}');
        return ApiResponse<List<Room>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách phòng',
        );
      }
    } catch (e) {
      print('❌ Exception khi lấy phòng: $e');
      if (e is DioException) {
        print('❌ DioException details: ${e.response?.data}');
      }
      
      // KHÔNG TRẢ VỀ FALLBACK - Trả về error thật để debug
      return ApiResponse<List<Room>>(
        success: false,
        data: [],
        message: 'Lỗi kết nối API: $e',
      );
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getPromotions() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.get(
        '/api/hotel-manager/promotions',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
          message: 'Lấy danh sách khuyến mãi thành công',
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách khuyến mãi',
        );
      }
    } catch (e) {
      print('❌ Lỗi BookingService.getPromotions: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  List<Room> _getFallbackRooms(int hotelId) {
    return [
      Room(
        id: 1,
        soPhong: '101',
        loaiPhongId: 1,
        khachSanId: hotelId,
        tinhTrang: true,
        moTa: 'Phòng tiêu chuẩn với đầy đủ tiện nghi hiện đại',
        tenLoaiPhong: 'Standard Room',
        giaPhong: 500000,
        sucChua: 2,
        hinhAnhPhong: ['http://localhost:5000/images/rooms/hanoi_deluxe_1.jpg'],
        tenKhachSan: 'Hotel Name',
        tienNghi: ['WiFi miễn phí', 'Điều hòa', 'TV', 'Tủ lạnh mini'],
        soGiuongDon: 1,
        soGiuongDoi: 0,
      ),
      Room(
        id: 2,
        soPhong: '102',
        loaiPhongId: 2,
        khachSanId: hotelId,
        tinhTrang: true,
        moTa: 'Phòng deluxe với view đẹp và tiện nghi cao cấp',
        tenLoaiPhong: 'Deluxe Room',
        giaPhong: 750000,
        sucChua: 3,
        hinhAnhPhong: ['http://localhost:5000/images/rooms/hanoi_deluxe_2.jpg'],
        tenKhachSan: 'Hotel Name',
        tienNghi: ['WiFi miễn phí', 'Điều hòa', 'TV', 'Tủ lạnh mini', 'Bồn tắm'],
        soGiuongDon: 0,
        soGiuongDoi: 1,
      ),
      Room(
        id: 3,
        soPhong: '201',
        loaiPhongId: 3,
        khachSanId: hotelId,
        tinhTrang: true,
        moTa: 'Suite cao cấp với không gian rộng rãi',
        tenLoaiPhong: 'Executive Suite',
        giaPhong: 1200000,
        sucChua: 4,
        hinhAnhPhong: ['http://localhost:5000/images/rooms/hanoi_deluxe_3.jpg'],
        tenKhachSan: 'Hotel Name',
        tienNghi: ['WiFi miễn phí', 'Điều hòa', 'TV', 'Tủ lạnh mini', 'Bồn tắm', 'Khu vực làm việc'],
        soGiuongDon: 1,
        soGiuongDoi: 1,
      ),
    ];
  }
}