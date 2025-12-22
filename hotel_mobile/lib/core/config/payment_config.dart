/**
 * Payment Gateway Configuration
 * Cấu hình môi trường cho VNPay và MoMo
 */

class PaymentConfig {
  // ============================================
  // VNPay Configuration
  // ============================================
  
  /// VNPay Sandbox/Test Environment
  static const String vnpaySandboxUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  
  /// VNPay Production Environment (khi deploy production)
  static const String vnpayProductionUrl = 'https://www.vnpayment.vn/paymentv2/vpcpay.html';
  
  /// VNPay API Base URL (dùng cho query transaction)
  static const String vnpayApiBaseUrl = 'https://sandbox.vnpayment.vn/merchant_webapi/api';
  
  /// VNPay Colors (theo brand guidelines)
  static const int vnpayRedColor = 0xFFED1C24;
  static const int vnpayOrangeColor = 0xFFFF6B00;
  
  /// VNPay Environment (sandbox hoặc production)
  static const bool useVnpaySandbox = true; // Đổi thành false khi deploy production
  
  /// VNPay TMN Code (Terminal Code) - Sandbox
  static const String vnpayTmnCode = 'M0O5UJ08';
  
  /// VNPay Hash Secret - Sandbox
  static const String vnpayHashSecret = '3B6KILI6JADKI0Z6AHQX2KRSHFKV6CFF';
  
  /// VNPay Base URL (tự động chọn theo environment)
  static String get vnpayBaseUrl {
    return useVnpaySandbox ? vnpaySandboxUrl : vnpayProductionUrl;
  }
  
  // ============================================
  // MoMo Configuration
  // ============================================
  
  /// MoMo Test/Sandbox Environment
  static const String momoSandboxApiUrl = 'https://test-payment.momo.vn/v2/gateway/api/create';
  
  /// MoMo Production Environment (khi deploy production)
  static const String momoProductionApiUrl = 'https://payment.momo.vn/v2/gateway/api/create';
  
  /// MoMo Query Transaction API
  static const String momoQueryApiUrl = 'https://test-payment.momo.vn/v2/gateway/api/query';
  
  /// MoMo Colors (theo brand guidelines)
  static const int momoPinkColor = 0xFFD82D8B;
  static const int momoDarkPinkColor = 0xFFB91C72;
  
  /// MoMo Environment (sandbox hoặc production)
  static const bool useMomoSandbox = true; // Đổi thành false khi deploy production
  
  /// MoMo API URL (tự động chọn theo environment)
  static String get momoApiUrl {
    return useMomoSandbox ? momoSandboxApiUrl : momoProductionApiUrl;
  }
  
  // ============================================
  // MoMo Native SDK Configuration
  // ============================================
  // ⚠️ QUAN TRỌNG: Các thông tin này lấy từ https://business.momo.vn
  // Sau khi đăng ký tài khoản MoMo, bạn sẽ nhận được:
  // - Partner Code (Mã đối tác)
  // - Partner Scheme ID (dùng cho deep linking)
  
  /// MoMo Partner Code (Mã đối tác)
  /// Test credentials mặc định từ MoMo
  /// ⚠️ Lưu ý: Đây là test credentials công khai, chỉ dùng cho môi trường test
  static const String momoPartnerCode = 'MOMO';
  
  /// MoMo Access Key (Test)
  static const String momoAccessKey = 'F8BBA842ECF85';
  
  /// MoMo Partner Scheme ID (dùng cho deep linking với MoMo app)
  /// ⚠️ QUAN TRỌNG: 
  /// - Với test credentials mặc định, có thể không có Partner Scheme ID
  /// - Nếu muốn dùng MoMo Mobile SDK (mở MoMo app trực tiếp), cần đăng ký tài khoản riêng tại https://business.momo.vn
  /// - Sau khi đăng ký, lấy Partner Scheme ID và cập nhật giá trị này
  /// - Phải cấu hình trong Info.plist (iOS) và AndroidManifest.xml (Android)
  /// 
  /// Hiện tại: Để trống vì dùng WebView (không cần Scheme ID)
  /// Nếu muốn dùng Native SDK: Thay bằng scheme ID thật từ MoMo
  static const String momoAppScheme = ''; // Để trống nếu dùng WebView, hoặc thay bằng scheme ID nếu dùng Native SDK
  
  /// MoMo Merchant Name (Tên merchant)
  static const String momoMerchantName = 'Hotel Booking System';
  
  /// MoMo Merchant Name Label (Label cho merchant name)
  static const String momoMerchantNameLabel = 'Dịch vụ';
  
  /// MoMo Order Label (Label cho order ID)
  static const String momoOrderLabel = 'Mã đơn hàng';
  
  // ============================================
  // Payment Return URLs
  // ============================================
  // ⚠️ QUAN TRỌNG: Các URL này phải là public URL (không phải localhost)
  // Backend sẽ tự động sử dụng các URL này từ .env file
  
  /// VNPay Return URL (backend endpoint)
  /// URL này được set trong backend .env file
  /// Flutter app chỉ cần gọi API, backend sẽ tự động redirect đến VNPay
  static const String vnpayReturnEndpoint = '/api/payment/vnpay-return';
  
  /// MoMo Return URL (backend endpoint)
  /// URL này được set trong backend .env file
  /// Flutter app chỉ cần gọi API, backend sẽ tự động redirect đến MoMo
  static const String momoReturnEndpoint = '/api/payment/momo-return';
  
  // ============================================
  // Payment API Endpoints (Backend)
  // ============================================
  
  /// Tạo VNPay payment URL
  static const String vnpayCreatePaymentUrlEndpoint = '/api/v2/vnpay/create-payment';
  
  /// Query VNPay transaction
  static const String vnpayQueryTransactionEndpoint = '/api/v2/vnpay/query-transaction';
  
  /// Lấy danh sách ngân hàng VNPay
  static const String vnpayGetBanksEndpoint = '/api/v2/vnpay/banks';
  
  /// Tạo MoMo payment URL
  static const String momoCreatePaymentUrlEndpoint = '/api/v2/momo/create-payment-url';
  
  /// Query MoMo transaction
  static const String momoQueryTransactionEndpoint = '/api/v2/momo/query-transaction';
  
  // ============================================
  // Payment Settings
  // ============================================
  
  /// Minimum payment amount (VND)
  static const int minPaymentAmount = 1000;
  
  /// Maximum payment amount (VND)
  static const int maxPaymentAmount = 50000000;
  
  /// Payment timeout (minutes)
  static const int paymentTimeoutMinutes = 15;
  
  /// Supported currencies
  static const String defaultCurrency = 'VND';
  
  // ============================================
  // Payment Status Codes
  // ============================================
  
  /// VNPay Response Codes
  static const Map<String, String> vnpayResponseMessages = {
    '00': 'Giao dịch thành công',
    '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ.',
    '09': 'Thẻ/Tài khoản chưa đăng ký InternetBanking.',
    '10': 'Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
    '11': 'Đã hết hạn chờ thanh toán',
    '12': 'Thẻ/Tài khoản bị khóa',
    '13': 'Nhập sai mật khẩu OTP',
    '24': 'Khách hàng hủy giao dịch',
    '51': 'Tài khoản không đủ số dư',
    '65': 'Vượt quá hạn mức giao dịch trong ngày',
    '75': 'Ngân hàng thanh toán đang bảo trì',
    '79': 'Nhập sai mật khẩu thanh toán quá số lần quy định',
    '99': 'Các lỗi khác',
  };
  
  /// MoMo Result Codes
  static const Map<int, String> momoResultMessages = {
    0: 'Giao dịch thành công',
    9000: 'Giao dịch được khởi tạo, chờ người dùng xác nhận thanh toán',
    8000: 'Giao dịch đang được xử lý',
    7000: 'Giao dịch đang chờ thanh toán',
    1000: 'Giao dịch đã được khởi tạo, chờ người dùng xác nhận thanh toán',
    11: 'Truy cập bị từ chối',
    12: 'Phiên bản API không được hỗ trợ cho yêu cầu này',
    13: 'Xác thực dữ liệu thất bại',
    20: 'Số tiền không hợp lệ',
    21: 'Số tiền thanh toán không hợp lệ',
    40: 'RequestId bị trùng',
    41: 'OrderId bị trùng',
    42: 'OrderId không hợp lệ hoặc không được tìm thấy',
    43: 'Yêu cầu bị từ chối vì xung đột trong quá trình xử lý giao dịch',
    1001: 'Giao dịch thanh toán thất bại do tài khoản người dùng không đủ tiền',
    1002: 'Giao dịch bị từ chối do nhà phát hành tài khoản thanh toán',
    1003: 'Giao dịch bị hủy',
    1004: 'Giao dịch thất bại do số tiền thanh toán vượt quá hạn mức thanh toán của người dùng',
    1005: 'Giao dịch thất bại do url hoặc QR code đã hết hạn',
    1006: 'Giao dịch thất bại do người dùng đã từ chối xác nhận thanh toán',
    1007: 'Giao dịch bị từ chối vì tài khoản người dùng đang ở trạng thái tạm khóa',
    1026: 'Giao dịch bị hạn chế theo thể lệ chương trình KM',
    1080: 'Giao dịch hoàn tiền bị từ chối. Giao dịch thanh toán ban đầu không được tìm thấy',
    1081: 'Giao dịch hoàn tiền bị từ chối. Giao dịch thanh toán ban đầu đã được hoàn',
    2001: 'Giao dịch thất bại do sai thông tin liên kết',
    2007: 'Giao dịch thất bại do liên kết thanh toán không tồn tại hoặc đã hết hạn',
    3001: 'Liên kết thanh toán bị từ chối vì người dùng chưa đăng ký dịch vụ',
    3002: 'Tài khoản chưa được kích hoạt',
    3003: 'Tài khoản đang bị khóa',
    4001: 'Giao dịch bị hạn chế theo thể lệ chương trình KM',
    4010: 'Giao dịch bị hạn chế do OTP chưa được gửi hoặc đã hết hạn',
    4011: 'Giao dịch bị từ chối vì OTP không hợp lệ',
    4100: 'Giao dịch thất bại do người dùng không xác nhận thanh toán',
    10: 'Hệ thống đang được bảo trì',
    99: 'Lỗi không xác định',
  };
  
  // ============================================
  // Helper Methods
  // ============================================
  
  /// Lấy message từ VNPay response code
  static String getVnpayMessage(String? responseCode) {
    if (responseCode == null) return 'Lỗi không xác định';
    return vnpayResponseMessages[responseCode] ?? 'Lỗi không xác định';
  }
  
  /// Lấy message từ MoMo result code
  static String getMomoMessage(int? resultCode) {
    if (resultCode == null) return 'Lỗi không xác định';
    return momoResultMessages[resultCode] ?? 'Lỗi không xác định (code: $resultCode)';
  }
  
  /// Kiểm tra xem payment amount có hợp lệ không
  static bool isValidPaymentAmount(double amount) {
    return amount >= minPaymentAmount && amount <= maxPaymentAmount;
  }
  
  /// Format payment amount thành VND
  static String formatPaymentAmount(double amount) {
    final amountStr = amount.toStringAsFixed(0);
    final formatted = amountStr.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted VNĐ';
  }
}
