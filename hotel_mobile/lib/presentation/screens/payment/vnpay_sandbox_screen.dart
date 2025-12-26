/**
 * Màn hình thanh toán VNPay Sandbox - Giao diện mới đơn giản
 * 
 * Theo thiết kế VNPay Sandbox chính thức:
 * - Giao diện đơn giản, clean
 * - Mở WebView trực tiếp đến VNPay Sandbox
 * - Xử lý callback tự động
 */

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/vnpay_service.dart';
import '../../../data/services/booking_history_service.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../core/services/vnpay_signature_service.dart';
import '../../../core/config/payment_config.dart';
import 'vnpay_payment_result_screen.dart';

class VNPaySandboxScreen extends StatefulWidget {
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

  const VNPaySandboxScreen({
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
  State<VNPaySandboxScreen> createState() => _VNPaySandboxScreenState();
}

class _VNPaySandboxScreenState extends State<VNPaySandboxScreen> {
  final VNPayService _vnpayService = VNPayService();
  final BackendAuthService _authService = BackendAuthService();
  final BookingHistoryService _bookingService = BookingHistoryService();
  
  // VNPay Signature Service để verify response
  late final VNPaySignatureService _signatureService = VNPaySignatureService(
    hashSecret: PaymentConfig.vnpayHashSecret,
  );
  
  bool _isLoading = true;
  String? _paymentUrl;
  String? _errorMessage;
  WebViewController? _webViewController;
  String? _orderId;
  bool _isProcessing = false; // Tránh xử lý trùng khi detect URL nhiều lần

  // VNPay colors (từ PaymentConfig)
  static const Color vnpayRed = Color(0xFFED1C24);
  static const Color vnpayOrange = Color(0xFFFF6B00);

  @override
  void initState() {
    super.initState();
    _createPaymentUrl();
  }

  Future<void> _createPaymentUrl() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔄 VNPay: Bắt đầu tạo payment URL trực tiếp từ Flutter...');
      print('📋 VNPay: bookingId=${widget.bookingId}, amount=${widget.amount}');

      // Chuẩn bị booking data với đầy đủ thông tin (để lưu vào backend)
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
        'totalAmount': totalAmount, // Tổng giá trị đầy đủ
        'depositAmount': widget.useDeposit ? widget.depositAmount : 0,
        'paidAmount': widget.amount, // Số tiền đã thanh toán (có thể là cọc hoặc toàn bộ)
        'remainingAmount': widget.useDeposit ? (totalAmount - widget.depositAmount) : 0,
        'discountAmount': 0,
        'finalPrice': widget.amount, // Giữ lại để tương thích
        'totalPrice': totalAmount, // Tổng giá trị
        'requiresDeposit': widget.useDeposit,
        'depositPercentage': widget.useDeposit ? 50 : 0,
        'cancellationAllowed': true,
      };
      
      print('📤 VNPay: Gọi API createPaymentUrl...');
      final paymentResult = await _vnpayService.createPaymentUrl(
        bookingId: widget.bookingId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
        bookingData: bookingData,
      );

      final paymentUrl = paymentResult['paymentUrl'];
      _orderId = paymentResult['orderId'];

      print('✅ VNPay: Nhận được payment URL: ${paymentUrl?.substring(0, 100) ?? 'null'}...');
      print('📋 VNPay: Order ID: $_orderId');

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('Payment URL rỗng');
      }

      // Fallback orderId nếu backend không trả về
      if (_orderId == null || _orderId!.isEmpty) {
        _orderId = 'BOOKING_${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}';
        print('📋 VNPay: Fallback Order ID: $_orderId');
      }

      // Initialize WebView trước
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              print('🔗 VNPay: Navigation request to: ${request.url}');
              return _handleNavigationRequest(request);
            },
            onPageStarted: (String url) {
              print('📄 VNPay: Page started: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false; // Dừng loading khi page bắt đầu load
                });
              }
              
              // Check VNPay error page (code 71 = Website chưa được phê duyệt)
              if (url.contains('Payment/Error.html') || url.contains('code=71')) {
                print('❌ VNPay Error detected in onPageStarted: Website chưa được phê duyệt (code 71)');
                if (!_isProcessing) {
                  _isProcessing = true;
                  _handleVNPayError71();
                }
                return;
              }
              
              _handleNavigationUrl(url);
            },
            onPageFinished: (String url) {
              print('✅ VNPay: Page finished: $url');
              
              // Check VNPay error page (code 71 = Website chưa được phê duyệt)
              if (url.contains('Payment/Error.html') || url.contains('code=71')) {
                print('❌ VNPay Error detected in onPageFinished: Website chưa được phê duyệt (code 71)');
                if (!_isProcessing) {
                  _isProcessing = true;
                  _handleVNPayError71();
                }
                return;
              }
              
              _handleNavigationUrl(url);
            },
            onWebResourceError: (WebResourceError error) {
              print('❌ VNPay: WebView error: ${error.description}');
              if (mounted) {
                setState(() {
                  _errorMessage = 'Lỗi tải trang: ${error.description}';
                  _isLoading = false;
                });
              }
            },
          ),
        );

      // Set state với payment URL và load ngay
      setState(() {
        _paymentUrl = paymentUrl;
        _isLoading = true; // Vẫn loading cho đến khi page started
      });

      print('🌐 VNPay: Loading payment URL vào WebView...');
      // Load payment URL ngay lập tức
      await _webViewController!.loadRequest(Uri.parse(paymentUrl));
      print('✅ VNPay: Payment URL đã được load vào WebView');
    } catch (e, stackTrace) {
      print('❌ VNPay: Lỗi tạo payment URL: $e');
      print('❌ VNPay: Stack trace: $stackTrace');
      
      // Xử lý error message để hiển thị rõ ràng hơn
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
      // Nếu error liên quan đến localhost, format message đẹp hơn
      if (errorMsg.contains('localhost') || errorMsg.contains('127.0.0.1') || errorMsg.contains('Return URL')) {
        errorMsg = 'VNPay Sandbox không chấp nhận localhost làm Return URL.\n\n'
            'Vui lòng:\n'
            '1. Kiểm tra file .env của backend có VNP_RETURN_URL với public URL\n'
            '2. Restart backend server sau khi cập nhật .env\n'
            '3. Ví dụ: VNP_RETURN_URL=http://118.71.17.228:5000/api/payment/vnpay-return';
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
      if (mounted) {
        setState(() {
          String errorMsg = e.toString().replaceAll('Exception: ', '');
          
          // Xử lý các loại lỗi khác nhau
          if (errorMsg.contains('SocketException') || errorMsg.contains('Failed host lookup')) {
            errorMsg = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
          } else if (errorMsg.contains('TimeoutException')) {
            errorMsg = 'Kết nối quá thời gian. Vui lòng thử lại.';
          } else if (errorMsg.contains('localhost') || errorMsg.contains('VNP_RETURN_URL')) {
            // Giữ nguyên message từ server về localhost
            // Message đã được format đúng từ backend
          }
          
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  /// Xử lý navigation request từ WebView
  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url;
    print('🔗 Navigation Request: $url');
    
    // ✅ FIX: Check deep link schemes (vnpaypayment:// or banktransfer://)
    if (url.startsWith('vnpaypayment://') || url.startsWith('banktransfer://')) {
      print('✅ Deep link detected in WebView: $url');
      try {
        // Parse deep link và extract params
        _handleNavigationUrl(url);
      } catch (e) {
        print('❌ Error parsing deep link: $e');
      }
      return NavigationDecision.prevent; // Prevent WebView from loading deep link
    }
    
    // Check VNPay error page (code 71 = Website chưa được phê duyệt)
    if (url.contains('Payment/Error.html') || url.contains('code=71')) {
      print('❌ VNPay Error detected: Website chưa được phê duyệt (code 71)');
      if (!_isProcessing && mounted) {
        _isProcessing = true;
        _handleVNPayError71();
      }
      return NavigationDecision.prevent; // Không cho load error page
    }
    
    // Check return URL từ VNPay or Bank Transfer (backend return URL)
    // Backend trả về: /api/payment/vnpay-return?vnp_ResponseCode=00&...
    // hoặc: /api/bank-transfer/return?orderId=...&success=...
    if (url.contains('vnpay-return') || url.contains('vnp_ResponseCode') || 
        url.contains('bank-transfer/return')) {
      _handleNavigationUrl(url);
      // Vẫn cho phép navigate để WebView load trang return
      return NavigationDecision.navigate;
    }
    
    return NavigationDecision.navigate;
  }

  void _handleVNPayError71() {
    print('⚠️ VNPay Error 71: Return URL không được phê duyệt');
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Lỗi cấu hình VNPay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VNPay Sandbox không chấp nhận localhost làm Return URL.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Giải pháp:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Backend cần được cấu hình với Return URL công khai (public URL) thay vì localhost.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vui lòng liên hệ admin hoặc kiểm tra cấu hình backend.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close payment screen
              },
              style: TextButton.styleFrom(
                foregroundColor: vnpayRed,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }

  void _handleNavigationUrl(String url) {
    print('🔗 Navigation URL: $url');
    
    // Check nếu URL chứa params từ VNPay return
    // Backend return URL: /api/payment/vnpay-return?vnp_ResponseCode=00&vnp_TransactionNo=...&vnp_TxnRef=...
    // Hoặc URL có chứa vnp_ResponseCode trong query params
    if (url.contains('vnp_ResponseCode') || url.contains('vnpay-return') || url.contains('/api/payment/')) {
      try {
        final uri = Uri.parse(url);
        final params = uri.queryParameters;
        
        // ⚠️ QUAN TRỌNG: Verify signature trước khi xử lý
        final isValidSignature = _signatureService.verifyResponse(
          params.map((key, value) => MapEntry(key, value ?? '')),
        );
        
        if (!isValidSignature) {
          print('❌ VNPay: Signature không hợp lệ - Có thể dữ liệu bị giả mạo!');
          if (!_isProcessing && mounted) {
            _isProcessing = true;
            _showSignatureError();
            return;
          }
        }
        
        final responseCode = params['vnp_ResponseCode'];
        final transactionNo = params['vnp_TransactionNo'];
        final orderId = params['vnp_TxnRef'];
        final amount = params['vnp_Amount'];
        final message = params['vnp_ResponseMessage'];
        
        print('📋 Parsed params - ResponseCode: $responseCode, TransactionNo: $transactionNo, OrderId: $orderId');
        
        // Cập nhật _orderId nếu có từ VNPay
        if (orderId != null && orderId.isNotEmpty) {
          _orderId = orderId;
        }
        
        // Xử lý responseCode (VNPay trả về '00' cho thành công)
        if (VNPaySignatureService.isSuccess(responseCode)) {
          // Thanh toán thành công - chỉ xử lý 1 lần
          if (!_isProcessing) {
            _isProcessing = true;
            final transactionId = transactionNo ?? orderId ?? 'VNP${DateTime.now().millisecondsSinceEpoch}';
            print('✅ Payment success detected, transactionId: $transactionId');
            _handlePaymentSuccess(transactionId);
          }
        } else if (responseCode != null && responseCode.isNotEmpty) {
          // Thanh toán thất bại - chỉ xử lý 1 lần
          if (!_isProcessing) {
            _isProcessing = true;
            print('❌ Payment failed, errorCode: $responseCode');
            final errorMessage = VNPaySignatureService.getResponseMessage(responseCode);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VNPayPaymentResultScreen(
                    isSuccess: false,
                    orderId: _orderId ?? orderId ?? 'UNKNOWN',
                    amount: widget.amount,
                    errorCode: responseCode,
                    message: message ?? errorMessage,
                  ),
                ),
              ).then((_) {
                Navigator.pop(context, {
                  'success': false,
                  'reason': 'payment_failed',
                  'message': message ?? errorMessage,
                  'errorCode': responseCode,
                });
              });
            }
          }
        }
      } catch (e) {
        print('❌ Error parsing return URL: $e');
        // Nếu không parse được, thử detect bằng string matching
        if (url.contains('vnp_ResponseCode=00') || url.contains('vnp_ResponseCode%3D00')) {
          if (!_isProcessing) {
            _isProcessing = true;
            print('✅ Payment success detected (fallback)');
            _handlePaymentSuccess('VNP${DateTime.now().millisecondsSinceEpoch}');
          }
        }
      }
    }
  }

  Future<void> _handlePaymentSuccess(String transactionId) async {
    try {
      print('🎉 Thanh toán thành công!');
      print('📋 Transaction ID: $transactionId');
      print('📋 Order ID: $_orderId');
      
      // Backend đã tự động tạo booking khi thanh toán thành công
      // Chỉ cần navigate đến success screen
      // Nếu cần query booking, có thể gọi API sau

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VNPayPaymentResultScreen(
              isSuccess: true,
              transactionNo: transactionId,
              orderId: _orderId ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
              amount: widget.amount,
              paymentTime: DateTime.now(),
            ),
          ),
        ).then((_) {
          // Return success result về PaymentScreen
          Navigator.pop(context, {
            'success': true,
            'transactionId': transactionId,
            'orderId': _orderId ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
          });
        });
      }
    } catch (e) {
      print('❌ Lỗi xử lý thanh toán thành công: $e');
      // Vẫn hiển thị success screen vì payment đã thành công
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VNPayPaymentResultScreen(
              isSuccess: true,
              transactionNo: transactionId,
              orderId: _orderId ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
              amount: widget.amount,
              paymentTime: DateTime.now(),
            ),
          ),
        ).then((_) {
          Navigator.pop(context, {
            'success': true,
            'transactionId': transactionId,
            'orderId': _orderId ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
            'note': 'Payment successful, but booking creation may have issues',
          });
        });
      }
    }
  }

  String _getErrorMessage(String? responseCode) {
    // Sử dụng VNPaySignatureService để lấy message
    return VNPaySignatureService.getResponseMessage(responseCode);
  }

  /// Hiển thị lỗi signature không hợp lệ
  void _showSignatureError() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lỗi bảo mật',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chữ ký xác thực không hợp lệ.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
            ),
            SizedBox(height: 12),
            Text(
              'Dữ liệu thanh toán có thể bị giả mạo. Vui lòng liên hệ admin để kiểm tra.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment screen
            },
            style: TextButton.styleFrom(
              foregroundColor: vnpayRed,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Widget helper để hiển thị instruction item
  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: vnpayRed,
          foregroundColor: Colors.white,
          title: const Text('VNPay', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
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
                // Hiển thị hướng dẫn thêm nếu là lỗi localhost
                if (_errorMessage!.contains('localhost') || _errorMessage!.contains('VNP_RETURN_URL'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Hướng dẫn khắc phục',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionItem('1', 'Backend cần được cấu hình với Return URL công khai (public URL)'),
                          const SizedBox(height: 8),
                          _buildInstructionItem('2', 'Kiểm tra file .env trong backend có VNP_RETURN_URL đúng chưa'),
                          const SizedBox(height: 8),
                          _buildInstructionItem('3', 'Đảm bảo Return URL có thể truy cập từ internet'),
                          const SizedBox(height: 8),
                          _buildInstructionItem('4', 'Liên hệ admin để được hỗ trợ cấu hình'),
                        ],
                      ),
                    ),
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
        ),
      );
    }

    if (_isLoading || _paymentUrl == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: vnpayRed,
          foregroundColor: Colors.white,
          title: const Text('VNPay', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: vnpayRed),
              const SizedBox(height: 16),
              const Text(
                'Đang tạo mã thanh toán...',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

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
      body: _isLoading || _webViewController == null || _paymentUrl == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: vnpayRed),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading 
                        ? 'Đang tạo mã thanh toán...'
                        : 'Đang tải trang thanh toán VNPay...',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            )
          : WebViewWidget(controller: _webViewController!),
    );
  }
}
