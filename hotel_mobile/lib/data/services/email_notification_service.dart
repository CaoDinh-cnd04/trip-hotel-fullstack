import 'package:dio/dio.dart';
import '../models/phieu_dat_phong_model.dart';

class EmailNotificationService {
  static final EmailNotificationService _instance = EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  late Dio _dio;
  static const String baseUrl = 'https://your-backend-api.com/api/notifications'; // Thay đổi URL này

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
        print('Email Notification API Error: ${error.message}');
        print('Response: ${error.response?.data}');
        handler.next(error);
      },
    ));
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
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
