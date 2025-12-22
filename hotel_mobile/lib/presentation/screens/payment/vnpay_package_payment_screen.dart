/**
 * Màn hình thanh toán VNPay sử dụng package vnpay_payment_flutter
 * 
 * Dựa trên package: https://pub.dev/packages/vnpay_payment_flutter
 * Và tài liệu VNPay: https://sandbox.vnpayment.vn/apis/
 * 
 * Tính năng:
 * - Tạo payment URL với HMAC-SHA512 signature tự động
 * - Mở trình duyệt để thanh toán
 * - Xử lý deep link callback tự động
 * - Verify signature từ VNPay response
 * - Hiển thị kết quả thanh toán
 */

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../data/services/vnpay_package_service.dart';
import '../../../data/services/booking_history_service.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/backend_auth_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/config/payment_config.dart';
import 'vnpay_payment_result_screen.dart';

class VNPayPackagePaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;
  final String orderInfo;
  
  // Thông tin booking
  final Hotel hotel;
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int nights;
  final String userName;
  final String userEmail;
  final String userPhone;
  final int roomCount;
  final bool useDeposit;
  final double depositAmount;
  final double fullTotal;

  const VNPayPackagePaymentScreen({
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
    this.roomCount = 1,
    this.useDeposit = false,
    this.depositAmount = 0,
    this.fullTotal = 0,
  }) : super(key: key);

  @override
  State<VNPayPackagePaymentScreen> createState() => _VNPayPackagePaymentScreenState();
}

class _VNPayPackagePaymentScreenState extends State<VNPayPackagePaymentScreen> with WidgetsBindingObserver {
  final VNPayPackageService _vnpayService = VNPayPackageService();
  final BackendAuthService _backendAuthService = BackendAuthService();
  final AuthService _authService = AuthService();
  final BookingHistoryService _bookingService = BookingHistoryService();
  late final AppLinks _appLinks;
  
  bool _isLoading = true;
  String? _errorMessage;
  String? _orderId;
  bool _isProcessing = false;
  StreamSubscription<Uri>? _deepLinkSubscription;
  Timer? _pollingTimer;
  bool _isPolling = false;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 40; // 40 lần x 3 giây = 2 phút
  static const Duration _pollingInterval = Duration(seconds: 3); // Giảm xuống 3 giây để phát hiện nhanh hơn
  static const Duration _initialPollingDelay = Duration(seconds: 3); // Bắt đầu sau 3 giây thay vì 5 giây

  // VNPay colors
  static const Color vnpayRed = Color(0xFFED1C24);
  static const Color vnpayOrange = Color(0xFFFF6B00);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAppLinks();
    _createPaymentUrl();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    
    print('🔗 VNPay Package: Initializing AppLinks...');
    
    // Kiểm tra initial link khi app khởi động
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print('📥 VNPay Package: Initial link on startup: $uri');
        if (uri.scheme == 'vnpaypayment' && uri.host == 'return') {
          print('✅ VNPay Package: Processing initial link on startup...');
          // Delay một chút để đảm bảo widget đã sẵn sàng
          Future.delayed(const Duration(milliseconds: 500), () {
            _handlePaymentReturn(uri);
          });
        }
      }
    }).catchError((error) {
      print('❌ VNPay Package: Error getting initial link: $error');
    });
    
    // Lắng nghe deep link khi app đang chạy
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('📥 VNPay Package: Deeplink received via stream: $uri');
        print('📥 VNPay Package: Scheme: ${uri.scheme}, Host: ${uri.host}');
        if (uri.scheme == 'vnpaypayment' && uri.host == 'return') {
          print('✅ VNPay Package: Processing deep link from stream...');
          _handlePaymentReturn(uri);
        } else {
          print('⚠️ VNPay Package: Deep link không khớp (scheme=${uri.scheme}, host=${uri.host})');
        }
      },
      onError: (err) {
        print('❌ VNPay Package: Deeplink stream error: $err');
      },
    );
    
    print('✅ VNPay Package: AppLinks initialized');
  }

  Future<void> _createPaymentUrl() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔄 VNPay Package: Bắt đầu tạo payment URL...');
      print('📋 VNPay Package: bookingId=${widget.bookingId}, amount=${widget.amount}');

      // Chuẩn bị booking data với đầy đủ thông tin
      final totalAmount = widget.useDeposit ? widget.fullTotal : widget.amount;
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
        'roomCount': widget.roomCount,
        'nights': widget.nights,
        'roomPrice': widget.room.giaPhong ?? 0,
        'totalAmount': totalAmount,
        'depositAmount': widget.useDeposit ? widget.depositAmount : 0,
        'paidAmount': widget.amount,
        'remainingAmount': widget.useDeposit ? (totalAmount - widget.depositAmount) : 0,
        'discountAmount': 0,
        'finalPrice': widget.amount,
        'totalPrice': totalAmount,
        'requiresDeposit': widget.useDeposit,
        'depositPercentage': widget.useDeposit ? 50 : 0,
        'cancellationAllowed': true,
      };
      
      // Lấy userId từ auth service
      final user = _authService.currentUser;
      if (user != null && user.id != null) {
        bookingData['userId'] = user.id;
      }
      
      print('📤 VNPay Package: Gọi service tạo payment URL...');
      final paymentResult = await _vnpayService.createPaymentUrl(
        bookingId: widget.bookingId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
        bookingData: bookingData,
      );

      final paymentUrl = paymentResult['paymentUrl'];
      _orderId = paymentResult['orderId'];

      print('✅ VNPay Package: Nhận được payment URL');
      print('📋 VNPay Package: Order ID: $_orderId');

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('Payment URL rỗng');
      }

      // Mở payment URL trong trình duyệt
      await _vnpayService.launchPaymentUrl(paymentUrl);
      
      // Bắt đầu polling payment status sau 5 giây
      _startPollingPaymentStatus();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ VNPay Package: Lỗi tạo payment URL: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _handlePaymentReturn(Uri uri) {
    if (_isProcessing) {
      print('⚠️ VNPay Package: Đang xử lý payment return, bỏ qua...');
      return;
    }
    
    // Stop polling khi đã nhận được callback
    _stopPolling();
    
    _isProcessing = true;
    
    print('📥 VNPay Package: Xử lý payment return...');
    print('📥 VNPay Package: URI: $uri');
    print('📥 VNPay Package: Scheme: ${uri.scheme}, Host: ${uri.host}');
    print('📥 VNPay Package: Query params: ${uri.queryParameters}');
    
    // Xử lý payment return
    final result = _vnpayService.handlePaymentReturn(uri);
    
    if (result == null) {
      print('⚠️ VNPay Package: Không thể xử lý payment return');
      _showError('Không thể xử lý kết quả thanh toán. Vui lòng thử lại.');
      _isProcessing = false;
      return;
    }
    
    final isSuccess = result['success'] == true;
    final message = result['message'] ?? 'Không xác định';
    final transactionNo = result['transactionNo'];
    final amount = result['amount'];
    final responseCode = result['responseCode'];
    
    print('📋 VNPay Package: Payment result:');
    print('   Success: $isSuccess');
    print('   Message: $message');
    print('   Transaction No: $transactionNo');
    print('   Amount: $amount');
    print('   Response Code: $responseCode');
    
    if (!mounted) {
      print('⚠️ VNPay Package: Widget not mounted, cannot navigate');
      _isProcessing = false;
      return;
    }
    
    // Navigate to result screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VNPayPaymentResultScreen(
          isSuccess: isSuccess,
          transactionNo: transactionNo,
          orderId: _orderId,
          amount: amount != null ? amount.toDouble() : widget.amount,
          message: message,
          errorCode: isSuccess ? null : responseCode,
          paymentTime: DateTime.now(),
        ),
      ),
    );
    
    _isProcessing = false;
  }
  
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('📱 VNPay Package: App lifecycle changed: $state');
    
    // Khi app quay lại từ background (sau khi thanh toán)
    if (state == AppLifecycleState.resumed) {
      print('📱 VNPay Package: App resumed, kiểm tra payment status ngay lập tức...');
      
      // Check payment status ngay khi app resume (không chờ deep link)
      if (_orderId != null && _orderId!.isNotEmpty && !_isProcessing) {
        print('🔍 VNPay Package: App resumed, checking payment status immediately...');
        // Check ngay lập tức, không chờ
        _checkPaymentStatusFromBackend();
      }
      
      // Kiểm tra deep link khi app resume
      _appLinks.getInitialLink().then((uri) {
        if (uri != null) {
          print('📥 VNPay Package: Initial link on resume: $uri');
          if (uri.scheme == 'vnpaypayment' && uri.host == 'return') {
            print('✅ VNPay Package: Processing initial link on resume...');
            _handlePaymentReturn(uri);
            return; // Đã xử lý deep link
          } else {
            print('⚠️ VNPay Package: Initial link không khớp (scheme=${uri.scheme}, host=${uri.host})');
          }
        } else {
          print('⚠️ VNPay Package: No initial link found on resume');
        }
        
        // Nếu không có deep link và polling chưa chạy, bắt đầu polling
        if (_orderId != null && _orderId!.isNotEmpty && !_isPolling && !_isProcessing) {
          print('🔍 VNPay Package: No deep link, starting polling...');
          _startPollingPaymentStatus();
        } else if (_orderId != null && _orderId!.isNotEmpty && _isPolling) {
          print('ℹ️ VNPay Package: Polling đã chạy, không cần check lại');
        }
      }).catchError((error) {
        print('❌ VNPay Package: Error checking deep link on resume: $error');
        // Vẫn thử start polling nếu có orderId và chưa polling
        if (_orderId != null && _orderId!.isNotEmpty && !_isPolling && !_isProcessing) {
          _startPollingPaymentStatus();
        }
      });
    }
  }
  
  /// Bắt đầu polling payment status
  void _startPollingPaymentStatus() {
    if (_orderId == null || _orderId!.isEmpty || _isPolling) {
      return;
    }
    
    _isPolling = true;
    _pollingAttempts = 0;
    
    print('🔄 VNPay Package: Bắt đầu polling payment status...');
    print('📋 VNPay Package: Order ID: $_orderId');
    print('⏱️ VNPay Package: Polling interval: ${_pollingInterval.inSeconds}s');
    print('⏱️ VNPay Package: Initial delay: ${_initialPollingDelay.inSeconds}s');
    print('📊 VNPay Package: Max attempts: $_maxPollingAttempts');
    
    // Bắt đầu polling sau 3 giây đầu tiên (nhanh hơn)
    _pollingTimer = Timer(_initialPollingDelay, () {
      _pollPaymentStatus();
    });
  }
  
  /// Dừng polling payment status
  void _stopPolling() {
    if (_pollingTimer != null) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
    _isPolling = false;
    _pollingAttempts = 0;
    print('🛑 VNPay Package: Đã dừng polling payment status');
  }
  
  /// Poll payment status từ backend
  void _pollPaymentStatus() {
    if (_orderId == null || _orderId!.isEmpty || _isProcessing || !_isPolling) {
      return;
    }
    
    _pollingAttempts++;
    print('🔍 VNPay Package: Polling attempt $_pollingAttempts/$_maxPollingAttempts');
    
    _checkPaymentStatusFromBackend().then((_) {
      // Nếu chưa có kết quả và chưa đạt max attempts, tiếp tục polling
      if (_isPolling && _pollingAttempts < _maxPollingAttempts && !_isProcessing) {
        _pollingTimer = Timer(_pollingInterval, () {
          _pollPaymentStatus();
        });
      } else if (_pollingAttempts >= _maxPollingAttempts) {
        print('⏰ VNPay Package: Đã đạt max polling attempts, dừng polling');
        _stopPolling();
        if (mounted && !_isProcessing) {
          // Hiển thị thông báo cho user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang chờ kết quả thanh toán. Vui lòng kiểm tra lại sau hoặc liên hệ hỗ trợ.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }).catchError((error) {
      print('❌ VNPay Package: Error trong polling: $error');
      // Tiếp tục polling nếu chưa đạt max attempts
      if (_isPolling && _pollingAttempts < _maxPollingAttempts && !_isProcessing) {
        _pollingTimer = Timer(_pollingInterval, () {
          _pollPaymentStatus();
        });
      }
    });
  }
  
  /// Kiểm tra payment status từ backend nếu không nhận được deep link
  Future<void> _checkPaymentStatusFromBackend() async {
    if (_orderId == null || _orderId!.isEmpty || _isProcessing) {
      return;
    }
    
    try {
      print('🔍 VNPay Package: Checking payment status for order: $_orderId');
      final status = await _vnpayService.getPaymentStatus(_orderId!);
      
      if (status != null && status['success'] == true) {
        print('✅ VNPay Package: Payment completed (from backend check)');
        _stopPolling();
        if (!mounted) return;
        
        _isProcessing = true;
        
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VNPayPaymentResultScreen(
              isSuccess: true,
              transactionNo: status['transactionNo'],
              orderId: _orderId,
              amount: status['amount']?.toDouble() ?? widget.amount,
              message: status['responseMessage'] ?? 'Thanh toán thành công',
              paymentTime: status['paidAt'] != null 
                  ? DateTime.parse(status['paidAt'])
                  : DateTime.now(),
            ),
          ),
        );
      } else if (status != null && status['status'] == 'failed') {
        print('❌ VNPay Package: Payment failed (from backend check)');
        _stopPolling();
        if (!mounted) return;
        
        _isProcessing = true;
        
        // Navigate to error screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VNPayPaymentResultScreen(
              isSuccess: false,
              orderId: _orderId,
              amount: widget.amount,
              message: status['responseMessage'] ?? 'Thanh toán thất bại',
              errorCode: status['responseCode'],
              paymentTime: DateTime.now(),
            ),
          ),
        );
      } else {
        print('ℹ️ VNPay Package: Payment still pending or not found');
      }
    } catch (e) {
      print('❌ VNPay Package: Error checking payment status: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red[300]!, width: 3),
                    ),
                    child: Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lỗi thanh toán',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vnpayRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Quay lại',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : _buildPaymentWaitingView(),
    );
  }

  /// Xây dựng AppBar với header VNPay
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: vnpayRed,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'VNPAY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CỔNG THANH TOÁN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'VNPAYQR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                  child: const Text(
                    'Hủy thanh toán',
                    style: TextStyle(color: vnpayRed, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Xây dựng màn hình loading
  Widget _buildLoadingView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Thông tin đơn hàng
          _buildOrderInfo(),
          
          const SizedBox(height: 40),
          
          // Loading indicator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: vnpayRed,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  'Đang tạo mã thanh toán...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng đợi trong giây lát',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Xây dựng màn hình chờ thanh toán
  Widget _buildPaymentWaitingView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Thông tin đơn hàng
          _buildOrderInfo(),
          
          const SizedBox(height: 40),
          
          // Thông báo đã mở trình duyệt
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: vnpayRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payment,
                          size: 40,
                          color: vnpayRed,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isPolling ? 'Đang kiểm tra kết quả thanh toán...' : 'Đã mở trình duyệt thanh toán',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (_isPolling) ...[
                        const CircularProgressIndicator(
                          color: vnpayRed,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tự động kiểm tra kết quả thanh toán...\n'
                          'Vui lòng đợi trong giây lát.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Vui lòng hoàn tất thanh toán trong trình duyệt.\n'
                          'Sau khi thanh toán xong, ứng dụng sẽ tự động quay lại.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Nếu trình duyệt không tự động mở, vui lòng nhấn nút "Mở lại trang thanh toán" bên dưới.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      // Chuẩn bị booking data
                      final totalAmount = widget.useDeposit ? widget.fullTotal : widget.amount;
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
                        'roomCount': widget.roomCount,
                        'nights': widget.nights,
                        'roomPrice': widget.room.giaPhong ?? 0,
                        'totalAmount': totalAmount,
                        'depositAmount': widget.useDeposit ? widget.depositAmount : 0,
                        'paidAmount': widget.amount,
                        'remainingAmount': widget.useDeposit ? (totalAmount - widget.depositAmount) : 0,
                        'discountAmount': 0,
                        'finalPrice': widget.amount,
                        'totalPrice': totalAmount,
                        'requiresDeposit': widget.useDeposit,
                        'depositPercentage': widget.useDeposit ? 50 : 0,
                        'cancellationAllowed': true,
                      };
                      
                      final user = _authService.currentUser;
                      if (user != null && user.id != null) {
                        bookingData['userId'] = user.id;
                      }
                      
                      final paymentResult = await _vnpayService.createPaymentUrl(
                        bookingId: widget.bookingId,
                        amount: widget.amount,
                        orderInfo: widget.orderInfo,
                        bookingData: bookingData,
                      );
                      
                      await _vnpayService.launchPaymentUrl(paymentResult['paymentUrl']);
                      
                      setState(() {
                        _isLoading = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã mở lại trang thanh toán'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Mở lại trang thanh toán'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vnpayRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Xây dựng card thông tin đơn hàng
  Widget _buildOrderInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: vnpayRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: vnpayRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông tin đơn hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Khách sạn', widget.hotel.ten),
          const SizedBox(height: 12),
          _buildInfoRow('Phòng', widget.room.soPhong ?? 'N/A'),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Ngày nhận phòng',
            '${DateFormat('dd/MM/yyyy').format(widget.checkInDate)}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Ngày trả phòng',
            '${DateFormat('dd/MM/yyyy').format(widget.checkOutDate)}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Số đêm', '${widget.nights} đêm'),
          const SizedBox(height: 12),
          _buildInfoRow('Số khách', '${widget.guestCount} người'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                CurrencyFormatter.format(widget.amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: vnpayRed,
                ),
              ),
            ],
          ),
          if (widget.useDeposit) ...[
            const SizedBox(height: 8),
            Text(
              'Số tiền còn lại: ${CurrencyFormatter.format(widget.fullTotal - widget.depositAmount)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Xây dựng một hàng thông tin
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

