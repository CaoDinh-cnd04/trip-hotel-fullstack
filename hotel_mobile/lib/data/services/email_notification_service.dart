import 'package:dio/dio.dart';
import '../models/phieu_dat_phong_model.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

class EmailNotificationService {
  static final EmailNotificationService _instance = EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  late Dio _dio;
  final BackendAuthService _backendAuthService = BackendAuthService();
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
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
      logPrint: (object) {
        print('📧 Email Notification API: $object');
      },
    ));

    // Add auth interceptor - automatically get token from BackendAuthService
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Get token from BackendAuthService automatically
        final token = _backendAuthService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('❌ Email Notification API Error: ${error.message}');
        print('❌ Response: ${error.response?.data}');
        handler.next(error);
      },
    ));
    
    _initialized = true;
  }

  // Set authorization token (deprecated - token is now automatically retrieved)
  void setAuthToken(String token) {
    // Deprecated: Token is now automatically retrieved from BackendAuthService
    initialize();
  }

  // Gửi email thông báo đặt phòng thành công
  Future<bool> sendBookingConfirmationEmail(PhieuDatPhongModel booking) async {
    try {
      final emailData = {
        'to_email': booking.email,
        'to_name': booking.tenKhachHang,
        'template_type': 'booking_confirmation',
        'subject': 'Xác nhận đặt phòng thành công - ${booking.tenPhong}',
        'data': {
          'booking_id': booking.id,
          'ma_phieu': booking.maPhieu,
          'ten_khach_hang': booking.tenKhachHang,
          'so_dien_thoai': booking.soDienThoai,
          'email': booking.email,
          'ten_phong': booking.tenPhong,
          'ma_phong': booking.maPhong,
          'ngay_check_in': booking.ngayCheckIn.toIso8601String(),
          'ngay_check_out': booking.ngayCheckOut.toIso8601String(),
          'so_dem': booking.soDem,
          'gia_phong': booking.giaPhong,
          'tong_tien': booking.tongTien,
          'ghi_chu': booking.ghiChu,
          'ngay_dat': booking.ngayTao.toIso8601String(),
          'formatted_check_in': booking.formattedCheckIn,
          'formatted_check_out': booking.formattedCheckOut,
          'formatted_tong_tien': booking.formattedTongTien,
          'formatted_ngay_dat': '${booking.ngayTao.day.toString().padLeft(2, '0')}/${booking.ngayTao.month.toString().padLeft(2, '0')}/${booking.ngayTao.year}',
        },
      };

      final response = await _dio.post('/email/booking-confirmation', data: emailData);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error sending booking confirmation email: ${_handleDioError(e)}');
      return false;
    }
  }

  // Gửi email thông báo hủy đặt phòng
  Future<bool> sendBookingCancellationEmail(PhieuDatPhongModel booking, String lyDoHuy) async {
    try {
      final emailData = {
        'to_email': booking.email,
        'to_name': booking.tenKhachHang,
        'template_type': 'booking_cancellation',
        'subject': 'Thông báo hủy đặt phòng - ${booking.tenPhong}',
        'data': {
          'booking_id': booking.id,
          'ma_phieu': booking.maPhieu,
          'ten_khach_hang': booking.tenKhachHang,
          'so_dien_thoai': booking.soDienThoai,
          'email': booking.email,
          'ten_phong': booking.tenPhong,
          'ma_phong': booking.maPhong,
          'ngay_check_in': booking.ngayCheckIn.toIso8601String(),
          'ngay_check_out': booking.ngayCheckOut.toIso8601String(),
          'so_dem': booking.soDem,
          'gia_phong': booking.giaPhong,
          'tong_tien': booking.tongTien,
          'ly_do_huy': lyDoHuy,
          'ngay_huy': DateTime.now().toIso8601String(),
          'formatted_check_in': booking.formattedCheckIn,
          'formatted_check_out': booking.formattedCheckOut,
          'formatted_tong_tien': booking.formattedTongTien,
          'formatted_ngay_huy': '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
        },
      };

      final response = await _dio.post('/email/booking-cancellation', data: emailData);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error sending booking cancellation email: ${_handleDioError(e)}');
      return false;
    }
  }

  // Gửi email nhắc nhở check-in
  Future<bool> sendCheckInReminderEmail(PhieuDatPhongModel booking) async {
    try {
      final emailData = {
        'to_email': booking.email,
        'to_name': booking.tenKhachHang,
        'template_type': 'checkin_reminder',
        'subject': 'Nhắc nhở check-in - ${booking.tenPhong}',
        'data': {
          'booking_id': booking.id,
          'ma_phieu': booking.maPhieu,
          'ten_khach_hang': booking.tenKhachHang,
          'so_dien_thoai': booking.soDienThoai,
          'email': booking.email,
          'ten_phong': booking.tenPhong,
          'ma_phong': booking.maPhong,
          'ngay_check_in': booking.ngayCheckIn.toIso8601String(),
          'ngay_check_out': booking.ngayCheckOut.toIso8601String(),
          'so_dem': booking.soDem,
          'gia_phong': booking.giaPhong,
          'tong_tien': booking.tongTien,
          'formatted_check_in': booking.formattedCheckIn,
          'formatted_check_out': booking.formattedCheckOut,
          'formatted_tong_tien': booking.formattedTongTien,
        },
      };

      final response = await _dio.post('/email/checkin-reminder', data: emailData);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error sending check-in reminder email: ${_handleDioError(e)}');
      return false;
    }
  }

  // Gửi email đánh giá sau khi check-out
  Future<bool> sendReviewRequestEmail(PhieuDatPhongModel booking) async {
    try {
      final emailData = {
        'to_email': booking.email,
        'to_name': booking.tenKhachHang,
        'template_type': 'review_request',
        'subject': 'Đánh giá trải nghiệm của bạn - ${booking.tenPhong}',
        'data': {
          'booking_id': booking.id,
          'ma_phieu': booking.maPhieu,
          'ten_khach_hang': booking.tenKhachHang,
          'so_dien_thoai': booking.soDienThoai,
          'email': booking.email,
          'ten_phong': booking.tenPhong,
          'ma_phong': booking.maPhong,
          'ngay_check_in': booking.ngayCheckIn.toIso8601String(),
          'ngay_check_out': booking.ngayCheckOut.toIso8601String(),
          'so_dem': booking.soDem,
          'gia_phong': booking.giaPhong,
          'tong_tien': booking.tongTien,
          'formatted_check_in': booking.formattedCheckIn,
          'formatted_check_out': booking.formattedCheckOut,
          'formatted_tong_tien': booking.formattedTongTien,
          'review_link': 'https://your-app.com/review/${booking.id}',
        },
      };

      final response = await _dio.post('/email/review-request', data: emailData);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error sending review request email: ${_handleDioError(e)}');
      return false;
    }
  }

  // Gửi email tùy chỉnh
  Future<bool> sendCustomEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String templateType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final emailData = {
        'to_email': toEmail,
        'to_name': toName,
        'template_type': templateType,
        'subject': subject,
        'data': data,
      };

      final response = await _dio.post('/email/custom', data: emailData);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error sending custom email: ${_handleDioError(e)}');
      return false;
    }
  }

  // Lấy lịch sử gửi email
  Future<List<Map<String, dynamic>>> getEmailHistory({
    String? bookingId,
    String? email,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (bookingId != null) queryParams['booking_id'] = bookingId;
      if (email != null) queryParams['email'] = email;

      final response = await _dio.get('/email/history', queryParameters: queryParams);
      
      final List<dynamic> historyJson = response.data['data'] ?? response.data;
      return historyJson.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Gửi email thông báo hàng loạt cho tất cả người dùng
  /// 
  /// Gửi email thông báo đến tất cả người dùng đã đăng ký
  /// 
  /// Parameters:
  ///   - subject: Tiêu đề email
  ///   - templateType: Loại template (new_hotel, new_promotion, general_notification)
  ///   - data: Dữ liệu để điền vào template
  /// 
  /// Returns: Map với thông tin kết quả gửi email
  Future<Map<String, dynamic>> sendBulkNotificationEmail({
    required String subject,
    required String templateType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final emailData = {
        'template_type': templateType,
        'subject': subject,
        'data': data,
        'send_to_all': true, // Gửi đến tất cả người dùng
      };

      final response = await _dio.post('/email/bulk-notification', data: emailData);
      
      if (response.statusCode == 200) {
        final result = response.data;
        return {
          'success': true,
          'sent_count': result['sent_count'] ?? 0,
          'failed_count': result['failed_count'] ?? 0,
          'message': result['message'] ?? 'Gửi email thành công',
        };
      } else {
        return {
          'success': false,
          'sent_count': 0,
          'failed_count': 0,
          'message': 'Lỗi gửi email: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('Error sending bulk notification email: ${_handleDioError(e)}');
      return {
        'success': false,
        'sent_count': 0,
        'failed_count': 0,
        'message': _handleDioError(e),
      };
    }
  }

  // Gửi email thông báo khách sạn mới
  Future<Map<String, dynamic>> sendNewHotelNotificationEmail({
    required String hotelName,
    required String hotelAddress,
    String? hotelImageUrl,
    int? hotelId,
  }) async {
    return sendBulkNotificationEmail(
      subject: '🏨 Khách sạn mới: $hotelName',
      templateType: 'new_hotel',
      data: {
        'hotel_name': hotelName,
        'hotel_address': hotelAddress,
        'hotel_image_url': hotelImageUrl,
        'hotel_id': hotelId,
        'view_hotel_link': hotelId != null ? 'https://your-app.com/hotels/$hotelId' : null,
      },
    );
  }

  // Gửi email thông báo ưu đãi mới
  Future<Map<String, dynamic>> sendNewPromotionNotificationEmail({
    required String promotionTitle,
    required String promotionDescription,
    String? promotionImageUrl,
    int? promotionId,
    double? discountPercent,
  }) async {
    return sendBulkNotificationEmail(
      subject: '🎉 Ưu đãi mới: $promotionTitle',
      templateType: 'new_promotion',
      data: {
        'promotion_title': promotionTitle,
        'promotion_description': promotionDescription,
        'promotion_image_url': promotionImageUrl,
        'promotion_id': promotionId,
        'discount_percent': discountPercent,
        'view_promotion_link': promotionId != null ? 'https://your-app.com/promotions/$promotionId' : null,
      },
    );
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
