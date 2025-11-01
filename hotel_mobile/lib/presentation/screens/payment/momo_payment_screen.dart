/**
 * Màn hình thanh toán MoMo
 * 
 * Chức năng:
 * - Hiển thị thông tin đơn hàng
 * - Tạo payment request và mở WebView
 * - Xử lý kết quả thanh toán
 * 
 * Giao diện: Theo thiết kế MoMo chính thức (màu hồng #D82D8B)
 */

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/services/momo_service.dart';
import '../../../data/services/booking_history_service.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/backend_auth_service.dart';

/// Màn hình thanh toán MoMo
class MoMoPaymentScreen extends StatefulWidget {
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
  }) : super(key: key);

  @override
  State<MoMoPaymentScreen> createState() => _MoMoPaymentScreenState();
}

class _MoMoPaymentScreenState extends State<MoMoPaymentScreen> {
  final MoMoService _momoService = MoMoService();
  final BackendAuthService _authService = BackendAuthService();
  
  bool _isLoading = true;
  String? _paymentUrl;
  String? _qrCodeUrl;
  String? _deeplink;
  String? _errorMessage;
  bool _showWebView = false;
  late WebViewController _webViewController;

  // MoMo brand colors
  static const Color momoPink = Color(0xFFD82D8B);
  static const Color momoDarkPink = Color(0xFFB91C72);
  static const Color momoLightPink = Color(0xFFFFE5F1);

  @override
  void initState() {
    super.initState();
    _checkAuthAndCreatePayment();
  }

  /// Kiểm tra authentication trước khi tạo payment
  Future<void> _checkAuthAndCreatePayment() async {
    // Kiểm tra user đã đăng nhập chưa
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      setState(() {
        _errorMessage = 'Vui lòng đăng nhập để thanh toán';
        _isLoading = false;
      });
      
      // Hiển thị dialog yêu cầu login
      Future.delayed(Duration.zero, () {
        _showLoginRequiredDialog();
      });
      return;
    }
    
    _createPaymentRequest();
  }

  /// Hiển thị dialog yêu cầu đăng nhập
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: momoPink),
            SizedBox(width: 12),
            Text('Yêu cầu đăng nhập'),
          ],
        ),
        content: const Text('Bạn cần đăng nhập để sử dụng tính năng thanh toán MoMo.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {'success': false, 'reason': 'not_logged_in'}); // Close payment screen
            },
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {'success': false, 'reason': 'not_logged_in'}); // Close payment screen
              Navigator.pushNamed(context, '/login'); // Navigate to login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: momoPink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  /// Tạo payment request đến MoMo
  Future<void> _createPaymentRequest() async {
    try {
      final result = await _momoService.createPayment(
        bookingId: widget.bookingId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
      );

      // Lấy data từ response
      final payUrl = result['payUrl'];
      final qrUrl = result['qrCodeUrl'];
      final deeplink = result['deeplink'];
      
      if (payUrl != null && payUrl.isNotEmpty) {
        if (mounted) {
          setState(() {
            _paymentUrl = payUrl;
            _qrCodeUrl = qrUrl;
            _deeplink = deeplink;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Không nhận được payment URL từ MoMo');
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  /// Mở WebView để thanh toán
  void _openWebViewPayment() {
    if (_paymentUrl == null) return;
    
    setState(() {
      _showWebView = true;
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
            _handleNavigationUrl(url);
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            _handleNavigationUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_paymentUrl!));
  }

  /// Xử lý URL navigation để detect return từ MoMo
  void _handleNavigationUrl(String url) {
    // Check if this is return URL from MoMo
    if (url.contains('/payment/success') || url.contains('/payment/failed')) {
      // Parse URL parameters
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;
      
      if (url.contains('/payment/success')) {
        // Payment successful
        Navigator.pop(context, {
          'success': true,
          'orderId': queryParams['orderId'],
          'amount': queryParams['amount'],
          'transactionNo': queryParams['transactionNo'],
        });
      } else {
        // Payment failed
        Navigator.pop(context, {
          'success': false,
          'reason': queryParams['reason'],
          'message': queryParams['message'],
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show WebView if user clicked payment button
    if (_showWebView && _paymentUrl != null) {
      return _buildWebView();
    }

    // Loading state
    if (_isLoading) {
      return _buildLoadingState();
    }

    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: momoPink,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Thanh toán MoMo', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon với MoMo style
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lỗi kết nối MoMo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _checkAuthAndCreatePayment();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Thử lại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: momoPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'success': false,
                    'reason': 'error',
                  }),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // MoMo Payment UI with QR
    return _buildMoMoPaymentUI();
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Shimmer.fromColors(
              baseColor: momoPink.withOpacity(0.3),
              highlightColor: momoPink.withOpacity(0.1),
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: momoPink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(momoPink),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Đang kết nối đến MoMo...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: momoPink,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: momoPink),
                  SizedBox(width: 12),
                  Text('Hủy thanh toán?'),
                ],
              ),
              content: const Text('Bạn có chắc muốn hủy giao dịch thanh toán MoMo?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Không'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, {'success': false, 'reason': 'user_cancelled'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: momoPink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Hủy thanh toán'),
                ),
              ],
            ),
          );
        },
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/icons/momo_icon.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.account_balance_wallet, color: momoPink, size: 24);
              },
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'MoMo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoMoPaymentUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // MoMo Logo Card với gradient đẹp
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [momoPink, momoDarkPink],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: momoPink.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.account_balance_wallet, color: momoPink, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thanh toán',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Thanh toán nhanh chóng qua Ví MoMo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'MÔI TRƯỜNG TEST',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: momoLightPink,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: momoPink.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: momoPink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: momoPink, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mã đơn hàng',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BOOKING_${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: momoPink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.payments, color: momoPink, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Số tiền',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(widget.amount),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: momoPink,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // QR Code Section
            if (_qrCodeUrl != null) ...[
              const Text(
                'Quét mã QR để thanh toán',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrCodeUrl!,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: momoPink,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Payment Button - MoMo gradient style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [momoPink, momoDarkPink],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: momoPink.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _openWebViewPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.lock, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'THANH TOÁN BẰNG VÍ MOMO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Back button
            TextButton(
              onPressed: () => Navigator.pop(context, {'success': false, 'reason': 'user_cancelled'}),
              child: const Text(
                'Quay về',
                style: TextStyle(
                  color: momoPink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _paymentUrl != null
          ? WebViewWidget(controller: _webViewController)
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(momoPink),
              ),
            ),
    );
  }
}

