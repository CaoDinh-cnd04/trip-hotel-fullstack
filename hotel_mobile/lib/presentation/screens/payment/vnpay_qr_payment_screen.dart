/**
 * Màn hình thanh toán VNPay QR Code
 * 
 * Giao diện đẹp theo thiết kế VNPay chính thức:
 * - Logo VNPay QR
 * - QR Code để quét
 * - Số tiền thanh toán
 * - Danh sách ngân hàng hỗ trợ
 * - Nút xác thực
 */

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/vnpay_service.dart';
import '../../../data/services/booking_history_service.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../data/models/booking_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/backend_auth_service.dart';
import '../../../presentation/widgets/payment/vnpay_test_card_dialog.dart';
import 'vnpay_payment_result_screen.dart';
import '../../../data/services/vnpay_native_service.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class VNPayQRPaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;
  final String orderInfo;
  
  // Thông tin booking để tạo sau khi thanh toán thành công
  final Hotel hotel;
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int nights;
  final String userName;
  final String userEmail;
  final String userPhone;

  const VNPayQRPaymentScreen({
    Key? key,
    required this.bookingId,
    required this.amount,
    required this.orderInfo,
    required this.hotel,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.nights,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  }) : super(key: key);

  @override
  State<VNPayQRPaymentScreen> createState() => _VNPayQRPaymentScreenState();
}

class _VNPayQRPaymentScreenState extends State<VNPayQRPaymentScreen> {
  final VNPayService _vnpayService = VNPayService();
  final BackendAuthService _authService = BackendAuthService();
  final BookingHistoryService _bookingService = BookingHistoryService();
  
  bool _isLoading = true;
  String? _paymentUrl;
  String? _qrData;
  String? _errorMessage;
  bool _showWebView = false;
  late WebViewController _webViewController;
  String? _selectedBankCode; // Bank code được chọn
  String? _orderId; // Mã đơn hàng
  DateTime? _transactionTime; // Thời gian tạo giao dịch
  int _selectedPaymentMethod = 0; // 0: QR, 1: ATM/Nội địa, 2: Thẻ quốc tế

  // VNPay colors
  static const Color vnpayRed = Color(0xFFED1C24);
  static const Color vnpayOrange = Color(0xFFFF6B00);

  @override
  void initState() {
    super.initState();
    _checkAuthAndCreatePayment();
  }

  Future<void> _checkAuthAndCreatePayment() async {
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      setState(() {
        _errorMessage = 'Vui lòng đăng nhập để thanh toán';
        _isLoading = false;
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Yêu cầu đăng nhập'),
            content: const Text('Bạn cần đăng nhập để thực hiện thanh toán'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, {'success': false, 'reason': 'not_authenticated'});
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
      return;
    }

    await _createPaymentUrl();
  }

  Future<void> _createPaymentUrl({String? bankCode}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🎯 Tạo VNPay payment URL...');
      if (bankCode != null) {
        print('🏦 Bank code: $bankCode');
      }
      
      // Chuẩn bị booking data để backend tạo booking sau payment
      // userId sẽ được lấy từ JWT token ở backend
      final bookingData = {
        'userEmail': widget.userEmail,
        'userName': widget.userName,
        'userPhone': widget.userPhone,
        'hotelId': widget.hotel.id,
        'hotelName': widget.hotel.ten,
        'roomId': widget.room.id,
        'roomNumber': widget.room.soPhong ?? '101',
        'roomType': widget.room.tenLoaiPhong ?? 'Standard',
        'checkInDate': widget.checkInDate.toIso8601String(),
        'checkOutDate': widget.checkOutDate.toIso8601String(),
        'guestCount': widget.guestCount,
        'roomCount': 1,
        'nights': widget.nights,
        'roomPrice': widget.room.giaPhong ?? 0,
        'totalPrice': widget.amount,
        'discountAmount': 0,
        'finalPrice': widget.amount,
        'cancellationAllowed': true,
      };
      
      final paymentUrl = await _vnpayService.createPaymentUrl(
        bookingId: widget.bookingId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
        bankCode: bankCode, // Sử dụng bank code đã chọn
        bookingData: bookingData, // Truyền booking data để tạo booking sau payment
      );

      // Tạo orderId từ bookingId và timestamp
      _orderId = 'BOOK${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}';
      _transactionTime = DateTime.now();

      setState(() {
        _paymentUrl = paymentUrl;
        _qrData = paymentUrl; // QR code chứa URL thanh toán
        _selectedBankCode = bankCode;
        _isLoading = false;
      });
      
      print('✅ Tạo payment URL thành công');
    } catch (e) {
      print('❌ Lỗi tạo payment URL: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _selectBank(String bankName, String bankCode) async {
    print('🏦 Chọn ngân hàng: $bankName ($bankCode)');
    
    // Hiển thị dialog thông tin thẻ test trước khi tạo payment URL
    final showCardInfo = await showDialog<bool>(
      context: context,
      builder: (context) => VNPayTestCardDialog(
        bankName: bankName,
        bankCode: bankCode,
      ),
    );
    
    // Nếu user nhấn "Đã ghi nhớ", tạo payment URL với bank code
    if (showCardInfo == true || showCardInfo == null) {
    _createPaymentUrl(bankCode: bankCode);
    }
  }

  Future<void> _handlePaymentSuccess(String transactionId) async {
    try {
      print('🎉 Thanh toán thành công, tạo booking...');
      
      // Tạo booking
      final booking = await _bookingService.createBooking({
        'hotelId': widget.hotel.id,
        'hotelName': widget.hotel.ten,
        'roomId': widget.room.id,
        'roomNumber': widget.room.soPhong,
        'roomType': widget.room.tenLoaiPhong,
        'checkInDate': widget.checkInDate.toIso8601String(),
        'checkOutDate': widget.checkOutDate.toIso8601String(),
        'guestCount': widget.guestCount,
        'roomCount': 1,
        'nights': widget.nights,
        'roomPrice': widget.room.giaPhong,
        'totalPrice': widget.amount,
        'discountAmount': 0,
        'finalPrice': widget.amount,
        'paymentMethod': 'vnpay',
        'paymentStatus': 'paid',
        'paymentTransactionId': transactionId,
        'userPhone': widget.userPhone,
        'cancellationAllowed': true,
      });

      if (mounted) {
        // Hiển thị màn hình kết quả VNPay
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VNPayPaymentResultScreen(
              isSuccess: true,
              transactionNo: transactionId,
              orderId: _orderId,
              amount: widget.amount,
              paymentTime: DateTime.now(),
            ),
          ),
        ).then((_) {
          // Return về payment screen với kết quả
        Navigator.pop(context, {
          'success': true,
          'booking': booking.toJson(),
          'transactionId': transactionId,
          });
        });
      }
    } catch (e) {
      print('❌ Lỗi tạo booking: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VNPayPaymentResultScreen(
              isSuccess: true,
              transactionNo: transactionId,
              orderId: _orderId,
              amount: widget.amount,
              paymentTime: DateTime.now(),
            ),
          ),
        ).then((_) {
        Navigator.pop(context, {
            'success': true,
          'transactionId': transactionId,
          'bookingError': e.toString(),
          });
        });
      }
    }
  }

  Future<void> _openWebViewPayment() async {
    if (_paymentUrl == null) return;
    
    // Kiểm tra nếu là Android THẬT (không phải emulator) và có thể dùng Native SDK
    if (Platform.isAndroid) {
      try {
        // Kiểm tra xem có phải emulator không bằng cách check model name
        final bool isEmulator = await _isAndroidEmulator();
        
        if (!isEmulator) {
          final isAvailable = await VnPayNativeService.isAvailable();
          if (isAvailable) {
            print('📱 Sử dụng VNPay Native SDK trên thiết bị thật');
            await _openNativeSdk();
            return;
          }
        } else {
          print('⚠️ Phát hiện Android Emulator - dùng WebView thay vì Native SDK');
        }
      } catch (e) {
        print('⚠️ Native SDK không khả dụng, dùng WebView: $e');
      }
    }
    
    // Fallback về WebView (iOS, emulator, hoặc nếu native SDK không khả dụng)
    print('🌐 Sử dụng WebView để thanh toán');
    setState(() {
      _showWebView = true;
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            _handleNavigationUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_paymentUrl!));
  }

  /// Kiểm tra xem có phải Android Emulator không
  Future<bool> _isAndroidEmulator() async {
    try {
      // Dùng cùng channel với VNPay
      const MethodChannel channel = MethodChannel('com.example.hotel_mobile/vnpay');
      final bool? isEmulator = await channel.invokeMethod<bool>('isEmulator');
      return isEmulator ?? false;
    } catch (e) {
      // Nếu không có method hoặc có lỗi, giả định là emulator để dùng WebView (an toàn hơn)
      print('⚠️ Không thể kiểm tra emulator, giả định là emulator để dùng WebView: $e');
      return true; // Mặc định là emulator để dùng WebView (an toàn hơn cho testing)
    }
  }

  Future<void> _openNativeSdk() async {
    try {
      print('📱 Mở VNPay Native SDK...');
      
      // Lấy TMN_CODE từ backend hoặc sử dụng giá trị mặc định
      // TODO: Có thể lấy từ API hoặc config
      const tmnCode = 'M005UJ08'; // Từ config vnpay.js
      
      // Extract URL từ payment URL (VNPay SDK cần URL đầy đủ)
      final result = await VnPayNativeService.openVnPaySdk(
        paymentUrl: _paymentUrl!,
        tmnCode: tmnCode,
        scheme: 'vnpayresult',
        isSandbox: true, // TODO: Lấy từ config
      );
      
      print('📱 VNPay Native SDK result: $result');
      
      if (result['success'] == true) {
        // Thanh toán thành công
        final transactionNo = result['transactionNo']?.toString() ?? 
            'VNP${DateTime.now().millisecondsSinceEpoch}';
        await _handlePaymentSuccess(transactionNo);
      } else {
        // Thanh toán thất bại hoặc bị hủy
        final reason = result['reason']?.toString() ?? 'unknown';
        final responseCode = result['responseCode']?.toString();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VNPayPaymentResultScreen(
                isSuccess: false,
                orderId: _orderId,
                amount: widget.amount,
                errorCode: responseCode,
                message: _getErrorMessage(responseCode),
              ),
            ),
          ).then((_) {
            Navigator.pop(context, {
              'success': false,
              'reason': reason,
              'message': result['error']?.toString() ?? 'Thanh toán không thành công',
            });
          });
        }
      }
    } catch (e) {
      print('❌ Lỗi mở Native SDK: $e');
      // Fallback về WebView
      setState(() {
        _showWebView = true;
      });
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              _handleNavigationUrl(request.url);
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_paymentUrl!));
    }
  }

  void _handleNavigationUrl(String url) {
    print('🔗 Navigation URL: $url');
    
    if (url.contains('vnp_ResponseCode')) {
      final uri = Uri.parse(url);
      final responseCode = uri.queryParameters['vnp_ResponseCode'];
      final transactionNo = uri.queryParameters['vnp_TransactionNo'];
      
      if (responseCode == '00') {
        // Thanh toán thành công
        _handlePaymentSuccess(transactionNo ?? 'VNP${DateTime.now().millisecondsSinceEpoch}');
      } else {
        // Thanh toán thất bại - hiển thị màn hình kết quả
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VNPayPaymentResultScreen(
                isSuccess: false,
                orderId: _orderId,
                amount: widget.amount,
                errorCode: responseCode,
                message: _getErrorMessage(responseCode),
              ),
            ),
          ).then((_) {
            Navigator.pop(context, {
              'success': false,
              'reason': 'payment_failed',
              'message': 'Mã lỗi: $responseCode',
            });
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _paymentUrl != null) {
      return _buildWebView();
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildQRPaymentUI(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: vnpayRed),
          const SizedBox(height: 16),
          const Text(
            'Đang tạo mã thanh toán...',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createPaymentUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: vnpayRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRPaymentUI() {
    return SafeArea(
      child: Column(
        children: [
          // Header với thông tin giao dịch - Fixed
          _buildVNPayHeader(),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  // Banner cảnh báo
                  _buildWarningBanner(),
                  
                  // Thông tin chi tiết giao dịch
                  _buildTransactionDetails(),
                  
                  // Phần chọn phương thức thanh toán
                  _buildPaymentMethodsSection(),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVNPayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo VNPay - Flexible để tránh overflow
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: vnpayRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VNPAY',
                        style: TextStyle(
                          color: vnpayRed,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CỔNG THANH TOÁN',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            'VNPAYQR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Language flags - Fixed size
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.grey[300]!, width: 0.5),
                    ),
                    child: const Center(
                      child: Text(
                        '★',
                        style: TextStyle(color: Colors.yellow, fontSize: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 24,
                    height: 18,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 18, color: Colors.blue),
                        Container(width: 12, height: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Thông tin giao dịch
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thanh toán đặt phòng - ${widget.hotel.ten}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (_orderId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mã giao dịch: $_orderId',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
                    ],
                  ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Số tiền cần thanh toán
          _buildDetailRow(
            'Số tiền cần thanh toán',
            CurrencyFormatter.format(widget.amount),
            isHighlight: true,
          ),
          
          const Divider(height: 24),
          
          // Mã đơn hàng
          if (_orderId != null)
            _buildDetailRow('Mã đơn hàng / Mã giao dịch', _orderId!),
          
          // Thời gian tạo giao dịch
          _buildDetailRow(
            'Thời gian tạo giao dịch',
            _transactionTime != null
                ? DateFormat('dd/MM/yyyy HH:mm:ss').format(_transactionTime!)
                : DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          ),
          
          // Mô tả
          _buildDetailRow(
            'Mô tả',
            'Thanh toán ${widget.room.tenLoaiPhong ?? "phòng"} – ${widget.hotel.ten}',
                ),
              ],
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlight ? 18 : 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? vnpayRed : Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light blue
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quý khách vui lòng không tắt trình duyệt cho đến khi nhận được kết quả giao dịch trên website. Xin cảm ơn!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[900],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close, color: Colors.blue[700], size: 18),
            onPressed: () {
              // Có thể ẩn banner nếu muốn
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPaymentTab(0, 'QR Code', Icons.qr_code_2),
              ),
              Expanded(
                child: _buildPaymentTab(1, 'ATM/Nội địa', Icons.account_balance),
              ),
              Expanded(
                child: _buildPaymentTab(2, 'Thẻ quốc tế', Icons.credit_card),
              ),
            ],
          ),
        ),
        
        // Content based on selected tab - không dùng Expanded vì đã ở trong SingleChildScrollView
        _buildPaymentMethodContent(),
      ],
    );
  }

  Widget _buildPaymentTab(int index, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? vnpayRed : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? vnpayRed : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodContent() {
    switch (_selectedPaymentMethod) {
      case 0:
        return _buildQRCodeMethod();
      case 1:
        return _buildATMMethod();
      case 2:
        return _buildInternationalCardMethod();
      default:
        return _buildQRCodeMethod();
    }
  }

  Widget _buildQRCodeMethod() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ứng dụng mobile quét mã',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // QR Code với logo VNPay ở giữa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _qrData != null
                ? QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                        size: 240,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                          color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  )
                : Container(
                        width: 240,
                        height: 240,
                    color: Colors.grey[200],
                  ),
                // Logo VNPay ở giữa QR
          Container(
                  width: 60,
                  height: 60,
            decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
            ),
                  child: Center(
                    child: Text(
                      'VNPAY',
              style: TextStyle(
                color: vnpayRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
              ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

              const Text(
            'Scan to Pay',
                style: TextStyle(
                  fontSize: 14,
              color: Color(0xFF2196F3),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 24),
          
          TextButton(
            onPressed: () {
              // Hiển thị hướng dẫn
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hướng dẫn thanh toán'),
                  content: const Text(
                    '1. Mở ứng dụng Mobile Banking của ngân hàng\n'
                    '2. Chọn tính năng "Quét mã QR"\n'
                    '3. Quét mã QR trên màn hình\n'
                    '4. Xác nhận thông tin và hoàn tất thanh toán',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
              ),
            ],
          ),
              );
            },
            child: const Text(
              'Hướng dẫn thanh toán?',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2196F3),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildATMMethod() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sử dụng Mobile Banking hỗ trợ VNPAYQR',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Bank logos grid - Chỉ hiển thị icon, không hiển thị tên
          SizedBox(
            height: 300, // Giảm height vì chỉ hiển thị icon
            child: _buildBankLogosGrid(),
          ),
          
        ],
      ),
    );
  }

  Widget _buildInternationalCardMethod() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card logos
          Row(
            children: [
              Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    'VISA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    'MC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Bank selection section - THÊM VÀO
          const Text(
            'Sử dụng Mobile Banking hỗ trợ VNPAYQR',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Bank logos grid - Chỉ hiển thị icon, không hiển thị tên
          SizedBox(
            height: 300,
            child: _buildBankLogosGrid(),
          ),
          
          const SizedBox(height: 24),
          
          // Form thẻ quốc tế - Thiết kế lại
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue[600], size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Thông tin thẻ quốc tế',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Card number
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Số thẻ',
                    hintText: '1234 5678 9012 3456',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                    ),
                    prefixIcon: Icon(Icons.credit_card, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Ngày hết hạn',
                          hintText: 'MM/YY',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'CVV/CVC',
                          hintText: '123',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Tên chủ thẻ',
                    hintText: 'NGUYEN VAN A',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
                width: double.infinity,
            height: 50,
                child: ElevatedButton(
              onPressed: () {
                _openWebViewPayment();
              },
                  style: ElevatedButton.styleFrom(
                backgroundColor: vnpayRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'THANH TOÁN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodePanel() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Ứng dụng mobile quét mã',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // QR Code với logo VNPay ở giữa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
                    children: [
                _qrData != null
                    ? QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      )
                    : Container(
                        width: 240,
                        height: 240,
                        color: Colors.grey[200],
                      ),
                // Logo VNPay ở giữa QR
                      Container(
                  width: 60,
                  height: 60,
                        decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'VNPAY',
                      style: TextStyle(
                        color: vnpayRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
                      const Text(
            'Scan to Pay',
                        style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2196F3), // Light blue
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Thanh toán trực tuyến',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(widget.amount),
            style: const TextStyle(
              fontSize: 24,
                          fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 24),
          
          TextButton(
            onPressed: () {
              // Hiển thị hướng dẫn
            },
            child: const Text(
              'Hướng dẫn thanh toán?',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2196F3),
                decoration: TextDecoration.underline,
                  ),
                ),
              ),
          
          const SizedBox(height: 16),
          
          // Separator với "Hoặc"
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Hoặc',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context, {'success': false, 'reason': 'user_cancelled'});
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'HỦY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankListPanel() {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 16, bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sử dụng Mobile Banking hỗ trợ VNPAYQR',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Bank logos grid - Chỉ hiển thị icon, không hiển thị tên
          SizedBox(
            height: 300, // Giảm height vì chỉ hiển thị icon
            child: _buildBankLogosGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildBankLogosGrid() {
    final banks = _getBankListWithLogos();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2, // Chỉ hiển thị icon nên tỷ lệ khác
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: banks.length,
      itemBuilder: (context, index) {
        final bank = banks[index];
        final isSelected = _selectedBankCode == bank['code'];
    
        return InkWell(
          onTap: () => _selectBank(bank['name']!, bank['code']!),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? vnpayRed.withOpacity(0.05) : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? vnpayRed : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bank['color'] as Color? ?? Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    bank['icon'] as String? ?? '🏦',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getBankListWithLogos() {
    return [
      {'name': 'Vietcombank', 'code': 'VIETCOMBANK', 'icon': 'VCB', 'color': Colors.green},
      {'name': 'Vietinbank', 'code': 'VIETINBANK', 'icon': 'VTB', 'color': Colors.blue},
      {'name': 'BIDV', 'code': 'BIDV', 'icon': 'BIDV', 'color': Colors.blue[700]},
      {'name': 'Agribank', 'code': 'AGRIBANK', 'icon': 'AGB', 'color': Colors.green[700]},
      {'name': 'Techcombank', 'code': 'TECHCOMBANK', 'icon': 'TCB', 'color': Colors.orange},
      {'name': 'ACB', 'code': 'ACB', 'icon': 'ACB', 'color': Colors.red},
      {'name': 'VPBank', 'code': 'VPBANK', 'icon': 'VPB', 'color': Colors.green},
      {'name': 'MB', 'code': 'MBBANK', 'icon': 'MB', 'color': Colors.red},
      {'name': 'TPBank', 'code': 'TPBANK', 'icon': 'TPB', 'color': Colors.purple},
      {'name': 'Sacombank', 'code': 'SACOMBANK', 'icon': 'STB', 'color': Colors.red[700]},
      {'name': 'HDBank', 'code': 'HDBANK', 'icon': 'HDB', 'color': Colors.orange[700]},
      {'name': 'VIB', 'code': 'VIB', 'icon': 'VIB', 'color': Colors.red[600]},
      {'name': 'SHB', 'code': 'SHB', 'icon': 'SHB', 'color': Colors.orange[800]},
      {'name': 'OCB', 'code': 'OCB', 'icon': 'OCB', 'color': Colors.orange},
      {'name': 'MSB', 'code': 'MSB', 'icon': 'MSB', 'color': Colors.red},
      {'name': 'SCB', 'code': 'SCB', 'icon': 'SCB', 'color': Colors.red[700]},
      {'name': 'SeABank', 'code': 'SEABANK', 'icon': 'SEA', 'color': Colors.blue},
      {'name': 'PVcomBank', 'code': 'PVCOMBANK', 'icon': 'PVB', 'color': Colors.orange},
    ];
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Phát triển bởi VNPAY © 2024',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 10, color: Colors.blue[700]),
                      const SizedBox(width: 3),
                      Text(
                        'secure',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Trustwave',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: vnpayRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('VNPay', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Hủy thanh toán?'),
                content: const Text('Bạn có chắc muốn hủy giao dịch thanh toán?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Không'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, {'success': false, 'reason': 'user_cancelled'});
                    },
                    child: const Text('Hủy thanh toán', style: TextStyle(color: vnpayRed)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }

  String _getErrorMessage(String? responseCode) {
    switch (responseCode) {
      case '07':
        return 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường)';
      case '09':
        return 'Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking';
      case '10':
        return 'Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần';
      case '11':
        return 'Đã hết hạn chờ thanh toán. Xin vui lòng thực hiện lại giao dịch';
      case '12':
        return 'Thẻ/Tài khoản bị khóa';
      case '51':
        return 'Tài khoản không đủ số dư để thực hiện giao dịch';
      case '65':
        return 'Tài khoản đã vượt quá hạn mức giao dịch trong ngày';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì';
      case '79':
        return 'Nhập sai mật khẩu thanh toán quá số lần quy định';
      default:
        return 'Giao dịch không thành công. Vui lòng thử lại';
    }
  }
}


