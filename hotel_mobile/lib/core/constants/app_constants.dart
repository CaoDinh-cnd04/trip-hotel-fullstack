class AppConstants {
  // API Base URL Configuration
  // For different environments
  static const String _localhostUrl = 'http://localhost:5000/api/v2';
  static const String _emulatorUrl = 'http://10.0.2.2:5000/api/v2';
  static const String _iosSimulatorUrl = 'http://127.0.0.1:5000/api/v2';

  // Auto-detect environment or set manually
  static String get baseUrl {
    // You can also check Platform.isAndroid, Platform.isIOS here
    // For now, default to emulator URL which works for Android emulator
    return _emulatorUrl;
  }

  // Alternative URLs for different scenarios
  static const String localhostBaseUrl = _localhostUrl;
  static const String emulatorBaseUrl = _emulatorUrl;
  static const String iosSimulatorBaseUrl = _iosSimulatorUrl;

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String hotelsEndpoint = '/khachsan';
  static const String searchHotelsEndpoint = '/khachsan/search';
  static const String bookingEndpoint = '/phieudatphong';
  static const String promotionsEndpoint = '/khuyenmai';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';

  // App Info
  static const String appName = 'Hotel Booking';
  static const String appVersion = '1.0.0';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}

class AppStrings {
  // Authentication
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String confirmPassword = 'Xác nhận mật khẩu';
  static const String fullName = 'Họ và tên';
  static const String phoneNumber = 'Số điện thoại';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String dontHaveAccount = 'Chưa có tài khoản?';
  static const String alreadyHaveAccount = 'Đã có tài khoản?';
  static const String loginWithGoogle = 'Đăng nhập với Google';
  static const String loginWithFacebook = 'Đăng nhập với Facebook';

  // Home
  static const String welcome = 'Chào mừng';
  static const String searchHotels = 'Tìm kiếm khách sạn';
  static const String popularDestinations = 'Điểm đến phổ biến';
  static const String featuredHotels = 'Khách sạn nổi bật';
  static const String viewAll = 'Xem tất cả';

  // Common
  static const String loading = 'Đang tải...';
  static const String error = 'Có lỗi xảy ra';
  static const String retry = 'Thử lại';
  static const String cancel = 'Hủy';
  static const String ok = 'OK';
  static const String save = 'Lưu';
  static const String edit = 'Chỉnh sửa';
  static const String delete = 'Xóa';
  static const String search = 'Tìm kiếm';

  // Validation Messages
  static const String emailRequired = 'Vui lòng nhập email';
  static const String emailInvalid = 'Email không hợp lệ';
  static const String passwordRequired = 'Vui lòng nhập mật khẩu';
  static const String passwordTooShort = 'Mật khẩu phải có ít nhất 6 ký tự';
  static const String passwordMismatch = 'Mật khẩu không khớp';
  static const String fullNameRequired = 'Vui lòng nhập họ tên';
  static const String phoneRequired = 'Vui lòng nhập số điện thoại';
}
