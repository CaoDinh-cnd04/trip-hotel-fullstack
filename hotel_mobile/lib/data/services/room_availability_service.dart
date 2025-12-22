import 'package:dio/dio.dart';
import '../models/room_availability.dart';
import '../../core/constants/app_constants.dart';

/// Service kiểm tra tình trạng phòng khách sạn
/// 
/// Chức năng:
/// - Kiểm tra phòng có sẵn trong khoảng thời gian
/// - Lấy availability của tất cả loại phòng trong khách sạn
/// - Lấy availability của một loại phòng cụ thể
class RoomAvailabilityService {
  static final RoomAvailabilityService _instance =
      RoomAvailabilityService._internal();
  factory RoomAvailabilityService() => _instance;
  RoomAvailabilityService._internal();

  late Dio _dio;

  /// Khởi tạo service với cấu hình Dio
  /// 
  /// Thiết lập interceptors cho logging
  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (object) {
          print('🏨 Availability API: $object');
        },
      ),
    );
  }

  /// Lấy tình trạng sẵn có của tất cả loại phòng trong khách sạn
  /// 
  /// [hotelId] - ID khách sạn (bắt buộc)
  /// [checkinDate] - Ngày check-in (bắt buộc)
  /// [checkoutDate] - Ngày check-out (bắt buộc)
  /// 
  /// Trả về HotelAvailabilityResponse chứa danh sách phòng và số lượng còn trống
  Future<HotelAvailabilityResponse> getHotelAvailability({
    required String hotelId,
    required DateTime checkinDate,
    required DateTime checkoutDate,
  }) async {
    try {
      print('🔍 Checking availability for hotel: $hotelId');
      print('📅 Checkin: $checkinDate, Checkout: $checkoutDate');

      final response = await _dio.get(
        '/inventory/khachsan/$hotelId/availability',
        queryParameters: {
          'ngay_checkin': checkinDate.toIso8601String(),
          'ngay_checkout': checkoutDate.toIso8601String(),
        },
      );

      print('✅ Availability response: ${response.data}');

      return HotelAvailabilityResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Availability error: ${e.message}');
      print('Response: ${e.response?.data}');
      
      // Return empty response on error
      return HotelAvailabilityResponse(
        success: false,
        message: _getErrorMessage(e),
        rooms: [],
      );
    } catch (e) {
      print('❌ Unexpected error: $e');
      return HotelAvailabilityResponse(
        success: false,
        message: 'Lỗi không xác định: $e',
        rooms: [],
      );
    }
  }

  /// Lấy tình trạng sẵn có của một loại phòng cụ thể
  /// 
  /// [hotelId] - ID khách sạn (bắt buộc)
  /// [roomTypeId] - ID loại phòng (bắt buộc)
  /// [checkinDate] - Ngày check-in (bắt buộc)
  /// [checkoutDate] - Ngày check-out (bắt buộc)
  /// 
  /// Trả về RoomAvailability nếu có dữ liệu, null nếu có lỗi
  Future<RoomAvailability?> getRoomTypeAvailability({
    required String hotelId,
    required String roomTypeId,
    required DateTime checkinDate,
    required DateTime checkoutDate,
  }) async {
    try {
      final response = await _dio.get(
        '/inventory/khachsan/$hotelId/loaiphong/$roomTypeId/availability',
        queryParameters: {
          'ngay_checkin': checkinDate.toIso8601String(),
          'ngay_checkout': checkoutDate.toIso8601String(),
        },
      );

      if (response.data['success']) {
        return RoomAvailability.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Error getting room type availability: $e');
      return null;
    }
  }

  /// Đặt phòng an toàn với xử lý race condition
  /// 
  /// Đảm bảo không có nhiều user đặt cùng một phòng vào cùng lúc
  /// 
  /// [hotelId] - ID khách sạn (bắt buộc)
  /// [roomTypeId] - ID loại phòng (bắt buộc)
  /// [checkinDate] - Ngày check-in (bắt buộc)
  /// [checkoutDate] - Ngày check-out (bắt buộc)
  /// [userId] - ID người dùng (bắt buộc)
  /// [guestCount] - Số lượng khách (bắt buộc)
  /// [totalPrice] - Tổng tiền (bắt buộc)
  /// 
  /// Trả về Map chứa success, message, data
  Future<Map<String, dynamic>> bookRoomSafe({
    required String hotelId,
    required String roomTypeId,
    required DateTime checkinDate,
    required DateTime checkoutDate,
    required String userId,
    required int guestCount,
    required double totalPrice,
  }) async {
    try {
      final response = await _dio.post(
        '/inventory/khachsan/book-room-safe',
        data: {
          'ma_khach_san': hotelId,
          'ma_loai_phong': roomTypeId,
          'ngay_checkin': checkinDate.toIso8601String(),
          'ngay_checkout': checkoutDate.toIso8601String(),
          'ma_nguoi_dung': userId,
          'so_khach': guestCount,
          'tong_tien': totalPrice,
        },
      );

      return {
        'success': response.data['success'] ?? false,
        'message': response.data['message'] ?? '',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Phòng đã hết
        return {
          'success': false,
          'message': e.response?.data['message'] ??
              'Không còn phòng trống trong khoảng thời gian này',
        };
      }
      
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi đặt phòng: $e',
      };
    }
  }

  /// Xử lý và chuyển đổi lỗi DioException thành thông báo tiếng Việt
  /// 
  /// [error] - Lỗi DioException
  /// 
  /// Trả về chuỗi thông báo lỗi bằng tiếng Việt
  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối timeout';
      case DioExceptionType.badResponse:
        return error.response?.data?['message'] ?? 'Có lỗi xảy ra';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy';
      case DioExceptionType.unknown:
        return 'Không có kết nối internet';
      default:
        return 'Có lỗi xảy ra';
    }
  }
}

