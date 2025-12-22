/**
 * Màn hình thanh toán MoMo - Giao diện mới giống VNPay
 * 
 * Theo thiết kế MoMo chính thức:
 * - Giao diện đơn giản, clean
 * - Mở WebView trực tiếp đến MoMo
 * - Xử lý callback tự động
 */

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/momo_service.dart';
import '../../../data/services/booking_history_service.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../core/services/backend_auth_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/config/payment_config.dart';
import 'momo_payment_result_screen.dart';

class MoMoPaymentScreen extends StatefulWidget {
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

  const MoMoPaymentScreen({
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
  State<MoMoPaymentScreen> createState() => _MoMoPaymentScreenState();
}

class _MoMoPaymentScreenState extends State<MoMoPaymentScreen> {
  final MoMoService _momoService = MoMoService();
  final BackendAuthService _authService = BackendAuthService();
  final BookingHistoryService _bookingService = BookingHistoryService();
  
  bool _isLoading = true;
  String? _paymentUrl;
  String? _qrCodeUrl;
  String? _deeplink;
  String? _errorMessage;
  WebViewController? _webViewController;
  String? _orderId;
  bool _isProcessing = false; // Tránh xử lý trùng khi detect URL nhiều lần

  // MoMo colors (từ PaymentConfig)
  static const Color momoPink = Color(0xFFD82D8B);
  static const Color momoDarkPink = Color(0xFFB91C72);

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

      print('🔄 MoMo: Bắt đầu tạo payment URL...');
      print('📋 MoMo: bookingId=${widget.bookingId}, amount=${widget.amount}');

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
      
      print('📤 MoMo: Gọi API createPaymentUrl...');
      final paymentResult = await _momoService.createPaymentUrl(
        bookingId: widget.bookingId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
        bookingData: bookingData,
      );

      print('✅ MoMo: Nhận được payment result');
      print('📋 MoMo: paymentUrl=${paymentResult['paymentUrl']?.substring(0, 100) ?? 'null'}...');
      print('📋 MoMo: qrCodeUrl=${paymentResult['qrCodeUrl'] != null ? 'có' : 'không'}');
      print('📋 MoMo: deeplink=${paymentResult['deeplink'] != null ? 'có' : 'không'}');

      if (paymentResult['paymentUrl'] == null || paymentResult['paymentUrl'].toString().isEmpty) {
        throw Exception('Payment URL rỗng từ server');
      }

      // Lấy orderId từ backend response (nếu có)
      _orderId = paymentResult['orderId'] ?? 'BOOK${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}';
      print('📋 MoMo: Order ID: $_orderId');

      // Initialize WebView trước với cấu hình để tránh ERR_BLOCKED_BY_ORB
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              print('🔗 MoMo: Navigation request to: ${request.url}');
              return _handleNavigationRequest(request);
            },
            onPageStarted: (String url) {
              print('📄 MoMo: Page started: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false; // Dừng loading khi page bắt đầu load
                });
              }
              _handleNavigationUrl(url);
            },
            onPageFinished: (String url) {
              print('✅ MoMo: Page finished: $url');
              _handleNavigationUrl(url);
            },
            onWebResourceError: (WebResourceError error) {
              print('❌ MoMo: WebView error: ${error.description}');
              print('❌ MoMo: Error code: ${error.errorCode}');
              print('❌ MoMo: Error type: ${error.errorType}');
              
              // Xử lý lỗi ERR_BLOCKED_BY_ORB - thử mở deeplink thay vì WebView
              if (error.description.contains('ERR_BLOCKED_BY_ORB') || 
                  error.description.contains('BLOCKED_BY_ORB') ||
                  error.errorCode == -3) {
                print('⚠️ MoMo: ERR_BLOCKED_BY_ORB detected, thử mở app MoMo bằng deeplink...');
                if (_deeplink != null && _deeplink!.isNotEmpty) {
                  _openMoMoApp(_deeplink!);
                  return; // Không set error message, đang thử mở app
                }
              }
              
              if (mounted) {
                setState(() {
                  // Cải thiện error message
                  String errorMsg = error.description;
                  if (error.description.contains('ERR_BLOCKED_BY_ORB')) {
                    errorMsg = 'Không thể tải trang thanh toán. Vui lòng thử mở app MoMo hoặc thử lại sau.';
                  } else if (error.description.contains('ERR_INTERNET_DISCONNECTED')) {
                    errorMsg = 'Không có kết nối internet. Vui lòng kiểm tra mạng.';
                  } else if (error.description.contains('ERR_TIMED_OUT')) {
                    errorMsg = 'Kết nối quá thời gian. Vui lòng thử lại.';
                  }
                  _errorMessage = errorMsg;
                  _isLoading = false;
                });
              }
            },
          ),
        );

      // Set state với payment URL
      final paymentUrl = paymentResult['paymentUrl'];
      final qrCodeUrl = paymentResult['qrCodeUrl'];
      final deeplink = paymentResult['deeplink'];
      
      setState(() {
        _paymentUrl = paymentUrl;
        _qrCodeUrl = qrCodeUrl;
        _deeplink = deeplink;
        _isLoading = true; // Vẫn loading cho đến khi page started
      });

      // Load WebView ngay lập tức với payment URL
      if (paymentUrl != null && paymentUrl.toString().isNotEmpty) {
        print('🌐 MoMo: Loading payment URL vào WebView ngay lập tức...');
        print('📋 MoMo Payment URL: ${paymentUrl.toString().substring(0, paymentUrl.toString().length > 100 ? 100 : paymentUrl.toString().length)}...');
        
        // Đảm bảo WebViewController đã được khởi tạo
        if (_webViewController != null) {
          try {
            await _webViewController!.loadRequest(Uri.parse(paymentUrl.toString()));
            print('✅ MoMo: Payment URL đã được load vào WebView');
            // Không set _isLoading = false ở đây, để onPageStarted xử lý
          } catch (e) {
            print('❌ MoMo: Error loading WebView: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Không thể tải trang thanh toán. Vui lòng thử lại.';
                _isLoading = false;
              });
            }
          }
        } else {
          print('⚠️ MoMo: WebViewController chưa sẵn sàng, sẽ retry sau 500ms...');
          // Retry sau khi WebViewController sẵn sàng
          Future.delayed(const Duration(milliseconds: 500), () async {
            if (_webViewController != null && paymentUrl != null && mounted) {
              try {
                await _webViewController!.loadRequest(Uri.parse(paymentUrl.toString()));
                print('✅ MoMo: Payment URL đã được load vào WebView (retry)');
              } catch (e) {
                print('❌ MoMo: Error loading WebView (retry): $e');
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Không thể tải trang thanh toán. Vui lòng thử lại.';
                    _isLoading = false;
                  });
                }
              }
            }
          });
        }
      } else {
        print('❌ MoMo: Không có payment URL để load');
        if (mounted) {
          setState(() {
            _errorMessage = 'Không có payment URL. Vui lòng thử lại.';
            _isLoading = false;
          });
        }
      }

      // Thử mở app MoMo bằng deeplink song song (không block WebView)
      if (deeplink != null && deeplink.toString().isNotEmpty) {
        print('🔗 MoMo: Thử mở app MoMo bằng deeplink (song song với WebView)...');
        print('📋 MoMo Deeplink: $deeplink');
        
        // Chạy async không block
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            final uri = Uri.tryParse(deeplink.toString());
            if (uri != null) {
              final canLaunch = await canLaunchUrl(uri);
              print('📋 MoMo: Can launch deeplink: $canLaunch');
              
              if (canLaunch) {
                final launched = await launchUrl(
                  uri, 
                  mode: LaunchMode.externalApplication,
                );
                print('📋 MoMo: Launch deeplink result: $launched');
                
                if (launched) {
                  print('✅ Đã mở app MoMo thành công bằng deeplink');
                  // Nếu mở được app, có thể dừng WebView (nhưng không bắt buộc)
                  // App MoMo sẽ xử lý và quay lại app khi thanh toán xong
                }
              }
            }
          } catch (e) {
            print('⚠️ MoMo: Error opening deeplink: $e (WebView vẫn đang chạy)');
          }
        });
      }

    } catch (e, stackTrace) {
      print('❌ MoMo: Lỗi tạo payment URL: $e');
      print('❌ MoMo: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          String errorMsg = e.toString().replaceAll('Exception: ', '');
          
          // Xử lý các loại lỗi khác nhau
          if (errorMsg.contains('SocketException') || errorMsg.contains('Failed host lookup')) {
            errorMsg = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
          } else if (errorMsg.contains('TimeoutException')) {
            errorMsg = 'Kết nối quá thời gian. Vui lòng thử lại.';
          } else if (errorMsg.contains('localhost') || errorMsg.contains('MOMO_RETURN_URL')) {
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
    
    // Nếu URL là deeplink momo://, thử mở app MoMo
    if (url.startsWith('momo://')) {
      _openMoMoApp(url);
      return NavigationDecision.prevent; // Không cho WebView load URL này
    }
    
    // Check return URL từ MoMo (backend return URL)
    // Backend trả về: /api/payment/momo-return?resultCode=0&...
    if (url.contains('momo-return') || url.contains('resultCode')) {
      _handleNavigationUrl(url);
      // Vẫn cho phép navigate để WebView load trang return
      return NavigationDecision.navigate;
    }
    
    return NavigationDecision.navigate;
  }

  /// Thử mở app MoMo bằng deeplink
  Future<void> _openMoMoApp(String deeplink) async {
    try {
      // Fix malformed URL - extract clean deeplink nếu có
      String cleanDeeplink = deeplink;
      
      // Nếu URL chứa web URL trong deeplink (malformed), chỉ lấy phần momo://
      if (deeplink.contains('momo://') && deeplink.contains('http')) {
        // Tìm vị trí của momo:// và extract
        final momoIndex = deeplink.indexOf('momo://');
        if (momoIndex != -1) {
          // Tìm vị trí của http trong URL (thường là sau serviceType)
          final httpIndex = deeplink.indexOf('http', momoIndex);
          if (httpIndex != -1) {
            // Lấy phần momo:// đến trước http
            cleanDeeplink = deeplink.substring(momoIndex, httpIndex);
            // Thêm phần sau nếu cần
            if (cleanDeeplink.endsWith('&') || cleanDeeplink.endsWith('?')) {
              cleanDeeplink = cleanDeeplink.substring(0, cleanDeeplink.length - 1);
            }
          }
        }
      }
      
      print('🔗 Clean deeplink: $cleanDeeplink');
      
      final uri = Uri.tryParse(cleanDeeplink);
      if (uri != null && await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          print('✅ Đã mở app MoMo thành công');
          // Hiển thị thông báo cho user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã mở app MoMo. Vui lòng hoàn tất thanh toán trong app.'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
            // Đợi một chút rồi đóng màn hình (app MoMo sẽ tự động quay lại khi thanh toán xong)
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context, {
                  'success': false,
                  'reason': 'opened_momo_app',
                  'message': 'Đã mở app MoMo. Vui lòng hoàn tất thanh toán.',
                });
              }
            });
          }
          return;
        }
      }
      
      // Fallback: Nếu không mở được app, thử load WebView với payUrl gốc
      print('⚠️ MoMo: Không thể mở app MoMo, fallback về WebView với payUrl');
      if (mounted && _paymentUrl != null && _paymentUrl!.isNotEmpty) {
        print('🌐 MoMo: Loading payUrl vào WebView: ${_paymentUrl!.substring(0, _paymentUrl!.length > 100 ? 100 : _paymentUrl!.length)}...');
        if (_webViewController != null) {
          try {
            await _webViewController!.loadRequest(Uri.parse(_paymentUrl!));
            print('✅ MoMo: PayUrl đã được load vào WebView');
            setState(() {
              _isLoading = false;
            });
          } catch (e) {
            print('❌ MoMo: Error loading payUrl vào WebView: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Không thể tải trang thanh toán. Vui lòng thử lại.';
                _isLoading = false;
              });
            }
          }
        } else {
          print('⚠️ MoMo: WebViewController chưa sẵn sàng');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('❌ MoMo: Không có payUrl để fallback');
        if (mounted) {
          setState(() {
            _errorMessage = 'Không thể mở app MoMo. Vui lòng cài đặt app MoMo hoặc thử lại.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Lỗi mở app MoMo: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi mở app MoMo: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleNavigationUrl(String url) {
    print('🔗 Navigation URL: $url');
    
    // Check nếu URL chứa params từ MoMo return
    // Backend return URL: /api/payment/momo-return?resultCode=0&orderId=...&transId=...
    // Hoặc URL có chứa resultCode trong query params
    if (url.contains('resultCode') || url.contains('momo-return') || url.contains('/api/payment/')) {
      try {
        final uri = Uri.parse(url);
        final resultCode = uri.queryParameters['resultCode'];
        final transId = uri.queryParameters['transId'];
        final orderId = uri.queryParameters['orderId'];
        final amount = uri.queryParameters['amount'];
        final message = uri.queryParameters['message'];
        
        print('📋 Parsed params - ResultCode: $resultCode, TransId: $transId, OrderId: $orderId');
        
        // Cập nhật _orderId nếu có từ MoMo
        if (orderId != null && orderId.isNotEmpty) {
          _orderId = orderId;
        }
        
        // Xử lý resultCode (có thể là string "0" hoặc int 0)
        final code = resultCode?.toString().trim();
        if (code == '0') {
          // Thanh toán thành công - chỉ xử lý 1 lần
          if (!_isProcessing) {
            _isProcessing = true;
            final transactionId = transId ?? orderId ?? 'MOMO${DateTime.now().millisecondsSinceEpoch}';
            print('✅ Payment success detected, transactionId: $transactionId');
            _handlePaymentSuccess(transactionId);
          }
        } else if (code != null && code.isNotEmpty) {
          // Thanh toán thất bại - chỉ xử lý 1 lần
          if (!_isProcessing) {
            _isProcessing = true;
            print('❌ Payment failed, errorCode: $code');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MoMoPaymentResultScreen(
                    isSuccess: false,
                    orderId: _orderId ?? orderId ?? 'UNKNOWN',
                    amount: widget.amount,
                    errorCode: code,
                    message: message ?? _getErrorMessage(code),
                  ),
                ),
              ).then((_) {
                Navigator.pop(context, {
                  'success': false,
                  'reason': 'payment_failed',
                  'message': message ?? 'Mã lỗi: $code',
                  'errorCode': code,
                });
              });
            }
          }
        }
      } catch (e) {
        print('❌ Error parsing return URL: $e');
        // Nếu không parse được, thử detect bằng string matching
        if (url.contains('resultCode=0') || url.contains('resultCode%3D0')) {
          if (!_isProcessing) {
            _isProcessing = true;
            print('✅ Payment success detected (fallback)');
            _handlePaymentSuccess('MOMO${DateTime.now().millisecondsSinceEpoch}');
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
            builder: (context) => MoMoPaymentResultScreen(
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
            builder: (context) => MoMoPaymentResultScreen(
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

  String _getErrorMessage(String? resultCode) {
    // Sử dụng PaymentConfig để lấy message
    final code = int.tryParse(resultCode ?? '');
    return PaymentConfig.getMomoMessage(code);
  }


  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: momoPink,
          foregroundColor: Colors.white,
          title: const Text('MoMo', style: TextStyle(fontWeight: FontWeight.bold)),
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
                if (_errorMessage!.contains('localhost') || _errorMessage!.contains('MOMO_RETURN_URL'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💡 Hướng dẫn:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '1. Chạy: cd hotel-booking-backend && npm run setup-public-url\n'
                            '2. Hoặc dùng Cloudflare Tunnel (miễn phí)\n'
                            '3. Cập nhật MOMO_RETURN_URL trong file .env\n'
                            '4. Restart backend server',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _createPaymentUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: momoPink,
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

    // Hiển thị WebView trực tiếp (theo đúng flow MoMo)
    // MoMo sẽ tự động redirect đến trang thanh toán
    return Scaffold(
      appBar: AppBar(
        backgroundColor: momoPink,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('MoMo', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: const Text('Hủy thanh toán', style: TextStyle(color: momoPink)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: (_isLoading && _paymentUrl == null) || _webViewController == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: momoPink),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading && _paymentUrl == null
                        ? 'Đang tạo mã thanh toán...'
                        : _webViewController == null
                            ? 'Đang khởi tạo WebView...'
                            : 'Đang tải trang thanh toán...',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            )
          : _webViewController != null
              ? WebViewWidget(controller: _webViewController!)
              : const Center(
                  child: Text('Đang khởi tạo WebView...'),
                ),
    );
  }

}
