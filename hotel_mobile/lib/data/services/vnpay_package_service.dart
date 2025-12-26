/**
 * VNPay Service sử dụng package vnpay_payment_flutter
 * 
 * Dựa trên package: https://pub.dev/packages/vnpay_payment_flutter
 * Và tài liệu VNPay: https://sandbox.vnpayment.vn/apis/
 * 
 * Chức năng:
 * - Tạo payment URL với HMAC-SHA512 signature
 * - Verify signature từ VNPay response
 * - Xử lý deep link callback
 * - Query trạng thái giao dịch
 */

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:vnpay_payment_flutter/vnpay_payment_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/config/payment_config.dart';
import '../services/backend_auth_service.dart';

/// Service xử lý VNPay sử dụng package vnpay_payment_flutter
class VNPayPackageService {
  final Dio _dio;
  final BackendAuthService _authService = BackendAuthService();
  late final VNPAYPayment _vnpayPayment;
  late final AppLinks _appLinks;

  VNPayPackageService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    // Khởi tạo VNPay Payment với config từ PaymentConfig
    _vnpayPayment = VNPAYPayment(
      tmnCode: PaymentConfig.vnpayTmnCode,
      hashSecret: PaymentConfig.vnpayHashSecret,
      isSandbox: PaymentConfig.useVnpaySandbox,
    );
    
    // Khởi tạo AppLinks để xử lý deep link
    _appLinks = AppLinks();
    
    // Add interceptor để thêm token vào header (cho các API khác)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Lấy Return URL từ backend
  /// ⚠️ QUAN TRỌNG: Return URL phải là public URL (không phải localhost)
  Future<String> _getReturnUrl() async {
    try {
      // Thử lấy từ backend API để lấy Return URL đã được config
      final response = await _dio.get('/api/v2/vnpay/config');
      
      // Kiểm tra nếu response có success: false (có thể là lỗi localhost)
      if (response.data['success'] == false) {
        final errorData = response.data;
        // Kiểm tra nếu là lỗi về Return URL
        if (errorData['error'] == 'INVALID_RETURN_URL' || 
            errorData['message']?.toString().contains('localhost') == true ||
            errorData['message']?.toString().contains('Return URL') == true) {
          throw Exception(
            '${errorData['message'] ?? 'Lỗi cấu hình VNPay'}\n\n'
            '${errorData['hint'] ?? ''}\n\n'
            'Ví dụ: ${errorData['example'] ?? ''}'
          );
        }
        // Nếu là lỗi khác
        throw Exception(errorData['message'] ?? 'Lỗi cấu hình VNPay');
      }
      
      // Nếu backend trả về error về localhost (status 400)
      if (response.statusCode == 400 && response.data['error'] == 'INVALID_RETURN_URL') {
        final errorData = response.data;
        throw Exception(
          '${errorData['message']}\n\n'
          '${errorData['hint'] ?? ''}\n\n'
          'Ví dụ: ${errorData['example'] ?? ''}'
        );
      }
      
      // Kiểm tra response thành công
      if (response.data['success'] == true && response.data['data'] != null) {
        final returnUrl = response.data['data']['returnUrl'];
        if (returnUrl != null && !returnUrl.contains('localhost') && !returnUrl.contains('127.0.0.1')) {
          print('✅ VNPay Package Service: Lấy Return URL từ backend: $returnUrl');
          return returnUrl;
        } else {
          throw Exception(
            'Backend trả về Return URL là localhost.\n\n'
            'Vui lòng cấu hình VNP_RETURN_URL trong file .env của backend với public URL (IP public hoặc domain) và restart backend server.\n\n'
            'Ví dụ: VNP_RETURN_URL=http://YOUR_PUBLIC_IP:5000/api/payment/vnpay-return'
          );
        }
      }
      
      // Nếu không có data
      throw Exception('Backend không trả về Return URL hợp lệ');
    } on DioException catch (e) {
      // Xử lý DioException
      if (e.response != null) {
        final errorData = e.response!.data;
        // Kiểm tra nếu là lỗi về Return URL
        if (e.response!.statusCode == 400 || 
            errorData['error'] == 'INVALID_RETURN_URL' ||
            errorData['message']?.toString().contains('localhost') == true) {
          throw Exception(
            '${errorData['message'] ?? 'Lỗi cấu hình VNPay'}\n\n'
            '${errorData['hint'] ?? ''}\n\n'
            'Ví dụ: ${errorData['example'] ?? ''}'
          );
        }
        throw Exception(errorData['message'] ?? 'Lỗi kết nối đến backend');
      }
      print('⚠️ VNPay Package Service: Không thể lấy Return URL từ backend: ${e.message}');
      throw Exception('Không thể kết nối đến backend: ${e.message}');
    } catch (e) {
      // Nếu đã là Exception thì rethrow, không cần wrap lại
      if (e is Exception) {
        rethrow;
      }
      print('⚠️ VNPay Package Service: Error lấy Return URL từ backend: $e');
      throw Exception('Lỗi không xác định: $e');
    }
    
    // Fallback: Dùng backend base URL (phải là public URL)
    final baseUrl = AppConstants.baseUrl;
    final returnUrl = '$baseUrl/api/payment/vnpay-return';
    
    // Kiểm tra nếu là localhost
    if (returnUrl.contains('localhost') || returnUrl.contains('127.0.0.1')) {
      throw Exception(
        'Backend URL đang là localhost.\n\n'
        'Vui lòng:\n'
        '1. Cấu hình VNP_RETURN_URL trong file .env của backend với public URL\n'
        '2. Hoặc cập nhật AppConstants.baseUrl trong Flutter với public URL\n'
        '3. Restart backend server sau khi cập nhật .env'
      );
    }
    
    return returnUrl;
  }

  /// Tạo URL thanh toán VNPay - SỬ DỤNG BACKEND API (khuyến nghị)
  /// 
  /// ⚠️ QUAN TRỌNG: Chuyển sang dùng backend API để tạo payment URL
  /// thay vì tạo ở client-side để đảm bảo signature đúng và bảo mật hơn
  /// 
  /// Parameters:
  /// - [bookingId]: ID của booking cần thanh toán
  /// - [amount]: Số tiền (VND)
  /// - [orderInfo]: Mô tả đơn hàng
  /// - [bankCode]: Mã ngân hàng (optional)
  /// - [bookingData]: Thông tin booking đầy đủ để lưu vào backend (optional)
  /// - [ipAddr]: IP address của client (optional)
  /// 
  /// Returns: Map với paymentUrl và orderId
  Future<Map<String, dynamic>> createPaymentUrl({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? bankCode,
    Map<String, dynamic>? bookingData,
    String? ipAddr,
  }) async {
    try {
      print('📤 VNPay Package Service: Tạo payment URL qua BACKEND API');
      print('📋 VNPay Package Service: bookingId=$bookingId, amount=$amount');
      print('💡 Sử dụng backend API để đảm bảo signature đúng và bảo mật');
      
      // Lấy token nếu có
      final token = await _authService.getToken();
      
      // Gọi backend API để tạo payment URL
      print('📤 VNPay Package Service: Gọi backend API: ${PaymentConfig.vnpayCreatePaymentUrlEndpoint}');
      print('📋 VNPay Package Service: Request data:');
      print('   bookingId: $bookingId');
      print('   amount: $amount');
      print('   orderInfo: $orderInfo');
      print('   bankCode: ${bankCode ?? 'N/A'}');
      print('   hasBookingData: ${bookingData != null}');
      
      final response = await _dio.post(
        PaymentConfig.vnpayCreatePaymentUrlEndpoint,
        data: {
          'bookingId': bookingId,
          'amount': amount,
          'orderInfo': orderInfo,
          if (bankCode != null && bankCode.isNotEmpty) 'bankCode': bankCode,
          if (bookingData != null) 'bookingData': bookingData,
        },
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('📥 VNPay Package Service: Backend response status: ${response.statusCode}');
      print('📥 VNPay Package Service: Backend response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final paymentUrl = data['paymentUrl'] as String?;
        final orderId = data['orderId'] as String?;
        
        print('✅ VNPay Package Service: Backend đã tạo payment URL thành công');
        print('📋 VNPay Package Service: Order ID: $orderId');
        print('📋 VNPay Package Service: Payment URL length: ${paymentUrl?.length ?? 0}');
        print('📋 VNPay Package Service: Payment URL (first 200 chars): ${paymentUrl?.substring(0, paymentUrl!.length > 200 ? 200 : paymentUrl.length) ?? 'null'}...');
        
        if (paymentUrl == null || paymentUrl.isEmpty) {
          throw Exception('Backend trả về payment URL rỗng');
        }
        
        if (orderId == null || orderId.isEmpty) {
          throw Exception('Backend trả về order ID rỗng');
        }
        
        // Validate payment URL
        if (!paymentUrl.startsWith('https://sandbox.vnpayment.vn') && 
            !paymentUrl.startsWith('https://www.vnpayment.vn')) {
          throw Exception('Payment URL không hợp lệ: URL phải bắt đầu bằng https://sandbox.vnpayment.vn hoặc https://www.vnpayment.vn');
        }
        
        return {
          'paymentUrl': paymentUrl,
          'orderId': orderId,
        };
      } else {
        final errorMessage = response.data['message'] ?? response.data['error'] ?? 'Unknown error';
        print('❌ VNPay Package Service: Backend trả về lỗi: $errorMessage');
        throw Exception('Backend trả về lỗi: $errorMessage');
      }
    } catch (e, stackTrace) {
      print('❌ VNPay Package Service: Error tạo payment URL qua backend: $e');
      print('❌ VNPay Package Service: Stack trace: $stackTrace');
      
      // Nếu backend API fail, fallback về package (nhưng log warning)
      print('⚠️ VNPay Package Service: Fallback về package (không khuyến nghị)');
      print('⚠️ VNPay Package Service: Có thể gặp lỗi signature nếu package tạo signature không đúng');
      
      // Fallback: Sử dụng package như cũ (nhưng log warning)
      return await _createPaymentUrlWithPackage(
        bookingId: bookingId,
        amount: amount,
        orderInfo: orderInfo,
        bankCode: bankCode,
        bookingData: bookingData,
        ipAddr: ipAddr,
      );
    }
  }
  
  /// Fallback: Tạo payment URL sử dụng package (không khuyến nghị)
  Future<Map<String, dynamic>> _createPaymentUrlWithPackage({
    required int bookingId,
    required double amount,
    required String orderInfo,
    String? bankCode,
    Map<String, dynamic>? bookingData,
    String? ipAddr,
  }) async {
    try {
      print('📤 VNPay Package Service: Tạo payment URL sử dụng package (FALLBACK)');
      print('📋 VNPay Package Service: bookingId=$bookingId, amount=$amount');
      
      // Tạo order ID unique
      final now = DateTime.now();
      final txnRef = 'ORD_${now.millisecondsSinceEpoch}';
      
      // Lấy Return URL từ backend (phải là public URL)
      final returnUrl = await _getReturnUrl();
      
      // Lấy IP address (nếu không có, dùng default)
      final clientIp = ipAddr ?? '127.0.0.1';
      
      print('📋 VNPay Package Service: Validating inputs...');
      print('   txnRef: $txnRef');
      print('   amount: ${amount.toInt()} VND');
      print('   orderInfo: $orderInfo');
      print('   returnUrl: $returnUrl');
      print('   ipAddr: $clientIp');
      
      // Tạo payment URL sử dụng package
      String paymentUrl;
      try {
        print('📤 VNPay Package Service: Gọi package generatePaymentUrl...');
        paymentUrl = _vnpayPayment.generatePaymentUrl(
          txnRef: txnRef,
          amount: amount,
          orderInfo: orderInfo,
          returnUrl: returnUrl,
          ipAddr: clientIp,
          orderType: 'billpayment',
          expireDate: now.add(const Duration(minutes: 15)),
          bankCode: bankCode,
        );
        print('✅ VNPay Package Service: Package đã tạo payment URL thành công');
      } catch (packageError, packageStackTrace) {
        print('❌ VNPay Package Service: Package throw error: $packageError');
        print('❌ VNPay Package Service: Stack trace: $packageStackTrace');
        throw Exception(
          'Lỗi khi tạo payment URL từ package: $packageError\n\n'
          'Vui lòng kiểm tra:\n'
          '1. Package vnpay_payment_flutter đã được cài đặt đúng chưa\n'
          '2. Config VNPay (TMN Code, Hash Secret) có đúng không\n'
          '3. Return URL có hợp lệ không'
        );
      }
      
      // Lưu booking data vào backend (nếu có)
      if (bookingData != null) {
        try {
          await _savePaymentInfo(bookingId, txnRef, amount, bookingData);
        } catch (e) {
          print('⚠️ VNPay Package Service: Không thể lưu payment info vào backend: $e');
        }
      }
      
      return {
        'paymentUrl': paymentUrl,
        'orderId': txnRef,
      };
    } catch (e) {
      print('❌ VNPay Package Service: Error tạo payment URL với package: $e');
      rethrow;
    }
  }

  /// Lưu thông tin payment vào backend (để backend xử lý IPN và tạo booking)
  Future<void> _savePaymentInfo(
    int bookingId,
    String orderId,
    double amount,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final token = await _authService.getToken();
      await _dio.post(
        '/api/v2/vnpay/save-payment-info',
        data: {
          'bookingId': bookingId,
          'orderId': orderId,
          'amount': amount,
          'bookingData': bookingData,
        },
        options: token != null ? Options(
          headers: {'Authorization': 'Bearer $token'},
        ) : null,
      );
      print('✅ VNPay Package Service: Đã lưu payment info vào backend');
    } catch (e) {
      print('⚠️ VNPay Package Service: Không thể lưu payment info: $e');
      // Không throw, chỉ log warning
    }
  }

  /// Mở payment URL trong trình duyệt
  Future<void> launchPaymentUrl(String paymentUrl) async {
    try {
      print('🌐 VNPay Package Service: Đang mở payment URL...');
      print('📋 VNPay Package Service: URL length: ${paymentUrl.length}');
      
      final uri = Uri.parse(paymentUrl);
      
      // Validate URI
      if (uri.scheme != 'https') {
        throw Exception('Payment URL phải sử dụng HTTPS: ${uri.scheme}');
      }
      
      if (!uri.host.contains('vnpayment.vn')) {
        throw Exception('Payment URL không hợp lệ: ${uri.host}');
      }
      
      print('📋 VNPay Package Service: URI parsed successfully');
      print('📋 VNPay Package Service: Scheme: ${uri.scheme}, Host: ${uri.host}');
      
      // Kiểm tra có thể mở URL không
      final canLaunch = await canLaunchUrl(uri);
      print('📋 VNPay Package Service: Can launch URL: $canLaunch');
      
      if (!canLaunch) {
        throw Exception('Không thể mở payment URL. Có thể thiếu quyền hoặc URL không hợp lệ.');
      }
      
      // Mở URL trong trình duyệt bên ngoài
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Mở trong trình duyệt bên ngoài
      );
      
      if (launched) {
        print('✅ VNPay Package Service: Đã mở payment URL trong trình duyệt thành công');
      } else {
        throw Exception('Không thể mở payment URL (launchUrl returned false)');
      }
    } catch (e, stackTrace) {
      print('❌ VNPay Package Service: Error mở payment URL: $e');
      print('❌ VNPay Package Service: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Xử lý deep link callback từ VNPay
  /// 
  /// Parameters:
  /// - [uri]: Deep link URI từ VNPay
  /// 
  /// Returns: Map với thông tin kết quả thanh toán
  Map<String, dynamic>? handlePaymentReturn(Uri uri) {
    try {
      print('📥 VNPay Package Service: Nhận deep link callback: $uri');
      
      // Kiểm tra scheme và host
      if (uri.scheme != 'vnpaypayment' || uri.host != 'return') {
        print('⚠️ VNPay Package Service: Deep link không phải từ VNPay');
        return null;
      }
      
      // Parse query parameters
      final params = uri.queryParameters;
      print('📋 VNPay Package Service: Query params: $params');
      
      // ⚠️ CRITICAL: Verify signature (Bắt buộc để bảo vệ chống giả mạo)
      final isValid = _vnpayPayment.verifyResponse(params);
      if (!isValid) {
        print('❌ VNPay Package Service: Chữ ký không hợp lệ - Có thể dữ liệu bị giả mạo!');
        return {
          'success': false,
          'error': 'INVALID_SIGNATURE',
          'message': 'Chữ ký không hợp lệ',
        };
      }
      
      // Lấy response code
      final responseCode = params['vnp_ResponseCode'] ?? '99';
      
      // Lấy thông tin chi tiết từ response code
      final responseCodeInfo = VNPayResponseCode.getByCode(responseCode);
      
      // Parse amount (VNPay gửi x100)
      final amountStr = params['vnp_Amount'] ?? '0';
      final amount = int.parse(amountStr) ~/ 100;
      
      // Lấy thông tin giao dịch
      final transactionNo = params['vnp_TransactionNo'];
      final orderId = params['vnp_TxnRef'];
      final bankCode = params['vnp_BankCode'];
      final payDate = params['vnp_PayDate'];
      
      print('📋 VNPay Package Service: Response Code: $responseCode');
      print('📋 VNPay Package Service: Is Success: ${responseCodeInfo.isSuccess}');
      print('📋 VNPay Package Service: Message: ${responseCodeInfo.message}');
      print('📋 VNPay Package Service: Amount: $amount VND');
      print('📋 VNPay Package Service: Transaction No: $transactionNo');
      
      return {
        'success': responseCodeInfo.isSuccess,
        'responseCode': responseCode,
        'message': responseCodeInfo.message,
        'description': responseCodeInfo.description,
        'amount': amount,
        'transactionNo': transactionNo,
        'orderId': orderId,
        'bankCode': bankCode,
        'payDate': payDate,
      };
    } catch (e) {
      print('❌ VNPay Package Service: Error xử lý payment return: $e');
      return {
        'success': false,
        'error': 'PROCESSING_ERROR',
        'message': 'Lỗi xử lý kết quả thanh toán: $e',
      };
    }
  }

  /// Lắng nghe deep link callback từ VNPay
  /// 
  /// Returns: Stream<Uri> - Stream của deep link URIs
  Stream<Uri> listenToDeepLinks() {
    return _appLinks.uriLinkStream;
  }

  /// Lấy danh sách ngân hàng hỗ trợ VNPay
  Future<List<Map<String, String>>> getBankList() async {
    try {
      final response = await Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
      )).get(PaymentConfig.vnpayGetBanksEndpoint);

      if (response.data['success'] == true) {
        final List<dynamic> banks = response.data['data'];
        return banks.map<Map<String, String>>((bank) => {
          'code': (bank['code'] ?? '').toString(),
          'name': (bank['name'] ?? '').toString(),
        }).toList();
      } else {
        throw Exception('Không thể lấy danh sách ngân hàng');
      }
    } catch (e) {
      print('❌ VNPay Package Service: Error lấy danh sách ngân hàng: $e');
      // Return default banks
      return _getDefaultBanks();
    }
  }

  /// Danh sách ngân hàng mặc định (fallback)
  List<Map<String, String>> _getDefaultBanks() {
    return [
      {'code': 'VNPAYQR', 'name': 'Cổng thanh toán VNPAYQR'},
      {'code': 'VNBANK', 'name': 'Thanh toán qua ứng dụng hỗ trợ VNPAYQR'},
      {'code': 'INTCARD', 'name': 'Thanh toán qua thẻ quốc tế'},
      {'code': 'VIETCOMBANK', 'name': 'Vietcombank'},
      {'code': 'VIETINBANK', 'name': 'VietinBank'},
      {'code': 'BIDV', 'name': 'BIDV'},
      {'code': 'AGRIBANK', 'name': 'Agribank'},
      {'code': 'TECHCOMBANK', 'name': 'Techcombank'},
      {'code': 'ACB', 'name': 'ACB'},
      {'code': 'VPBANK', 'name': 'VPBank'},
      {'code': 'MBBANK', 'name': 'MB Bank'},
      {'code': 'SACOMBANK', 'name': 'Sacombank'},
    ];
  }

  /// Query payment status từ backend
  /// 
  /// Parameters:
  /// - [orderId]: Mã đơn hàng cần kiểm tra
  /// 
  /// Returns: Map với thông tin payment status
  Future<Map<String, dynamic>?> getPaymentStatus(String orderId) async {
    try {
      print('🔍 VNPay Package Service: Querying payment status for order: $orderId');
      
      final response = await _dio.get(
        '/api/v2/vnpay/payment-status/$orderId',
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        print('✅ VNPay Package Service: Payment status retrieved');
        print('   Status: ${data['status']}');
        print('   Response Code: ${data['responseCode']}');
        
        return {
          'success': data['status'] == 'completed',
          'status': data['status'],
          'responseCode': data['responseCode'],
          'responseMessage': data['responseMessage'],
          'transactionNo': data['transactionNo'],
          'amount': data['amount'],
          'orderId': data['orderId'],
          'bookingId': data['bookingId'],
          'paidAt': data['paidAt'],
        };
      } else {
        print('⚠️ VNPay Package Service: Payment not found or error');
        return null;
      }
    } catch (e) {
      print('❌ VNPay Package Service: Error querying payment status: $e');
      return null;
    }
  }

  /// Get VNPay Payment instance (để sử dụng trực tiếp nếu cần)
  VNPAYPayment get vnpayPayment => _vnpayPayment;
}

